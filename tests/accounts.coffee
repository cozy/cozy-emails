should = require('should')
helpers = require './helpers'
client = helpers.getClient()
Account = require '../server/models/account'

describe "Accounts Tests", ->

    # before helpers.loadFixtures
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
            @boxes = body.mailboxes
            for box in @boxes
                @inboxID = box.id if box.label is 'INBOX'
                @testboxID = box.id if box.label is 'Test Folder'

            @accountID = body.id
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

    it "When I query the /tasks, they are all finished", (done) ->
        client.get "/tasks", (err, res, body) =>
            body.should.have.length 8
            # 8 = 1 diff + 1 diff-apply-fetch / mailbox
            unfinishedTask = body.some (task) -> not task.finished
            unfinishedTask.should.be.false
            done()

    it "When I get a mailbox count", (done) ->
        client.get "/mailbox/#{@inboxID}/count", (err, res, body) =>
            body.should.have.property 'count', 12
            done()

    it "When I get a mailbox", (done) ->
        client.get "/mailbox/#{@inboxID}/page/1/limit/3", (err, res, body) =>
            body.should.have.lengthOf 3
            body[0].subject.should.equal 'Message with multipart/alternative'
            # @TODO add a thread in the mailbox to test threading
            # body[0].conversationID.should.equal body[1].conversationID
            done()

    # Synchronizations test
    it "When I move a message on the IMAP server", (done) ->
        @timeout 10000
        imap = helpers.getImapServerRawConnection()

        imap.waitConnected
        .then -> imap.openBox 'INBOX'
        .then -> imap.move '14', 'Test Folder'
        .then -> imap.end()
        .nodeify done

    it "And refresh the account", (done) ->
        @timeout 10000
        Account.findPromised @accountID
        .then (account) -> account.fetchMails()
        .nodeify done

    it "Message have moved", (done) ->
        client.get "/mailbox/#{@inboxID}/count", (err, res, body) =>
            body.should.have.property 'count', 11
            client.get "/mailbox/#{@testboxID}/count", (err, res, body) =>
                body.should.have.property 'count', 4
                done()

    # Synchronizations test
    it "When I copy a message on the IMAP server", (done) ->
        @timeout 10000
        imap = helpers.getImapServerRawConnection()

        imap.waitConnected
        .then -> imap.openBox 'INBOX'
        .then -> imap.copy '15', 'Test Folder'
        .then -> imap.end()
        .nodeify done

    it "And refresh the account", (done) ->
        @timeout 10000
        Account.findPromised @accountID
        .then (account) -> account.fetchMails()
        .nodeify done

    it "Message have been copied", (done) ->
        client.get "/mailbox/#{@inboxID}/count", (err, res, body) =>
            body.should.have.property 'count', 11
            client.get "/mailbox/#{@testboxID}/count", (err, res, body) =>
                body.should.have.property 'count', 5
                done()

    it "When I delete an account", (done) ->
        client.del "/account/#{@accountID}", (err, res, body) =>
            res.statusCode.should.equal 204
            done()
