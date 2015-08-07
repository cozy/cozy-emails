Message = require '../models/message'
safeLoop = require '../utils/safeloop'
async = require 'async'
ramStore = require '../models/store_account_and_boxes'
log = require('../utils/logging')(prefix: 'patch:ignored')

exports.patchAllAccounts = (callback) ->
    accounts = ramStore.getAllAccounts()
    async.eachSeries accounts, patchOneAccount, callback

# Public: patch this account to mark its junk & spam message as ignored
#
# Returns (callback) at completion
patchOneAccount = (account, callback) ->
    log.debug "applyPatchIgnored, already = ", account.patchIgnored
    return callback null if account.patchIgnored

    boxes = []
    boxes.push account.trashMailbox if account.trashMailbox
    boxes.push account.junkMailbox if account.junkMailbox
    log.debug "applyPatchIgnored", boxes
    safeLoop boxes, markAllMessagesAsIgnored, (errors) ->
        if errors.length
            log.debug "applyPatchIgnored:fail", account.id
            callback null
        else
            log.debug "applyPatchIgnored:success", account.id
            # if there was no error, the account is patched
            # note it so we dont apply patch again
            account.updateAttributes patchIgnored: true, callback


# Public: mark all messages in a box as ignoreInCount
# keep looping but throw an error if one fail
#
# boxID - {String} the box id
#
# Returns (callback) at completion
markAllMessagesAsIgnored = (boxID, callback) ->
    changes = {ignoreInCount: true}
    markIgnored = (id, next) -> Message.updateAttributes id, changes, next

    Message.rawRequest 'byMailboxRequest',
        startkey: ['uid', boxID, 0]
        endkey: ['uid', boxID, 'a'] # = Infinity in couchdb collation
        reduce: false
    , (err, rows) ->
        return callback err if err
        ids = rows?.map (row) -> row.id
        safeLoop ids, markIgnored, (errors) ->
            log.warn "error marking msg ignored", err for err in errors
            callback errors[0]
