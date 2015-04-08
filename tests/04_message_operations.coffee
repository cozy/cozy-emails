should = require 'should'
log = -> console.log.apply(console, arguments)
fs = require 'fs'

describe 'Message actions', ->


    it "Pick a message from the inbox", (done) ->
        client.get "/mailbox/#{store.inboxID}", (err, res, body) =>
            store.latestInboxMessageId = body.messages[0].id
            store.someIds = body.messages[1..4].map (msg) -> msg.id
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
        imap = helpers.getImapServerRawConnection done, ->
            @openBox 'INBOX', =>
                @fetchOneMail store.uid, (err, msg) =>
                    msg.flags.should.containEql '\\Seen'
                    @end()

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

        req = client.post "/message", null, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 1 # UID
            store.draftStatus = body
            store.draftID = body.id
            done()

        form = req.form()
        form.append 'body', JSON.stringify draft

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

        req = client.post "/message", null, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 2 # UID
            store.secondDraftStatus = body
            done()

        form = req.form()
        form.append 'body', JSON.stringify draft

    it "When I edit a Draft", (done) ->

        store.draftStatus.content = """
            Hi, I am a recruiter and we need you for epic quest'
        """

        req = client.post "/message", null, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 3 # UID
            store.draftStatus = body
            done()

        form = req.form()
        form.append 'body', JSON.stringify store.draftStatus

    it "When I edit a Draft (add attachments)", (done) ->

        store.draftStatus.attachments.push {
            fileName:           'README.md'
            length:             666
            contentType:        'text/plain'
            generatedFileName:  'README.md'
        }
        store.draftStatus.attachments.push {
            fileName:           'README.md'
            length:             666
            contentType:        'text/plain'
            generatedFileName:  'README-2.md'
        }

        req = client.post "/message", null, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 4 # UID
            store.draftStatus = body
            done()

        form = req.form()
        form.append 'body', JSON.stringify store.draftStatus
        form.append 'README.md', fs.createReadStream __dirname + '/../README.md'
        form.append 'README-2.md', fs.createReadStream __dirname + '/../README.md'

    it "When I edit a Draft (add other attachment)", (done) ->

        store.draftStatus.attachments.push {
            fileName:           'README.md'
            length:             666
            contentType:        'text/plain'
            generatedFileName:  'README-3.md'
        }

        req = client.post "/message", null, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 5 # UID
            store.draftStatus = body
            done()

        form = req.form()
        form.append 'body', JSON.stringify store.draftStatus
        form.append 'README-3.md', fs.createReadStream __dirname + '/../README.md'

    it "When I edit a Draft (remove first attachment)", (done) ->

        store.draftStatus.attachments = store.draftStatus.attachments.filter (file) ->
            file.generatedFileName isnt 'README-2.md'

        req = client.post "/message", null, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 200
            body.should.have.property 'id'
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.draftBoxID
            body.mailboxIDs[store.draftBoxID].should.equal 6 # UID
            store.draftStatus = body
            done()

        form = req.form()
        form.append 'body', JSON.stringify store.draftStatus


    it "When I send the first Draft", (done) ->

        store.draftStatus.isDraft = false

        req = client.post "/message", null, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 200
            body.should.have.property 'id', store.draftID
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.sentBoxID
            body.mailboxIDs.should.not.have.property store.draftBoxID

            SMTPTesting.mailStore.should.have.lengthOf 1
            done()

        form = req.form()
        form.append 'body', JSON.stringify store.draftStatus



    it "If the server try to be smart, When I send the second Draft", (done) ->

        # pretend GMail and add message sent via SMTP
        # to IMAP send box
        SMTPTesting.onSecondMessage = (env, callback) ->
            imap = helpers.getImapServerRawConnection callback, ->
                @append env.body, mailbox: 'Sent', flags: ['\\Seen'], ->
                    @end()

        store.secondDraftStatus.isDraft = false

        req = client.post "/message", null, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 200
            body.should.have.property 'id', store.secondDraftStatus.id
            body.should.have.property 'mailboxIDs'
            body.mailboxIDs.should.have.property store.sentBoxID
            body.mailboxIDs.should.not.have.property store.draftBoxID

            SMTPTesting.mailStore.should.have.lengthOf 2
            done()

        form = req.form()
        form.append 'body', JSON.stringify store.secondDraftStatus


    it "Creates a trashBox", (done) ->

        box =
            accountID: store.accountID
            label: 'trash'
            parentID: null


        client.post "/mailbox/", box, (err, res, body) =>
            res.statusCode.should.equal 200
            body.id.should.equal store.accountID
            body.should.have.property('mailboxes').with.lengthOf(6)
            for box in body.mailboxes when box.label is 'trash'
                store.trashBoxID = box.id
            should.exist store.trashBoxID

            store.accountState.trashMailbox = store.trashBoxID
            data = store.accountState
            client.put "/account/#{store.accountID}", data, (err, res, body) =>
                res.statusCode.should.equal 200
                body.should.have.property 'trashMailbox', store.trashBoxID
                done()


    it "When I delete a batch of messages", (done) ->
        data =
            accountID: store.accountID
            ids: store.someIds

        req = client.put "/messages/batchTrash", data, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 202
            store.batchTrashReporterId = body.id
            done()

    it "Wait for operation to complete", (done) ->
        @timeout 5000
        helpers.waitAllTaskComplete done

    it "Then they have been moved to trash", (done) ->
        client.get "/mailbox/#{store.trashBoxID}", (err, res, body) =>
            should.not.exist err
            body.messages.should.have.lengthOf 4
            done()
