cozydb = require 'cozydb'
emit = null # jslint

module.exports =
    settings:
        all: cozydb.defaultRequests.all

    account:
        all: cozydb.defaultRequests.all

    contact:
        all: cozydb.defaultRequests.all
        mailByName: (doc) ->
            if doc.fn? and doc.fn.length > 0
                emit doc.fn, doc
            if doc.n?
                emit doc.n.split(';').join(' ').trim(), doc
            for dp in doc.datapoints
                if dp.name is 'email'
                    emit dp.value, doc
                    emit dp.value.split('@')[1], doc
        mailByEmail: (doc) ->
            for dp in doc.datapoints
                if dp.name is 'email'
                    emit dp.value, doc

    mailbox:
        treeMap: (doc) ->
            emit [doc.accountID].concat(doc.tree), null

    message:

        byMailboxRequest:
            reduce: '_count'
            map: (doc) ->
                for boxid, uid of doc.mailboxIDs
                    docDate = doc.date or (new Date()).toISOString()
                    emit ['uid', boxid, uid], doc.flags

                    emit ['date', boxid, null, docDate], null
                    emit ['subject', boxid, null, doc.normSubject], null

                    for xflag in ['\\Seen', '\\Flagged', '\\Answered']

                        xflag = '!' + xflag if -1 is doc.flags.indexOf(xflag)

                        emit ['date', boxid, xflag, docDate], null
                        emit ['subject', boxid, xflag, doc.normSubject], null
                    if doc.attachments?.length > 0
                        emit ['date', boxid, '\\Attachments', docDate], null
                        emit ['subject', boxid, '\\Attachments', doc.normSubject], null
                undefined # prevent coffeescript comprehension

        # this map is used to dedup by message-id
        dedupRequest: (doc) ->
            if doc.messageID
                emit [doc.accountID, 'mid', doc.messageID], doc.conversationID

            if doc.normSubject
                emit [doc.accountID, 'subject', doc.normSubject],
                    doc.conversationID

        byConversationID:
            reduce: '_count'
            map: (doc) ->
                if doc.conversationID
                    emit doc.conversationID
