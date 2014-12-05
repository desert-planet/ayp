chalk = require 'chalk'
fs = require 'fs'
childprocess = require 'child_process'
spawn = childprocess.spawn

app = null

spawnApp = ->
  console.log chalk.green 'spawning app'
  app = spawn 'coffee', ['server.coffee']
  app.on 'close', (code, signal) ->
    console.log chalk.green 'server.coffee closed with signal ', signal if signal
  app.stdout.on 'data', (data) ->
    console.log '' + data
  app.stderr.on 'data', (data) ->
    console.log chalk.red 'server.coffee STDERR: ', '' + data

cycleApp = ->
  console.log chalk.yellow 'killing app'
  app.kill()
  spawnApp()

handleFileChange = (filename) ->
  return if /^\.\#/.test(filename) # Fuck a color emacs temp
  if /coffee$/.test(filename) == true
    console.log chalk.yellow 'file changed: ', filename
    console.log chalk.yellow 'cycling app'
    cycleApp()

fs.watch '.', (event, filename) ->
  handleFileChange filename

fs.watch 'lib', (event, filename) ->
  handleFileChange filename

spawnApp()
