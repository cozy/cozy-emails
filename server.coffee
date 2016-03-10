americano = require 'americano'


module.exports = application =  (options = {}, callback = ->) ->
    options.name = 'cozy-emails'
    options.root ?= __dirname
    options.port ?= process.env.PORT or 9125
    options.host ?= process.env.HOST or '127.0.0.1'

    americano.start options, callback


if not module.parent
    application()
