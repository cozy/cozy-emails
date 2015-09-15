ramStore = require '../models/store_account_and_boxes'
Message = require '../models/message'
safeLoop = require '../utils/safeloop'
Process = require './_base'
RemoveAllMessagesFromMailbox = require './message_remove_by_mailbox'
Scheduler = require './_scheduler'
log = require('../utils/logging')('process:removeorphans')
async  = require 'async'


module.exports = class OrphanRemoval extends Process

    code: 'orphan-removal'

    initialize: (options, callback) ->

        async.series [
            @removeMailboxOrphans
            @getOrphanMessageMailboxesIDs
            @removeOrphansMessageFromMailboxes
            @destroyNoBoxMessages
        ], callback

    # Public: remove mailboxes linked to an account that doesn't exist
    # in cozy.
    #
    # Returns (callback) at completion
    removeMailboxOrphans: (callback) ->
        log.debug "removeOrphans"
        safeLoop ramStore.getOrphanBoxes(), (box, next) ->
            box.destroy next
        , (errors) ->
            for err in errors when -1 is err.message.indexOf 'not found'
                log.error 'failed to delete box', err
            callback null

    getOrphanMessageMailboxesIDs: (callback) =>
        Message.rawRequest 'byMailboxRequest',
            reduce: true
            group_level: 2
            startkey: ['uid', '']
            endkey: ['uid', "\uFFFF"]
        , (err, rows) =>
            return callback err if err
            mailboxIDs = rows.map (row) -> row.key[1]
            existingMailboxes = ramStore.getMailboxesID()
            @toDestroyMailboxIDs = mailboxIDs.filter (id) ->
                id not in existingMailboxes
            callback null

    removeOrphansMessageFromMailboxes: (callback) =>
        safeLoop @toDestroyMailboxIDs, (mailboxID, next) =>
            log.debug "removeOrphans - found orphan from box", mailboxID
            options = {mailboxID, @toDestroyMailboxIDs}
            removal = new RemoveAllMessagesFromMailbox options
            removal.run next
        , (errors) ->
            log.error "failed to remove message", err for err in errors
            callback null

    destroyNoBoxMessages: (callback) ->
        options =
            key: ['nobox']
            reduce: false
        Message.rawRequest 'byMailboxRequest', options, (err, rows) ->
            return callback err if err
            safeLoop rows, (row, next) ->
                Message.destroy row.id, next
            , (errors) ->
                log.error 'fail to destroy orphan msg', err for err in errors
                callback null

