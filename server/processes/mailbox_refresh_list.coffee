Process = require './_base'
log = require('../utils/logging')(prefix: 'process:mailbox_refresh')
async = require 'async'
ramStore = require '../models/store_account_and_boxes'
_ = require 'lodash'
Mailbox = require '../models/mailbox'
safeLoop = require '../utils/safeloop'

module.exports = class MailboxRefreshList extends Process

    code: 'mailbox-refresh-list'

    initialize: (options, callback) ->

        @account = options.account
        async.series [
            @diffBoxesList
            @createNewBoxes
            @destroyOldBoxes
        ], callback


    diffBoxesList: (callback) =>
        cozyBoxes = ramStore.getMailboxesByAccount @account.id
        @account.imap_getBoxes (err, imapBoxes) =>
            log.debug "refreshBoxes#results", cozyBoxes.length
            return callback err if err

            # find new imap boxes
            @created = imapBoxes.filter (box) ->
                not _.findWhere(cozyBoxes, path: box.path)

            @destroyed = cozyBoxes.filter (box) ->
                not _.findWhere(imapBoxes, path: box.path)

            log.debug "refreshBoxes#results2", @created.length,
                imapBoxes.length, @destroyed.length

            callback null

    createNewBoxes: (callback) =>
        log.debug "creating", @created.length, "boxes"
        safeLoop @created, (box, next) =>
            box.accountID = @account.id
            Mailbox.create box, next
        , (errors) ->
            log.error 'fail to create box', err for err in errors
            callback null


    destroyOldBoxes: (callback) =>
        log.debug "destroying", @destroyed.length, "boxes"
        safeLoop @destroyed, (box, next) =>
            box.destroy (err) =>
                log.error 'fail to destroy box', err if err
                @account.forgetBox box.id, next
        , (errors) ->
            log.error 'fail to forget box', err for err in errors
            callback null
