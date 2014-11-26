path = require 'path'
url = require 'url'

Redis = require 'redis'
express = require 'express'
handlebars = require 'express-handlebars'
bodyParser = require 'body-parser'

root = path.resolve(__dirname)

## External configuration
AYP_SECRET = process.env.AYP_SECRET or "That's my secret, they're all my pants."

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


app.set 'view engine', 'handlebars'
app.engine 'handlebars', handlebars(defaultLayout: 'main')

app.set 'views', path.resolve(root, 'views')
app.use '/static/', express.static(path.resolve(root, 'public'))



# Parse JSON
app.use(bodyParser.json(type: '*/json'))

## Application routes
app.get '/', (request, response) ->
  Comic.latest (err, comic) ->
    # TODO: Better error handling
    return response.status(404).send "I am literally on fire" if err

    response.render 'strip', comic: comic

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

  @key: () -> "#{@prefix}:comics"
  key: -> @constructor.key()

  constructor: (@url, @time, options={}) ->
    @saved = options.saved ? false

  save: (cb=(->)) ->
    return cb("already saved") if @saved
    @saved = true
    redis.zadd [@key(), @time, @url], (err, res) ->
      cb(err, this)

  # Return a comic stamped at `stamp` to caller by
  # invoking callback as `cb(err, Comic)` if it is found.
  # `err` will be set otherwise
  @at: (stamp, cb) ->
    redis.zrangebyscore [@key(), stamp, stamp], (err, res) ->
      return cb(err) if err
      return cb("Not found") unless res.length > 0
      cb(null, new Comic(res[0], stamp, saved: true))


  @latest: (cb) ->
    redis.zrange [@key(), -1, -1, "WITHSCORES"], (err, res) ->
      return cb(err) if err
      return cb(null, new Comic("http://s3.amazonaws.com/ayp/db.jpg", 0)) unless res.length > 0
      return cb(null, new Comic(res[0], res[1], saved: true))