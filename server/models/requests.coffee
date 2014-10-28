americano = require 'americano'

module.exports =
    settings:
        all: americano.defaultRequests.all

    account:
        all: americano.defaultRequests.all

    contact:
        all: americano.defaultRequests.all
        byName: (doc) ->
            if doc.fn? and doc.fn.length > 0
                emit doc.fn, doc
            else if doc.n?
                emit doc.n.split(';').join(' ').trim(), doc
            else
                for dp in doc.datapoints
                    if dp.name is 'email'
                        emit dp.value, doc

    mailbox:
        all: americano.defaultRequests.all
        treeMap: (doc) ->
            emit [doc.accountID].concat(doc.tree), null

    message:
        all: americano.defaultRequests.all

        # this map has 3 usages
        # - fetch mails of a mailbox between two dates
        # - fetch mails count of a mailbox
        # - get UIDs of mails in a mailbox
        byMailboxAndDate:
            reduce: '_count'
            map: (doc) ->
                for boxid, uid of doc.mailboxIDs
                    emit [boxid, doc.date], uid
                undefined # prevent coffeescript comprehension

        # fastly find unread or flagged count
        byMailboxAndFlag:
            reduce: '_count'
            map: (doc) ->
                for boxid, uid of doc.mailboxIDs
                    for flag in doc.flags
                        emit [boxid, flag], null
                    undefined # prevent coffeescript comprehension
                undefined # prevent coffeescript comprehension


        # this map is used to dedup by message-id
        byMessageId: (doc) ->
            if doc.messageID
                emit [doc.accountID, doc.messageID], doc.conversationID

        # this map is used to find conversation by sujects
        byNormSubject: (doc) ->
            if doc.normSubject
                emit [doc.accountID, doc.normSubject], doc.conversationID

