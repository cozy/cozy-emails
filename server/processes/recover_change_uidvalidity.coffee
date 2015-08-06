Process = require './_base'
safeLoop = require '../utils/safeloop'
async = require 'async'
log = require('../utils/logging')('process:recover-uidvalidity')
mailutils = require '../utils/jwz_tools'
Message = require '../models/message'



module.exports = class RecoverChangedUIDValidity extends Process

    code: 'recover-uidvalidity'

    initialize: (options, callback) ->
        @mailbox = options.mailbox
        @newUidvalidity = options.newUidvalidity
        @imap = options.imap
        @done = 0
        @total = 1

        async.series [
            (cb) => @imap.openBox @mailbox.path, cb
            @fetchAllImapMessageIDs
            @fixMessagesUIDs
            @storeNewUIDValidty
        ], callback

    getProgress: ->
        @done / @total

    fetchAllImapMessageIDs: (callback) =>
        @imap.fetchBoxMessageIDs (err, messages) =>
            return callback err if err
            # messages is a map uid -> message-id
            @messages = messages
            @uids = Object.keys(messages)
            @total = @uids.length
            callback null

    fixMessagesUIDs: (callback) =>
        safeLoop @uids, (newUID, cb) =>
            messageID = mailutils.normalizeMessageID @messages[newUID]
            @fixOneMessageUID messageID, newUID, cb
        , (errors) ->
            log.error err for err in errors
            callback errors[0]

    fixOneMessageUID: (messageID, newUID, callback) =>
        log.debug "recoverChangedUID"
        @done += 1
        Message.byMessageID @mailbox.accountID, messageID, (err, message) =>
            return callback err if err
            # no need to recover if the message doesnt exist
            return callback null unless message
            return callback null unless message.mailboxIDs[@mailbox.id]
            mailboxIDs = message.cloneMailboxIDs()
            mailboxIDs[@mailbox.id] = newUID
            message.updateAttributes {mailboxIDs}, callback

    storeNewUIDValidty: (callback) =>
        changes = uidvalidity: @newUidvalidity
        @mailbox.updateAttributes changes, callback
