


americano = require 'americano'

application = module.exports = (options, callback) ->
    options ?= {}
    options.name = 'cozy-emails'
    options.root ?= __dirname
    options.port ?= process.env.PORT or 9125
    options.host ?= process.env.HOST or '127.0.0.1'

    callback ?= ->

    americano.start options, (app, server) ->
        callback null, app, server

if not module.parent
    application()
