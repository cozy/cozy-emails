americano = require 'americano-cozy'

module.exports = Mailbox = americano.getModel 'Mailbox',
    accountID: String        # Parent account
    label: String            # Human readable label
    path: String             # IMAP path
    lastsync: String         # Date.ISOString of last full box synchro
    tree: (x) -> x           # Normalized path as Array
    delimiter: String        # delimiter between this box and its children
    uidvalidity: Number      # Imap UIDValidity
    attribs: (x) -> x        # [String] Attributes of this folder

Message = require './message'
log = require('../utils/logging')(prefix: 'models:mailbox')
_ = require 'lodash'
async = require 'async'
mailutils = require '../utils/jwz_tools'
ImapPool = require '../imap/pool'
ImapReporter = require '../imap/reporter'
{Break} = require '../utils/errors'
{FETCH_AT_ONCE} = require '../utils/constants'


# map of account's attributes -> RFC6154 special use box attributes
Mailbox.RFC6154 =
    draftMailbox:   '\\Drafts'
    sentMailbox:    '\\Sent'
    trashMailbox:   '\\Trash'
    allMailbox:     '\\All'
    spamMailbox:    '\\Junk'
    flaggedMailbox: '\\Flagged'

Mailbox::isInbox = -> @path is 'INBOX'
Mailbox::isSelectable = ->
    '\\Noselect' not in (@attribs or [])

Mailbox::RFC6154use = ->
    for field, attribute of Mailbox.RFC6154
        if attribute in @attribs
            return field

Mailbox::guessUse = ->
    path = @path.toLowerCase()
    if 0 is path.indexOf 'sent'
        return 'sentMailbox'
    else if 0 is path.indexOf 'draft'
        return 'draftMailbox'
    else if 0 is path.indexOf 'flagged'
        return 'flaggedMailbox'
    else if 0 is path.indexOf 'trash'
        return 'trashMailbox'
    # @TODO add more


Mailbox.imapcozy_create = (account, parent, label, callback) ->
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
        imap.addBox path, cbRelease
    , (err) ->
        return callback err if err
        Mailbox.create mailbox, callback

Mailbox.findSafe = (callback) ->
    Mailbox.find id, (err, box) ->
        return callback err if err
        return callback new NotFound "Account #{account.id} draftbox #{id}"
        draftBox = box
        callback()


# Public: find selectable mailbox for an account ID
# as an array
#
# accountID - id of the account
#
# Returns  [{Mailbox}]
Mailbox.getBoxes = (accountID, callback) ->
    Mailbox.rawRequest 'treeMap',
        startkey: [accountID]
        endkey: [accountID, {}]
        include_docs: true

    , (err, rows) ->
        return callback err if err
        rows = rows.map (row) ->
            new Mailbox row.doc
        rows = rows.filter (box) ->
            '\\Noselect' not in box.attribs

        callback null, rows

# Public: get this mailbox's children mailboxes
#
# Returns  [{Mailbox}]
Mailbox::getSelfAndChildren = (callback) ->
    Mailbox.rawRequest 'treemap',
        startkey: [@accountID].concat @tree
        endkey: [@accountID].concat @tree, {}
        include_docs: true

    , (err, rows) ->
        return callback err if err
        rows = rows.map (row) -> new Mailbox row.doc

        callback null, rows


# Public: build a tree of the mailboxes
#
# accountID - id of the account
#
# Returns  the tree
Mailbox.getClientTree = (accountID, callback) ->

    DELIMITER = '/|/'

    Mailbox.rawRequest 'treeMap',
        startkey: [accountID]
        endkey: [accountID, {}]
        include_docs: true

    , (err, rows) ->
        return callback err if err

        out = []
        byPath = {}

        rows.forEach (row) ->
            path = row.key[1..] # remove accountID
            # we keep a reference by path to easily find parent
            box = _.pick row.doc, 'label', 'attribs'
            byPath[path.join DELIMITER] = box

            box.id = row.id
            box.children = []

            if path.length is 1 # first level box
                out.push box
            else
                # this is a submailbox,  we find its parent
                # by path and append it
                parentPath = path[0..-2].join DELIMITER
                if byPath[parentPath]?
                    byPath[parentPath].children.push box
                else
                    # this should never happen
                    log.error "NO MAILBOX of path #{parentPath} in #{accountID}"


        callback null, out


