# See documentation on https://github.com/frankrousseau/americano#routes

index     = require './index'
accounts  = require './accounts'
activity  = require './activity'
mailboxes = require './mailboxes'
messages  = require './messages'
providers = require './providers'
settings  = require './settings'
test      = require './test'

module.exports =

    '': get: index.main

    'refreshes': get: index.refreshes
    'refresh': get: index.refresh

    'settings':
        get: settings.get
        put: settings.change

    'activity':
        post: activity.create

    'account':
        post: [accounts.create, accounts.format]
        get: [accounts.list, accounts.formatList]

    'account/:accountID':
        put: [accounts.fetch, accounts.edit, accounts.format]
        delete: [accounts.fetch, accounts.remove]

    # We want to allow to test parameters before saving the account
    # so don't use accountID in this route
    'accountUtil/check':
        put: [accounts.check]

    'mailbox':
        post: [accounts.fetch,
            mailboxes.fetchParent,
            mailboxes.create,
            accounts.format]

    'mailbox/:mailboxID':
        get: [messages.listByMailboxOptions,
              messages.listByMailbox]

        put: [mailboxes.fetch,
              accounts.fetch,
              mailboxes.update,
              accounts.format]

        delete: [mailboxes.fetch,
            accounts.fetch,
            mailboxes.delete,
            accounts.format]

    'mailbox/:mailboxID/expunge':
        delete: [mailboxes.fetch,
            accounts.fetch,
            mailboxes.expunge,
            accounts.format]

    'message':
        post: [messages.parseSendForm,
               accounts.fetch,
               messages.fetchMaybe,
               messages.send]

    'messages/batchFetch':
        get: [messages.batchFetch, messages.batchSend]
        put: [messages.batchFetch, messages.batchSend]

    'messages/batchTrash':
        put: [messages.batchFetch, accounts.fetch, messages.batchTrash]

    'messages/batchMove':
        put: [messages.batchFetch, accounts.fetch, messages.batchMove]

    'messages/batchAddFlag':
        put: [messages.batchFetch, messages.batchAddFlag]

    'messages/batchRemoveFlag':
        put: [messages.batchFetch, messages.batchRemoveFlag]

    'message/:messageID':
        get: [messages.fetch, messages.details]

    'message/:messageID/attachments/:attachment':
        get: [messages.fetch, messages.attachment]

    'raw/:messageID':
        get: [messages.fetch, messages.raw]

    'provider/:domain':
        get: providers.get

    'test': get: test.main
