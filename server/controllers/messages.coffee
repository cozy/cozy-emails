Message     = require '../models/message'
Account     = require '../models/account'
Mailbox     = require '../models/mailbox'
{NotFound, BadRequest, AccountConfigError} = require '../utils/errors'
{MSGBYPAGE} = require '../utils/constants'
Promise     = require 'bluebird'
htmlToText  = require 'html-to-text'
sanitizer   = require 'sanitizer'
_ = require 'lodash'
querystring = require 'querystring'

htmlToTextOptions =
    tables: true
    wordwrap: 80


formatMessage = (message) ->
    if message.html?
        message.html = sanitizer.sanitize message.html, (value) ->
            value.toString()

    if not message.text?
        message.text = htmlToText.fromString message.html, htmlToTextOptions

    return message

# list messages from a mailbox
module.exports.listByMailbox = (req, res, next) ->

    sort = if req.query.sort then req.query.sort
    else '-date'

    descending = sort.substring(0, 1)
    if descending is '+' then descending = false
    else if descending is '-' then descending = true
    else return next new BadRequest "Unsuported sort order #{descending}"

    pageAfter = req.query.pageAfter
    sortField = sort.substring(1)
    before = req.query.before
    after = req.query.after
    if sortField is 'date'
        before ?= new Date(0).toISOString()
        after ?= new Date().toISOString()
        if new Date(before).toISOString() isnt before or
           new Date(after).toISOString() isnt after
            return next new BadRequest "before & after should be a valid JS " +
                "date.toISOString()"

    else if sortField is 'subject'
        before = if before then decodeURIComponent(before) else ''
        after = if after then decodeURIComponent(after) else {}
        pageAfter = if pageAfter then decodeURIComponent pageAfter

    else return next new BadRequest "Unsuported sort field #{sortField}"

    FLAGS_CONVERT =
        'seen'       : '\\Seen'
        'unseen'     : '!\\Seen'
        'flagged'    : '\\Flagged'
        'unflagged'  : '!\\Flagged'
        'answered'   : '\\Answered'
        'unanswered' : '!\\Answered'

    flagcode = req.query.flag
    if flagcode
        flag = FLAGS_CONVERT[flagcode]
        return next new BadRequest "Unsuported flag filter" unless flag
    else
        flag = null

    mailboxID = req.params.mailboxID

    Message.getResultsAndCount mailboxID,
        sortField: sortField
        descending: descending
        before: before
        after: after
        resultsAfter: pageAfter
        flag: flag

    .then (result) ->

        messages = result.messages
        if messages.length is MSGBYPAGE
            last = messages[messages.length - 1]
            pageAfter = if sortField is 'date' then last.date.toISOString()
            else last.normSubject

            links = next: "/mailbox/#{mailboxID}?" + querystring.stringify
                flag: flagcode
                sort: sort
                before: before
                after: after
                pageAfter: pageAfter

        else
            links = {}


        res.send 200,
            mailboxID: mailboxID
            messages: result.messages?.map(formatMessage) or []
            count: result.count
            links: links

    .catch next

# get a message and attach it to req.message
module.exports.fetch = (req, res, next) ->
    Message.findPromised req.params.messageID
    .throwIfNull -> new NotFound "Message #{req.params.messageID}"
    .then (message) -> req.message = message
    .nodeify next

# return a message's details
module.exports.details = (req, res, next) ->

    # @TODO : fetch message's status
    # @TODO : fetch whole conversation ?

    res.send 200, formatMessage req.message

module.exports.attachment = (req, res, next) ->
    stream = req.message.getBinary req.params.attachment, (err) ->
        return next err if err

    stream.on 'error', next
    stream.pipe res

# patch e message
module.exports.patch = (req, res, next) ->
    req.message.applyPatchOperations req.body
    .then -> res.send 200, formatMessage req.message
    .catch next

