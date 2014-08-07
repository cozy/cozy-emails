# See documentation on https://github.com/frankrousseau/americano-cozy/#requests

americano = require 'americano'

module.exports =
    mailbox:
        all: americano.defaultRequests.all

    email:
        all: americano.defaultRequests.all
        byMailbox: (doc) -> emit doc.mailbox, doc

    template:
        # shortcut for emit doc._id, doc
        all: americano.defaultRequests.all

        # create all the requests you want!
        customRequest:
            map: (doc) ->
                # map function
            reduce: (key, values, rereduce) ->
                # non mandatory reduce function