# Public: destroy mailboxes by their account ID
#
# accountID - id of the account to destroy mailboxes from
#
# Returns  mailboxes destroyed completion
Mailbox.destroyByAccount = (accountID, callback) ->
    Mailbox.rawRequest 'treemap',
            startkey: [accountID]
            endkey: [accountID, {}]

    , (err, rows) ->
        return callback err if err
        async.eachSeries rows, (row, cb) ->
            new Mailbox(id: row.id).destroy (err) ->
                log.error "Fail to delete box", err.stack or err if err
                # ignore one faillure
                cb null

        , callback


Mailbox::imapcozy_rename = (newLabel, newPath, callback) ->
    log.debug "imapcozy_rename", newLabel, newPath
    @imap_rename newLabel, newPath, (err) =>
        log.debug "imapcozy_rename err", err
        return callback err if err
        @renameWithChildren newLabel, newPath, (err) ->
            return callback err if err
            callback null

Mailbox::imap_rename = (newLabel, newPath, callback) ->
    @doASAP (imap, cbRelease) =>
        imap.renameBox2 @path, newPath, cbRelease
    , callback


Mailbox::imapcozy_delete = (account, callback) ->
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

Mailbox::imap_delete = (callback) ->
    log.debug "imap_delete"
    @doASAP (imap, cbRelease) =>
        imap.delBox2 @path, cbRelease
    , callback



# rename this mailbox and its children
#
# newPath - the new path
# newLabel - the new label
#
# Returns  updated box
Mailbox::renameWithChildren = (newLabel, newPath, callback) ->
    log.debug "renameWithChildren", newLabel, newPath, @path
    depth = @tree.length - 1
    path = @path

    @getSelfAndChildren (err, boxes) ->
        log.debug "imapcozy_rename#boxes", boxes, depth
        return callback err if err

        async.eachSeries boxes, (box, cb) ->
            log.debug "imapcozy_rename#box", box
            box.path = box.path.replace path, newPath
            box.tree[depth] = newLabel
            box.label = newLabel if box.tree.length is depth + 1
            log.debug "imapcozy_rename#boxafter", box
            box.save cb
        , callback

# Public: destroy a mailbox and sub-mailboxes
# remove all message from it & its sub-mailboxes
# returns fast after destroying mailbox & sub-mailboxes
# in the background, proceeds to remove messages
#
# Returns  mailbox destroyed completion
Mailbox::destroyAndRemoveAllMessages = (callback) ->

    @getSelfAndChildren (err, boxes) ->
        return callback err if err

        async.eachSeries boxes, (box, cb) ->
            box.destroy (err) ->
                log.error "fail to destroy box #{box.id}", err if err
                Message.safeRemoveAllFromBox box.id, (err) ->
                    log.error "fail to remove msg of box #{box.id}", err if err
                    # loop anyway
                    cb()
        , callback


Mailbox::imap_fetchMails = (limitByBox, callback) ->
    log.debug "imap_fetchMails", limitByBox
    @imap_refreshStep limitByBox, null, (err) =>
        log.debug "imap_fetchMailsEnd", limitByBox
        return callback err if err
        unless limitByBox
            changes = lastSync: new Date().toISOString()
            @updateAttributes changes, callback
        else
            callback null



computeNextStep = (laststep, uidnext, limitByBox) ->
    log.debug "computeNextStep", laststep, uidnext, limitByBox
    laststep ?= min: uidnext + 1

    if laststep.min is 1
        return false


    step =
        max: Math.max 1, laststep.min - 1
        min: Math.max 1, laststep.min - FETCH_AT_ONCE

    if limitByBox
        step.min = Math.max 1, laststep.min - limitByBox

    return step

Mailbox::getDiff = (laststep, limit, callback) ->
    log.debug "diff", laststep, limit

    step = null
    box = this

    @doLaterWithBox (imap, imapbox, cbRelease) =>

        unless step = computeNextStep(laststep, imapbox.uidnext, limit)
            return cbRelease null

        log.info "IMAP REFRESH", box.label, "UID #{step.min}:#{step.max}"

        async.parallel [
            (cb) -> imap.fetchMetadata step.min, step.max, cb
            (cb) -> Message.UIDsInRange box.id, step.min, step.max, cb
        ], cbRelease

    ,  (err, results) ->
        log.debug "diff#results"
        return callback err if err
        return callback null, null unless results
        [imapUIDs, cozyIds] = results


        toFetch = []
        toRemove = []
        flagsChange = []

        for uid, imapMessage of imapUIDs
            if cozyMessage = cozyIds[uid]
                # this message is already in cozy, compare flags
                imapFlags = imapMessage[1]
                cozyFlags = cozyMessage[1]
                if _.xor(imapFlags, cozyFlags).length
                    id = cozyMessage[0]
                    flagsChange.push id: id, flags: imapFlags

            else # this message isnt in this box in cozy
                # add it to be fetched
                toFetch.push {uid: parseInt(uid), mid: imapMessage[0]}

        for uid, cozyMessage of cozyIds
            unless imapUIDs[uid]
                toRemove.push id = cozyMessage[0]

        callback null, {toFetch, toRemove, flagsChange, step}

