describe 'Account creation', ->

    it "When I post a new account to /accounts", (done) ->
        @timeout 12000
        account = store.accountDefinition
        client.post '/account', account, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property('mailboxes').with.lengthOf(4)

            expectedBoxes =
                'INBOX': 'inboxID'
                'Sent': 'sentBoxID'
                'Test Folder': 'testBoxID'
                'Flagged Email': 'flaggedBoxID'

            for box in body.mailboxes
                if key = expectedBoxes[box.label]
                    store[key] = box.id

            body.sentMailbox     .should.equal store.sentBoxID
            body.inboxMailbox    .should.equal store.inboxID
            body.flaggedMailbox  .should.equal store.flaggedBoxID

            body.should.have.property('favorites').with.lengthOf 4

            store.accountID = body.id
            done()

    it "When I update an account", (done) ->
        changes = store.accountDefinition
        changes.label = "Ze Dovecot"
        client.put "/account/#{store.accountID}", changes, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'label', 'Ze Dovecot'
            done()

    it "Wait for mails fetching", (done) ->
        @timeout 30000
        helpers.waitAllTaskComplete done

    it "When I query the /refreshes, they are all finished", (done) ->
        client.get "/refreshes", (err, res, body) =>
            # body.should.have.length 12
            # 12 = 1 diff (limited) + 1 diff-apply-fetch + 1 diff (not limited but nothing) / mailbox
            unfinishedTask = body.some (task) -> not task.finished
            unfinishedTask.should.be.false
            done()
