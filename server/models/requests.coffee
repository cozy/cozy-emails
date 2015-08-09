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

        totalUnreadByAccount:
            reduce: '_count'
            map: (doc) ->
                if not doc.ignoreInCount and -1 is doc.flags.indexOf '\\Seen'
                    emit doc.accountID, null

        byMailboxRequest:
            reduce: '_count'
            map: (doc) ->
                nobox = true

                for boxid, uid of doc.mailboxIDs
                    nobox = false
                    docDate = doc.date or (new Date()).toISOString()
                    emit ['uid', boxid, uid], doc.flags
                    emit ['date', boxid, null, docDate], null

                    for xflag in ['\\Seen', '\\Flagged', '\\Answered']

                        xflag = '!' + xflag if -1 is doc.flags.indexOf(xflag)

                        emit ['date', boxid, xflag, docDate], null
                    if doc.attachments?.length > 0
                        emit ['date', boxid, '\\Attachments', docDate], null

                    for sender in doc.from
                        if sender.name?
                            emit ['from', boxid, null, sender.name, docDate], \
                                                                           null
                        emit ['from', boxid, null, sender.address, docDate], \
                                                                           null

                    # some messages may not have to or cc fields
                    dests = []
                    if doc.to?
                        dests = dests.concat(doc.to)
                    if doc.cc?
                        dests = dests.concat(doc.cc)
                    for dest in dests
                        if dest.name?
                            emit ['dest', boxid, null, dest.name, docDate], null
                        emit ['dest', boxid, null, dest.address, docDate], null
                undefined

                for boxid, uids of doc.twinMailboxIDs or {}
                    for uid in uids
                        emit ['uid', boxid, uid], doc.flags

                undefined # prevent coffeescript comprehension

                if nobox
                    emit ['nobox']

        # this map is used to dedup by message-id
        dedupRequest: (doc) ->
            if doc.messageID
                emit [doc.accountID, 'mid', doc.messageID], doc.conversationID

            if doc.normSubject
                emit [doc.accountID, 'subject', doc.normSubject],
                    doc.conversationID

        conversationPatching:
            reduce: (key, values, rereduce) ->
                valuesShouldNotBe = if rereduce then null else values[0]
                for value in values when value isnt valuesShouldNotBe
                    return value

                return null

            map: (doc) ->
                if doc.messageID
                    emit [doc.accountID, doc.messageID], doc.conversationID
                for reference in doc.references or []
                    emit [doc.accountID, reference], doc.conversationID

        byConversationID:
            reduce: '_count'
            map: (doc) ->
                if doc.conversationID and not doc.ignoreInCount
                    emit doc.conversationID
