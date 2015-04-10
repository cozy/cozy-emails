cozydb = require 'cozydb'

# Public: the mailbox model
class Mailbox extends cozydb.CozyModel
    @docType: 'Mailbox'
    @schema:
        accountID: String        # Parent account
        label: String            # Human readable label
        path: String             # IMAP path
        lastSync: String         # Date.ISOString of last full box synchro
        tree: [String]           # Normalized path as Array
        delimiter: String        # delimiter between this box and its children
        uidvalidity: Number      # Imap UIDValidity
        attribs: [String]        # [String] Attributes of this folder

    # map of account's attributes -> RFC6154 special use box attributes
    @RFC6154:
        draftMailbox:   '\\Drafts'
        sentMailbox:    '\\Sent'
        trashMailbox:   '\\Trash'
        allMailbox:     '\\All'
        junkMailbox:    '\\Junk'
        flaggedMailbox: '\\Flagged'

    # Public: create a box in imap and in cozy
    #
    # account - {Account} to create the box in
    # parent - {Mailbox} to create the box in
    # label - {String} label of the new mailbox
    #
    # Returns (callback) {Mailbox}
    @imapcozy_create: (account, parent, label, callback) ->
        if parent
            path = parent.path + parent.delimiter + label
            tree = parent.tree.concat label
        else
            path = label
            tree = [label]

        mailbox =
            accountID: account.id
            label: label
            path: path
            tree: tree
            delimiter: parent?.delimiter or '/'
            attribs: []

        ImapPool.get(account.id).doASAP (imap, cbRelease) ->
            imap.addBox2 path, cbRelease
        , (err) ->
            return callback err if err
            Mailbox.create mailbox, callback


    # Public: find selectable mailbox for an account ID
    # as an array
    #
    # accountID - id of the account
    #
    # Returns (callback) {Array} of {Mailbox}
    @getBoxes: (accountID, callback) ->
        Mailbox.rawRequest 'treeMap',
            startkey: [accountID]
            endkey: [accountID, {}]
            include_docs: true

        , (err, rows) ->
            return callback err if err
            rows = rows.map (row) ->
                new Mailbox row.doc

            callback null, rows

    # Public: find selectable mailbox for an account ID
    # as an id indexed object with only path attributes
    # @TODO : optimize this with a map/reduce request
    #
    # accountID - id of the account
    #
    # Returns (callback) [{Mailbox}]
    @getBoxesIndexedByID: (accountID, callback) ->
        Mailbox.getBoxes accountID, (err, boxes) ->
            return callback err if err
            boxIndex = {}
            boxIndex[box.id] = box for box in boxes
            callback null, boxIndex

    # Public: remove mailboxes linked to an account that doesn't exist
    # in cozy.
    # @TODO : optimize this with a map destroy
    #
    # existing - {Array} of {String} ids of existing accounts
    #
    # Returns (callback) [{Mailbox}] all remaining mailboxes
    @removeOrphans: (existings, callback) ->
        log.debug "removeOrphans"
        Mailbox.rawRequest 'treemap', {}, (err, rows) ->
            return callback err if err

            boxes = []

            async.eachSeries rows, (row, cb) ->
                accountID = row.key[0]
                if accountID in existings
                    boxes.push row.id
                    cb null
                else
                    log.debug "removeOrphans - found orphan", row.id
                    Mailbox.destroy row.id, (err) ->
                        log.error 'failed to delete box', row.id
                        cb null

            , (err) ->
                callback err, boxes

    # Public: get the recent, unread and total count of message for a mailbox
    #
    # mailboxID - {String} id of the mailbox
    #
    # Returns (callback) {Object} counts
    #           :recent - {Number} number of recent messages
    #           :total - {Number} total number of messages
    #           :unread - {Number} number of unread messages
    @getCounts: (mailboxID, callback) ->
        options = if mailboxID
            startkey: ['date', mailboxID]
            endkey: ['date', mailboxID, {}]
        else
            startkey: ['date', ""]
            endkey: ['date', {}]

        options.reduce = true
        options.group_level = 3

        Message.rawRequest 'byMailboxRequest', options, (err, rows) ->
            return callback err if err
            result = {}
            rows.forEach (row) ->
                [DATEFLAG, boxID, flag] = row.key
                result[boxID] ?= {unread: 0, total: 0, recent: 0}
                if flag is "!\\Recent"
                    result[boxID].recent = row.recent
                if flag is "!\\Seen"
                    result[boxID].unread = row.value
                else if flag is null
                    result[boxID].total = row.value

            callback null, result

    # Public: is this box the inbox
    #
    # Returns {Boolean} if its the INBOX
    isInbox: -> @path is 'INBOX'


    # Public: is this box selectable (ie. can contains mail)
    #
    # Returns {Boolean} if its selectable
    isSelectable: ->
        '\\Noselect' not in (@attribs or [])


    # Public: get this box usage by special attributes
    #
    # Returns {String} the account attribute to set or null
    RFC6154use: ->
        for field, attribute of Mailbox.RFC6154
            if attribute in @attribs
                return field

    # Public: try to guess this box usage by its name
    #
    # Returns {String} the account attribute to set or null
    guessUse: ->
        path = @path.toLowerCase()
        if /sent/i.test path
            return 'sentMailbox'
        else if /draft/i.test path
            return 'draftMailbox'
        else if /flagged/i.test path
            return 'flaggedMailbox'
        else if /trash/i.test path
            return 'trashMailbox'
        # @TODO add more


    # Public: wrap an async function (the operation) to get a connection from
    # the pool before performing it and release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAP: (operation, callback) ->
        ImapPool.get(@accountID).doASAP operation, callback

    # Public: wrap an async function (the operation) to get a connection from
    # the pool and open the mailbox without error before performing it and
    # release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAPWithBox: (operation, callback) ->
        ImapPool.get(@accountID).doASAPWithBox @, operation, callback

    # Public: wrap an async function (the operation) to get a connection from
    # the pool and open the mailbox without error before performing it and
    # release the connection once it is done. The operation will be put at the
    # bottom of the queue.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doLaterWithBox: (operation, callback) ->
        ImapPool.get(@accountID).doLaterWithBox @, operation, callback


    # Public: get this mailbox's children mailboxes
    #
    # Returns (callback) an {Array} of {Mailbox}
    getSelfAndChildren: (callback) ->
        Mailbox.rawRequest 'treemap',
            startkey: [@accountID].concat @tree
            endkey: [@accountID].concat @tree, {}
            include_docs: true

        , (err, rows) ->
            return callback err if err
            rows = rows.map (row) -> new Mailbox row.doc

            callback null, rows


    # Public: destroy all mailboxes belonging to an account.
    #
    # accountID - {String} id of the account to destroy mailboxes from
    #
    # Returns (callback) at completion
    @destroyByAccount: (accountID, callback) ->
        Mailbox.rawRequest 'treemap',
                startkey: [accountID]
                endkey: [accountID, {}]

        , (err, rows) ->
            return callback err if err
            async.eachSeries rows, (row, cb) ->
                Mailbox.destroy row.id, (err) ->
                    log.error "Fail to delete box", err.stack or err if err
                    cb null # ignore one faillure
            , callback


    # Public: rename a box in IMAP and Cozy
    #
    # newLabel - {String} the box updated label
    # newPath - {String} the box updated path
    #
    # Returns (callback) at completion
    imapcozy_rename: (newLabel, newPath, callback) ->
        log.debug "imapcozy_rename", newLabel, newPath
        @imap_rename newLabel, newPath, (err) =>
            log.debug "imapcozy_rename err", err
            return callback err if err
            @renameWithChildren newLabel, newPath, (err) ->
                return callback err if err
                callback null

    # Public: rename a box in IMAP
    #
    # newLabel - {String} the box updated label
    # newPath - {String} the box updated path
    #
    # Returns (callback) at completion
    imap_rename: (newLabel, newPath, callback) ->
        @doASAP (imap, cbRelease) =>
            imap.renameBox2 @path, newPath, cbRelease
        , callback

    # Public: delete a box in IMAP and Cozy
    #
    # Returns (callback) at completion
    imapcozy_delete: (account, callback) ->
        log.debug "imapcozy_delete"
        box = this

        async.series [
            (cb) =>
                @imap_delete cb
            (cb) ->
                log.debug "account.forget"
                account.forgetBox box.id, cb
            (cb) =>
                log.debug "destroyAndRemoveAllMessages"
                @destroyAndRemoveAllMessages cb
        ], callback

    # Public: delete a box in IMAP
    #
    # Returns (callback) at completion
    imap_delete: (callback) ->
        log.debug "imap_delete"
        @doASAP (imap, cbRelease) =>
            imap.delBox2 @path, cbRelease
        , callback



    # Public: rename a box and its children in cozy
    #
    # newPath - {String} the new path
    # newLabel - {String} the new label
    #
    # Returns (callback) {Array} of {Mailbox} updated boxes
    renameWithChildren: (newLabel, newPath, callback) ->
        log.debug "renameWithChildren", newLabel, newPath, @path
        depth = @tree.length - 1
        path = @path

        @getSelfAndChildren (err, boxes) ->
            log.debug "imapcozy_rename#boxes", boxes, depth
            return callback err if err

            async.eachSeries boxes, (box, cb) ->
                log.debug "imapcozy_rename#box", box
                changes = {}
                changes.path = box.path.replace path, newPath
                changes.tree = (item for item in box.tree)
                changes.tree[depth] = newLabel
                if box.tree.length is depth + 1 # self
                    changes.label = newLabel
                box.updateAttributes changes, cb
            , callback

    # Public: destroy a mailbox and sub-mailboxes
    # remove all message from it & its sub-mailboxes
    # returns fast after destroying mailbox & sub-mailboxes
    # in the background, proceeds to remove messages
    #
    # Returns  mailbox destroyed completion
    destroyAndRemoveAllMessages: (callback) ->

        @getSelfAndChildren (err, boxes) ->
            return callback err if err

            async.eachSeries boxes, (box, cb) ->
                box.destroy (err) ->
                    log.error "fail to destroy box #{box.id}", err if err
                    Message.safeRemoveAllFromBox box.id, (err) ->
                        if err
                            log.error """"
                                fail to remove msg of box #{box.id}""", err
                        # loop anyway
                        cb()
            , callback

    # Public: refresh some mails from this box
    #
    # options - the parameter {Object}
    #   :limitByBox - {Number} limit nb of message by box
    #   :firstImport - {Boolean} is this part of the first import of an account
    #
    # Returns (callback) {Boolean} shouldNotif whether or not new unread mails
    # have been fetched in this fetch
    imap_fetchMails: (options, callback) ->
        {limitByBox, firstImport} = options
        log.debug "imap_fetchMails", limitByBox
        step = RefreshStep.initial options

        @imap_refreshStep step, (err, shouldNotif) =>
            log.debug "imap_fetchMailsEnd", limitByBox
            return callback err if err
            unless limitByBox
                changes = lastSync: new Date().toISOString()
                @updateAttributes changes, callback
            else
                callback null, shouldNotif


    # Public: compute the diff between the imap box and the cozy one
    #
    # laststep - {RefreshStep} the previous step
    #
    # Returns (callback) {Object} operations and {RefreshStep} the next step
    #           :toFetch - [{Object}(uid, mid)] messages to fetch
    #           :toRemove - [{String}] messages to remove
    #           :flagsChange - [{Object}(id, flags)] messages where flags
    #                            need update
    getDiff: (laststep, callback) ->
        log.debug "diff", laststep

        step = null
        box = this

        @doLaterWithBox (imap, imapbox, cbRelease) ->

            step = laststep.getNext(imapbox.uidnext)
            if step is RefreshStep.finished
                return cbRelease null

            log.info "IMAP REFRESH", box.label, "UID #{step.min}:#{step.max}"

            async.series [
                (cb) -> Message.UIDsInRange box.id, step.min, step.max, cb
                (cb) -> imap.fetchMetadata step.min, step.max, cb
            ], cbRelease

        ,  (err, results) ->
            log.debug "diff#results"
            return callback err if err
            return callback null, null unless results
            [cozyIDs, imapUIDs] = results


            toFetch = []
            toRemove = []
            flagsChange = []

            for uid, imapMessage of imapUIDs
                cozyMessage = cozyIDs[uid]
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
                        flagsChange.push id: id, flags: imapFlags

                else # this message isnt in this box in cozy
                    # add it to be fetched
                    toFetch.push {uid: parseInt(uid), mid: imapMessage[0]}

            for uid, cozyMessage of cozyIDs
                unless imapUIDs[uid]
                    toRemove.push id = cozyMessage[0]

            callback null, {toFetch, toRemove, flagsChange}, step


    # Public: remove a batch of messages from the cozy box
    #
    # toRemove - {Array} of {String} ids of cozy messages to remove
    # reporter - {ImapReporter} will be incresead by 1 for each remove
    #
    # Returns (callback) at completion
    applyToRemove: (toRemove, reporter, callback) ->
        log.debug "applyRemove", toRemove.length
        async.eachSeries toRemove, (id, cb) =>
            Message.removeFromMailbox id, this, (err) ->
                reporter.onError err if err
                reporter.addProgress 1
                cb null

        , callback


    # Public: apply a batch of flags changes on messages in the cozy box
    #
    # flagsChange - {Array} of {Object}(id, flags) changes to make
    # reporter - {ImapReporter} will be incresead by 1 for each change
    #
    # Returns (callback) at completion
    applyFlagsChanges: (flagsChange, reporter, callback) ->
        log.debug "applyFlagsChange", flagsChange.length
        async.eachSeries flagsChange, (change, cb) ->
            Message.applyFlagsChanges change.id, change.flags, (err) ->
                reporter.onError err if err
                reporter.addProgress 1
                cb null
        , callback

    # Public: fetch a serie of message from the imap box
    #
    # toFetch - {Array} of {Object}(mid, uid) msg to fetch
    # reporter - {ImapReporter} will be incresead by 1 for each fetch
    #
    # Returns (callback) {Boolean} shouldNotif if one newly fetched is unread
    applyToFetch: (toFetch, reporter, callback) ->
        log.debug "applyFetch", toFetch.length
        box = this
        toFetch.reverse()
        shouldNotif = false
        async.eachSeries toFetch, (msg, cb) ->
            Message.fetchOrUpdate box, msg, (err, result) ->
                reporter.onError err if err
                reporter.addProgress 1
                if result?.shouldNotif is true
                    shouldNotif = true
                # loop anyway, let the DS breath
                setTimeout (-> cb null), 50
        , (err) ->
            callback err, shouldNotif

    # Public: refresh part of a mailbox
    #
    # laststep - {RefreshStep} can be null, step references            -
    #
    # Returns (callback) {Boolean} shouldNotif display a notification for it
    imap_refreshStep: (laststep, callback) ->
        log.debug "imap_refreshStep", laststep
        box = this
        @getDiff laststep, (err, ops, step) =>
            log.debug "imap_refreshStep#diff", err, ops

            return callback err if err
            return callback null, false unless ops

            nbTasks = ops.toFetch.length + ops.toRemove.length +
                                                        ops.flagsChange.length
            if nbTasks > 0
                isFirstImport = laststep.firstImport
                reporter = ImapReporter.boxFetch @, nbTasks, isFirstImport

            shouldNotifStep = false

            async.series [
                (cb) => @applyToRemove     ops.toRemove,    reporter, cb
                (cb) => @applyFlagsChanges ops.flagsChange, reporter, cb
                (cb) =>
                    @applyToFetch ops.toFetch, reporter, (err, shouldNotif) ->
                        return cb err if err
                        shouldNotifStep = shouldNotif
                        cb null
            ], (err) =>
                reporter?.onDone()

                if err
                    reporter.onError err if err
                    return callback err

                else # next step
                    @imap_refreshStep step, (err, shouldNotifNext) ->
                        callback err, shouldNotifStep or shouldNotifNext


    # Public: get a message UID from its message id in IMAP
    #
    # messageID - {String} the message ID to find
    #
    # Returns (callback) {String} the message uid or null
    imap_UIDByMessageID: (messageID, callback) ->
        @doLaterWithBox (imap, imapbox, cb) ->
            imap.search [['HEADER', 'MESSAGE-ID', messageID]], cb
        , (err, uids) ->
            callback err, uids?[0]

    # Public: create a mail in IMAP if it doesnt exist yet
    # use for sent mail
    #
    # account - {Account} the account
    # message - {Message} the message
    #
    # Returns (callback) at task completion
    imap_createMailNoDuplicate: (account, message, callback) ->
        messageID = message.headers['message-id']
        mailbox = this
        @imap_UIDByMessageID messageID, (err, uid) ->
            return callback err if err
            return callback null, uid if uid
            account.imap_createMail mailbox, message, callback


    # Public: remove a mail in the given box
    # used for drafts
    #
    # uid - {Number} the message to remove
    #
    # Returns (callback) at completion
    imap_removeMail: (uid, callback) ->
        @doASAPWithBox (imap, imapbox, cbRelease) ->
            async.series [
                (cb) -> imap.addFlags uid, '\\Deleted', cb
                (cb) -> imap.expunge uid, cb
                (cb) -> imap.closeBox cb
            ], cbRelease
        , callback

    # Public: recover if this box has changed its UIDVALIDTY
    #
    # imap - the {ImapConnection}
    #
    # Returns (callback) at completion
    recoverChangedUIDValidity: (imap, callback) ->
        box = this

        imap.openBox @path, (err) ->
            return callback err if err
            # @TODO : split it by 1000
            imap.fetchBoxMessageIDs (err, messages) ->
                # messages is a map uid -> message-id
                uids = Object.keys(messages)
                reporter = ImapReporter.recoverUIDValidty box, uids.length
                async.eachSeries uids, (newUID, cb) ->
                    messageID = mailutils.normalizeMessageID messages[newUID]
                    Message.recoverChangedUID box, messageID, newUID, (err) ->
                        reporter.onError err if err
                        reporter.addProgress 1
                        cb null
                , (err) ->
                    reporter.onDone()
                    callback null

    # Public: BEWARE expunge (permanent delete) all mails from this box
    #
    # Returns (callback) at completion
    imap_expungeMails: (callback) ->
        box = this
        @doASAPWithBox (imap, imapbox, cbRelease) ->
            imap.fetchBoxMessageUIDs (err, uids) ->
                return cbRelease err if err
                return cbRelease null if uids.length is 0
                async.series [
                    (cb) -> imap.addFlags uids, '\\Deleted', cb
                    (cb) -> imap.expunge uids, cb
                    (cb) -> imap.closeBox cb
                    (cb) -> Message.safeRemoveAllFromBox box.id, (err) ->
                        if err
                            log.error """
                                fail to remove msg of box #{box.id}""", err
                        # loop anyway
                        cb()
                ], cbRelease
        , callback

    # Public: refresh part of a mailbox
    #
    # uid - uid to fetch
    #
    # Returns (callback) {Boolean} shouldNotif if the message is not read
    Mailbox::imap_fetchOneMail = (uid, callback) ->
        @doLaterWithBox (imap, imapbox, cb) ->
            imap.fetchOneMail uid, cb

        , (err, mail) =>
            return callback err if err
            shouldNotif = '\\Seen' in mail.flags
            Message.createFromImapMessage mail, this, uid, (err) ->
                return callback err if err
                callback null, {shouldNotif}

    # Public: whether this box messages should be ignored
    # in the account's total (trash or junk)
    #
    # Returns {Boolean} true if this message should be ignored.
    Mailbox::ignoreInCount = ->
        return Mailbox.RFC6154.trashMailbox in @attribs or
               Mailbox.RFC6154.junkMailbox  in @attribs or
               @guessUse() in ['trashMailbox', 'junkMailbox']


