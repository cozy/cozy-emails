# See documentation on https://github.com/frankrousseau/americano#routes

index = require './index'
mailboxes = require './mailboxes'
emails = require './emails'
imapFolders = require './imap_folders'

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

    'mailbox/:id/folders':
        get: [mailboxes.fetch, imapFolders.listByMailbox]

    'folder/:id/emails':
        get: [imapFolders.fetch, emails.listByImapFolder]


    'email/:id': get: [emails.fetch, emails.get]


