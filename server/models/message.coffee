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
uuid = require 'uuid'
_ = require 'lodash'
log = require('../utils/logging')(prefix: 'models:message')
Promise = require 'bluebird'
Mailbox = require './mailbox'


MSGBYPAGE = 7
# Public: get messages in a box, sorted by Date
#
# mailboxID - {String} the mailbox's ID
# params - query's options
#
# Returns {Promise} for an array of {Message}
Message.getResultsAndCount = (mailboxID, params) ->
    {before, after, descending, sortField, flag} = params

    flag ?= null

    [before, after] = [after, before] if descending
    options =
        descending: descending
        startkey: [sortField, mailboxID, flag, before]
        endkey: [sortField, mailboxID, flag, after]
        reduce: true
        group_level: 2


    pCount = Message.rawRequestPromised 'byMailboxRequest', options

    # options for results
    delete options.group_level
    options.reduce = false
    options.include_docs = true
    options.limit =  MSGBYPAGE

    if params.resultsAfter
        options.startkey[3] = params.resultsAfter
        options.skip = 1

    pResults = Message.rawRequestPromised 'byMailboxRequest', options
    .map (row) -> new Message row.doc

    Promise.join pResults, pCount, (messages, count) ->
        return {messages, count: count[0]?.value or 0}

# Public: get the uids present in a box in cozy
#
# mailboxID - id of the mailbox to check
# min, max - get only UIDs between min & max
#
# Returns a {Promise} for an map of {uid: [couchdID, flags]}
Message.UIDsInRange = (mailboxID, min, max) ->
    result = {}
    Message.rawRequestPromised 'byMailboxRequest',
        startkey: ['uid', mailboxID, min]
        endkey: ['uid', mailboxID, max]
        inclusive_end: true
        reduce: false

    .map (row) ->
        uid = row.key[2]
        result[uid] = [row.id, row.value]

    .then -> return result

# Public: find a message by its message id
#
# accountID - id of the account to scan
# messageID - message-id to search, no need to normalize
#
# Returns a {Promise} for an array of {Message}
Message.byMessageId = (accountID, messageID) ->
    messageID = mailutils.normalizeMessageID messageID
    Message.rawRequestPromised 'dedupRequest',
        key: [accountID, 'mid', messageID]
        include_docs: true

    .then (rows) ->
        if data = rows[0]?.doc then new Message data

# Public: find messages by there conversation-id
#
# conversationID - id of the conversation to fetch
#
# Returns a {Promise} for an array of {Message}
Message.byConversationId = (conversationID) ->
    Message.rawRequestPromised 'byConversationId',
        key: conversationID
        include_docs: true

    .map (row) -> new Message row.doc


# Public: destroy a message without making a new JDB Model
#
# messageID - id of the message to destroy
# cb - {Function}(err) for task completion
#
# Returns {void}
Message.destroyByID = (messageID, cb) ->
    Message.adapter.destroy null, messageID, cb


# safeDestroy parameters (to be tweaked)
# loads 200 ids in memory at once
LIMIT_DESTROY = 200
# loads 30 messages in memory at once
LIMIT_UPDATE = 30
# send 5 request to the DS in parallel
CONCURRENT_DESTROY = 5

# Public: destroy all messages for an account
# play it safe by limiting number of messages in RAM
# and number of concurrent requests to the DS
# and allowing for the occasional DS failure
# @TODO : refactor this after a good night
# @TODO : stress test DS requestDestroy
#
# accountID - {String} id of the account
# retries - {Number} of DS failures we tolerate
#
# Returns a {Promise} for task completion
Message.safeDestroyByAccountID = (accountID, retries = 2) ->

    destroyOne = (row) ->
        Message.destroyByIDPromised(row.id)
        .delay 100 # let the DS breath

    # get LIMIT_DESTROY messages IDs in RAM
    Message.rawRequestPromised 'dedupRequest',
        limit: LIMIT_DESTROY
        startkey: [accountID]
        endkey: [accountID, {}]

    .map destroyOne, concurrency: CONCURRENT_DESTROY

    .then (results) ->
        # no more messages, we are done here
        return 'done' if results.length is 0

        # we are not done, loop again, resetting the retries
        Message.safeDestroyByAccountID accountID, 2

    , (err) ->
        # random DS failure
        throw err unless retries > 0
        # wait a few seconds to let DS & Couch restore
        Promise.delay 4000
        .then -> Message.safeDestroyByAccountID accountID, retries - 1


# Public: remove all messages from a mailbox
# play it safe by limiting number of messages in RAM
# and number of concurrent requests to the DS
# and allowing for the occasional DS failure
# @TODO : refactor this after a good night
# @TODO : stress test DS requestDestroy & use it instead
#
# mailboxID - {String} id of the mailbox
# retries - {Number} of DS failures we tolerate
#
# Returns a {Promise} for task completion
Message.safeRemoveAllFromBox = (mailboxID, retries = 2) ->



    removeOne = (row) ->
        new Message(row.doc).removeFromMailbox(id: mailboxID)

    log.info "REMOVING ALL MESSAGES FROM #{mailboxID}"
    Message.rawRequestPromised 'byMailboxRequest',
        limit: LIMIT_UPDATE
        startkey: ['uid', mailboxID, 0]
        endkey: ['uid', mailboxID, {}]
        include_docs: true
        reduce: false

    .tap (results) -> log.info "  LOAD #{results.length} MESSAGES"
    .map removeOne, concurrency: CONCURRENT_DESTROY
    .then (results) ->
        if results.length < LIMIT_UPDATE then return 'done'

        # we are not done, loop again, resetting the retries
        Message.safeRemoveAllFromBox mailboxID, 2

    , (err) ->
        log.warn "ERROR ON MESSAGE REMOVAL", err.stack
        # random DS failure
        throw err unless retries > 0
        # wait a few seconds to let DS & Couch restore
        Promise.delay 4000
        .then -> Message.safeRemoveAllFromBox mailboxID, retries - 1


