
# See cozy-fixtures documentation for testing on
# https://github.com/jsilvestre/cozy-fixtures#automatic-tests
fixtures = require 'cozy-fixtures'
{exec} = require 'child_process'
DovecotTesting = require 'dovecot-testing'

module.exports = helpers = {}

helpers.app = null

helpers.getImapServerRawConnection = ->
    Imap = require '../server/processes/imap_promisified'
    imap = new Imap
        user: "testuser"
        password: "applesauce"
        host: DovecotTesting.serverIP()
        port: 993
        tls: true
        tlsOptions: rejectUnauthorized: false

helpers.startApp = (host, port) -> (done) ->
    @timeout 10000
    americano = require 'americano'

    americano.start name: 'template', host: host, port: port, (app, server) =>
        @app = app
        @app.server = server
        done()

helpers.stopApp = (done) ->
    @timeout 10000
    if @app then @app.server.close done
    else done null