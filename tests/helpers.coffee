
# See cozy-fixtures documentation for testing on
# https://github.com/jsilvestre/cozy-fixtures#automatic-tests
fixtures = require 'cozy-fixtures'
{exec} = require 'child_process'
DovecotTesting = require 'dovecot-testing'
Imap = require '../server/imap/connection'
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

helpers.waitAllTaskComplete = (done) ->
    lastFinished = false
    checkIfDone = ->
        client.get "/refreshes", (err, res, body) ->
            console.log "WAITING TASKS", body
            finished = not body.some (task) -> not task.finished
            if finished and lastFinished then return done()

            lastFinished = finished
            setTimeout checkIfDone, 1000

    setTimeout checkIfDone, 1000

helpers.startApp = (appPath, host, port) -> (done) ->
    @timeout 20000

    app = require appPath + 'server'

    options = {host, port, name:'emails-tests'}
    app options, (err, app, server) =>
        return done err if err
        @app = app
        @app.server = server
        done()

helpers.stopApp = (done) ->
    @timeout 10000
    if @app then @app.server.close done
    else done null