module.exports = Mailbox
Message = require './message'
log = require('../utils/logging')(prefix: 'models:mailbox')
_ = require 'lodash'
async = require 'async'
mailutils = require '../utils/jwz_tools'
ImapPool = require '../imap/pool'
ImapReporter = require '../imap/reporter'
{Break, NotFound} = require '../utils/errors'
{FETCH_AT_ONCE} = require '../utils/constants'

require('../utils/socket_handler').wrapModel Mailbox, 'mailbox'




# Public: store the state of a refresh
#
# Examples
#
#    step0 = RefreshStep.initial(100, false)
#    step1 = step0.getNext(30)
#    step1.min == 1 and step1.max == 30
#
#    step0 = RefreshStep.initial(100, false)
#    step1 = step0.getNext(1500)
#    step1.min == 1401 and step1.max == 1500
#
#    step0 = RefreshStep.initial(null, false)
#    step1 = step0.getNext(1500)
#    step1.min == 501 and step1.max == 1500
#    step2 = step1.getNext(1500) # 1500 is not used here
#    step2.min == 1 and step2.max == 500
class RefreshStep

    # a pseudo symbol for comparison
    @finished: {symbol: 'DONE'}

    # Public: get the first step.
    # The first step is marked as .initial = true and doesnt have min or max
    #
    # options - {Object}
    #       :limitByBox - {Number} max number of message to fetch in a box or
    #              null for all
    #       :firstImport - {Boolean}
    #
    # Returns {RefreshStep} an initial step
    @initial: (options) ->
        step = new RefreshStep()
        step.limitByBox = options.limitByBox
        step.firstImport = options.firstImport
        step.shouldNotif = false
        step.initial = true
        return step

    # Public: compute the next step.
    # The step will have a [.min - .max] range of uid
    # of length = max(limitByBox, Constants.FETCH_AT_ONCE)
    #
    # uidnext - the box uidnext, which is always the upper limit of a
    #           box uids.
    #
    # Returns {RefreshStep} the next step
    getNext: (uidnext) ->
        log.debug "computeNextStep", this, uidnext, @limitByBox

        if @initial
            # pretend the last step was max: INFINITY, min: uidnext
            @min = uidnext + 1

        if @min is 1
            # uid are always > 1, we are done
            return RefreshStep.finished

        if @limitByBox and not @initial
            # the first step has the proper limitByBox size, we are done
            return RefreshStep.finished

        range = if @limitByBox then @limitByBox else FETCH_AT_ONCE

        step = new RefreshStep()
        step.firstImport = @firstImport
        step.limitByBox = @limitByBox
        step.shouldNotif = @shouldNotif
        # new max is old min
        step.max = Math.max 1, @min - 1
        # new min is old min - range
        step.min = Math.max 1, @min - range

        return step












