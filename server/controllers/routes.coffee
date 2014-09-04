# See documentation on https://github.com/frankrousseau/americano#routes

index = require './index'
accounts = require './accounts'
messages = require './messages'

module.exports =

    '': get: index.main

    'account':
        post: accounts.create
        get: accounts.list

    'account/:accountID':
        get: [accounts.fetch, accounts.details]
        put: [accounts.fetch, accounts.edit]
        delete: [accounts.fetch, accounts.remove]

    'mailbox/:mailboxID':
        get: [messages.listByMailboxId]

    'message':
        post: messages.send

    'message/:messageID':
        get: [messages.fetch, messages.details]
        put: [messages.fetch, messages.updateFlags]

    'load-fixtures':
        get: index.loadFixtures
