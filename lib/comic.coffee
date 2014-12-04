redis = require './redis-connection'

# The Comic data model.
module.exports = class Comic
  @prefix: "ayp:"

  # The Class and Instance accessors for the keys.
  # The instance accessor just looks it up by class one
  @key: (suffix) ->
    key = "#{@prefix}:comics"
    key += ":#{suffix}" if suffix?
    key
  key: (suffix) -> @constructor.key(suffix)

  # Describe either a new, or exsting comic
  constructor: (@url, @time, options={}) ->
    @votes = 0
    @saved = options.saved ? false

  # Store the current commic in the database.
  save: (cb=(->)) ->
    return cb("already saved") if @saved
    @saved = true
    redis.zadd [@key(), @time, @url], (err, res) ->
      # TODO: Check success and pass loading through Comic.at
      cb(err, this)

  # Return the mime type of the image
  mime: ->
    ext = @url[-3..].toLowerCase()
    return "image/#{ext}"

  # Cast a vote for `this`. The `caster` should be a permanent-ish
  # identifier for a voter, each `caster` can vote for every Comic once
  #
  # Callback will be invoked as `cb(err, comic)`.
  vote: (caster, cb) =>
    caster ?= 'anonymous'

    # TODO: Guard by caster
    redis.zincrby @key('votes'), 1, @url, (err, res) =>
      return cb(err) if err
      return @update(cb)

  # Populate `prev` and `next` if possible, then invoke callback
  # The new properties will be populated with timestamps, not comic objects
  #
  # Requires that `@time` is set
  update: (cb) ->
    cb("@time not set") unless @time

    failed = false
    gotVotes = false
    finish = (finishPart) =>
      (err, res) =>
        return if failed # Make sure nothing else happens after we fail
        return cb(failed = true) if err # The first failure is reported to the caller

        # At this point, we can finish the part we were given
        finishPart(res)

        # Then return success to the caller if we filled in both sides
        if (@next isnt undefined) and (@prev isnt undefined) and gotVotes
          return cb(undefined, this)

    # Fire the workers to update the next and prev
    #
    # To avoid `undefined`, we set `null` explictly
    # so that the `finish` check can be an explicit test for `undefined`
    #
    # We use offset the start/stop time by one to make sure we exclude ourselves from the result.
    # This works ONLY because we have integer precision timestamps, so that the next closest comic can only
    # be exacly +/-1 away from the current.
    #
    # I would **like** to use the `'(start', +inf` notation, but the redis library doesn't allow it as it asserts
    # the arguments have to be floats :rage4:
    redis.zrangebyscore [@key(), "#{@time + 1}", '+inf', 'WITHSCORES', 'LIMIT', 0, 1], finish (res) =>
        @next = res[1] || null
    redis.zrevrangebyscore [@key(), "#{@time - 1}", '-inf', 'WITHSCORES', 'LIMIT', 0, 1], finish (res) =>
        @prev = res[1] || null

    # Kick off the job to fetch the vote count, or keep it at 0
    redis.zscore @key('votes'), @url, finish (res) =>
      @votes = res or 0
      gotVotes = true


  # Return a comic stamped at `stamp` to caller by
  # invoking callback as `cb(err, Comic)` if it is found.
  # `err` will be set otherwise
  @at: (stamp, cb) ->
    redis.zrangebyscore [@key(), stamp, stamp], (err, res) ->
      return cb(err) if err
      return cb("Not found") unless res.length > 0

      # If we found a comic, we'll stuff what we know about it
      # and invoke `Comic#update` and pass our callback down to it
      # to be invoked whtn the structure is fully filled in
      (new Comic(res[0], stamp, saved: true)).update(cb)

  @random: (cb) =>
    redis.zcard @key(), (err, count) =>
      return cb(err) if err
      pick = Math.round(Math.random() * (count - 1))
      redis.zrange [@key(), pick, pick, 'WITHSCORES'], (err, res) =>
        return cb(err) if err
        [url, at] = res
        return Comic.at(at, cb)

  @before: (stamp, count, cb) =>
    redis.zrevrangebyscore [@key(), (stamp - 1), '-inf', "WITHSCORES", "LIMIT", 0, count], (err, res) ->
      return cb(err) if err

      # Transform the list into lazy objects.
      comics = []
      for i in [0...res.length] by 2
        comics.push new Comic(res[i], res[i+1], saved: true)

      cb(undefined, comics)

  @after: (stamp, count, cb) =>
    redis.zrangebyscore [@key(), (stamp + 1), '+inf', "WITHSCORES", "LIMIT", 0, count], (err, res) ->
      return cb(err) if err

      # Transform the list into lazy objects.
      comics = []
      for i in [0...res.length] by 2
        comics.push new Comic(res[i], res[i+1], saved: true)

      cb(undefined, comics)

  # Invoke callback as `cb(err, {archive: [Comic, ...], next: Comic, prev: Comic}...)`
  # `err` will be set if an error is encountered.
  #
  # Every Comic except the first comic in the `archive:` list are shallow-loaded, and should _NOT_
  # be expected to contain pointer information, only the `Comic#time` should be considered correct, and if
  # any additional info is required it should be loaded with `Comic.at` using `Comic#time` on the shallow
  # objects.
  @archive: (start, count, cb) ->
    # Select either the latest (if start is nonsense or missing)
    # or the Comic specifed at `start` to begin the archive page
    start = parseInt(start)
    if isNaN(start)
      fetch = (cb) -> Comic.latest(cb)
    else
      fetch = (cb) -> Comic.at(start, cb)

    fetch (err, first) =>
      return cb(err) if err
      Comic.before first.time, count, (err, comicsBefore) =>
        return cb(err) if err
        # We fetch the list of comics after so we can generate
        # a "Previous" (Forward in time) archive page
        Comic.after first.time, count, (err, comicsAfter) =>
          return cb(err) if err
          cb undefined,
            archive: [first, comicsBefore[..-2]...]
            next: comicsBefore[comicsBefore.length - 1]
            prev: comicsAfter[comicsAfter.length - 1]



  # Fetch the latest comic and invoke cb as in `Comic.at`
  @latest: (cb) ->
    redis.zrange [@key(), -1, -1, "WITHSCORES"], (err, res) ->
      return cb(err) if err
      return cb(null, new Comic("http://s3.amazonaws.com/ayp/db.jpg", 0)) unless res.length > 0
      return Comic.at(res[1], cb) # We piggy-back on `Comic.at` to DRY the fetch->update->callback path
