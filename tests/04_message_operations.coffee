should = require 'should'

describe 'Message actions', ->

    it "Pick a message from the inbox", (done) ->
        client.get "/mailbox/#{store.inboxID}", (err, res, body) =>
            store.latestInboxMessageId = body.messages[0].id
            done()

        # Cozy actions
    it "When I send a request to add flag \\Seen", (done) ->

        path = "/message/#{store.latestInboxMessageId}"
        patch = [ op: 'add', path:'/flags/0', value:'\\Seen' ]
        client.patch path, patch, (err, res, body) =>
            res.statusCode.should.equal 200
            body.flags.should.containEql '\\Seen'
            store.uid = body.mailboxIDs[store.inboxID]
            done()

    it "The flags has been changed on the server", (done) ->
        imap = helpers.getImapServerRawConnection()
        imap.waitConnected
        .then -> imap.openBox 'INBOX'
        .then => imap.fetchOneMail store.uid
        .then (msg) -> msg.flags.should.containEql '\\Seen'
        .then -> imap.end()
        .nodeify done


    it "When I send a request to copy and move (more add)", (done) ->
        path = "/message/#{store.latestInboxMessageId}"
        patch = [
            { op: 'remove', path: "/mailboxIDs/#{store.inboxID}" }
            { op: 'add', path: "/mailboxIDs/#{store.testBoxID}", value: -1 }
            { op: 'add', path: "/mailboxIDs/#{store.sentBoxID}", value: -1 }
        ]

        client.patch path, patch, (err, res, body) =>
            res.statusCode.should.equal 200
            body.flags.should.containEql '\\Seen'
            should.exist body.mailboxIDs[store.testBoxID]
            should.exist body.mailboxIDs[store.sentBoxID]
            should.not.exist body.mailboxIDs[store.inboxID]
            done()


    it "When I send a request to copy and move (more remove)", (done) ->
        path = "/message/#{store.latestInboxMessageId}"
        patch = [
            { op: 'add', path: "/mailboxIDs/#{store.inboxID}", value: -1 }
            { op: 'remove', path: "/mailboxIDs/#{store.testBoxID}" }
            { op: 'remove', path: "/mailboxIDs/#{store.sentBoxID}" }
        ]

        client.patch path, patch, (err, res, body) =>
            res.statusCode.should.equal 200
            body.flags.should.containEql '\\Seen'
            should.not.exist body.mailboxIDs[store.testBoxID]
            should.not.exist body.mailboxIDs[store.sentBoxID]
            should.exist body.mailboxIDs[store.inboxID]
            done()


    it "When I create a Draft", (done) ->

        draft =
            isDraft     : true
            accountID   : store.accountID
            from        : [name: 'testuser', address: 'testuser@dovecot.local']
            to          : [name: 'Bob', address: 'bob@example.com']
            cc          : []
            bcc         : []
            attachments : []
            subject     : 'Wanted : dragon slayer'
            content     : 'Hi, I am a recruiter and ...'

        client.post "/message", draft, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 1 # UID
            store.draftStatus = body
            store.draftID = body.id
            done()

    it "When I create a second Draft", (done) ->

        draft =
            isDraft     : true
            accountID   : store.accountID
            from        : [name: 'testuser', address: 'testuser@dovecot.local']
            to          : [name: 'John', address: 'john@example.com']
            cc          : []
            bcc         : []
            attachments : []
            subject     : 'Wanted : magician'
            content     : 'Hi, I am a recruiter and ...'

        client.post "/message", draft, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 2 # UID
            store.secondDraftID = body.id
            done()

    it "When I edit a Draft", (done) ->

        store.draftStatus.content = """
            Hi, I am a recruiter and we need you for epic quest'
        """

        client.post "/message", store.draftStatus, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 3 # UID
            store.draftStatus = body
            done()


    it "When I send this Draft", (done) ->

        store.draftStatus.isDraft = false

        client.post "/message", store.draftStatus, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'id', store.draftID
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.sentBoxID
            body.mailboxIDs.should.not.have.property store.draftBoxID

            SMTPTesting.mailStore.should.have.lengthOf 1
            done()