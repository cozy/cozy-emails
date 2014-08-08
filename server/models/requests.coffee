# See documentation on https://github.com/frankrousseau/americano-cozy/#requests

americano = require 'americano'

module.exports =
    mailbox:
        all: americano.defaultRequests.all

    email:
        all: americano.defaultRequests.all
        byMailbox: (doc) -> emit doc.mailbox, doc
