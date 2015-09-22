# this module contains a store, where accounts and Boxes are stored in RAM
# this makes the rest of the application faster

Account = require './account'
Message = require './message'
Mailbox = require './mailbox'
Scheduler = require '../processes/_scheduler'
ImapPool = require '../imap/pool'
_ = require 'lodash'
async = require 'async'
log = require('../utils/logging')(prefix: 'models:ramStore')
{EventEmitter} = require 'events'


accountsByID = {}
allAccounts = []
mailboxesByID = {}
mailboxesByAccountID = {}

orphanMailboxes = []
countsByMailboxID = {}
unreadByAccountID = {}

imapPools = {}

eventEmitter = new EventEmitter()

retrieveAccounts = (callback) ->
    log.debug "retrieveAccounts"
    Account.all (err, cozyAccounts) ->
        return callback err if err

        # @TODO remove me after fixing DS password handling on requests
        async.mapSeries cozyAccounts, (account, next) ->
            Account.find account.id, next
        , (err, cozyAccounts) ->
            return callback err if err
            for account in cozyAccounts
                exports.addAccount account

            callback null


retrieveMailboxes = (callback) ->
    log.debug "retrieveMailboxes"
    Mailbox.rawRequest 'treeMap',
        include_docs: true
    , (err, rows) ->
        return callback err if err

        for row in rows
            box = new Mailbox row.doc
            exports.addMailbox box

        callback null

retrieveCounts = (callback) ->
    log.debug "retrieveCounts"
    options =
        startkey: ['date', ""]
        endkey: ['date', {}]
        reduce: true
        group_level: 3

    Message.rawRequest 'byMailboxRequest', options, (err, rows) ->
        return callback err if err
        for row in rows
            [DATEFLAG, boxID, flag] = row.key
            countsByMailboxID[boxID] ?= {unread: 0, total: 0, recent: 0}
            if flag is "!\\Recent"
                countsByMailboxID[boxID].recent = row.recent
            if flag is "!\\Seen"
                countsByMailboxID[boxID].unread = row.value
            else if flag is null
                countsByMailboxID[boxID].total = row.value

        callback null

retrieveTotalCounts = (callback) ->
    log.debug "retrieveTotalCounts"
    Message.rawRequest 'totalUnreadByAccount',
        reduce: true
    , (err, rows) ->
        return callback err if err
        for row in rows
            accountID = row.key
            count = row.value
            unreadByAccountID[accountID] = count

        callback null

exports.initialize = (callback) ->
    async.series [
        retrieveAccounts,
        retrieveMailboxes,
        retrieveCounts,
        retrieveTotalCounts
    ], callback

# CLIENT OBJECTS
exports.clientList = ->
    return (exports.getAccountClientObject(id) for id of accountsByID)

exports.getAccountClientObject = (id) ->
    rawObject = accountsByID[id]?.toObject()
    return null unless rawObject
    rawObject.favorites ?= []
    rawObject.totalUnread = unreadByAccountID[id] or 0
    rawObject.mailboxes = mailboxesByAccountID[id].map (box) ->
        exports.getMailboxClientObject box.id
    return rawObject

exports.getMailboxClientObject = (id) ->
    count = countsByMailboxID[id]
    box = mailboxesByID[id]
    return clientBox =
        id       : box.id
        label    : box.label
        tree     : box.tree
        attribs  : box.attribs
        nbTotal  : count?.total  or 0
        nbUnread : count?.unread or 0
        nbRecent : count?.recent or 0
        lastSync : box.lastSync


# GETTERS
exports.on = eventEmitter.on.bind(eventEmitter)

exports.getAllAccounts = ->
    return (account for id, account of accountsByID)

exports.getAccount = (accountID) ->
    accountsByID[accountID]

exports.getAllMailboxes = ->
    out = []
    for id, account of accountsByID
        for mailbox in exports.getMailboxesByAccount id
            out.push mailbox
    return out

exports.getFavoriteMailboxes = ->
    out = []
    for id, account of accountsByID
        for mailbox in exports.getMailboxesByAccount id
            out.push mailbox if mailbox.id in account.favorites or []
    return out

exports.getFavoriteMailboxesByAccount = (accountID) ->
    out = []
    account = exports.getAccount accountID
    for mailbox in exports.getMailboxesByAccount accountID
        out.push mailbox if mailbox.id in account.favorites or []
    return out.sort (a, b) ->
        if a.label is 'INBOX' then return -1
        else if b.label is 'INBOX' then return 1
        else return a.label.localeCompare b.label

