http    = require 'http'
urllib  = require 'url'

proxy = http.createServer (request, response) ->
  url = urllib.parse request.url
  proxied = http.request
    port: process.env.UPSTREAM_PORT
    method: request.method
    path: url.path
    auth: url.auth
    headers: request.headers
  proxied.once 'response', (upstream) ->
    response.writeHead upstream.statusCode, upstream.headers
    upstream.pipe response
  request.pipe proxied

proxy.listen process.env.PORT
