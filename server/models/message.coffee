americano = require 'americano-cozy'

# Public: Message
#

module.exports = Message = americano.getModel 'Message',

    accountID: String        # account this message belongs to
    messageID: String        # normalized message-id (no <"">)
    normSubject: String      # normalized subject (no Re: ...)
    conversationID: String   # all message in thread have same conversationID
    mailboxIDs: (x) -> x     # mailboxes as an hash {boxID:uid, boxID2:uid2}
    flags: (x) -> x          # [String] flags of the message
    headers: (x) -> x        # hash of the message headers
    from: (x) -> x           # array of {name, address}
    to: (x) -> x             # array of {name, address}
    cc: (x) -> x             # array of {name, address}
    bcc: (x) -> x            # array of {name, address}
    replyTo: (x) -> x        # array of {name, address}
    subject: String          # subject of the message
    inReplyTo: (x) -> x      # array of message-ids
    references: (x) -> x     # array of message-ids
    text: String             # message content as text
    html: String             # message content as html
    date: Date               # message date
    priority: String         # message priority
    binary: (x) -> x         # cozy binaries
    attachments: (x) -> x    # array of message attachments objects

mailutils = require '../utils/jwz_tools'
CONSTANTS = require '../utils/constants'
{MSGBYPAGE, LIMIT_DESTROY, LIMIT_UPDATE, CONCURRENT_DESTROY} = CONSTANTS
{NotFound} = require '../utils/errors'
uuid = require 'uuid'
_ = require 'lodash'
async = require 'async'
log = require('../utils/logging')(prefix: 'models:message')
Mailbox = require './mailbox'
ImapPool = require '../imap/pool'
sanitizer = require 'sanitizer'
htmlToText  = require 'html-to-text'

# Public: get messages in a box, sorted by Date
#
# mailboxID - {String} the mailbox's ID
# params - query's options
# callback - Function(err, [{Message}])
#
# Returns void
Message.getResultsAndCount = (mailboxID, params, callback) ->
    {before, after, descending, sortField, flag} = params

    flag ?= null

    [before, after] = [after, before] if descending
    optionsCount =
        descending: descending
        startkey: [sortField, mailboxID, flag, before]
        endkey: [sortField, mailboxID, flag, after]
        reduce: true
        group_level: 2

    optionsResults =
        descending: descending
        startkey: [sortField, mailboxID, flag, before]
        endkey: [sortField, mailboxID, flag, after]
        reduce: false
        include_docs: true
        limit: MSGBYPAGE

    if params.resultsAfter
        optionsResults.startkey[3] = params.resultsAfter
        optionsResults.skip = 1

    async.parallel [
        (cb) -> Message.rawRequest 'byMailboxRequest', optionsCount, cb
        (cb) -> Message.rawRequest 'byMailboxRequest', optionsResults, cb
    ], (err, results) ->
        return callback err if err
        [count, results] = results

        messages = results.map (row) -> new Message row.doc
        callback null, {messages, count: count[0]?.value or 0}


Message.updateOrCreate = (message, callback) ->
    log.debug "create or update"
    if message.id
        Message.find message.id, (err, existing) ->
            log.debug "update"
            return cb err if err
            return cb new NotFound "Message #{message.id}" unless existing
            # prevent overiding of binary
            message.binary = existing.binary
            existing.updateAttributes message, callback

    else
        log.debug "create"
        Message.create message, callback

Message.fetchOrUpdate = (box, mid, uid, callback) ->
    Message.byMessageId box.accountID, mid, (err, existing) ->
        return callback err if err
        if existing and not existing.isInMailbox box
            existing.addToMailbox box, uid, callback
        else if existing
            # this is the weird case when a message is in the box
            # under two different UIDs
            # @TODO : maybe mark the message to handle modification of
            # such messages
            return callback null
        else
            box.imap_fetchOneMail uid, callback

# Public: get the uids present in a box in cozy
#
# mailboxID - id of the mailbox to check
# min, max - get only UIDs between min & max
# callback - Function(err, {uid: [couchdID, flags]})
#
# Returns void
Message.UIDsInRange = (mailboxID, min, max, callback) ->
    Message.rawRequest 'byMailboxRequest',
        startkey: ['uid', mailboxID, min]
        endkey: ['uid', mailboxID, max]
        inclusive_end: true
        reduce: false

    , (err, rows) ->
        return callback err if err
        result = {}
        for row in rows
            uid = row.key[2]
            result[uid] = [row.id, row.value]
        callback null, result

