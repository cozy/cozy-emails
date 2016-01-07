path      = require 'path'
americano = require 'americano'
log       = require('./utils/logging')(prefix: 'config')
cozydb    = require 'cozydb'
{errorHandler} = require './utils/errors'

config =
    common:
        set:
            'view engine': 'jade'
            'views': path.resolve __dirname, 'views'
        use: [
            americano.bodyParser()
            americano.methodOverride()
            americano.static __dirname + '/../client/public',
                maxAge: 86400000
        ]

        useAfter: [
            errorHandler
        ]

        afterStart: (app, server) ->
            SocketHandler = require './utils/socket_handler'
            SocketHandler.setup app, server

            Scheduler = require './processes/_scheduler'
            ApplicationStartup = require './processes/application_startup'
            proc = new ApplicationStartup()
            Scheduler.schedule proc, (err) ->
                log.info "Initialization complete"

    development: [
        americano.logger 'dev'
    ]

    production: [
        americano.logger 'short'
    ]

    plugins: [
        'cozydb'
    ]

module.exports = config