Mailbox::applyToRemove = (toRemove, reporter, callback) ->
    log.debug "applyRemove", toRemove.length
    async.eachSeries toRemove, (id, cb) =>
        Message.removeFromMailbox id, this, (err) ->
            reporter.onError err if err
            reporter.addProgress 1
            cb null

    , callback


Mailbox::applyFlagsChanges = (flagsChange, reporter, callback) ->
    log.debug "applyFlagsChange", flagsChange.length
    async.eachSeries flagsChange, (change, cb) ->
        Message.applyFlagsChanges change.id, change.flags, (err) ->
            reporter.onError err if err
            reporter.addProgress 1
            cb null
    , callback

Mailbox::applyToFetch = (toFetch, reporter, callback) ->
    log.debug "applyFetch", toFetch.length
    box = this
    async.eachSeries toFetch, (msg, cb) ->
        Message.fetchOrUpdate box, msg.mid, msg.uid, (err) ->
            if err
                reporter.onError err if err
                reporter.addProgress 1
            # dont stop
            cb null
    , callback

Mailbox::imap_refreshStep = (limitByBox, laststep, callback) ->
    log.debug "imap_refreshStep", limitByBox, laststep
    box = this
    @getDiff laststep, limitByBox, (err, ops) =>
        log.debug "imap_refreshStep#diff", err, ops

        return callback err if err
        return callback null unless ops

        nbTasks = ops.toFetch.length + ops.toRemove.length +
                                                        ops.flagsChange.length
        reporter = ImapReporter.boxFetch @, nbTasks if nbTasks > 0

        async.series [
            (cb) => @applyToRemove     ops.toRemove,    reporter, cb
            (cb) => @applyFlagsChanges ops.flagsChange, reporter, cb
            (cb) => @applyToFetch      ops.toFetch,     reporter, cb
        ], (err) =>

            reporter?.onDone()
            if limitByBox
                callback null
            else
                @imap_refreshStep null, ops.step, callback


Mailbox::imap_UIDByMessageID = (messageID, callback) ->
    @doLaterWithBox (imap, imapbox, cb) ->
        imap.search [['HEADER', 'MESSAGE-ID', messageID]], cb
    , (err, uids) ->
        callback err, uids?[0]

# check if a mail exist in destination before
# creating it
Mailbox::imap_createMailNoDuplicate = (account, message, callback) ->
    messageID = message.headers['message-id']
    mailbox = this
    @imap_UIDByMessageID messageID, (err, uid) ->
        return cb err if err
        return callback null, uid if uid
        account.imap_createMail mailbox, message, callback

Mailbox::imap_fetchOneMail = (uid, callback) ->
    @doLaterWithBox (imap, imapbox, cb) ->
        imap.fetchOneMail uid, cb

    , (err, mail) =>
        return callback err if err
        Message.createFromImapMessage mail, this, uid, callback

# Public: remove a mail in the given box
# used for drafts
#
# uid - {Number} the message to remove
#
# Returns  the UID of the created mail
Mailbox::imap_removeMail = (uid, callback) ->
    @doASAPWithBox (imap, imapbox, cbRelease) ->
        async.series [
            (cb) -> imap.addFlags uid, '\\Deleted', cb
            (cb) -> imap.expunge uid, cb
            (cb) -> imap.closeBox cb
        ], cbRelease
    , callback

Mailbox::recoverChangedUIDValidity = (imap, callback) ->
    box = this

    imap.openBox @path, (err) ->
        return callback err if err
        # @TODO : split it by 1000
        imap.fetchBoxMessageIds (err, messages) ->
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



Mailbox::doASAP = (operation, callback) ->
    ImapPool.get(@accountID).doASAP operation, callback

Mailbox::doASAPWithBox = (operation, callback) ->
    ImapPool.get(@accountID).doASAPWithBox @, operation, callback

Mailbox::doLaterWithBox = (operation, callback) ->
    ImapPool.get(@accountID).doLaterWithBox @, operation, callback