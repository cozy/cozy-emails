# See documentation on https://github.com/frankrousseau/americano#routes

index    = require './index'
accounts = require './accounts'
messages = require './messages'
test     = require './test'

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

    'search/:query/page/:numPage/limit/:numByPage':
        get: messages.search

    # temporary routes for testing purpose
    'messages/index': get: messages.index

    'load-fixtures':
        get: index.loadFixtures

    'test': get: test.main