# Public: find a message by its message id
#
# accountID - id of the account to scan
# messageID - message-id to search, no need to normalize
# callback - Function(err, [{Message}])
#
# Returns void
Message.byMessageId = (accountID, messageID, callback) ->
    messageID = mailutils.normalizeMessageID messageID
    Message.rawRequest 'dedupRequest',
        key: [accountID, 'mid', messageID]
        include_docs: true

    , (err, rows) ->
        return callback err if err
        message = rows[0]?.doc
        message = new Message message if message

        callback null, message

# Public: find messages by there conversation-id
#
# conversationID - id of the conversation to fetch
#
# callback - Function(err, [{Message}]
#
# Returns void
Message.byConversationId = (conversationID, callback) ->
    Message.rawRequest 'byConversationId',
        key: conversationID
        include_docs: true

    , (err, rows) ->
        return callback err if err
        messages = rows.map (row) -> new Message row.doc
        callback null, messages


# Public: destroy all messages for an account
# play it safe by limiting number of messages in RAM
# and number of concurrent requests to the DS
# and allowing for the occasional DS failure
# @TODO : refactor this after a good night
# @TODO : stress test DS requestDestroy
#
# accountID - {String} id of the account
# retries - {Number} of DS failures we tolerate
# callback - Function(err)
#
# Returns void
Message.safeDestroyByAccountID = (accountID, callback, retries = 2) ->
    log.info "destroying all messages in account #{accountID}"
    Message.rawRequest 'dedupRequest',
        limit: LIMIT_DESTROY
        startkey: [accountID]
        endkey: [accountID, {}]

    , (err, rows) ->
        return callback err if err
        return callback null if rows.length is 0
        log.info "destroying", rows.length, "messages"

        async.eachLimit rows, CONCURRENT_DESTROY, (row, cb) ->
            new Message(id: row.id).destroy cb
        , (err) ->

            if err and retries > 0
                log.info "DS has crashed ? waiting 4s before try again", err
                async.delay 4000, ->
                    retries = retries - 1
                    Message.safeDestroyByAccountID accountID, callback, retries

            else if err
                return callback err

            else
                # we are not done, loop again, resetting the retries
                Message.safeDestroyByAccountID accountID, callback, 2


# Public: remove all messages from a mailbox
# play it safe by limiting number of messages in RAM
# and number of concurrent requests to the DS
# and allowing for the occasional DS failure
# @TODO : refactor this after a good night
# @TODO : stress test DS requestDestroy & use it instead
#
# mailboxID - {String} id of the mailbox
# retries - {Number} of DS failures we tolerate
# callback - Function(err)
#
# Returns void

Message.safeRemoveAllFromBox = (mailboxID, callback, retries = 2) ->
    log.info "removing all messages from mailbox #{mailboxID}"
    Message.rawRequest 'byMailboxRequest',
        limit: LIMIT_UPDATE
        startkey: ['uid', mailboxID, 0]
        endkey: ['uid', mailboxID, {}]
        include_docs: true
        reduce: false

    , (err, rows) ->
        return callback err if err
        return callback null if rows.length is 0

        async.eachLimit rows, CONCURRENT_DESTROY, (row, cb) ->
            new Message(row.doc).removeFromMailbox(id: mailboxID, cb)

        , (err) ->

            if err and retries > 0
                log.info "DS has crashed ? waiting 4s before try again", err
                async.delay 4000, ->
                    retries = retries - 1
                    Message.safeRemoveAllFromBox mailboxID, callback, retries

            else if err
                return callback err

            else
                # we are not done, loop again, resetting the retries
                Message.safeRemoveAllFromBox mailboxID, callback, 2


# Public: add the message to a mailbox in the cozy
#
# box - {Mailbox} to add this message to
# uid - {Number} uid of the message in the mailbox
# callback - Function(err, {Message} updated)
#
# Returns void
Message::addToMailbox = (box, uid, callback) ->
    log.info "MAIL #{box.path}:#{uid} ADDED TO BOX"
    mailboxIDs = @mailboxIDs or {}
    mailboxIDs[box.id] = uid
    @updateAttributes {mailboxIDs}, callback

Message::isInMailbox = (box) ->
    return @mailboxIDs[box.id]?

# Public: remove a message from a mailbox in the cozy
# if the message becomes an orphan, we destroy it
#
# box - {Mailbox} to remove this message from
# noDestroy - {Boolean} dont destroy orphan messages
# callback - Function(err, {Message} updated)
#
# Returns void
Message::removeFromMailbox = (box, noDestroy = false, callback) ->
    log.debug ".removeFromMailbox", @id, box.label
    noDestroy = callback unless callback

    mailboxIDs = @mailboxIDs
    delete mailboxIDs[box.id]

    isOrphan = Object.keys(mailboxIDs).length is 0
    log.info "REMOVING #{@id}, NOW ORPHAN = ", isOrphan

    if isOrphan and not noDestroy then @destroy callback
    else @updateAttributes {mailboxIDs}, callback


