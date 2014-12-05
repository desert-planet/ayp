path = require 'path'
app = require './lib/app'

## Boot sequence
app.listen app.get('port'), ->
  console.log "Your pants running at http://localhost:#{app.get('port')}/"
