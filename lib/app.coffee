path = require 'path'

ROOT = process.env.APP_ROOT

express = require 'express'
handlebars = require 'express-handlebars'
bodyParser = require 'body-parser'
morgan = require 'morgan'
favicon = require 'serve-favicon'
mincer = require 'mincer'

## Set up the app
module.exports = app = express()

# Logging
app.use morgan('short')

# Set up handlebars
app.set 'view engine', 'handlebars'
app.engine 'handlebars', handlebars
  defaultLayout: 'main'
  helpers:
    comicUrl: (at) -> "/at/#{at}/"
    baseUrl: -> "http://ayp.wtf.cat" # TODO: Switch on development mode
    xmlDate: (at) -> (new Date(parseInt(at))).toString()

# View, static, and LESS paths on disk
app.set 'views', path.resolve(ROOT, 'views')
app.use '/static/', express.static(path.resolve(ROOT, 'public'))

# The most important thing of all.The /favicon.ico handler
app.use favicon(path.resolve(ROOT, 'public', 'favicon.ico'))

# Handle assets with mincer.
mincerEnv = new mincer.Environment();
mincerEnv.appendPath path.resolve(ROOT, 'assets')
app.use '/assets', mincer.createServer(mincerEnv)

# Parse JSON
app.use(bodyParser.json(type: '*/json'))