# @TODO : this should be one request
Message.removeFromMailbox = (id, box, callback) ->
    log.debug "removeFromMailbox", id, box.label
    Message.find id, (err, message) ->
        return callback err if err
        return callback new NotFound "Message #{id}" unless message
        message.removeFromMailbox box, false, callback

# @TODO : this should be one request
Message.applyFlagsChanges = (id, flags, callback) ->
    log.debug "applyFlagsChanges", id, flags
    Message.find id, (err, message) ->
        return callback err if err
        message.updateAttributes {flags}, callback


# Public: apply a json-patch to the message in both cozy & imap
#
# patch: {Object} the json-patch
# callback - Function(err, {Message} updated)
#
# Returns void
Message::applyPatchOperations = (patch, callback) ->
    log.debug ".applyPatchOperations", patch

    # copy the fields
    newmailboxIDs = {}
    newmailboxIDs[boxid] = uid for boxid, uid of @mailboxIDs

    # scan the patch and change the fields
    boxOps = {addTo: [], removeFrom: []}
    for operation in patch when operation.path.indexOf('/mailboxIDs/') is 0
        boxid = operation.path.substring 12
        if operation.op is 'add'
            boxOps.addTo.push boxid
            newmailboxIDs[boxid] = -1
        else if operation.op is 'remove'
            boxOps.removeFrom.push boxid
            delete newmailboxIDs[boxid]
        else throw new Error 'modifying UID is not possible'

    # copy flags
    newflags = (flag for flag in @flags)
    for operation in patch when operation.path.indexOf('/flags/') is 0
        index = parseInt operation.path.substring 7
        if operation.op is 'add'
            newflags.push operation.value

        else if operation.op is 'remove'
            newflags.splice index, 1

        else if operation.op is 'replace'
            newflags[index] = operation.value

    # applyMessageChanges will perform operation in IMAP
    # and store results in the message (this)
    # wee need to save afterward
    @imap_applyChanges newflags, newmailboxIDs, boxOps, (err, changes) =>
        return callback err if err
        @updateAttributes changes, callback

Message::imap_applyChanges = (newflags, newmailboxIDs, boxOps, callback) ->
    log.debug ".applyChanges", newflags, newmailboxIDs

    Mailbox.getBoxes @accountID, (err, boxes) =>


        boxIndex = {}
        for box in boxes
            uid = @mailboxIDs[box.id]
            boxIndex[box.id] = path: box.path, uid: uid

        # ERROR CASES
        for boxid in boxOps.addTo when not boxIndex[boxid]
            throw new Error "the box ID=#{boxid} doesn't exists"

        firstboxid = Object.keys(@mailboxIDs)[0]
        firstuid = @mailboxIDs[firstboxid]

        log.debug "CHANGING FLAGS OF ", firstboxid, firstuid, @mailboxIDs

        @doASAP (imap, releaseImap) ->

            async.series [

                # step 1 - open one box at random
                (cb) -> imap.openBox boxIndex[firstboxid].path, cb
                # step 2 - change flags to newflags
                (cb) -> imap.setFlags firstuid, newflags, cb
                # step 3 - copy the message to all addTo
                (cb) ->
                    paths = boxOps.addTo.map (destId) ->
                        boxIndex[destId].path

                    imap.multicopy firstuid, paths, (err, uids) ->
                        return callback err if err
                        for i in [0..uids.length - 1] by 1
                            destId = boxOps.addTo[i]
                            newmailboxIDs[destId] = uids[i]
                        cb null
                # step 4 - remove the message from all removeFrom
                (cb) ->
                    async.eachSeries boxOps.removeFrom, (boxid, cb2) ->
                        {path, uid} = boxIndex[boxid]
                        imap.deleteMessageInBox path, uid, cb2
                    , cb

            ], releaseImap

        , (err) ->
            return callback err if err
            callback null,
                mailboxIDs: newmailboxIDs
                flags: newflags


