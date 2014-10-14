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
    flags: (x) -> x          # array of message flags (Seen, Flagged, Draft)

mailutils = require '../utils/jwz_tools'
uuid = require 'uuid'
ImapProcess = require '../processes/imap_processes'
Promise = require 'bluebird'
Mailbox = require './mailbox'
Compiler    = require 'nodemailer/src/compiler'

# Public: get messages in a box, sorted by Date
#
# mailboxID - {String} the mailbox's ID
# params - query's options
#    :numByPage - number of message in one page
#    :numPage - number of the page we want
#
# Returns {Promise} for an array of {Message}
Message.getByMailboxAndDate = (mailboxID, params) ->
    options =
        startkey: [mailboxID, {}]
        endkey: [mailboxID]
        include_docs: true
        descending: true
        reduce: false

    if params
        options.limit = params.numByPage if params.numByPage
        options.skip = params.numByPage * params.numPage if params.numPage

    Message.rawRequestPromised 'byMailboxAndDate', options
    .map (row) -> new Message(row.doc)

# Public: get the number of messages in a box
#
# mailboxID - {String} the mailbox's ID
#
# Returns {Promise} for the count
Message.countByMailbox = (mailboxID) ->
    Message.rawRequestPromised 'byMailboxAndDate',
        startkey: [mailboxID]
        endkey: [mailboxID, {}]
        reduce: true
        group_level: 1 # group by mailboxID

    .then (result) -> result[0]?.value or 0

# Public: get the number of unread messages in a box
#
# mailboxID - {String} the mailbox's ID
#
# Returns {Promise} for the count
Message.countReadByMailbox = (mailboxID) ->
    Message.rawRequestPromised 'byMailboxAndFlag',
        key: [mailboxID, '\\Seen']
        reduce: true
        group_level: 1

    .then (result) -> result[0]?.value or 0

# Public: get the uids present in a box in coz
#
# mailboxID - id of the mailbox to check
#
# Returns a {Promise} for an array of [couchdID, messageUID]
Message.getUIDs = (mailboxID) ->
    Message.rawRequestPromised 'byMailboxAndDate',
        startkey: [mailboxID]
        endkey: [mailboxID, {}]
        reduce: false

    .map (row) -> [row.id, row.value]

# Public: find a message by its message id
#
# accountID - id of the account to scan
# messageID - message-id to search, no need to normalize
#
# Returns a {Promise} for an array of {Message}
Message.byMessageId = (accountID, messageID) ->
    messageID = mailutils.normalizeMessageID messageID
    Message.rawRequestPromised 'byMessageId',
        key: [accountID, messageID]
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

    destroyOne = (row) -> Message.destroyByIDPromised row.id

    # get LIMIT_DESTROY messages IDs in RAM
    Message.rawRequestPromised 'treemap',
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

    removeOne = (message) -> message.removeFromMailbox(id: mailboxID)

    Message.getByMailboxAndDate mailboxID,
        numByPage: 30
        numPage: 0

    .map removeOne, concurrency: CONCURRENT_DESTROY


    .then (results) ->
        if results.length is 0 then return 'done'

        # we are not done, loop again, resetting the retries
        Message.safeRemoveAllFromBox mailboxID, 2

    , (err) ->
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
    delete @mailboxIDs[box.id]
    if noDestroy or Object.keys(@mailboxIDs).length > 0 then @savePromised()
    else @destroyPromised()


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

    # applyMessageChanges will perform operation on the server
    # and store results in the message (this)
    # wee need to save afterward
    ImapProcess.applyMessageChanges this, flagOps, boxOps
    .then => @savePromised()

# Public: move a message to trash
# @DEADCODE (done in client now)
#
# Returns a {Promise} for the updated {Message}
Message::moveToTrash = ->
    Account.findPromised @accountID
    .then (account) =>
        trashID = account.trashMailbox
        throw new WrongConfigError 'need define trash' unless trashID

        # build a patch that remove from all mailboxes and add to trash
        patch = Object.keys @mailboxIDs
        .filter (boxid) -> boxid isnt trashID
        .map (boxid) -> op: 'remove', path: "/mailboxIDs/#{boxid}"

        patch.push op: 'add', path: "/mailboxIDs/#{trashID}"

        @applyPatchOperations patch


Message.toRawMessage = (message, callback) ->
    mailbuilder = new Compiler(message).compile()
    return mailbuilder.build callback

# Public: create a message and store it on the imap server
#
# message - {Object} the message attributes
# boxtypes - {String} one of the account specialuse attributes
# uid -
#
# Returns a {Promise} for the created {Message}
Message.saveOnImapServer = (message, boxtype, uid) ->
    Account.findPromised message.accountID
    .then (account) =>
        boxID = account[boxtype]
        throw new WrongConfigError 'wrong boxtype' unless boxid

        Mailbox.findPromised boxID
        .then (box) ->
            ImapProcess.createMail account, box, message
        .then (uid) ->
            message.mailboxIDs[box.id] = uid
            Message.createPromised message



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
    Message.rawRequestPromised 'byMessageId',
        keys: references.map (id) -> [mail.accountID, id]

    # and get a conversationID from them
    .then Message.pickConversationID

# Attempt to find the message conversationID from its subject
# return null if the subject is too short for matching
Message.findConversationIdBySubject = (mail) ->

    # do not merge thread by subject if the subject is only a few letters
    return null unless mail.normSubject?.length > 3

    # find all messages with same subject
    Message.rawRequestPromised 'byNormSubject',
        key: [mail.accountID, mail.normSubject]

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


Promise.promisifyAll Message, suffix: 'Promised'
Promise.promisifyAll Message::, suffix: 'Promised'
