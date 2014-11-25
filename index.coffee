path = require 'path'
url = require 'url'

Redis = require 'redis'
express = require 'express'
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
app.use express.static(path.resolve(root, 'public'))

# Parse JSON
app.use(bodyParser.json(type: '*/json'))

## Application routes
app.get '/', (request, response) ->
  redis.info (err, res) ->
    response.send "All who's pants?"

app.post "/new/", (req, res) ->
  res.set 'Content-Type', 'application/json'
  if req.body.secret != AYP_SECRET
    return res.status(401).
      send JSON.stringify error: "You don't know the secret."

  {url, time} = req.body
  return res.status(400).
    send JSON.stringify(error: "Bad format") unless url && time

  # TODO: Stuff image into a place

  res.send JSON.stringify {ok: Date.now()}

## Boot sequence
app.listen app.get('port'), ->
  console.log "Your pants running at http://localhost:#{app.get('port')}/"