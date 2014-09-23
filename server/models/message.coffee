americano = require 'americano-cozy'
mailutils = require '../utils/jwz_tools'
GUID = require 'guid'
Promise = require 'bluebird'

module.exports = Message = americano.getModel 'Message',

    accountID: String        # account this message belongs to
    messageID: String        # normalized message-id (no <"">)
    normSubject: String      # normalized subject (no Re: ...)
    conversationID: String   # all message in thread have same conversationID
    mailboxIDs: (x) -> x     # mailboxes where this message appears
                             # as an hash {boxID:uid, boxID2:uid2}
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
    attachments: (x) -> x    # array of message attachments objects
                                # {contentType, fileName, generatedFileName,
                                # contentDisposition, contentId,
                                # transferEncoding, length, checksum}
    flags: (x) -> x          # array of message flags (Seen, Flagged, Draft)


# return a promise for an Array of Message object
# params : numByPage & numPage
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

# count number of messages in a box
# @TODO: also count read/unread messages ?
Message.countByMailbox = (mailboxID) ->
    Message.rawRequestPromised 'byMailboxAndDate',
        startkey: [mailboxID]
        endkey: [mailboxID, {}]
        reduce: true
        group_level: 1 # group by mailboxID

    .then (result) -> return count: result[0]?.value or 0

# given a mailbox
# get the uids present in the cozy
Message.getUIDs = (mailboxID) ->
    Message.rawRequestPromised 'byMailboxAndDate',
        startkey: [mailboxID]
        endkey: [mailboxID, {}]
        reduce: false

    .map (row) -> row.value

# find a message by its message id
Message.byMessageId = (accountID, messageID) ->
    Message.rawRequestPromised 'byMessageId',
        key: [accountID, messageID]
        include_docs: true

    .then (rows) ->
        if data = rows[0]?.doc then new Message data

# add the message to a box
Message::addToMailbox = (box, uid) ->
    @mailboxIDs[box.id] = uid
    @savePromised()

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
    mail.messageID = mailutils.normalizeMessageID messageID if mail.messageID
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
        keys: messageIds.map (id) -> [mail.accountID, id]
        reduce: true

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
    rows.forEach (result, row) ->
        conversationIDCounts[row.value] ?= 1
        conversationIDCounts[row.value]++

    pickedConversationID = null
    pickedConversationIDCount = 0

    # find the most used conversationID
    for conversationID, count of conversationIDCounts
        if count > pickedConversationIDCount
            pickedConversationID = conversationID
            pickedConversationIDCount = count

    # if its undefined, we create one (GUID)
    unless pickedConversationID? and pickedConversationID isnt 'undefined'
        pickedConversationID = GUID.raw()

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
