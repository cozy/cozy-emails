path = require 'path'
americano = require 'americano'
Account = require './models/account'
ImapReporter = require './imap/reporter'
log = require('./utils/logging')(prefix: 'config')

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
            ImapReporter.initSocketIO app, server

            Account.removeOrphansAndRefresh null, false, ->
                log.info "initial refresh completed"

    development: [
        americano.logger 'dev'
    ]

    production: [
        americano.logger 'short'
    ]

    plugins: [
        'americano-cozy'
    ]

module.exports = config