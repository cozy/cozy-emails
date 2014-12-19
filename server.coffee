americano = require 'americano'

application = module.exports.start = (options, callback) ->
    options ?= {}
    options.name = 'webmail'
    options.root ?= __dirname
    options.port ?= process.env.PORT or 9125
    options.host ?= process.env.HOST or '0.0.0.0'

    global.MODEL_MODULE = 'americano-cozy-pouchdb'

    callback ?= ->

    americano.start options, (app, server) ->
        callback null, app, server

if not module.parent
    application()
