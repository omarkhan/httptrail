http    = require 'http'
stream  = require 'stream'
urllib  = require 'url'


class HttpStream extends stream.Transform

  constructor: (options) ->
    super
    this.prefix = options.prefix or ''
    this.buffer = ''
    this.on 'pipe', this.headers

  headers: (request) ->
    for header, value of request.headers
      this.write "#{header}: #{value}\n"
    this.write '\n'

  format: (line) => "#{this.prefix}#{line}\n"

  _transform: (chunk, encoding, done) ->
    this.buffer += chunk.toString(if encoding == 'buffer' then null else encoding)
    if this.buffer.indexOf('\n') > -1
      [lines..., this.buffer] = this.buffer.split '\n'
      this.push lines.map(this.format).join('')
    done()

  _flush: (done) ->
    this.push this.format this.buffer if this.buffer
    done()


proxy = http.createServer (request, response) ->
  log =
    request:  new HttpStream prefix: '> '
    response: new HttpStream prefix: '< '

  log.request.pipe  process.stdout
  log.response.pipe process.stdout

  url = urllib.parse request.url
  proxied = http.request
    port:    process.env.UPSTREAM_PORT
    method:  request.method
    path:    url.path
    auth:    url.auth
    headers: request.headers
  request.pipe proxied
  request.pipe log.request

  proxied.once 'response', (upstream) ->
    response.writeHead upstream.statusCode, upstream.headers
    upstream.pipe response
    upstream.pipe log.response

proxy.listen process.env.PORT
