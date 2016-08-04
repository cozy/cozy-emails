Immutable = require('immutable')
{MessageFlags} = require('../constants/app_constants')

getAttachmentType = require('../libs/attachment_types')

Message = Immutable.Record

    # cozydb secret fields
    _id            : undefined
    _attachments   : undefined
    _rev           : undefined
    docType        : undefined
    binaries       : undefined


    # FIELDS USED IN CLIENT
    subject        : undefined
    cc             : undefined
    to             : undefined
    from           : undefined
    id             : undefined
    conversationID : undefined
    flags          : undefined
    attachments    : Immutable.List()
    headers        : undefined
    text           : undefined
    html           : undefined
    alternatives   : undefined
    mailboxIDs     : undefined
    mailboxID      : undefined
    accountID      : undefined
    date           : undefined

    # FIELDS SPECIFIC TO CLIENT
    _displayImages: false
    updated: 0

    # OTHER FIELDS ON SERVER
    createdAt      : undefined
    binary         : undefined
    messageID      : undefined
    inReplyTo      : undefined

    normSubject    : undefined
    hasTwin        : undefined
    twinMailboxIDs : undefined

    bcc            : undefined
    replyTo        : undefined
    references     : undefined
    priority       : undefined
    ignoreInCount  : undefined

Message::hasFlag = (flag) ->
    flag in (@get('flags') or [])

Message::isUnread = ->
    not @hasFlag MessageFlags.SEEN

Message::isFlagged = ->
    @hasFlag MessageFlags.FLAGGED

Message::isDraft = ->
    @hasFlag MessageFlags.DRAFT

Message::isAttached = ->
    attachments = @get('attachments')
    size = if attachments?.size is undefined then attachments?.length
    else attachments?.size

    return size? and size > 0

Message::inMailbox = (mailboxID) ->
    Boolean @get('mailboxIDs')[mailboxID]

Message::getResources = ->
    @get('attachments').groupBy (file) ->
        contentType = file.get 'contentType'
        attachementType = getAttachmentType contentType
        if attachementType is 'image' then 'preview' else 'binary'


module.exports = Message
