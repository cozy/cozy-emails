fs        = require 'fs'
path      = require 'path'
americano = require 'americano'
cozydb    = require 'cozydb'

log            = require('./utils/logging')(prefix: 'config')
{errorHandler} = require './utils/errors'

viewsDir     = path.resolve __dirname, 'views'
useBuildView = fs.existsSync path.resolve viewsDir, 'index.js'


config =
    common:
        set:
            'view engine': if useBuildView then 'js' else 'jade'
            'views': viewsDir

        engine:
            js: (path, locals, callback) ->
                callback null, require(path)(locals)

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
            Scheduler          = require './processes/_scheduler'
            SocketHandler      = require './utils/socket_handler'
            ApplicationStartup = require './processes/application_startup'

            SocketHandler.setup app, server

            # Try to get assets definitions from root (only valid in build, not
            # used in watch mode)
            try
                assets = require('../webpack-assets.json').main
            catch
                assets =
                    js: 'app.js'
                    css: 'app.css'
            app.locals.assets = assets

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
