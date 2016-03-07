cozydb = require 'cozydb'

# Public: a mail address, used in {Message} schema
class MailAdress extends cozydb.Model
    @schema:
        name: String
        address: String


class MailAttachment extends cozydb.Model
    @schema: cozydb.NoSchema


# Public: Message
module.exports = class Message extends cozydb.CozyModel
    @docType: 'Message'
    @schema:
        accountID      : String          # account this message belongs to
        messageID      : String          # normalized message-id (no <"">)
        normSubject    : String          # normalized subject (no Re: ...)
        conversationID : String          # all message in thread have same
                                         # conversationID
        mailboxIDs     : cozydb.NoSchema # mailboxes as an hash
                                         # {boxID: uid, boxID2 : uid2}
        hasTwin        : [String]        # [String] mailboxIDs where this
                                         # message has twin
        twinMailboxIDs : cozydb.NoSchema # mailboxes as an hash of array
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
        ignoreInCount  : Boolean         # whether or not to count this message
                                         # in account values
        binary         : cozydb.NoSchema
        attachments    : [MailAttachment]
        alternatives   : cozydb.NoSchema # for calendar content

    # Public: fetch a list of message
    #
    # ids - {Array} of {String} message ids
    #
    # Returns (callback) {Array} of {Message} the fetched messages in same order
    @findMultiple: (ids, callback) ->
        async.mapSeries ids, (id, cb) ->
            Message.find id, cb
        , callback

    # Public: from a list of messages, choses the conversation ID
    # Take a list of messageid -> conversationID, pick the most used
    # and updates all messages to have the same.
    #
    # rows - [{Object}] key=messageID, value=conversationID
    #
    # Returns (callback) {String} the chosen conversation ID
    @pickConversationID: (rows, callback) ->
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

    # Public: get a message conversation ID.
    # Select the method if the message has references or by subject,
    # the uses {.pickConversationID} to unify and chose the conversationID
    #
    # mail - {Object} the raw node-imap mail
    #
    # Returns (callback) {String} the chosen conversation ID
    @findConversationID: (mail, callback) ->
        log.debug "findConversationID"

        # is reply or forward
        subject = mail.subject
        isReplyOrForward = subject and mailutils.isReplyOrForward subject

        # try to find by references
        references = mail.references or []
        references.concat mail.inReplyTo or []
        references = references.map mailutils.normalizeMessageID
            .filter (mid) -> mid # ignore unparsable messageID


        log.debug "findConversationID", references, mail.normSubject,
            isReplyOrForward
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
                log.debug "found similar", rows.length
                Message.pickConversationID rows, callback

        # give it a random uid
        else
            callback null, uuid.v4()

    # Public: get messages in cozy by their uids
    #
    # mailboxID - {String} id of the mailbox to check
    #
    # Returns (callback) an {Array} of {String} uids in the cozy
    @UIDsInCozy: (mailboxID, callback) ->


    # Public: find a message by its message id
    #
    # accountID - id of the account to scan
    # messageID - message-id to search, no need to normalize
    #
    # Returns (callback) {Message} the first message with this Message-ID
    @byMessageID: (accountID, messageID, callback) ->
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
    # Returns (callback) an {Object} with conversationsIDs as keys and
    #                    counts as values
    @getConversationLengths: (conversationIDs, callback) ->

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
    # Returns (callback) an {Array} of {Message}
    @byConversationID: (conversationID, callback) ->
        Message.byConversationIDs [conversationID], callback

    # Public: find messages by multiple conversation-id
    #
    # conversationIDs - {Array} of {String} id of the conversations to fetch
    #
    # Returns (callback) an {Array} of {Message}
    @byConversationIDs: (conversationIDs, callback) ->
        Message.rawRequest 'byConversationID',
            keys: conversationIDs
            reduce: false
            include_docs: true

        , (err, rows) ->
            return callback err if err
            messages = rows.map (row) ->
                try
                    new Message row.doc
                catch err
                    log.error "Wrong message", err, row.doc
                    return null
            callback null, messages

    # Public: remove a message from a mailbox.
    # Uses {::removeFromMailbox}
    #
    # id - {String} id of the message
    # box - {Mailbox} mailbox to remove From
    #
    # Returns (callback) the updated {Message}
    @removeFromMailbox: (id, box, callback) ->
        log.debug "removeFromMailbox", id, box.label
        Message.find id, (err, message) ->
            return callback err if err
            return callback new NotFound "Message #{id}" unless message
            message.removeFromMailbox box, false, callback

    # Public: get messages in a box depending on the query params
    #
    # mailboxID - {String} the mailbox's ID
    # params - query's options
    # callback - Function(err, [{Message}])
    #
    # Returns (callback) an {Object} with properties
    #           :messages - the result of {.getResults}
    #           :count - the result of {.getCount}
    #           :conversationLengths - length of conversations in the result
    @getResultsAndCount: (mailboxID, params, callback) ->
        params.flag ?= null
        if params.descending
            [params.before, params.after] = [params.after, params.before]

        async.parallel [
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

    # Public: get messages in a box depending on the query params
    #
    # mailboxID - {String} the mailbox's ID
    # params - query's options
    #
    # Returns (callback) an {Array} of {Message}
    @getResults: (mailboxID, params, callback) ->
        {before, after, descending, sortField, flag} = params

        skip = 0


        if sortField is 'from' or sortField is 'dest'
            if params.resultsAfter?
                skip = params.resultsAfter
            startkey = [sortField, mailboxID, flag, before, null]
            endkey   = [sortField, mailboxID, flag, after, null]
        else
            if params.resultsAfter?
                startkey = [sortField, mailboxID, flag, params.resultsAfter]
            else
                startkey = [sortField, mailboxID, flag, before]
            endkey = [sortField, mailboxID, flag, after]

        requestOptions =
            descending: descending
            startkey: startkey
            endkey: endkey
            reduce: false
            skip: skip
            include_docs: true
            limit: MSGBYPAGE

        Message.rawRequest 'byMailboxRequest', requestOptions
        , (err, rows) ->
            return callback err if err
            callback null, rows.map (row) -> new Message row.doc

    # Public: get number of messages in a box, depending on the query params
    #
    # mailboxID - {String} the mailbox's ID
    # params - query's options
    #
    # Returns (callback) {Number} of messages in the search
    @getCount: (mailboxID, params, callback) ->
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

    # Public: create or update a message
    #
    # message - {Message} the mailbox's ID
    #
    # Returns (callback) {Message} the updated / created message
    @updateOrCreate: (message, callback) ->
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

    # Public: check if a message is already in cozy by its mid.
    # If it is update it with {::markTwin} or {::addToMailbox}, else fetch it.
    #
    # box - {Mailbox} the box to create this message in
    # msg - {Object} the msg
    #           :mid - {String} Message-id
    #           :uid - {String} the uid
    # ignoreInCount - {Boolean} mark this message as ignored in counts.
    #
    # Returns (callback) {Object} information about what happened
    #           :shouldNotif - {Boolean} whether a new unread message was added
    #           :actuallyAdded - {Boolean} whether a message was actually added
    @fetchOrUpdate: (box, msg, callback) ->
        {mid, uid} = msg
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
                Message.fetchOneMail box, uid, callback

    @fetchOneMail: (box, uid, callback) ->
        box.doLaterWithBox (imap, imapbox, cb) ->
            imap.fetchOneMail uid, cb
        , (err, mail) ->
            return callback err if err
            shouldNotif = '\\Seen' in (mail.flags or [])
            Message.createFromImapMessage mail, box, uid, (err) ->
                return callback err if err
                callback null, {shouldNotif: shouldNotif, actuallyAdded: true}

    # Public: mark a message has having a twin (2 messages with same MID,
    # but different UID) in the same box so they can be smartly handled at
    # deletion.
    #
    # box - {Mailbox} the mailbox
    #
    # Returns (callback) {Object} information about what happened
    #           :shouldNotif - {Boolean} always false
    #           :actuallyAdded - {Boolean} wheter a message was actually added
    markTwin: (box, uid, callback) ->
        hasTwin = @hasTwin or []
        twinMailboxIDs = @twinMailboxIDs or {}
        twinMailboxIDsBox = twinMailboxIDs[box.id] or []
        if box.id in hasTwin and uid in twinMailboxIDsBox
            # already noted
            callback null, {shouldNotif: false, actuallyAdded: false}

        else if box.id in hasTwin
            # the message was marked as twin before the introduction of
            # twinMailboxIDs
            twinMailboxIDs[box.id] ?= []
            twinMailboxIDs[box.id].push uid
            @updateAttributes {twinMailboxIDs}, (err) ->
                callback err, {shouldNotif: false, actuallyAdded: true}


        else
            hasTwin.push box.id
            twinMailboxIDs[box.id] ?= []
            twinMailboxIDs[box.id].push uid
            @updateAttributes {hasTwin, twinMailboxIDs}, (err) ->
                callback err, {shouldNotif: false, actuallyAdded: true}


    # Public: add the message to a mailbox in the cozy
    #
    # box - {Mailbox} to add this message to
    # uid - {Number} uid of the message in the mailbox
    # callback - Function(err, {Message} updated)
    #
    # Returns (callback) {Object} information about what happened
    #           :shouldNotif - {Boolean} always false
    #           :actuallyAdded - {Boolean} always true
    addToMailbox: (box, uid, callback) ->
        log.info "MAIL #{box.path}:#{uid} ADDED TO BOX"
        mailboxIDs = {}
        mailboxIDs[key] = value for key, value of @mailboxIDs or {}
        mailboxIDs[box.id] = uid
        changes = {mailboxIDs}
        changes.ignoreInCount = box.ignoreInCount()
        @updateAttributes changes, (err) ->
            callback err, {shouldNotif: false, actuallyAdded: true}

    # Public: helper to check if a message is in a box
    #
    # box - {Mailbox} the mailbox
    #
    # Returns {Boolean} whether this message is in the box or not
    isInMailbox: (box) ->
        return @mailboxIDs[box.id]? and @mailboxIDs[box.id] isnt -1

    # Public: remove a message from a mailbox in the cozy
    # if the message becomes an orphan, we destroy it
    #
    # box - {Mailbox} to remove this message from
    # noDestroy - {Boolean} dont destroy orphan messages
    #
    # Returns (callback) the updated {Message}
    removeFromMailbox: (box, noDestroy = false, callback) ->
        log.debug ".removeFromMailbox", @id, box.label
        callback = noDestroy unless callback

        changes = {}
        changed = false

        if box.id of (@mailboxIDs or {})
            changes.mailboxIDs = _.omit @mailboxIDs, box.id
            changed = true

        if box.id of (@twinMailboxIDs or {})
            changes.twinMailboxIDs = _.omit @twinMailboxIDs, box.id
            changed = true

        if changed
            boxes = Object.keys(changes.mailboxIDs or @mailboxIDs)
            isOrphan = boxes.length is 0
            log.debug "REMOVING #{@id}, NOW ORPHAN = ", isOrphan

            if isOrphan and not noDestroy then @destroy callback
            else @updateAttributes changes, callback

        else
            setImmediate callback


    # Public: Create a message from a raw imap message.
    # Handle attachments and normalization of message ids and subjects.
    #
    # mail - an node-imap mail {Object}
    # box - {Mailbox} to create the message in
    # uid - {Number} UID of the message in the box
    #
    # Returns (callback) at completion
    @createFromImapMessage: (mail, box, uid, callback) ->
        log.info "createFromImapMessage", box.label, uid
        log.debug 'flags = ', mail.flags

        # we store the box & account id
        mail.accountID = box.accountID
        mail.ignoreInCount = box.ignoreInCount()
        mail.mailboxIDs = {}
        mail.mailboxIDs[box._id] = uid

        # we store normalized versions of subject & messageID for threading
        messageID = mail.headers['message-id']
        delete mail.messageId

        # reported bug : if a mail has two messageID, mailparser make it
        # an array and it crashes the server
        if messageID and messageID instanceof Array
            messageID = messageID[0]

        if messageID
            mail.messageID = mailutils.normalizeMessageID messageID

        if mail.subject
            mail.normSubject = mailutils.normalizeSubject mail.subject

        # @TODO, find and parse from mail.headers ?
        mail.replyTo ?= []
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

    # Public: Store the node-imap attachment to the cozy message
    #
    # attachments - an {Array} of {Object}(name, buffer)
    #
    # Returns (callback) at completion
    storeAttachments: (attachments, callback) ->
        log.debug "storeAttachments"
        async.eachSeries attachments, (att, cb) =>
            # WEIRDFIX#1 - some attachments name are broken
            # WEIRDFIX#2 - some attachments have no buffer
            # att.name = att.name.replace "\ufffd", ""
            att.buffer ?= new Buffer 0
            @attachBinary att.buffer, name: att.name, cb

        , callback

    # Public: get this message formatted for the client.
    # Generate html & text appropriately and give each
    # attachment an URL.
    #
    # Returns (callback) {Object} the formatted message
    toClientObject: ->
        # log.debug "toClientObject"
        raw = @toObject()

        raw.attachments?.forEach (file) ->
            encodedFileName = encodeURIComponent file.generatedFileName
            file.url = "message/#{raw.id}/attachments/#{encodedFileName}"

        if raw.html?
            attachments = raw.attachments or []
            raw.html = mailutils.sanitizeHTML raw.html, raw.id, attachments

        if not raw.text? and raw.html?
            try
                raw.text = htmlToText.fromString raw.html,
                    tables: true
                    wordwrap: 80
            catch err
                log.error "Error converting HTML to text", err, raw.html

        return raw


    @doGroupedByBox: (messages, iterator, done) ->
        return done null if messages.length is 0

        accountID = messages[0].accountID
        messagesByBoxID = {}
        for message in messages
            for boxID, uid of message.mailboxIDs
                messagesByBoxID[boxID] ?= []
                messagesByBoxID[boxID].push message

        state = {}
        async.eachSeries Object.keys(messagesByBoxID), (boxID, next) ->
            state.box = ramStore.getMailbox boxID
            state.messagesInBox = messagesByBoxID[boxID]
            iterator2 = (imap, imapBox, releaseImap) ->
                state.imapBox = imapBox
                state.uids = state.messagesInBox.map (msg) ->
                    msg.mailboxIDs[state.box.id]
                iterator imap, state, releaseImap

            pool = ramStore.getImapPool(messages[0])
            if not pool
                return done new BadRequest "Pool isn't defined"
            pool.doASAPWithBox state.box, iterator2, next
        , done

    @batchAddFlag: (messages, flag, callback) ->

        # dont add flag twice
        messages = messages.filter (msg) -> flag not in msg.flags

        Message.doGroupedByBox messages, (imap, state, next) ->
            imap.addFlags state.uids, flag, next
        , (err) ->
            return callback err if err
            async.mapSeries messages, (message, next) ->
                newflags = message.flags.concat flag
                message.updateAttributes flags: newflags, (err) ->
                    next err, message
            , callback

    @batchRemoveFlag: (messages, flag, callback) ->

        # dont remove flag if it wasnt
        messages = messages.filter (msg) -> flag in msg.flags

        Message.doGroupedByBox messages, (imap, state, next) ->
            imap.delFlags state.uids, flag, next
        , (err) ->
            return callback err if err
            async.mapSeries messages, (message, next) ->
                newflags = _.without message.flags, flag
                message.updateAttributes flags: newflags, (err) ->
                    next err, message
            , callback

    cloneMailboxIDs: ->
        out = {}
        out[boxID] = uid for boxID, uid of @mailboxIDs
        return out

    # Public: wether or not this message
    # is a draft. Consider a message a draft if it is in Draftbox or has
    # the \\Draft flag
    #
    # Returns {Bollean} is this message a draft ?
    isDraft: (draftBoxID) ->
        @mailboxIDs[draftBoxID]? or '\\Draft' in @flags


module.exports = Message
mailutils = require '../utils/jwz_tools'
CONSTANTS = require '../utils/constants'
{MSGBYPAGE, LIMIT_DESTROY, CONCURRENT_DESTROY} = CONSTANTS
{NotFound, BadRequest, AccountConfigError} = require '../utils/errors'
uuid = require 'uuid'
_ = require 'lodash'
async = require 'async'
log = require('../utils/logging')(prefix: 'models:message')
htmlToText  = require 'html-to-text'
require('./model-events').wrapModel Message
ramStore = require './store_account_and_boxes'
