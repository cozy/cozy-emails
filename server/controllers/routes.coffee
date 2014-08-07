# See documentation on https://github.com/frankrousseau/americano#routes

index = require './index'
mailboxes = require './mailboxes'
emails = require './emails'

module.exports =

    '': get: index.main

    'mailbox':
        post: mailboxes.create
        get: mailboxes.list

    'mailbox/:id':
        put: [mailboxes.fetch, mailboxes.edit]
        delete: [mailboxes.fetch, mailboxes.remove]

    'mailbox/:id/emails':
        get: [mailboxes.fetch, emails.listByMailbox]


    'email/:id':
        get: [emails.fetch, emails.get]


