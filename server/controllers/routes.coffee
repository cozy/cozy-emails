# See documentation on https://github.com/frankrousseau/americano#routes

index = require './index'
mailboxes = require './mailboxes'
emails = require './emails'
imapFolders = require './imap_folders'

module.exports =

    '': get: index.main

    'account':
        post: mailboxes.create
        get: mailboxes.list

    'account/:id':
        put: [mailboxes.fetch, mailboxes.edit]
        delete: [mailboxes.fetch, mailboxes.remove]

    'account/:id/messages':
        get: [mailboxes.fetch, emails.listByMailbox]

    'account/:id/mailboxes':
        get: [mailboxes.fetch, imapFolders.listByMailbox]

    'mailbox/:id/messages':
        get: [imapFolders.fetch, emails.listByImapFolder]


    'message/:id': get: [emails.fetch, emails.get]

    'load-fixtures':
        get: index.loadFixtures


