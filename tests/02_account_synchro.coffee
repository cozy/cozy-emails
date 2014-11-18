describe 'Account Synchronizations', ->

    it "Get initialInboxCount", (done) ->
        client.get "/mailbox/#{store.inboxID}", (err, res, body) =>
            body.should.have.property 'count'
            store.initialInboxCount = body.count
            done()

    it "When I move a message on the IMAP server", (done) ->
        @timeout 10000
        imap = helpers.getImapServerRawConnection()

        imap.waitConnected
        .then -> imap.openBox 'INBOX'
        .then -> imap.move '8', 'Test Folder'
        .then -> imap.closeBox()
        .then -> imap.end()
        .nodeify done

    it "And refresh the account", (done) ->
        @timeout 10000
        client.get "/refresh", done

    it "Message have moved", (done) ->

        client.get "/mailbox/#{store.inboxID}", (err, res, body) =>
            body.should.have.property 'count', store.initialInboxCount - 1
            client.get "/mailbox/#{store.testBoxID}", (err, res, body) =>
                body.should.have.property 'count', 4
                done()

    it "When I copy a message on the IMAP server", (done) ->
        @timeout 10000
        imap = helpers.getImapServerRawConnection()

        imap.waitConnected
        .then -> imap.openBox 'INBOX'
        .then -> imap.copy '9', 'Test Folder'
        .then -> imap.end()
        .nodeify done

    it "And refresh the account", (done) ->
        @timeout 10000
        client.get "/refresh", done

    it "Message have been copied", (done) ->
        client.get "/mailbox/#{store.inboxID}", (err, res, body) =>
            body.should.have.property 'count', store.initialInboxCount - 1
            client.get "/mailbox/#{store.testBoxID}", (err, res, body) =>
                body.should.have.property 'count', 5
                done()

    it "When I read a message on the IMAP server", (done) ->
        @timeout 10000
        imap = helpers.getImapServerRawConnection()

        imap.waitConnected
        .then -> imap.openBox 'INBOX'
        .then -> imap.addFlags '10', ['\\Seen']
        .then -> imap.end()
        .nodeify done

    it "And refresh the account", (done) ->
        @timeout 10000
        client.get "/refresh", done

    it "Message have been mark as read in cozy", (done) ->
        Message = require '../server/models/message'
        Message.UIDsInRange store.inboxID, 10, 10
        .then (msg) ->
            flags = msg[10][1]
            flags.should.containEql '\\Seen'

        .nodeify done

    it "When the server changes one UIDValidity", (done) ->
        @timeout 10000
        DovecotTesting.changeSentUIDValidity done

    it "And refresh the account", (done) ->
        @timeout 10000
        client.get "/refresh", done

    it "Then the mailbox has been updated", (done) ->
        Mailbox = require '../server/models/mailbox'
        Mailbox.findPromised store.sentBoxID
        .then (sentBox) ->
            sentBox.should.have.property 'uidvalidity', 1337
        .nodeify done
