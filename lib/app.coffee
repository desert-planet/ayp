path = require 'path'

express = require 'express'
handlebars = require 'express-handlebars'
bodyParser = require 'body-parser'
morgan = require 'morgan'
favicon = require 'serve-favicon'
mincer = require 'mincer'

## Set up the app
module.exports = app = express()

## Set the env so that we don't have to ask again
APP_ROOT = process.env.APP_ROOT = path.resolve(__dirname, '..')

## External configuration
app.locals.AYP_SECRET = process.env.AYP_SECRET or "That's my secret, they're all my pants."
app.locals.GA_ID = process.env.GA_ID


# Heroku forwards our clients with `X-Forarded-For`
# and also sets the port
app.set 'port', (process.env.PORT or 5000)
app.set 'trust proxy', true

# Logging
app.use morgan('short')

# Set up handlebars
app.set 'view engine', 'handlebars'
app.engine 'handlebars', handlebars
  defaultLayout: 'main'
  helpers:
    comicUrl: (at) -> "/at/#{at}/"
    baseUrl: -> "http://ayp.wtf.cat" # TODO: Switch on development mode
    xmlDate: (at) -> (new Date(parseInt(at))).toUTCString()
    banner: ->
      ads = [
        '<a href="http://amongthechosen.com/" title="Among the Chosen"><img alt="Ad for Among the Chosen" src="/static/images/ayp_atc.jpg"></a>',
        '<a href="http://19teeth.org/" title="19 Tooth Foundation"><img alt="Ad for 19 Tooth Foundation" src="/static/images/ayp_19t.jpg"></a>',
        '<a href="https://www.youtube.com/channel/UCke_95iHaMHXxzD13TpCR4Q" title="Arctic Taco Gaming"><img alt="Ad for Arctic Taco Gaming" src="/static/images/ayp_atg.png"></a>',
      ]
      ad = ads[Math.floor(math.random()*ads.length)]
      return ad


# View, static, and LESS paths on disk
app.set 'views', path.resolve(APP_ROOT, 'views')
app.use '/static/', express.static(path.resolve(APP_ROOT, 'public'))

# The most important thing of all.The /favicon.ico handler
app.use favicon(path.resolve(APP_ROOT, 'public', 'favicon.ico'))

# Handle assets with mincer.
mincerEnv = new mincer.Environment();
mincerEnv.appendPath path.resolve(APP_ROOT, 'assets')

mincer.CoffeeEngine.configure bare: false

app.use '/assets', mincer.createServer(mincerEnv)

# Parse JSON
app.use(bodyParser.json(type: '*/json'))

# Load app routes
require './routes'