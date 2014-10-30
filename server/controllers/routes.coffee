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

    'tasks': get: index.tasks
    'refresh': get: index.refresh

    'settings':
        put: settings.change

    'activity':
        post: activity.create

    'account':
        post: accounts.create
        get: accounts.list

    'account/:accountID':
        get: [accounts.fetch, accounts.details]
        put: [accounts.fetch, accounts.edit]
        delete: [accounts.fetch, accounts.remove]

    'conversation/:conversationID':
        get: [messages.conversationGet]
        delete: [messages.conversationDelete]
        patch: [messages.conversationPatch]

    'mailbox':
        post: mailboxes.create

    'mailbox/:mailboxID':
        get: messages.listByMailbox
        put: mailboxes.update
        delete: mailboxes.delete

    'message':
        post: messages.send

    'message/:messageID':
        get: [messages.fetch, messages.details]
        patch: [messages.fetch, messages.patch]
        'delete': messages.del

    'message/:messageID/attachments/:attachment':
        get: [messages.fetch, messages.attachment]

    'search/:query/page/:numPage/limit/:numByPage':
        get: messages.search

    'provider/:domain':
        get: providers.get

    # temporary routes for testing purpose
    'messages/index': get: messages.index

    'load-fixtures':
        get: index.loadFixtures

    'test': get: test.main
