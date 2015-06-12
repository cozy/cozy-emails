

should = require('should')
Message = require '../server/models/message'
Mailbox = require '../server/models/mailbox'
Account = require '../server/models/account'
async = require 'async'

TESTBOXID = 'test-conversations-mailbox2'

describe 'Conversation tests', ->

    testMailbox = null
    testAccount = null
    ids = []

    before ->

        testMailbox = new Mailbox
            accountID: 'test-conversations-account'
            id: TESTBOXID
            _id: TESTBOXID
            path: '/yolo'

        testAccount = new Account
            id: 'test-conversations-account'

    after (done) ->
        async.eachSeries ids, (id, cb) ->
            Message.destroy id, cb
        , done


    it 'handle a conversation fetched in reverse order', (done) ->

        async.series [
            (cb) -> Message.createFromImapMessage MAIL3, testMailbox, 3, cb
            (cb) -> Message.createFromImapMessage MAIL2, testMailbox, 2, cb
            (cb) -> Message.createFromImapMessage MAIL1, testMailbox, 1, cb
            (cb) -> testAccount.applyPatchConversation cb
        ], (err, [mail1, mail2, mail3]) ->
            return done err if err
            Message.rawRequest 'byMailboxRequest',
                startkey: ['uid', TESTBOXID]
                endkey: ['uid', TESTBOXID, {}]
                reduce: false
                include_docs: true

            , (err, rows) ->
                return done err if err
                ids = rows.map (row) -> row.id
                conversationID = rows[0].doc.conversationID
                for row in rows
                    conversationID.should.equal row.doc.conversationID
                done null


MAIL1 =
    flags:[]
    subject: "Test 1"
    text: "Test 1"
    headers:
        "message-id": "<mail1@example.org>"

MAIL2 =
    flags:[]
    subject: "RE: Test 1"
    text: "Test 2"
    inReplyTo: ["mail1@example.org"]
    references: ["mail1@example.org"]
    headers:
        "message-id": "<mail2@example.org>"

MAIL3 =
    flags:[]
    subject: "RE: RE: Test 1"
    text: "Test 3"
    inReplyTo: ["mail2@example.org"]
    references: ["mail1@example.org", "mail2@example.org"]
    headers:
        "message-id": "<mail3@example.org>"