# create a message from a raw imap message
# handle normalization of message ids & subjects
# handle attachments
# callback - Function(err, {Message} created)
#
# Returns void
Message.createFromImapMessage = (mail, box, uid, callback) ->
    log.debug "createFromImapMessage"

    # we store the box & account id
    mail.accountID = box.accountID
    mail.mailboxIDs = {}
    mail.mailboxIDs[box._id] = uid

    # we store normalized versions of subject & messageID for threading
    messageID = mail.headers['message-id']
    mail.messageID = mailutils.normalizeMessageID messageID if messageID
    mail.normSubject = mailutils.normalizeSubject mail.subject if mail.subject

    # @TODO, find and parse from mail.headers ?
    mail.replyTo = []
    mail.cc ?= []
    mail.bcc ?= []
    mail.to ?= []
    mail.from ?= []

    if not mail.date?
        mail.date = new Date().toISOString()

    # we extract the attachments buffers
    # @TODO : directly create binaries ? (first step for streaming)
    attachments = []
    if mail.attachments
        attachments = mail.attachments.map (att) ->
            buffer = att.content
            delete att.content
            return out =
                name: att.generatedFileName
                buffer: buffer

    # pick a method to find the conversation id
    # if there is a x-gm-thrid, use it
    # else find the thread using References or Subject
    Message.findConversationId mail, (err, conversationID) ->
        return callback err if err
        mail.conversationID = conversationID
        Message.create mail, (err, jdbMessage) ->
            return callback err if err
            jdbMessage.storeAttachments attachments, callback


Message::storeAttachments = (attachments, callback) ->
    log.debug "storeAttachments"
    async.eachSeries attachments, (att, cb) =>
        # WEIRDFIX#1 - some attachments name are broken
        # WEIRDFIX#2 - some attachments have no buffer
        # att.name = att.name.replace "\ufffd", ""
        # attachBinary need a path attributes
        att.buffer ?= new Buffer 0
        att.buffer.path = encodeURI att.name
        @attachBinary att.buffer, name: att.name, cb

    , callback

Message.findConversationId = (mail, callback) ->
    log.debug "findConversationId"
    if mail.headers['x-gm-thrid']
        return callback null, mail.headers['x-gm-thrid']


    # try to find by references
    references = mail.references or []
    references.concat mail.inReplyTo or []
    references = references.map mailutils.normalizeMessageID
        .filter (mid) -> mid # ignore unparsable messageID


    if references.length
        # find all messages in references
        keys = references.map (id) -> [mail.accountID, 'mid', id]
        Message.rawRequest 'dedupRequest', {keys}, (err, rows) ->
            return callback err if err
            Message.pickConversationID rows, callback

    # no references, try to find by subject
    # @TODO, should only do this if subject start with variation of Re:
    else if mail.normSubject?.length > 3
        key = [mail.accountID, 'subject', mail.normSubject]
        Message.rawRequest 'dedupRequest', {key}, (err, rows) ->
            return callback err if err
            Message.pickConversationID rows, callback

    else
        callback null, uuid.v4()
        # give it a random uid




# we have a number of rows key=messageID, value=ThrID
# that we assume are actually one thread
# we pick one thrId (most used)
# we update the messages to use it
# and return it
Message.pickConversationID = (rows, callback) ->
    log.debug "pickConversationID"
    conversationIDCounts = {}
    for row in rows
        conversationIDCounts[row.value] ?= 1
        conversationIDCounts[row.value]++

    pickedConversationID = null
    pickedConversationIDCount = 0

    # find the most used conversationID
    for conversationID, count of conversationIDCounts
        if count > pickedConversationIDCount
            pickedConversationID = conversationID
            pickedConversationIDCount = count

    # if its undefined, we create one (UUID)
    unless pickedConversationID? and pickedConversationID isnt 'undefined'
        pickedConversationID = uuid.v4()

    change = conversationID: pickedConversationID

    # we update all messages to the new conversationID
    async.eachSeries rows, (row, cb) ->
        Message.find row.id, (err, message) ->
            log.warn "Cant get message #{row.id}, ignoring"
            if err or message.conversationID is pickedConversationID
                cb null
            else
                message.updateAttributes change, cb

    , (err) ->
        return callback err if err
        callback null, pickedConversationID

Message::toClientObject = ->
    # log.debug "toClientObject"
    raw = @toObject()

    raw.attachments?.forEach (file) ->
        file.url = "/message/#{raw.id}/attachments/#{file.generatedFileName}"

    if raw.html?
        raw.html = mailutils.sanitizeHTML raw.html, raw.attachments

    if not raw.text?
        raw.text = htmlToText.fromString raw.html,
            tables: true
            wordwrap: 80

    return raw



Message::doASAP = (operation, callback) ->
    ImapPool.get(@accountID).doASAP operation, callback

Message.recoverChangedUID = (box, messageID, newUID, callback) ->
    log.debug "recoverChangedUID"
    Message.byMessageId box.accountID, messageID, (err, message) ->
        return callback err if err
        # no need to recover if the message doesnt exist
        return callback null unless message
        return callback null unless message.mailboxIDs[box.id]
        mailboxIDs = message.mailboxIDs
        mailboxIDs[box.id] = newUID
        message.updateAttributes {mailboxIDs}, callback