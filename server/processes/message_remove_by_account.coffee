Process = require './_base'
{MAX_RETRIES, CONCURRENT_DESTROY, LIMIT_DESTROY} = require '../utils/constants'
ERRORMSG = "DS has crashed ? waiting 4s before try again"
Message = require '../models/message'
async = require 'async'
log = require('../utils/logging')('process:removebyaccount')



module.exports = class RemoveAllMessagesFromAccount extends Process

    code: 'delete-messages-from-account'

    initialize: (options, callback)->
        @accountID = options.accountID
        @retries = MAX_RETRIES

        async.doWhilst @step, @notFinished, callback

    notFinished: =>
        @batch and @batch.length > 0

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
        Message.rawRequest 'dedupRequest',
            limit: LIMIT_DESTROY
            startkey: [@accountID]
            endkey: [@accountID, {}]

        , (err, rows) =>
            return callback err if err
            @batch = rows or []
            callback null


    destroyMessages: (callback) =>
        async.eachLimit @batch, CONCURRENT_DESTROY, (row, cb) ->
            Message.destroy(row.id, cb)
        , callback
