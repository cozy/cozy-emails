should = require 'should'

describe 'Account Synchronizations', ->

    it "Get initial Inbox count", (done) ->
        client.get "/mailbox/#{store.inboxID}", (err, res, body) =>
            body.should.have.property 'count'
            store.initialInboxCount = body.count
            done()

    it "When I move a message on the IMAP server", (done) ->
        @timeout 10000
        imap = helpers.getImapServerRawConnection done, ->
            @openBox 'INBOX', =>
                @move '8', 'Test Folder', =>
                    @closeBox =>
                        @end()

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
        imap = helpers.getImapServerRawConnection done, ->
            @openBox 'INBOX', =>
                @copy '9', 'Test Folder', =>
                    @end()

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

        imap = helpers.getImapServerRawConnection done, ->
            @openBox 'INBOX', =>
                @addFlags '10', ['\\Seen'], =>
                    @end()

    it "And refresh the account", (done) ->
        @timeout 10000
        client.get "/refresh", done

    it "Message have been mark as read in cozy", (done) ->
        Message = require appPath + 'server/models/message'
        options =
            reduce: false
            key: ['uid', store.inboxID, 10]
        Message.rawRequest 'byMailboxRequest', options, (err, rows)->
            return done err if err
            rows[0].value.should.containEql '\\Seen'
            done null

    it "When the server changes one UIDValidity", (done) ->
        @timeout 30000
        DovecotTesting.changeSentUIDValidity done

    it "And refresh the account", (done) ->
        @timeout 15000
        client.get "/refresh", done

    it "Then the mailbox has been updated", (done) ->
        Mailbox = require appPath + 'server/models/mailbox'
        Mailbox.find store.sentBoxID, (err, sentBox) ->
            return done err if err
            sentBox.should.have.property 'uidvalidity', 1337
            done null

    it "When the server add one mailbox", (done) ->
        @timeout 10000
        helpers.getImapServerRawConnection done, ->
            @addBox 'Yolo', =>
                @end()

    it "And refresh the account", (done) ->
        @timeout 10000
        client.get "/refresh", done

    it "Then the mailbox has been created in couch", (done) ->
        Mailbox = require appPath + 'server/models/mailbox'
        Mailbox.rawRequest 'treeMap', include_docs: true, (err, rows) ->
            return done err if err
            for row in rows when row.doc.path is 'Yolo'
                store.yoloID = row.id

            should.exist store.yoloID
            done null

    it "Then the mailbox has been created in store", (done) ->
        ramStore = require appPath + 'server/models/store_account_and_boxes'
        boxes = ramStore.getMailboxesByAccount store.accountID

        for box in boxes when box.path is 'Yolo'
            store.yoloID = box.id

        should.exist store.yoloID
        done null

    it "When the server remove one mailbox", (done) ->
        @timeout 10000
        helpers.getImapServerRawConnection done, ->
            @delBox 'Yolo', =>
                @end()

    it "And refresh the account", (done) ->
        @timeout 10000
        client.get "/refresh", done

    it "Then the mailbox has been deleted", (done) ->
        Mailbox = require appPath + 'server/models/mailbox'
        Mailbox.find store.yoloID, (err, found) ->
            should.not.exist found
            done()

