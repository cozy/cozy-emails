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

    it "When I post a new account to /accounts", (done) ->
        @timeout 10000
        account = helpers.imapServerAccount()
        client.post '/account', account, (err, res, body) =>
            res.statusCode.should.equal 201
            body.should.have.property('mailboxes').with.lengthOf(4)
            @accountID = body.id
            @mailboxID = body.mailboxes[0].id
            done()

    it "When I update an account", (done) ->
        changes = label: "New Name"
        client.put "/account/#{@accountID}", changes, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'label', 'New Name'
            done()

    it "Wait for mails fetching", (done) ->
        @timeout 30000
        setTimeout done, 29000

    it "When I get a mailbox count", (done) ->
        client.get "/mailbox/#{@mailboxID}/count", (err, res, body) =>
            body.should.have.property 'count', 7
            done()

    it "When I get a mailbox", (done) ->
        client.get "/mailbox/#{@mailboxID}/page/1/limit/3", (err, res, body) =>
            body.should.have.lengthOf 3
            body[0].subject.should.equal 'Flagged Orange'
            # @TODO add a thread in the mailbox to test threading
            # body[0].conversationID.should.equal body[1].conversationID
            done()

    it "When I delete an account", (done) ->
        client.del "/account/#{@accountID}", (err, res, body) =>
            res.statusCode.should.equal 204
            done()