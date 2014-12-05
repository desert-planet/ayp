## The applications routes are loaded from inside of `app.coffee` after
## the app is configured.
##
## There's not a good reason to ever require this manually, require `./app` isntead

app = require './app'
Comic = require './comic'

## Application routes
app.get '/', (request, response) ->
  Comic.latest (err, comic) =>
    # TODO: Better error handling
    return response.status(404).send "I am literally on fire, and I can't find the latest" if err
    response.render 'strip', comic: comic

app.get '/feed.xml', (request, response) ->
  Comic.archive 'latest', 100, (err, archive) ->
    return response.status(500).send "Sorry, my programming broke building the feed" if err

    response.set 'Content-Type', 'application/rss+xml'
    return response.render 'feed',
      layout: null
      archive: archive.archive

app.get '/top/:page?', (request, response) ->
  failHome = -> return response.redirect('/')

  # If the page is bullshit, we go to one.
  page = parseInt(request.params.page || 1)
  page = 1 if isNaN(page)

  perPage = 10
  skipTotal = ((page - 1) * perPage)

  # We fetch one more than we ask for, so that we can know if we
  # have a potential next page
  Comic.top (perPage + 1), skipTotal, (err, comics) =>
    return response.status(400).send JSON.stringify err: err if err
    response.render 'top',
      top: comics[0...perPage]
      page: page
      nextPage: if (comics[perPage..].length > 0) then page + 1
      prevPage: if (page > 1) then page - 1

app.get '/archive/:start?', (request, response) ->
  Comic.archive request.params.start, 10, (err, archive) =>
    return response.redirect("/archive/") if err
    return response.render 'archive', archive

app.get '/random/', (request, response) ->
  Comic.random (err, comic) =>
    # If we fuck up, go back to /
    return response.redirect('/') if err
    return response.redirect("/at/#{comic.time}/")

app.get '/at/:stamp?', (request, response) ->
  failHome = ->
    return response.redirect('/')
  return failHome() if isNaN(stamp = parseInt(request.params.stamp))

  Comic.at stamp, (err, comic) ->
    return failHome() if err
    response.render 'strip', comic: comic

app.post "/vote/:stamp?", (req, res) ->
  fail = (why, status=400) ->
    res.status(status).send JSON.stringify error: why
  res.set 'Content-Type', 'application/json'

  if isNaN(stamp = parseInt(req.params.stamp))
    return fail "Bad comic index #{req.params.stamp}"
  unless req.body.now
    return fail "You didn't even try that hard!"

  Comic.at stamp, (err, comic) =>
    return fail("Failed to load comic @#{stamp}") if err
    comic.vote req.ip, (err, comic) =>
      # An error that is also okay is a soft error,
      # we'll tell the user to not do it agin with the reason
      if err && {ok: reason} = err
        return fail(reason, 403)
      # Any other error is just flunked out
      return fail("Failed to vote") if err
      return res.send JSON.stringify
        ok: 'count'
        count: comic.votes


app.post "/new/", (req, res) ->
  res.set 'Content-Type', 'application/json'
  if req.body.secret != app.locals.AYP_SECRET
    return res.status(401).
      send JSON.stringify error: "You don't know the secret."

  {url, time} = req.body
  return res.status(400).
    send JSON.stringify(error: "Bad format") unless url && time

  (new Comic(url, time)).save (err, comic) ->
    return res.status(500).send(JSON.stringify error: "#{err}") if err
    res.send JSON.stringify {ok: Date.now()}
