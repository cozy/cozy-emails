Process = require './_base'
safeLoop = require '../utils/safeloop'
async = require 'async'
log = require('../utils/logging')(prefix: 'process:box_refresh_deep')
{FETCH_AT_ONCE} = require '../utils/constants'
{RefreshError} = require '../utils/errors'
_ = require 'lodash'
Message = require '../models/message'
ramStore = require '../models/store_account_and_boxes'


# This process perform the deep refresh of one mailbox
#
# options
#  :limitByBox
#  :firstImport
#  :storeHighestModSeq
#  :mailbox
#
# actions on couchdb
#   - create / delete / update messages to match the IMAP state of this box
#   - set lastSync and optionally total and higestmod on the box
#
# output
#  :shouldNotif - whether or not the unread count has changed in this refresh
#
module.exports = class MailboxRefreshDeep extends Process

    code: 'mailbox-refresh-deep'

    initialize: (options, done) ->
        @limitByBox = options.limitByBox
        @firstImport = options.firstImport
        @storeHighestModSeq = options.storeHighestModSeq
        @mailbox = options.mailbox
        @initialStep = true

        @shouldNotif = false

        @nbStep = 1
        @nbStepDone = 0
        @nbOperationDone = 0
        @nbOperationCurrentStep = 1

        if ramStore.getAccount(@mailbox.accountID).isTest()
            @finished = true

        async.whilst (=> not @finished), @refreshStep, (err) =>
            return done err if err
            @saveLastSync done

    # Public: refresh part of a mailbox
    refreshStep: (callback) =>
        log.debug "imap_refreshStep", @status()

        async.series [
            @getDiff
            @computeDiff
            @applyToRemove
            @applyFlagsChanges
            @applyToFetch
        ], callback

    getProgress: =>
        currentPart = @nbOperationDone / @nbOperationCurrentStep
        return (@nbStepDone + currentPart) / @nbStep

    status: =>
        msg = if @initialStep then 'initial' else ''
        msg += " limit: #{@limitByBox}" if @limitByBox
        msg += " range: #{@min}:#{@max}"
        msg += " finished" if @finished
        return msg

    # Public: compute the next step.
    # The step will have a [.min - .max] range of uid
    # of length = max(limitByBox, Constants.FETCH_AT_ONCE)
    #
    # uidnext - the box uidnext, which is always the upper limit of a
    #           box uids.
    #
    # Returns (void)
    setNextStep: (uidnext) =>
        log.debug "computeNextStep", @status(), "next", uidnext

        if @limitByBox and not @initialStep
            # the first step has the proper limitByBox size, we are done
            @finished = true

        else if @limitByBox
            # GET @limitByBox from the end of the box
            @initialStep = false
            @nbStep = 1
            @min = Math.max 1, uidnext - @limitByBox
            @max = Math.max 1, uidnext - 1

        else if @initialStep
            # first step, 1:FETCH_AT_ONCE
            @initialStep = false
            @nbStep = Math.ceil uidnext / FETCH_AT_ONCE
            @min = 1
            @max = Math.min uidnext, FETCH_AT_ONCE

        else
            # next steps, increase all by FETCH_AT_ONCE
            @min = Math.min uidnext, @max + 1
            @max = Math.min uidnext, @min + FETCH_AT_ONCE

        if @min is @max
            @finished = true

        log.debug "nextStepEnd", @status()

    UIDsInRange: (callback) ->
        Message.rawRequest 'byMailboxRequest',
            startkey: ['uid', @mailbox.id, @min]
            endkey: ['uid', @mailbox.id, @max]
            inclusive_end: true
            reduce: false
        , (err, rows) ->
            return callback err if err
            result = {}
            for row in rows
                uid = row.key[2]
                result[uid] = [row.id, row.value]
            callback null, result


    # Public: compute the diff between the imap box and the cozy one
    #
    # laststep - {RefreshStep} the previous step
    #
    # Returns (callback) {Object} operations and {RefreshStep} the next step
    #           :toFetch - [{Object}(uid, mid)] messages to fetch
    #           :toRemove - [{String}] messages to remove
    #           :flagsChange - [{Object}(id, flags)] messages where flags
    #                            need update
    getDiff: (callback) =>
        log.debug "diff", @status()
        @mailbox.doLaterWithBox (imap, imapbox, cbRelease) =>

            @setNextStep imapbox.uidnext
            @imapHighestmodseq = imapbox.highestmodseq
            @imapTotal = imapbox.messages.total
            if @finished
                return cbRelease null

            log.info "IMAP REFRESH #{@mailbox.label} UID #{@min}:#{@max}"

            async.series [
                (cb) => @UIDsInRange cb
                (cb) => imap.fetchMetadata @min, @max, cb
            ], cbRelease

        ,  (err, results) =>
            log.debug "diff#results"
            if err
                callback err
            else if @finished
                callback null
            else
                [@cozyIDs, @imapUIDs] = results
                callback null

    computeDiff: (callback) =>
        return callback null if @finished
        @toFetch = []
        @toRemove = []
        @flagsChange = []

        for uid, imapMessage of @imapUIDs
            cozyMessage = @cozyIDs[uid]
            if cozyMessage
                # this message is already in cozy, compare flags
                imapFlags = imapMessage[1]
                cozyFlags = cozyMessage[1]
                diff = _.xor(imapFlags, cozyFlags)

                # gmail is weird (same message has flag \\Draft
                # in some boxes but not all)
                needApply = diff.length > 2 or
                            diff.length is 1 and diff[0] isnt '\\Draft'

                if needApply
                    id = cozyMessage[0]
                    @flagsChange.push id: id, flags: imapFlags

            else # this message isnt in this box in cozy
                # add it to be fetched
                @toFetch.push {uid: parseInt(uid), mid: imapMessage[0]}

        for uid, cozyMessage of @cozyIDs
            unless @imapUIDs[uid]
                @toRemove.push id = cozyMessage[0]

        @nbOperationDone = 0
        @nbOperationCurrentStep = @toFetch.length + @toRemove.length +
                                                            @flagsChange.length

        callback null


    # Public: remove a batch of messages from the cozy box
    #
    # Returns (callback) at completion
    applyToRemove: (callback) =>
        return callback null if @finished
        log.debug "applyRemove", @toRemove.length
        safeLoop @toRemove, (id, cb) =>
            @nbOperationDone += 1
            Message.removeFromMailbox id, @mailbox, cb
        , (errors) ->
            if errors?.length then callback new RefreshError errors
            else callback null


    # Public: apply a batch of flags changes on messages in the cozy box
    #
    # Returns (callback) at completion
    applyFlagsChanges: (callback) =>
        return callback null if @finished
        log.debug "applyFlagsChanges", @flagsChange.length
        safeLoop @flagsChange, (change, cb) ->
            @nbOperationDone += 1
            log.debug "applyFlagsChanges", change
            Message.updateAttributes change.id, {flags: change.flags}, cb
        , (errors) ->
            if errors?.length then callback new RefreshError errors
            else callback null


    # Public: fetch a serie of message from the imap box
    #
    # Returns (callback) {Boolean} shouldNotif if one newly fetched is unread
    applyToFetch: (callback) =>
        return callback null if @finished
        log.debug "applyFetch", @toFetch.length
        safeLoop @toFetch, (msg, cb) =>
            Message.fetchOrUpdate @mailbox, msg, (err, result) ->
                @nbOperationDone += 1
                @shouldNotif = true if result?.shouldNotif is true
                # loop anyway, let the DS breath
                setTimeout (-> cb null), 50
        , (errors) ->
            if errors?.length then callback new RefreshError errors
            else callback null

    saveLastSync: (callback) =>
        changes = lastSync: new Date().toISOString()
        if @storeHighestModSeq
            changes.lastHighestModSeq = @imapHighestmodseq
            changes.lastTotal = @imapTotal
            log.debug "saveLastSync", @mailbox.label, changes
        @mailbox.updateAttributes changes, callback
