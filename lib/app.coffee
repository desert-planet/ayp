path = require 'path'

ROOT = process.env.APP_ROOT

express = require 'express'
handlebars = require 'express-handlebars'
bodyParser = require 'body-parser'
morgan = require 'morgan'
expressLess = require 'express-less'
favicon = require 'serve-favicon'

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

# View, static, and LESS paths on disk
app.set 'views', path.resolve(ROOT, 'views')
app.use '/static/', express.static(path.resolve(ROOT, 'public'))
app.use '/style/', expressLess path.resolve(ROOT, 'assets', 'style')

# The most important thing of all.The /favicon.ico handler
app.use favicon(path.resolve(ROOT, 'public', 'favicon.ico'))

# Parse JSON
app.use(bodyParser.json(type: '*/json'))
