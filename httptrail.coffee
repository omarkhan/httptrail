#!/usr/bin/env coffee

http    = require 'http'
stream  = require 'stream'
urllib  = require 'url'


exports.HttpStream = class HttpStream extends stream.Transform

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


exports.proxy = proxy = (host) ->
  host = urllib.parse cleanHost host
  if host.protocol not in ['http:', 'https:']
    throw new Error 'httptrail only supports http'
  client = if host.protocol == 'https:' then require 'https' else http

  return http.createServer (request, response) ->
    log =
      request:  new HttpStream prefix: '> '
      response: new HttpStream prefix: '< '

    log.request.pipe  process.stdout
    log.response.pipe process.stdout

    url = urllib.parse request.url
    proxied = client.request
      hostname: host.hostname
      port:     host.port
      method:   request.method
      path:     url.path
      auth:     url.auth
      headers:  request.headers
    request.pipe proxied
    request.pipe log.request

    proxied.once 'response', (upstream) ->
      response.writeHead upstream.statusCode, upstream.headers
      upstream.pipe response
      upstream.pipe log.response


cleanHost = (host) ->
  host = host.trim()
  if /^\d+$/.test host
    host = "http://localhost:#{host}/"
  else if not /:\/\//.test host
    host = host.replace /^(\/\/)?/, 'http://'
  {protocol, hostname, port} = urllib.parse host
  protocol ||= 'http:'
  hostname ||= 'localhost'
  port     ||= 8000
  return "#{protocol}//#{hostname}:#{port}/"


if require.main == module
  [upstream, port] = process.argv[2..]
  if upstream and port
    try
      upstream = cleanHost upstream
      proxy(upstream).listen(port)
    catch error
      process.stderr.write "#{error}\n"
      process.exit 1
    process.stderr.write "Proxying port #{port} to upstream server at #{upstream}\n"
  else
    process.stderr.write 'Usage: httptrail <upstream host> <proxy port>\n'
    process.exit 1
