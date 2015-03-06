cozydb = require 'cozydb'

# Public: Message
#

class MailAdress extends cozydb.Model
    @schema:
        name: String
        address: String

module.exports = Message = cozydb.getModel 'Message',

    accountID      : String          # account this message belongs to
    messageID      : String          # normalized message-id (no <"">)
    normSubject    : String          # normalized subject (no Re: ...)
    conversationID : String          # all message in thread have same
                                     # conversationID
    mailboxIDs     : cozydb.NoSchema # mailboxes as an hash
                                     # {boxID: uid, boxID2 : uid2}
    hasTwin        : [String]        # [String] mailboxIDs where this message
                                     # has twin
    flags          : [String]        # [String] flags of the message
    headers        : cozydb.NoSchema # hash of the message headers
    from           : [MailAdress]    # array of {name, address}
    to             : [MailAdress]    # array of {name, address}
    cc             : [MailAdress]    # array of {name, address}
    bcc            : [MailAdress]    # array of {name, address}
    replyTo        : [MailAdress]    # array of {name, address}
    subject        : String          # subject of the message
    inReplyTo      : [String]        # array of message-ids
    references     : [String]        # array of message-ids
    text           : String          # message content as text
    html           : String          # message content as html
    date           : Date            # message date
    priority       : String          # message priority
    binary         : cozydb.NoSchema
    attachments    : cozydb.NoSchema
    alternatives   : cozydb.NoSchema # for calendar content

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
htmlToText  = require 'html-to-text'

require('../utils/socket_handler').wrapModel Message, 'message'

# Public: get messages in a box, sorted by Date
#
# mailboxID - {String} the mailbox's ID
# params - query's options
# callback - Function(err, [{Message}])
#
# Returns void
Message.getResultsAndCount = (mailboxID, params, callback) ->
    params.flag ?= null
    if params.descending
        [params.before, params.after] = [params.after, params.before]

    async.series [
        (cb) -> Message.getCount mailboxID, params, cb
        (cb) -> Message.getResults mailboxID, params, cb
    ], (err, results) ->
        return callback err if err
        [count, messages] = results

        conversationIDs = _.uniq _.pluck messages, 'conversationID'

        Message.getConversationLengths conversationIDs, (err, lengths) ->
            return callback err if err

            callback null,
                messages: messages
                count: count
                conversationLengths: lengths

Message.getResults = (mailboxID, params, callback) ->
    {before, after, descending, sortField, flag} = params

    skip = 0

    if params.resultsAfter
        before = params.resultsAfter
        skip = 1

    Message.rawRequest 'byMailboxRequest',
        descending: descending
        startkey: [sortField, mailboxID, flag, before]
        endkey: [sortField, mailboxID, flag, after]
        reduce: false
        skipe: skip
        include_docs: true
        limit: MSGBYPAGE
    , (err, rows) ->
        return callback err if err
        callback null, rows.map (row) -> new Message row.doc

Message.getCount = (mailboxID, params, callback) ->
    {before, after, descending, sortField, flag} = params

    Message.rawRequest 'byMailboxRequest',
        descending: descending
        startkey: [sortField, mailboxID, flag, before]
        endkey: [sortField, mailboxID, flag, after]
        reduce: true
        group_level: 2
    , (err, rows) ->
        return callback err if err
        callback null, rows[0]?.value or 0



Message.updateOrCreate = (message, callback) ->
    log.debug "create or update"
    if message.id
        Message.find message.id, (err, existing) ->
            log.debug "update"
            if err
                callback err
            else if not existing
                callback new NotFound "Message #{message.id}"
            else
                # prevent overiding of binary
                message.binary = existing.binary
                existing.updateAttributes message, callback

    else
        log.debug "create"
        Message.create message, callback

Message.fetchOrUpdate = (box, mid, uid, callback) ->
    log.debug "fetchOrUpdate", box.id, mid, uid
    Message.byMessageID box.accountID, mid, (err, existing) ->
        return callback err if err
        if existing and not existing.isInMailbox box
            log.debug "        add"
            existing.addToMailbox box, uid, callback
        else if existing
            # this is the weird case when a message is in the box
            # under two different UIDs
            log.debug "        twin"
            existing.markTwin box, uid, callback
        else
            log.debug "        fetch"
            setTimeout ->
                box.imap_fetchOneMail uid, callback
            , 50

Message::markTwin = (box, uid, callback) ->
    hasTwin = @hasTwin or []
    return callback null unless box.id in hasTwin
    hasTwin.push box.id
    @updateAttributes changes: {hasTwin}, callback


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
Message.byMessageID = (accountID, messageID, callback) ->
    messageID = mailutils.normalizeMessageID messageID
    Message.rawRequest 'dedupRequest',
        key: [accountID, 'mid', messageID]
        include_docs: true

    , (err, rows) ->
        return callback err if err
        message = rows[0]?.doc
        message = new Message message if message

        callback null, message

