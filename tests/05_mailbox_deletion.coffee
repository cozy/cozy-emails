should = require 'should'

describe "mailbox deletion", ->

    it "When I delete the draft box", (done) ->
        @timeout 4000

        client.del "/mailbox/#{store.draftBoxID}", (err, res, body) =>
            res.statusCode.should.equal 200
            body.should.have.property('mailboxes').with.lengthOf(5)
            for box in body.mailboxes
                box.id.should.not.equal store.draftBoxID
            done()

    it "Wait a sec", (done) ->
        @timeout 4000
        setTimeout done, 3000

    it "And its message have been cleaned up", (done) ->
        client.get "/mailbox/#{store.draftBoxID}", (err, res, body) ->
            res.statusCode.should.equal 200
            body.messages.should.have.lengthOf 0
            done()

    it "And it has been removed from the account favorites", (done) ->

        Account = require appPath + 'server/models/account'
        Account.find store.accountID, (err, account) ->
            return done err if err
            account.favorites.should.not.containEql store.draftBoxID
            should.not.exist account.draftMailbox
            done null