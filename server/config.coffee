path = require 'path'
americano = require 'americano'
ImapReporter = require './processes/imap_reporter'
Account = require './models/account'

require './utils/promise_extensions'
if process.env.NODE_ENV isnt 'production'
    require('bluebird').longStackTraces()

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
            app.use americano.errorHandler()
            ImapReporter.initSocketIO app, server
            Account.refreshAllAccounts()


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