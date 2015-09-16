ERRORMSG = "DS has crashed ? waiting 4s before try again"
{MAX_RETRIES, CONCURRENT_DESTROY, LIMIT_UPDATE} = require '../utils/constants'
Process = require './_base'
async = require 'async'
Message = require '../models/message'
log = require('../utils/logging')('process:removebymailbox')


module.exports = class RemoveAllMessagesFromMailbox extends Process

    code: 'remove-all-from-box'

    initialize: (options, callback)->
        @mailboxID = options.mailboxID
        @toDestroyMailboxIDs = options.toDestroyMailboxIDs or []
        @retries = MAX_RETRIES
        @batch

        async.doWhilst @step, @notFinished, callback

    notFinished: =>
        @batch.length > 0

    step: (callback) =>
        @fetchMessages (err) =>
            return callback err if err
            return callback null if @batch.length is 0
            @destroyMessages (err) =>
                if err and @retries > 0
                    log.warn ERRORMSG, err
                    @retries--
                    setTimeout callback, 4000

                else if err
                    callback err

                else
                    # we are not done, loop again, resetting the retries
                    @retries = MAX_RETRIES
                    callback null

    fetchMessages: (callback) =>
        Message.rawRequest 'byMailboxRequest',
            limit: LIMIT_UPDATE
            startkey: ['uid', @mailboxID, -1]
            endkey: ['uid', @mailboxID, {}]
            include_docs: true
            reduce: false

        , (err, rows) =>
            return callback err if err
            @batch = rows.map (row) -> new Message(row.doc)
            callback null

    shouldDestroy: (message) =>
        for boxID, uid of message.mailboxIDs
            if boxID not in @toDestroyMailboxIDs
                return false

        return true

    destroyMessages: (callback) =>
        async.eachLimit @batch, CONCURRENT_DESTROY, (message, cb) =>
            if @shouldDestroy message then message.destroy cb
            else message.removeFromMailbox id: @mailboxID, false, cb
        , callback
