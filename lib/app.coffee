path = require 'path'

ROOT = path.resolve(__dirname, '..')

express = require 'express'
handlebars = require 'express-handlebars'
bodyParser = require 'body-parser'
morgan = require 'morgan'
expressLess = require 'express-less'

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
app.use '/style/', expressLess path.resolve(ROOT, 'style')

# Parse JSON
app.use(bodyParser.json(type: '*/json'))
