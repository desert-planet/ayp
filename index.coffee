path = require 'path'
url = require 'url'

Redis = require 'redis'
express = require 'express'
handlebars = require 'express-handlebars'
bodyParser = require 'body-parser'
morgan = require 'morgan'
expressLess = require 'express-less'

root = path.resolve(__dirname)

## External configuration
AYP_SECRET = process.env.AYP_SECRET or "That's my secret, they're all my pants."
GA_ID = process.env.GA_ID

## The "Database"
redis = do (->
  info = url.parse process.env.REDISTOGO_URL or
    process.env.REDISCLOUD_URL or
    process.env.BOXEN_REDIS_URL or
    'redis://localhost:6379'
  storage = Redis.createClient(info.port, info.hostname)
  storage.auth info.auth.split(":")[1] if info.auth
  return storage
)

## App config
app = express()
app.set 'port', (process.env.PORT or 5000)

# Logging
app.use morgan('short')

# Set up handlebars
app.set 'view engine', 'handlebars'
app.engine 'handlebars', handlebars
  defaultLayout: 'main'
  helpers:
    comicUrl: (at) -> "/at/#{at}/"

# App locals
app.locals.GA_ID = GA_ID if GA_ID

# View, static, and LESS paths on disk
app.set 'views', path.resolve(root, 'views')
app.use '/static/', express.static(path.resolve(root, 'public'))
app.use '/style/', expressLess path.resolve(root, 'style')

# Parse JSON
app.use(bodyParser.json(type: '*/json'))

## Application routes
app.get '/', (request, response) ->
  Comic.latest (err, comic) =>
    # TODO: Better error handling
    return response.status(404).send "I am literally on fire, and I can't find the latest" if err
    response.render 'strip', comic: comic

app.get '/archive/:start?', (request, response) ->
  # Select either the latest (if start is nonsense or missing)
  # or the Comic specifed at `start` to begin the archive page
  start = parseInt(request.params.start)
  if isNaN(start)
    fetch = (cb) -> Comic.latest(cb)
  else
    fetch = (cb) -> Comic.at(start, cb)

  fetch (err, first) =>
    # If we fail, redirect to the beginning of the archive
    return response.redirect("/archive/") if err

    Comic.before first.time, 10, (err, comicsBefore) =>
      return response.redirect("/archive/") if err

      # We fetch the list of comics after so we can generate
      # a "Previous" (Forward in time) archive page
      Comic.after first.time, 10, (err, comicsAfter) =>
        return response.redirect("/archive/") if err

        return response.render 'archive',
          archive: [first, comicsBefore[..-2]...]
          next: comicsBefore[comicsBefore.length - 1]
          prev: comicsAfter[comicsAfter.length - 1]

app.get '/random/', (request, response) ->
  Comic.random (err, comic) =>
    # If we fuck up, go back to /
    return response.redirect('/') if err
    return response.redirect("/at/#{comic.time}/")

app.get '/at/:stamp', (request, response) ->
  failHome = ->
    return response.redirect('/')
  return failHome() if isNaN(stamp = parseInt(request.params.stamp))

  Comic.at stamp, (err, comic) ->
    return failHome() if err
    response.render 'strip', comic: comic

app.post "/new/", (req, res) ->
  res.set 'Content-Type', 'application/json'
  if req.body.secret != AYP_SECRET
    return res.status(401).
      send JSON.stringify error: "You don't know the secret."

  {url, time} = req.body
  return res.status(400).
    send JSON.stringify(error: "Bad format") unless url && time

  (new Comic(url, time)).save (err, comic) ->
    return res.status(500).send(JSON.stringify error: "#{err}") if err
    res.send JSON.stringify {ok: Date.now()}

## Boot sequence
app.listen app.get('port'), ->
  console.log "Your pants running at http://localhost:#{app.get('port')}/"

## Helpers, models, "Uesr Code"
AYP_PREFIX = "ayp:"

# The Comic data model.
class Comic
  @prefix: AYP_PREFIX

  # The Class and Instance accessors for the keys.
  # The instance accessor just looks it up by class one
  @key: () -> "#{@prefix}:comics"
  key: -> @constructor.key()

  # Describe either a new, or exsting comic
  constructor: (@url, @time, options={}) ->
    @saved = options.saved ? false

  # Store the current commic in the database.
  save: (cb=(->)) ->
    return cb("already saved") if @saved
    @saved = true
    redis.zadd [@key(), @time, @url], (err, res) ->
      # TODO: Check success and pass loading through Comic.at
      cb(err, this)

  # Populate `prev` and `next` if possible, then invoke callback
  # The new properties will be populated with timestamps, not comic objects
  #
  # Requires that `@time` is set
  update: (cb) ->
    cb("@time not set") unless @time

    failed = false
    finish = (finishPart) =>
      (err, res) =>
        return if failed # Make sure nothing else happens after we fail
        return cb(failed = true) if err # The first failure is reported to the caller

        # At this point, we can finish the part we were given
        finishPart(res)

        # Then return success to the caller if we filled in both sides
        return cb(undefined, this) if (@next isnt undefined) and (@prev isnt undefined)

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


  # Fetch the latest comic and invoke cb as in `Comic.at`
  @latest: (cb) ->
    redis.zrange [@key(), -1, -1, "WITHSCORES"], (err, res) ->
      return cb(err) if err
      return cb(null, new Comic("http://s3.amazonaws.com/ayp/db.jpg", 0)) unless res.length > 0
      return Comic.at(res[1], cb) # We piggy-back on `Comic.at` to DRY the fetch->update->callback path