# send a message through the DS
module.exports.send = (req, res, next) ->

    # @TODO : if message was a draft, delete it from Draft folder
    # @TODO : save draft into DS

    message = req.body

    # convert base64 attachments to buffer
    message.attachments.map (attachment) ->
        filename: attachment.filename
        contents: new Buffer attachment.content.split(",")[1], 'base64'

    # @TODO : save attachments in the DS

    # find the account and draftBox
    Account.findPromised message.accountID
    .throwIfNull -> new NotFound "Account #{message.accountID}"
    .then (account) ->
        Mailbox.findPromised account.draftMailbox
        .then (draftBox) -> return [account, draftBox]

    .spread (account, draftBox) ->

        # remove the old version if necessary
        removeOld = ->
            uid = message.mailboxIDs?[draftBox?.id]
            if uid then draftBox?.imap_removeMail uid
            else Promise.resolve null

        message.flags = ['\\Seen']

        if message.isDraft
            out = removeOld()
            .then ->
                unless draftBox
                    throw new AccountConfigError('draftMailbox')

                message.flags.push '\\Draft'
                account.imap_createMail draftBox, message

        else
            # send before deleting draft
            out = account.sendMessagePromised message
            .then (info) -> message.headers['message-id'] = info.messageId
            .then -> removeOld()
            .then -> Mailbox.findPromised account.sentMailbox
            .then (sentBox) ->
                account.imap_createMail sentBox, message

        return out

    # save the message
    .spread (dest, uidInDest) ->
        message.mailboxIDs = {}
        message.mailboxIDs[dest.id] = uidInDest
        message.date = new Date().toISOString()

        if message.id
            Message.findPromised message.id
            .then (jdbMessage) -> jdbMessage.updateAttributesPromised message
        else
            Message.createPromised message

    .then (msg) -> res.send 200, msg
    .catch next


# search in the messages using the indexer
module.exports.search = (req, res, next) ->

    if not req.params.query?
        return next new BadRequest '`query` body field is mandatory'

    # we add one temporary because the search doesn't return the
    # number of results so we can't paginate properly
    numPageCheat = parseInt(req.params.numPage) *
                    parseInt(req.params.numByPage) + 1
    Message.searchPromised
        query: req.params.query
        numPage: req.params.numPage
        numByPage: numPageCheat
    .then (messages) -> res.send 200, messages.map formatMessage
    .catch next

# Temporary routes for testing purpose
module.exports.index = (req, res, next) ->
    Message.requestPromised 'all', {}
    .map (message) -> messages.indexPromised ['subject', 'text']
    .then -> res.send 200, 'Indexation OK'
    .catch next

module.exports.del = (req, res, next) ->

    Account.findPromised req.message.accountID
    .throwIfNull -> new NotFound "Account #{req.message.accountID}"
    .then (account) ->
        trashID = account.trashMailbox
        throw new AccountConfigError 'trashMailbox' unless trashID

        # build a patch that remove from all mailboxes and add to trash
        patch = Object.keys(req.message.mailboxIDs)
        .filter (boxid) -> boxid isnt trashID
        .map (boxid) -> op: 'remove', path: "/mailboxIDs/#{boxid}"

        patch.push op: 'add', path: "/mailboxIDs/#{trashID}"

        req.message.applyPatchOperations patch

    .then -> res.send 200, req.message
    .catch next


module.exports.conversationGet = (req, res, next) ->

    Message.byConversationId req.params.conversationID
    .then (messages) -> res.send 200, messages.map formatMessage

    .catch next

module.exports.conversationDelete = (req, res, next) ->

    # @TODO : Delete Conversation

    res.send 200, []


module.exports.conversationPatch = (req, res, next) ->

    Message.byConversationId req.params.conversationID
    .then (messages) ->
        # @TODO : be smarter : dont remove message from sent folder, ...
        Promise.serie messages, (msg) ->
            msg.applyPatchOperations req.body

        .then -> res.send 200, messages

    .catch next
