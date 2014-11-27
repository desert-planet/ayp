path = require 'path'
rek = require 'rekuire'

## Set the env so that we don't have to ask again
APP_ROOT = process.env.APP_ROOT = path.resolve(__dirname)

## External configuration
AYP_SECRET = process.env.AYP_SECRET or "That's my secret, they're all my pants."
GA_ID      = process.env.GA_ID

## Load and configure the app
app = rek '/lib/app'
Comic = rek '/lib/Comic'

app.locals.GA_ID = GA_ID
app.set 'port', (process.env.PORT or 5000)

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
