should = require('should')

describe 'Mailbox operations', ->

    it "When I get a mailbox", (done) ->
        client.get "/mailbox/#{store.inboxID}", (err, res, body) =>
            body.should.have.property 'count'
            body.messages.should.have.lengthOf 3
            body.messages[0].subject
                .should.equal 'Re: First message of conversation'
            body.messages[1].subject
                .should.equal 'Re: This is the first Message for a conversation'
            body.messages[1].conversationID
                .should.equal body.messages[1].conversationID
            done()


    it "When I add a draft mailbox", (done) ->
        box =
            accountID: store.accountID
            label: 'Drafts'
            parentID: null


        client.post "/mailbox/", box, (err, res, body) =>
            res.statusCode.should.equal 200
            body.id.should.equal store.accountID
            body.should.have.property('mailboxes').with.lengthOf(5)
            for box in body.mailboxes when box.label is 'Drafts'
                store.draftBoxID = box.id
            should.exist store.draftBoxID
            done()

    it "When I change this box label", (done) ->
        box =
            accountID: store.accountID
            label: 'My Drafts'


        client.put "/mailbox/#{store.draftBoxID}", box, (err, res, body) =>
            res.statusCode.should.equal 200
            body.id.should.equal store.accountID
            body.should.have.property('mailboxes').with.lengthOf(5)
            for box of body.mailboxes when box.id is store.draftBoxID
                box.label.should.equal 'My Drafts'
            store.accountState = body
            done()


    it "When I set this box as Draft Folder", (done) ->

        store.accountState.draftMailbox = store.draftBoxID

        client.put "/account/#{store.accountID}", store.accountState, (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property 'draftMailbox', store.draftBoxID
            done()

    it "When I set this box as a favorite", (done) ->

        box =
            accountID: store.accountID
            favorite: false
            mailboxID: store.draftBoxID

        done() #@TODO : finish this test


