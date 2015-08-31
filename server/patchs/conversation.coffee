Message = require '../models/message'
async = require 'async'
ramStore = require '../models/store_account_and_boxes'
log = require('../utils/logging')(prefix: 'patch:conversation')

PATCH_BATCH_SIZE = 10000

exports.patchAllAccounts = (callback) ->
    accounts = ramStore.getAllAccounts()
    async.eachSeries accounts, exports.patchOneAccount, callback


exports.patchOneAccount =  (account, callback) ->
    log.debug "applyPatchConversation"
    status = {skip: 0}
    async.whilst (-> not status.complete),
        (cb) -> applyPatchConversationStep account, status, cb
    , callback

applyPatchConversationStep = (account, status, next) ->
    Message.rawRequest 'conversationPatching',
        reduce: true
        group_level: 2
        startkey: [account.id]
        endkey: [account.id, {}]
        limit: PATCH_BATCH_SIZE
        skip: status.skip
    , (err, rows) ->
        return next err if err
        if rows.length is 0
            status.complete = true
            return next null

        # rows without value are correct conversations
        problems = rows.filter (row) -> row.value isnt null
            .map (row) -> row.key

        log.debug "conversationPatchingStep", status.skip,
              rows.length, problems.length

        if problems.length is 0
            status.skip += PATCH_BATCH_SIZE
            next null
        else
            async.eachSeries problems, patchConversationOne, (err) ->
                return next err if err
                status.skip += PATCH_BATCH_SIZE
                next null

patchConversationOne = (key, callback) ->
    Message.rawRequest 'conversationPatching',
        reduce: false
        key: key
    , (err, rows) ->
        return callback err if err
        Message.pickConversationID rows, callback
