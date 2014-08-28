americano = require 'americano'

module.exports =
    account:
        all: americano.defaultRequests.all
        # browse mailboxes tree and emit id, path
        pathById: (doc) ->
            do emitChildren = (children = doc.mailboxes) ->
                for child in children
                    emit child.id, child.path
                    if child.children?.length
                        emitChildren child.children
                return # prevent coffeescript magic loop

    message:
        all: americano.defaultRequests.all
        byMailboxAndDate: (doc) ->
            for boxid in doc.mailboxIDs
                emit [boxid, doc.createdAt], null

