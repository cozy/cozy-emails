
# See cozy-fixtures documentation for testing on
# https://github.com/jsilvestre/cozy-fixtures#automatic-tests
fixtures = require 'cozy-fixtures'
{exec} = require 'child_process'
Client = require('request-json').JsonClient

helpers = {}

# server management
helpers.options =
    serverPort: '8888'
    serverHost: 'localhost'
helpers.app = null
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

helpers.getClient = -> client

helpers.startImapServer = (done) ->
    @timeout 60000 # this is damn slow
    DovecotStartScript = 'sh tests/DovecotTesting/SetupEnvironment.sh'
    exec DovecotStartScript, (err, stdout, stderr) ->
        if err
            console.log err, stderr
            done new Error('failed to start dovecot')
        else
            done null

helpers.imapServerAccount = ->
    label: "DoveCot"
    login: "testuser"
    password: "applesauce"
    smtpServer: "172.0.0.1"
    smtpPort: 0
    imapServer: "127.0.0.1"
    imapPort: 993
    imapSecure: true

helpers.startApp = (done) ->
    @timeout 10000
    americano = require 'americano'

    host = helpers.options.serverHost || "127.0.0.1"
    port = helpers.options.serverPort || 9250

    americano.start name: 'template', host: host, port: port, (app, server) =>
        @app = app
        @app.server = server
        done()

helpers.stopApp = (done) ->
    @timeout 10000
    if @app then @app.server.close done
    else done null

# database helper
helpers.cleanDB = (done) ->
    @timeout 20000
    fixtures.resetDatabase callback: done

helpers.cleanDBWithRequests = (done) ->
    @timeout 20000
    fixtures.resetDatabase removeAllRequests: true, callback: done

helpers.loadFixtures = (done) ->
    @timeout 20000
    fixtures.load
        dirPath: __dirname + '/fixtures'
        silent: true
        callback: done

module.exports = helpers
