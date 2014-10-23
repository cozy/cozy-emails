
# See cozy-fixtures documentation for testing on
# https://github.com/jsilvestre/cozy-fixtures#automatic-tests
fixtures = require 'cozy-fixtures'
{exec} = require 'child_process'
Client = require('request-json').JsonClient
DovecotTesting = require 'dovecot-testing'
Imap = require '../server/processes/imap_promisified'
SMTPTesting = require './smtp-testing/index'

module.exports = helpers = {}

# server management
helpers.options =
    smtpPort: 8889
    serverPort: '8888'
    serverHost: 'localhost'
helpers.app = null
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

helpers.getClient = -> client


helpers.imapServerAccount = ->
    label: "DoveCot"
    login: "testuser"
    password: "applesauce"
    smtpServer: "127.0.0.1"
    smtpPort: helpers.options.smtpPort
    smtpSSL: false
    smtpTLS: true
    imapServer: DovecotTesting.serverIP()
    imapPort: 993
    imapSecure: true

helpers.getImapServerRawConnection = ->
    imap = new Imap
        user: "testuser"
        password: "applesauce"
        host: DovecotTesting.serverIP()
        port: 993
        tls: true
        tlsOptions: rejectUnauthorized: false

helpers.startApp = (done) ->
    @timeout 10000
    americano = require 'americano'

    host = helpers.options.serverHost || "127.0.0.1"
    port = helpers.options.serverPort || 9250

    americano.start name: 'template', host: host, port: port, (app, server) =>
        @app = app
        @app.server = server
        done()

helpers.startSMTPTesting = (done) ->
    @timeout 3000
    SMTPTesting.init helpers.options.smtpPort, done

helpers.stopApp = (done) ->
    @timeout 10000
    if @app then @app.server.close done
    else done null

# database helper
helpers.cleanDB = (done) ->
    @timeout 20000
    fixtures.removeDocumentsOf 'account', (err) ->
        return done err if err
        fixtures.removeDocumentsOf 'message', (err) ->
            return done err if err
            fixtures.removeDocumentsOf 'mailbox', (err) ->
                return done err if err

                done null

helpers.loadFixtures = (done) ->
    @timeout 20000
    fixtures.load
        dirPath: __dirname + '/fixtures'
        silent: true
        callback: done
