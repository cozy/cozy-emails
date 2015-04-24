cozydb = require 'cozydb'

# Public: a mail address, used in {Message} schema
class MailAdress extends cozydb.Model
    @schema:
        name: String
        address: String

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
        attachments    : cozydb.NoSchema
        alternatives   : cozydb.NoSchema # for calendar content

    # Public: recover from when a box change its UIDVALIDITY.
    # Find the message with {.byMessageID} and change its UID for the box.
    #
    # box - {Mailbox} the mailbox
    # messageID - {String} the message message-id
    # newUID - {String} the message message-id
    #
    # Returns (callback) {Message} the updated message
    @recoverChangedUID: (box, messageID, newUID, callback) ->
        log.debug "recoverChangedUID"
        Message.byMessageID box.accountID, messageID, (err, message) ->
            return callback err if err
            # no need to recover if the message doesnt exist
            return callback null unless message
            return callback null unless message.mailboxIDs[box.id]
            mailboxIDs = message.mailboxIDs
            mailboxIDs[box.id] = newUID
            message.updateAttributes {mailboxIDs}, callback

    # Public: move a message to trash from its id.
    # Find the message then use {::moveToTrash}.
    #
    # account - {Account} this message belongs to
    # id - {String} the message id
    #
    # Returns (callback) {Message} the updated message
    @moveToTrash: (account, id, callback) ->
        Message.find id, (err, message) ->
            if err
                callback err
            else if not message
                callback new NotFound "Message##{id}"
            else if account.id isnt message.accountID
                callback new BadRequest """
                    Message##{id} not in account #{account.id}"""
            else
                message.moveToTrash account, callback

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

    # Public: get the uids present in a box in cozy
    #
    # mailboxID - id of the mailbox to check
    # min - get only UIDs between min & max
    # max - get only UIDs between min & max
    #
    # Returns (callback) an {Object} with couchdb ids as keys and
    #                    flags as values
    @UIDsInRange: (mailboxID, min, max, callback) ->
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
    # @TODO : stress test DS requestDestroy
    #
    # accountID - {String} id of the account
    # retries - {Number} of DS failures we tolerate
    #
    # Returns (callback) at completion
    @safeDestroyByAccountID: (accountID, callback, retries = 2) ->
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
                        Message.safeDestroyByAccountID accountID, callback, \
                            retries - 1
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
    @safeRemoveAllFromBox: (mailboxID, callback, retries = 2) ->
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
                new Message(row.doc).removeFromMailbox(id: mailboxID, true, cb)

            , (err) ->

                if err and retries > 0
                    log.warn "DS has crashed ? waiting 4s before try again", err
                    setTimeout ->
                        Message.safeRemoveAllFromBox mailboxID, callback, \
                            retries - 1
                    , 4000

                else if err
                    return callback err

                else
                    # we are not done, loop again, resetting the retries
                    Message.safeRemoveAllFromBox mailboxID, callback, 2

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

    # Public: set new flags on a message.
    #
    # id - {String} id of the message
    # flags - {Array} of {String} the flags ot set
    #
    # Returns (callback) the updated {Message}
    @applyFlagsChanges: (id, flags, callback) ->
        log.debug "applyFlagsChanges", id, flags
        Message.updateAttributes id, {flags}, callback

    # Public: remove messages from mailboxes that doesnt exist
    # anymore.
    #
    # existings - {Array} of {String} ids of existings mailboxes
    #
    # Returns (callback) at completion
    @removeOrphans: (existings, callback) ->
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
                        if err
                            log.error """
                                failed to remove message""", row.id, err
                        cb null

            , (err) ->
                options =
                    key: ['nobox']
                    reduce: false
                Message.rawRequest 'byMailboxRequest', options, (err, rows) ->
                    return callback err if err
                    async.eachSeries rows, (row, cb) ->
                        Message.destroy row.id, (err) ->
                            log.error 'fail to destroy orphan', err if err
                            cb null
                    , callback


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

    # Public: get messages in a box depending on the query params
    #
    # mailboxID - {String} the mailbox's ID
    # params - query's options
    #
    # Returns (callback) an {Array} of {Message}
    @getResults: (mailboxID, params, callback) ->
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
    # Returns (callback) {Message} the updated Message
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
                existing.markTwin box, callback
            else
                log.debug "        fetch"
                box.imap_fetchOneMail uid, callback


    # Public: mark a message has having a twin (2 messages with same MID,
    # but different UID) in the same box so they can be smartly handled at
    # deletion.
    #
    # box - {Mailbox} the mailbox
    #
    # Returns (callback) {Number} of messages in the search
    markTwin: (box, callback) ->
        hasTwin = @hasTwin or []
        return callback null unless box.id in hasTwin
        hasTwin.push box.id
        @updateAttributes changes: {hasTwin}, callback


    # Public: add the message to a mailbox in the cozy
    #
    # box - {Mailbox} to add this message to
    # uid - {Number} uid of the message in the mailbox
    # callback - Function(err, {Message} updated)
    #
    # Returns void
    addToMailbox: (box, uid, callback) ->
        log.info "MAIL #{box.path}:#{uid} ADDED TO BOX"
        mailboxIDs = @mailboxIDs or {}
        mailboxIDs[box.id] = uid
        @updateAttributes {mailboxIDs}, callback

    # Public: helper to check if a message is in a box
    #
    # box - {Mailbox} the mailbox
    #
    # Returns {Boolean} whether this message is in the box or not
    isInMailbox: (box) ->
        return @mailboxIDs[box.id]?

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

        mailboxIDs = @mailboxIDs
        delete mailboxIDs[box.id]

        isOrphan = Object.keys(mailboxIDs).length is 0
        log.debug "REMOVING #{@id}, NOW ORPHAN = ", isOrphan

        if isOrphan and not noDestroy then @destroy callback
        else @updateAttributes {mailboxIDs}, callback


    # Public: apply a json-patch to the message in both cozy & imap
    #
    # patch - {Object} the json-patch
    # callback - Function(err, {Message} updated)
    #
    # Returns void
    applyPatchOperations: (patch, callback) ->
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
            else return callback new Error """
                modifying UID is not possible, bad operation #{operation.op}
            """

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
        @imap_applyChanges newflags, newmailboxIDs, boxOps, (err, changes) =>
            return callback err if err
            @updateAttributes changes, callback

    # Public: apply changes of flags and boxes to a message in imap, properly
    # set flags and keywords, then copy and remove the message as appropriate.
    #
    # newflags - {Array} of {String} flags after the change
    # newmailboxIDs - {Array} of {String} flags after the change
    # callback - Function(err, {Message} updated)
    #
    # Returns void
    imap_applyChanges: (newflags, newmailboxIDs, boxOps, callback) ->
        log.debug ".applyChanges", newflags, newmailboxIDs

        oldflags = @flags

        Mailbox.getBoxesIndexedByID @accountID, (err, boxIndex) =>

            return callback err if err
            for boxID, box of boxIndex
                box.uid = @mailboxIDs[boxID]

            # ERROR CASES
            for boxid in boxOps.addTo when not boxIndex[boxid]
                return callback new Error "the box ID=#{boxid} doesn't exists"

            shouldIgnoreAfterUpdate = Object.keys(newmailboxIDs)
                                            .map (id) -> boxIndex[id]
                                            .some (box) -> box.ignoreInCount()


            firstboxid = Object.keys(@mailboxIDs)[0]
            firstuid = @mailboxIDs[firstboxid]

            log.debug "CHANGING FLAGS OF ", firstboxid, firstuid, @mailboxIDs

            @doASAP (imap, releaseImap) ->

                permFlags = null

                async.series [

                    # step 1 - open one box at random
                    (cb) ->
                        path = boxIndex[firstboxid].path
                        imap.openBox path, (err, imapBox) ->
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
                    ignoreInCount: shouldIgnoreAfterUpdate
                    mailboxIDs: newmailboxIDs
                    flags: newflags


    # Public: Create a message from a raw imap message.
    # Handle attachments and normalization of message ids and subjects.
    #
    # mail - an node-imap mail {Object}
    # box - {Mailbox} to create the message in
    # uid - {Number} UID of the message in the box
    #
    # Returns (callback) at completion
    Message.createFromImapMessage = (mail, box, uid, callback) ->
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
            # attachBinary need a path attributes
            att.buffer ?= new Buffer 0
            att.buffer.path = encodeURI att.name
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
            raw.text = htmlToText.fromString raw.html,
                tables: true
                wordwrap: 80

        return raw


    # Public: move this message to the trash Mailbox
    #
    # account - the {Account} this message is from
    #
    # Returns (callback) {Message} the updated message
    moveToTrash: (account, callback) ->
        trashBoxID = account.trashMailbox
        mailboxes = Object.keys(@mailboxIDs)

        unless trashBoxID
            callback new AccountConfigError 'trashMailbox'

        else if trashBoxID in mailboxes
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


    # Public: wrap an async function (the operation) to get a connection from
    # the pool before performing it and release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAP: (operation, callback) ->
        ImapPool.get(@accountID).doASAP operation, callback




module.exports = Message

mailutils = require '../utils/jwz_tools'
CONSTANTS = require '../utils/constants'
{MSGBYPAGE, LIMIT_DESTROY, LIMIT_UPDATE, CONCURRENT_DESTROY} = CONSTANTS
{NotFound, BadRequest, AccountConfigError} = require '../utils/errors'
uuid = require 'uuid'
_ = require 'lodash'
async = require 'async'
log = require('../utils/logging')(prefix: 'models:message')
Mailbox = require './mailbox'
ImapPool = require '../imap/pool'
htmlToText  = require 'html-to-text'

require('../utils/socket_handler').wrapModel Message, 'message'



