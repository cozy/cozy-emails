# See documentation on https://github.com/frankrousseau/americano#routes

index     = require './index'
accounts  = require './accounts'
activity  = require './activity'
mailboxes = require './mailboxes'
messages  = require './messages'
providers = require './providers'
settings  = require './settings'
contacts  = require './contacts'
test      = require './test'

module.exports =

    '': get: index.main

    'refreshes': get: index.refreshes
    'refresh': get: index.refresh

    'refresh/:mailboxID':
        get: [mailboxes.refresh]

    'settings':
        get: settings.get
        put: settings.change

    'activity':
        post: activity.create

    'account':
        post: accounts.create

    'account/:accountID':
        put: accounts.edit
        delete: accounts.remove

    # We want to allow to test parameters before saving the account
    # so don't use accountID in this route
    'accountUtil/check':
        put: [accounts.check]

    'mailbox':
        post: [mailboxes.create]

    'mailbox/:mailboxID':
        get: [messages.listByMailboxOptions, messages.listByMailbox]
        put: [mailboxes.update]
        delete: [mailboxes.delete]

    'mailbox/:mailboxID/expunge':
        delete: [mailboxes.expunge]

    'message':
        post: [messages.parseSendForm, messages.fetchMaybe, messages.send]

    'messages/batchFetch':
        get: [messages.batchFetch, messages.batchSend]
        put: [messages.batchFetch, messages.batchSend]

    'messages/batchTrash':
        put: [messages.batchFetch, messages.batchTrash]

    'messages/batchMove':
        put: [messages.batchFetch, messages.batchMove]

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

    'contacts/list':
        get: [contacts.list]

    'contacts/:contactID/picture.jpg':
        get: [contacts.picture]

    'provider/:domain':
        get: providers.get

    'test': get: test.main