# Public: get lengths of multiple conversations
#
# conversationIDs - [String] id of the conversations
#
# callback - Function(err, {conversationID:count}
#
# Returns void
Message.getConversationLengths = (conversationIDs, callback) ->

    Message.rawRequest 'byConversationID',
        keys: conversationIDs
        group: true
        reduce: true

    , (err, rows) ->
        return callback err if err
        out = {}
        out[row.key] = row.value for row in rows
        callback null, out



# Public: find messages by there conversation-id
#
# conversationID - id of the conversation to fetch
#
# callback - Function(err, [{Message}]
#
# Returns void
Message.byConversationID = (conversationID, callback) ->
    Message.rawRequest 'byConversationID',
        key: conversationID
        reduce: false
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
            new Message(id: row.id).destroy (err) ->
                if err?.message is "Document not found"
                    cb null
                else
                    cb err
        , (err) ->

            if err and retries > 0
                log.warn "DS has crashed ? waiting 4s before try again", err
                setTimeout ->
                    retries = retries - 1
                    Message.safeDestroyByAccountID accountID, callback, retries
                , 4000

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
                log.warn "DS has crashed ? waiting 4s before try again", err
                setTimeout ->
                    retries = retries - 1
                    Message.safeRemoveAllFromBox mailboxID, callback, retries
                , 4000

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
    callback = noDestroy unless callback

    mailboxIDs = @mailboxIDs
    delete mailboxIDs[box.id]

    isOrphan = Object.keys(mailboxIDs).length is 0
    log.debug "REMOVING #{@id}, NOW ORPHAN = ", isOrphan

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


Message.removeOrphans = (existings, callback) ->
    log.debug "removeOrphans"
    Message.rawRequest 'byMailboxRequest',
        reduce: true
        group_level: 2
        startkey: ['uid', '']
        endkey: ['uid', "\uFFFF"]
    , (err, rows) ->
        return callback err if err

        async.eachSeries rows, (row, cb) ->
            mailboxID = row.key[1]
            if mailboxID in existings
                cb null
            else
                log.debug "removeOrphans - found orphan", row.id
                Message.safeRemoveAllFromBox mailboxID, (err) ->
                    log.error 'failed to remove message', row.id, err if err
                    cb null

        , callback


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
        else throw new Error "modifying UID is not possible, bad operation #{operation.op}"

    flagsOps = {add: [], remove: []}
    for operation in patch when operation.path.indexOf('/flags/') is 0
        index = parseInt operation.path.substring 7
        if operation.op is 'add'
            flagsOps.add.push operation.value

        else if operation.op is 'remove'
            flagsOps.remove.push @flags[index]

        else if operation.op is 'replace'
            if @flags[index] isnt operation.value
                flagsOps.remove.push @flags[index]
                flagsOps.add.push operation.value

    # create the newflags
    newflags = @flags
    newflags = _.difference newflags, flagsOps.remove
    newflags = _.union newflags, flagsOps.add

    # applyMessageChanges will perform operation in IMAP
    @imap_applyChanges newflags, flagsOps, newmailboxIDs, \
                                                    boxOps, (err, changes) =>
        return callback err if err
        @updateAttributes changes, callback

