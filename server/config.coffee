path      = require 'path'
americano = require 'americano'
log       = require('./utils/logging')(prefix: 'config')
CONSTANTS = require './utils/constants'
async = require 'async'
cozydb = require 'cozydb'
{errorHandler} = require './utils/errors'


initializeSocketHandler = (app, server, callback) ->
    SocketHandler = require './utils/socket_handler'
    SocketHandler.setup app, server
    callback null

initializeAccountRefresh = (callback) ->
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
        callback null

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
            async.series [
                #(cb) -> cozydb.forceReindexing cb
                (cb) -> initializeSocketHandler app, server, cb
                (cb) -> initializeAccountRefresh cb
            ], (err) ->
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
