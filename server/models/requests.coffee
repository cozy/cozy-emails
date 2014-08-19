# See documentation on https://github.com/frankrousseau/americano-cozy/#requests

americano = require 'americano'

byMailbox = (doc) -> emit doc.mailbox, doc

module.exports =
    mailbox:
        all: americano.defaultRequests.all

    email:
        all: americano.defaultRequests.all
        byMailbox: byMailbox
        byMailboxAndDate: (doc) -> emit [doc.mailbox, doc.createdAt], doc

    imap_folder:
        byMailbox: byMailbox
