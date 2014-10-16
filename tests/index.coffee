should = require('should')
helpers = require './helpers'
DovecotTesting = require 'dovecot-testing'
SMTPTesting = require './smtp-testing/index'
client = helpers.getClient()
Account = require '../server/models/account'

describe "Accounts Tests", ->

    # before helpers.cleanDB
    before DovecotTesting.setupEnvironment
    before helpers.startSMTPTesting
    before helpers.startApp
    after helpers.stopApp


    it "When I get the index", (done) ->
        @timeout 6000
        client.get '/', (err, res, body) =>
            res.statusCode.should.equal 200
            done()

    it "When I post a new account to /accounts", (done) ->
        @timeout 12000
        account = helpers.imapServerAccount()
        client.post '/account', account, (err, res, body) =>
            res.statusCode.should.equal 201
            body.should.have.property('mailboxes').with.lengthOf(4)
            @boxes = body.mailboxes
            for box in @boxes
                if box.label is 'INBOX' then @inboxID = box.id
                else if box.label is 'Sent' then @sentID = box.id
                else if box.label is 'Test Folder' then @testboxID = box.id
                else @flaggedBoxId = box.id

            body.inboxMailbox.should.equal @inboxID
            body.sentMailbox.should.equal @sentID
            body.flaggedMailbox.should.equal @flaggedBoxId

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
            body.should.have.length 12
            # 12 = 1 diff (limited) + 1 diff-apply-fetch + 1 diff (not limited but nothing) / mailbox
            unfinishedTask = body.some (task) -> not task.finished
            unfinishedTask.should.be.false
            done()

    # it "When I get a mailbox", (done) ->
    #     client.get "/mailbox/#{@inboxID}/page/1/limit/3", (err, res, body) =>
    #         body.should.have.property 'count'
    #         body.messages.should.have.lengthOf 3
    #         @initialInboxCount = body.count
    #         @latestInboxMessageId = body.messages[0].id
    #         body.messages[0].subject.should.equal 'Re: First message of conversation'
    #         body.messages[1].subject.should.equal 'Re: First message of conversation'
    #         body.messages[1].conversationID.should.equal body.messages[1].conversationID
    #         done()


    # # Synchronizations test
    # it "When I move a message on the IMAP server", (done) ->
    #     @timeout 10000
    #     imap = helpers.getImapServerRawConnection()

    #     imap.waitConnected
    #     .then -> imap.openBox 'INBOX'
    #     .then -> imap.move '14', 'Test Folder'
    #     .then -> imap.end()
    #     .nodeify done

    # it "And refresh the account", (done) ->
    #     @timeout 10000
    #     Account.findPromised @accountID
    #     .then (account) -> account.fetchMails()
    #     .nodeify done

    # it "Message have moved", (done) ->
    #     client.get "/mailbox/#{@inboxID}/page/1/limit/3", (err, res, body) =>
    #         body.should.have.property 'count', @initialInboxCount - 1
    #         client.get "/mailbox/#{@testboxID}/page/1/limit/3", (err, res, body) =>
    #             body.should.have.property 'count', 4
    #             done()

    # # Synchronizations test
    # it "When I copy a message on the IMAP server", (done) ->
    #     @timeout 10000
    #     imap = helpers.getImapServerRawConnection()

    #     imap.waitConnected
    #     .then -> imap.openBox 'INBOX'
    #     .then -> imap.copy '15', 'Test Folder'
    #     .then -> imap.end()
    #     .nodeify done

    # it "And refresh the account", (done) ->
    #     @timeout 10000
    #     Account.findPromised @accountID
    #     .then (account) -> account.fetchMails()
    #     .nodeify done

    # it "Message have been copied", (done) ->
    #     client.get "/mailbox/#{@inboxID}/page/1/limit/3", (err, res, body) =>
    #         body.should.have.property 'count', @initialInboxCount - 1
    #         client.get "/mailbox/#{@testboxID}/page/1/limit/3", (err, res, body) =>
    #             body.should.have.property 'count', 5
    #             done()

    # it "When the server changes one UIDValidity (Sent folder)", (done) ->
    #     @timeout 10000
    #     DovecotTesting.changeSentUIDValidity done

    # it "And refresh the account", (done) ->
    #     @timeout 10000
    #     Account.findPromised @accountID
    #     .then (account) -> account.fetchMails()
    #     .nodeify done

    # it "Then the mailbox has been updated", (done) ->
    #     # @TODO
    #     done()


    # # Cozy actions
    # it "When I send a request to add flag \\Seen", (done) ->

    #     patch = [ op: 'add', path:'/flags/0', value:'\\Seen' ]

    #     client.patch "/message/#{@latestInboxMessageId}", patch, (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.flags.should.containEql '\\Seen'
    #         @uid = body.mailboxIDs[@inboxID]
    #         done()

    # it "The flags has been changed on the server", (done) ->
    #     imap = helpers.getImapServerRawConnection()
    #     imap.waitConnected
    #     .then -> imap.openBox 'INBOX'
    #     .then => imap.fetchOneMail @uid
    #     .then (msg) -> msg.flags.should.containEql '\\Seen'
    #     .nodeify done


    # it "When I send a request to copy and move (more add)", (done) ->
    #     patch = [
    #         { op: 'remove', path: "/mailboxIDs/#{@inboxID}" }
    #         { op: 'add', path: "/mailboxIDs/#{@testboxID}", value: -1 }
    #         { op: 'add', path: "/mailboxIDs/#{@sentID}", value: -1 }
    #     ]

    #     client.patch "/message/#{@latestInboxMessageId}", patch, (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.flags.should.containEql '\\Seen'
    #         should.exist body.mailboxIDs[@testboxID]
    #         should.exist body.mailboxIDs[@sentID]
    #         should.not.exist body.mailboxIDs[@inboxID]
    #         done()


    # it "When I send a request to copy and move (more remove)", (done) ->
    #     patch = [
    #         { op: 'add', path: "/mailboxIDs/#{@inboxID}", value: -1 }
    #         { op: 'remove', path: "/mailboxIDs/#{@testboxID}" }
    #         { op: 'remove', path: "/mailboxIDs/#{@sentID}" }
    #     ]

    #     client.patch "/message/#{@latestInboxMessageId}", patch, (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.flags.should.containEql '\\Seen'
    #         should.not.exist body.mailboxIDs[@testboxID]
    #         should.not.exist body.mailboxIDs[@sentID]
    #         should.exist body.mailboxIDs[@inboxID]
    #         done()


    # it "When I add a draft mailbox", (done) ->
    #     box =
    #         accountID: @accountID
    #         label: 'Drafts'
    #         parentID: null


    #     client.post "/mailbox/", box, (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.id.should.equal @accountID
    #         body.should.have.property('mailboxes').with.lengthOf(5)
    #         @newBoxID = box.id for box in body.mailboxes when box.label is 'Drafts'
    #         should.exist @newBoxID
    #         done()

    # it "When I change this box label", (done) ->
    #     box =
    #         accountID: @accountID
    #         label: 'My Drafts'


    #     client.put "/mailbox/#{@newBoxID}", box, (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.id.should.equal @accountID
    #         body.should.have.property('mailboxes').with.lengthOf(5)
    #         for box of body.mailboxes when box.id is @newBoxID
    #             box.label.should.equal 'My Drafts'
    #         @accountState = body
    #         done()


    # it "When I set this box as Draft Folder", (done) ->

    #     @accountState.draftMailbox = @newBoxID

    #     client.put "/account/#{@accountID}", @accountState, (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.should.have.property 'draftMailbox', @newBoxID
    #         done()


    # it "When I create a Draft", (done) ->

    #     draft =
    #         isDraft     : true
    #         accountID   : @accountID
    #         from        : [name: 'testuser', address: 'testuser@dovecot.local']
    #         to          : [name: 'Bob', address: 'bob@example.com']
    #         cc          : []
    #         bcc         : []
    #         attachments : []
    #         subject     : 'Wanted : dragon slayer'
    #         content     : 'Hi, I am a recruiter and ...'

    #     client.post "/message", draft, (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.should.have.property 'id'
    #         body.should.have.property 'mailboxIDs'
    #         body.mailboxIDs.should.have.property @newBoxID
    #         body.mailboxIDs[@newBoxID].should.equal 1
    #         @draftID = body.id
    #         done()


    # it "When I send this Draft", (done) ->

    #     smtpOK = false
    #     httpOK = false


    #     email =
    #         id          : @draftID
    #         accountID   : @accountID
    #         from        : [name: 'testuser', address: 'testuser@dovecot.local']
    #         to          : [name: 'Bob', address: 'bob@example.com']
    #         cc          : []
    #         bcc         : []
    #         attachments : []
    #         subject     : 'Wanted : dragon slayer'
    #         content     : 'Hello, I am a recruiter and ...'

    #     client.post "/message", email, (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.should.have.property 'id', @draftID
    #         body.should.have.property 'mailboxIDs'
    #         body.mailboxIDs.should.have.property @sentID
    #         body.mailboxIDs.should.not.have.property @newBoxID

    #         SMTPTesting.mailStore.should.have.lengthOf 1
    #         console.log SMTPTesting.mailStore.pop()
    #         done()

    # it "When I delete the box", (done) ->
    #     @timeout 4000

    #     client.del "/mailbox/#{@newBoxID}", (err, res, body) =>
    #         res.statusCode.should.equal 200
    #         body.should.have.property('mailboxes').with.lengthOf(4)
    #         box.id.should.not.equal @newBoxID for box in body.mailboxes
    #         done()

    # it "Wait a sec", (done) ->
    #     @timeout 4000
    #     setTimeout done, 3000

    # it "And its message have been cleaned up", (done) ->
    #     client.get "/mailbox/#{@newBoxID}/page/1/limit/3", (err, res, body) ->
    #         res.statusCode.should.equal 200
    #         body.messages.should.have.lengthOf 0
    #         done()


    # it "When I delete an account", (done) ->
    #     client.del "/account/#{@accountID}", (err, res, body) =>
    #         res.statusCode.should.equal 204
    #         done()