# Public: add the message to a mailbox in the cozy
#
# box - {Mailbox} to add this message to
# uid - {Number} uid of the message in the mailbox
#
# Returns {Promise} for the updated {Message}
Message::addToMailbox = (box, uid) ->
    log.info "MAIL #{box.path}:#{uid} ADDED TO BOX"
    @mailboxIDs[box.id] = uid
    @savePromised()

# Public: remove a message from a mailbox in the cozy
# if the message becomes an orphan, we destroy it
#
# box - {Mailbox} to remove this message from
# noDestroy - {Boolean} dont destroy orphan messages
#
# Returns {Promise} for the updated {Message}
Message::removeFromMailbox = (box, noDestroy = false) ->
    mailboxIDs = @mailboxIDs
    delete mailboxIDs[box.id]

    isOrphan = Object.keys(mailboxIDs).length is 0
    log.info "REMOVING #{@id}, NOW ORPHAN = ", isOrphan

    if isOrphan and not noDestroy then @destroyPromised()
    else @updateAttributesPromised {mailboxIDs}

Message.removeFromMailbox = (id, box) ->
    Message.findPromised id
    .then (message) -> message.removeFromMailbox box

Message.applyFlagsChanges = (id, flags) ->
    Message.findPromised id
    .then (message) -> message.updateAttributesPromised flags: flags


# Public: apply a json-patch to the message in both cozy & imap
#
# patch: {Object} the json-patch
#
# Returns {Promise} for the updated {Message}
Message::applyPatchOperations = (patch) ->

    # scan the patch
    boxOps = {addTo: [], removeFrom: []}
    for operation in patch when operation.path.indexOf('/mailboxIDs/') is 0
        boxid = operation.path.substring 12
        if operation.op is 'add'
            boxOps.addTo.push boxid
        else if operation.op is 'remove'
            boxOps.removeFrom.push boxid
        else throw new Error 'modifying UID is not possible'


    flagOps = {add: [], remove: []}
    for operation in patch when operation.path.indexOf('/flags/') is 0
        index = parseInt operation.path.substring 7
        if operation.op is 'add'
            flagOps.add.push operation.value

        else if operation.op is 'remove'
            flagOps.remove.push @flags[index]

        else if operation.op is 'replace'
            flagOps.remove.push @flags[index]
            flagOps.add.push operation.value

    # applyMessageChanges will perform operation in IMAP
    # and store results in the message (this)
    # wee need to save afterward
    @imap_applyChanges flagOps, boxOps
    .then => @savePromised()



# create a message from a raw imap message
# handle normalization of message ids & subjects
# handle attachments
Message.createFromImapMessage = (mail, box, uid) ->

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
    Promise.resolve mail['x-gm-thrid'] or
        Message.findConversationIdByMessageIds(mail) or
        Message.findConversationIdBySubject(mail)

    # once we have it, save it with the mail
    .then (conversationID)->
        mail.conversationID = conversationID
        Message.createPromised mail

    # After document creation, we store the attachments as binaries
    .then (jdbMessage) ->
        Promise.serie attachments, (att) ->
            # WEIRDFIX#1 - some attachments name are broken
            # WEIRDFIX#2 - some attachments have no buffer
            # att.name = att.name.replace "\ufffd", ""
            # attachBinary need a path attributes
            att.buffer ?= new Buffer 0
            att.buffer.path = encodeURI att.name
            jdbMessage.attachBinaryPromised att.buffer,
                name: encodeURI att.name

# Attempt to find the message conversationID from its references
# return null if there is no usable references
Message.findConversationIdByMessageIds = (mail) ->
    references = mail.references or []
    references.concat mail.inReplyTo or []
    references = references.map mailutils.normalizeMessageID
        .filter (mid) -> mid # ignore unparsable messageID

    return null unless references.length

    # find all messages in references
    Message.rawRequestPromised 'dedupRequest',
        keys: references.map (id) -> [mail.accountID, 'mid', id]

    # and get a conversationID from them
    .then Message.pickConversationID

# Attempt to find the message conversationID from its subject
# return null if the subject is too short for matching
Message.findConversationIdBySubject = (mail) ->

    # do not merge thread by subject if the subject is only a few letters
    return null unless mail.normSubject?.length > 3

    # find all messages with same subject
    Message.rawRequestPromised 'dedupRequest',
        key: [mail.accountID, 'subject', mail.normSubject]

    # and get a conversationID from them
    .then Message.pickConversationID


# we have a number of rows key=messageID, value=ThrID
# that we assume are actually one thread
# we pick one thrId (most used)
# we update the messages to use it
# and return it
Message.pickConversationID = (rows) ->
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
    Promise.serie rows, (row) ->
        Message.findPromised row.id
        .then (message) ->
            if message.conversationID isnt pickedConversationID
                message.updateAttributesPromised change

    # we pass it to the next function
    .return pickedConversationID

require './message_imap'
Promise.promisifyAll Message, suffix: 'Promised'
Promise.promisifyAll Message::, suffix: 'Promised'
