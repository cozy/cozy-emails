global.appPath = if process.env.USEJS then '../build/'
else '../'

should = require('should')
helpers = require './helpers'
fixtures = require 'cozy-fixtures'
DovecotTesting = require 'dovecot-testing'
SMTPTesting = require './smtp-testing/index'
Client = require('request-json').JsonClient

# CONSTANTS
SMTP_PORT = 8889
APP_PORT = '8888'
APP_HOST = 'localhost'

# UNIT TESTS
require './units/mailbox_flattening'

describe "Server tests", ->

    # load the fixtures
    unless process.env.SKIP_FIXTURES
        before (done) ->
            @timeout 120000
            fixtures.removeDocumentsOf 'account', done

        before (done) ->
            @timeout 120000
            fixtures.removeDocumentsOf 'message', done

        before (done) ->
            @timeout 120000
            fixtures.removeDocumentsOf 'mailbox', done

        before (done) ->
            @timeout 120000
            fixtures.removeDocumentsOf 'mailssettings', done

        before (done) ->
            @timeout 120000
            fixtures.removeDocumentsOf 'contact', done

    # setup test IMAP server
    unless process.env.SKIP_DOVECOT
        before DovecotTesting.setupEnvironment

    # setup test SMTP server
    before (done) ->
        @timeout 3000
        SMTPTesting.init SMTP_PORT, done

    # start the app & prepare store
    before helpers.startApp appPath, APP_HOST, APP_PORT
    before ->
        global.store = {}
        global.helpers = helpers
        global.SMTPTesting = SMTPTesting
        global.DovecotTesting = DovecotTesting
        global.client = new Client "http://#{APP_HOST}:#{APP_PORT}/"

    # define the test account
    before ->
        store.accountDefinition =
            label: "DoveCot"
            login: "testuser"
            password: "applesauce"
            smtpMethod: "NONE"
            smtpServer: "127.0.0.1"
            smtpPort: SMTP_PORT
            smtpSSL: false
            smtpTLS: true
            imapServer: DovecotTesting.serverIP()
            imapPort: 993
            imapSSL: true

    # stop the app
    after helpers.stopApp
    after ->
        delete global.appPath
        delete global.store
        delete global.helpers
        delete global.SMTPTesting
        delete global.DovecotTesting
        delete global.client

    # SERVER TESTS
    require './00_index'
    require './01_account_creation'
    require './02_account_synchro'
    require './03_mailbox_operations'
    require './04_message_operations'
    require './05_mailbox_deletion'
    require './06_settings'
    require './07_activities'
