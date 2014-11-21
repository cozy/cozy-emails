
# See cozy-fixtures documentation for testing on
# https://github.com/jsilvestre/cozy-fixtures#automatic-tests
fixtures = require 'cozy-fixtures'
{exec} = require 'child_process'
DovecotTesting = require 'dovecot-testing'
Imap = require 'imap'
_ = require 'lodash'

module.exports = helpers = {}

helpers.app = null

helpers.getImapServerRawConnection = (done, operation) ->

    next = _.once done
    imap = new Imap
        user: "testuser"
        password: "applesauce"
        host: DovecotTesting.serverIP()
        port: 993
        tls: true
        tlsOptions: rejectUnauthorized: false
    imap.on 'ready', operation.bind imap
    imap.on 'error', (err) -> next err
    imap.on 'close', (err) ->
        if err then next err else next null
    imap.connect()

helpers.startApp = (host, port) -> (done) ->
    @timeout 20000
    americano = require 'americano'

    americano.start name: 'template', host: host, port: port, (app, server) =>
        @app = app
        @app.server = server
        done()

helpers.stopApp = (done) ->
    @timeout 10000
    if @app then @app.server.close done
    else done null