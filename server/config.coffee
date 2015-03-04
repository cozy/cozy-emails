path      = require 'path'
americano = require 'americano'
log       = require('./utils/logging')(prefix: 'config')
CONSTANTS = require './utils/constants'
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

        afterStart: (app, server) ->
            # move it here needed after express 4.4
            app.use errorHandler
            SocketHandler = require './utils/socket_handler'
            SocketHandler.setup app, server
            Account = require './models/account'
            if process.env.NODE_ENV is 'production'
                limitByBox    = null
                onlyFavorites = false
            else
                # Don't refresh all malboxes to speed up restart on
                # developement environment
                limitByBox    = CONSTANTS.LIMIT_BY_BOX
                onlyFavorites = true
            Account.removeOrphansAndRefresh limitByBox, onlyFavorites, ->
                log.info "initial refresh completed"

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
