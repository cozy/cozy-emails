should = require('should')
_ = require 'lodash'
{MSGBYPAGE} = require appPath + 'server/utils/constants'

describe 'Mailbox fetching', ->

    inboxCount = 0
    readCount = 0


    testResultLength = (first, iterator, callback) ->
        [iterator, callback] = [null, iterator] unless callback
        totalFound = null

        step = (link, callback) ->
            client.get link, (err, res, body) ->
                return callback err if err
                body.messages.length.should.be.lessThan MSGBYPAGE + 1
                totalFound = body.messages.length
                iterator?(body.messages)
                callback null

        step first, ->
            if totalFound isnt null then callback null, totalFound
            else callback new Error 'total & count doesnt match'


    it "When I follow the next links", (done) ->
        testResultLength "/mailbox/#{store.inboxID}",
            (messages) ->
                readCount += messages
                    .filter (m) -> '\\Seen' in m.flags
                    .length

            (error, total) ->
                inboxCount = total
                done error


    it "When I get a mailbox (filter by flag)", (done) ->
        testResultLength "/mailbox/#{store.inboxID}?flag=seen",
            (err, total) ->
                total.should.equal readCount
                done()


    it "When I get a mailbox (filter by not flag)", (done) ->
        testResultLength "/mailbox/#{store.inboxID}?flag=unseen",
            (err, total) ->
                total.should.equal inboxCount - readCount
                done()


describe 'Mailbox operations', ->

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
            draftBox = null
            for box in body.mailboxes when box.id is store.draftBoxID
                draftBox = box
            should.exist draftBox
            draftBox.label.should.equal 'My Drafts'
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
            favorite: true
            mailboxID: store.draftBoxID

        client.put "/mailbox/#{store.draftBoxID}", box, (err, res, body) =>
            res.statusCode.should.equal 200
            body.id.should.equal store.accountID
            body.should.have.property('favorites').with.lengthOf 5
            body.favorites.should.containEql store.draftBoxID
            done()
