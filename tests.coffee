assert = require 'assert'
http = require 'http'
server = require './server'
port = 5000

getGetOptions = (path) ->
  options = {
    "host": "localhost",
    "port": port,
    "path": path,
    "method": "GET"
  }
  return options

describe 'server', ->
  it 'just works', ->
    headers = getGetOptions '/'
    http.get headers, (res) ->
      assert res.statusCode == 200