Message::imap_applyChanges = (newflags, flagsOps, newmailboxIDs, \
                                                        boxOps, callback) ->
    log.debug ".applyChanges", newflags, newmailboxIDs

    oldflags = @flags

    Mailbox.getBoxesIndexedByID @accountID, (err, boxIndex) =>

        return callback err if err
        for boxID, box of boxIndex
            box.uid = @mailboxIDs[boxID]

        # ERROR CASES
        for boxid in boxOps.addTo when not boxIndex[boxid]
            return callback new Error "the box ID=#{boxid} doesn't exists"

        firstboxid = Object.keys(@mailboxIDs)[0]
        firstuid = @mailboxIDs[firstboxid]

        log.debug "CHANGING FLAGS OF ", firstboxid, firstuid, @mailboxIDs

        @doASAP (imap, releaseImap) ->

            permFlags = null

            async.series [

                # step 1 - open one box at random
                (cb) ->
                    imap.openBox boxIndex[firstboxid].path, (err, imapBox) ->
                        return cb err if err
                        permFlags = imapBox.permFlags
                        log.debug "SUPPORTED FLAGS", permFlags
                        cb null

                # step 2a - set flags
                (cb) ->
                    flags = _.intersection newflags, permFlags
                    if flags.length is 0
                        oldpflags = _.intersection oldflags, permFlags
                        if oldpflags.length isnt 0
                            imap.delFlags firstuid, oldpflags, cb
                        else cb null
                    else
                        imap.setFlags firstuid, flags, cb

                # step 2b - set keywords
                (cb) ->
                    keywords = _.difference newflags, permFlags
                    if keywords.length is 0
                        oldkeywords = _.difference oldflags, permFlags
                        if oldkeywords.length isnt 0
                            imap.delKeywords firstuid, oldkeywords, cb
                        else cb null
                    else
                        imap.setKeywords firstuid, keywords, cb

                # step 3 - copy the message to all addTo
                (cb) ->
                    paths = boxOps.addTo.map (destID) ->
                        boxIndex[destID].path

                    imap.multicopy firstuid, paths, (err, uids) ->
                        return callback err if err
                        for i in [0..uids.length - 1] by 1
                            destID = boxOps.addTo[i]
                            newmailboxIDs[destID] = uids[i]
                        cb null
                # step 4 - remove the message from all removeFrom
                (cb) ->
                    #paths = [{path:xxx, uid:xxx},{path:xxx, uid:xxx}]
                    paths = boxOps.removeFrom.map (boxid) ->
                        boxIndex[boxid]
                    imap.multiremove paths, cb

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
    log.info "createFromImapMessage", box.label, uid

    # we store the box & account id
    mail.accountID = box.accountID
    mail.mailboxIDs = {}
    mail.mailboxIDs[box._id] = uid

    # we store normalized versions of subject & messageID for threading
    messageID = mail.headers['message-id']
    delete mail.messageId

    # reported bug : if a mail has two messageID, mailparser make it an array
    # and it crashes the server
    if messageID and messageID instanceof Array
        messageID = messageID[0]

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
    Message.findConversationID mail, (err, conversationID) ->
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

Message.findConversationID = (mail, callback) ->
    log.debug "findConversationID"

    # is reply or forward
    isReplyOrForward = mail.subject and mailutils.isReplyOrForward mail.subject

    # try to find by references
    references = mail.references or []
    references.concat mail.inReplyTo or []
    references = references.map mailutils.normalizeMessageID
        .filter (mid) -> mid # ignore unparsable messageID


    if references.length
        # find all messages in references
        keys = references.map (mid) -> [mail.accountID, 'mid', mid]
        Message.rawRequest 'dedupRequest', {keys}, (err, rows) ->
            return callback err if err
            log.debug '   found = ',rows?.length
            Message.pickConversationID rows, callback

    # no references, try to find by subject
    # @TODO : handle the unlikely case where we got a reply
    # before the original message
    else if mail.normSubject?.length > 3 and isReplyOrForward
        key = [mail.accountID, 'subject', mail.normSubject]
        Message.rawRequest 'dedupRequest', {key}, (err, rows) ->
            return callback err if err
            Message.pickConversationID rows, callback

    # give it a random uid
    else
        callback null, uuid.v4()




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
        return cb null if row.value is pickedConversationID
        Message.find row.id, (err, message) ->
            log.warn "Cant get message #{row.id}, ignoring" if err
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
        file.url = "message/#{raw.id}/attachments/#{file.generatedFileName}"

    if raw.html?
        attachments = raw.attachments or []
        raw.html = mailutils.sanitizeHTML raw.html, raw.id, attachments

    if not raw.text? and raw.html?
        raw.text = htmlToText.fromString raw.html,
            tables: true
            wordwrap: 80

    return raw

Message::moveToTrash = (account, callback) ->
    trashBoxID = account.trashMailbox
    mailboxes = Object.keys(@mailboxIDs)

    if trashBoxID in mailboxes
        # message is already in trash
        # @TODO : expunge ?
        callback null

    else
        # make a patch that remove from all boxes and add to trash
        patch = for boxid in mailboxes
            op: 'remove'
            path: "/mailboxIDs/#{boxid}"
        patch.push
            op: 'add'
            path: "/mailboxIDs/#{trashBoxID}"
            value: -1

        @applyPatchOperations patch, callback


Message::doASAP = (operation, callback) ->
    ImapPool.get(@accountID).doASAP operation, callback

Message.recoverChangedUID = (box, messageID, newUID, callback) ->
    log.debug "recoverChangedUID"
    Message.byMessageID box.accountID, messageID, (err, message) ->
        return callback err if err
        # no need to recover if the message doesnt exist
        return callback null unless message
        return callback null unless message.mailboxIDs[box.id]
        mailboxIDs = message.mailboxIDs
        mailboxIDs[box.id] = newUID
        message.updateAttributes {mailboxIDs}, callback

Message.removeAccountOrphans = ->
    Message.rawRequest
