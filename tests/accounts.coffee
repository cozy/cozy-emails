should = require('should')
helpers = require './helpers'
client = helpers.getClient()

describe "Accounts Tests", ->

    before helpers.loadFixtures
    before helpers.startImapServer
    before helpers.startApp
    after helpers.stopApp


    it "When I get the index", (done) ->
        @timeout 6000
        client.get '/', (err, res, body) =>
            res.statusCode.should.equal 200
            done()

    it "When I post a new account to /accounts", (done) =>
        @timeout 10000
        account = helpers.imapServerAccount()
        client.post '/accounts', account, (err, res, body) =>
            res.statusCode.should.equal 201
            body.should.have.property('mailboxes').with.lengthOf(4)
            done()

    it "When I update an account", (done) ->
        changes = name: "New Name"
        client.put '/accounts/dovecot-ID', changes, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'name', 'New Name'
            done()

    it "When I delete an account", (done) ->
        client.del '/accounts/dovecot-ID', (err, res, body) =>
            res.statusCode.should.equal 204
            done()

    it "When I get a mailbox messages", (done) ->
        client.get '/mailboxes/gmail-ID-folder1', (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.lengthOf 5
            done()

    it "When I get one message", (done) ->
        client.get '/messages/email-ID-1', (err, res, body) ->
            res.statusCode.should.equal 200
            done()