exports.getMailbox = (mailboxID) ->
    mailboxesByID[mailboxID]

exports.getMailboxesIDByAccount = (accountID) ->
    exports.getMailboxesByAccount(accountID).map (box) -> box.id

exports.getMailboxesByAccount = (accountID) ->
    mailboxesByAccountID[accountID] or []

exports.getSelfAndChildrenOf = (mailbox) ->
    exports.getMailboxesByAccount(mailbox.accountID).filter (box) ->
        box.path.indexOf(mailbox.path) is 0

exports.getOrphanBoxes = ->
    return orphanMailboxes

exports.getMailboxesID = (mailboxID) ->
    Object.keys mailboxesByID

exports.getUninitializedAccount = ->
    exports.getAllAccounts().filter (account) ->
        account.initialized is false

exports.getIgnoredMailboxes = (accountID) ->
    ignores = {}
    for box in exports.getMailboxesByAccount(accountID)
        ignores[box.id] = box.ignoreInCount()

    return ignores

exports.getImapPool = (object) ->
    if object.accountID then imapPools[object.accountID]
    else imapPools[object.id]


# SETTERS
exports.addAccount = (account) ->
    log.debug "addAccount"
    accountsByID[account.id] = account
    allAccounts.push account
    imapPools[account.id] = new ImapPool account
    mailboxesByAccountID[account.id] = []

exports.removeAccount = (accountID) ->
    log.debug "removeAccount"
    allAccounts = allAccounts.filter (tested) -> tested.id isnt accountID
    delete accountsByID[accountID]
    delete unreadByAccountID[accountID]
    mailboxes = mailboxesByAccountID[accountID]
    delete mailboxesByAccountID[accountID]
    orphanMailboxes.push box for box in mailboxes
    Scheduler.orphanRemovalDebounced(accountID)

exports.addMailbox = (mailbox) ->
    mailboxesByID[mailbox.id] = mailbox
    accountID = mailbox.accountID
    countsByMailboxID[mailbox.id] ?= {unread: 0, total: 0, recent: 0}
    if mailboxesByAccountID[accountID]
        mailboxesByAccountID[accountID].push mailbox
        _.sortBy mailboxesByAccountID[accountID], 'path'
    else
        orphanMailboxes.push mailbox

exports.removeMailbox = (mailboxID) ->
    log.debug "removeMailbox"
    mailbox = mailboxesByID[mailboxID]
    delete mailboxesByID[mailboxID]
    accountID = mailbox.accountID
    list = mailboxesByAccountID[accountID]
    mailboxesByAccountID[accountID] = _.without list, mailbox if list
    list = orphanMailboxes
    orphanMailboxes = _.without list, mailbox
    Scheduler.orphanRemovalDebounced()


# LISTENERS

Account.on 'create', (created) ->
    exports.addAccount created

Account.on 'delete', (id, deleted) ->
    exports.removeAccount id

Mailbox.on 'create', (created) ->
    exports.addMailbox created

Mailbox.on 'delete', (id, deleted) ->
    exports.removeMailbox id

Message.on 'create', onMessageCreated = (created) ->
    isRead = '\\Seen' in created.flags
    isRecent = '\\Recent' in created.flags

    for boxID, uid of created.mailboxIDs
        countsByMailboxID[boxID].total  += 1
        countsByMailboxID[boxID].unread += 1 unless isRead
        countsByMailboxID[boxID].recent += 1 if isRecent

    unreadByAccountID[created.accountID] += 1 if isRead
    eventEmitter.emit 'change', created.accountID

Message.on 'delete', onMessageDestroyed = (id, old) ->
    wasRead = '\\Seen' in old.flags
    wasRecent = '\\Recent' in old.flags

    for boxID, uid of old.mailboxIDs
        countsByMailboxID[boxID].total  -= 1
        countsByMailboxID[boxID].unread -= 1 unless wasRead
        countsByMailboxID[boxID].recent -= 1 if wasRecent

    unreadByAccountID[old.accountID] -= 1 if wasRead
    eventEmitter.emit 'change', old.accountID

Message.on 'update', (updated, old) ->
    onMessageDestroyed old.id, old
    onMessageCreated updated


