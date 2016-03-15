Message     = require '../models/message'
Account     = require '../models/account'
Mailbox     = require '../models/mailbox'
{NotFound, BadRequest, AccountConfigError} = require '../utils/errors'
{MSGBYPAGE} = require '../utils/constants'
_ = require 'lodash'
async = require 'async'
querystring = require 'querystring'
multiparty = require 'multiparty'
crlf = require 'crlf-helper'
minify = require('html-minifier').minify
stream_to_buffer = require '../utils/stream_to_array'
log = require('../utils/logging')(prefix: 'controllers:mesage')
{normalizeMessageID} = require('../utils/jwz_tools')
uuid = require 'uuid'
ramStore = require '../models/store_account_and_boxes'
SaveOrSendMessage = require '../processes/message_save_or_send'
MessageMove = require '../processes/message_move'

minifierOpts =
    removeComments: true
    removeCommentsFromCDATA: true
    collapseWhitespace: true
    collapseBooleanAttributes: true
    removeRedundantAttributes: true
    removeEmptyAttributes: true
    removeScriptTypeAttributes: true
    removeStyleLinkTypeAttributes: true
    removeOptionalTags: true
    removeEmptyElements: true
    keepClosingSlash: true
    minifyJS: true
    minifyCSS: true

# get a message and attach it to req.message
module.exports.fetch = (req, res, next) ->

    id = req.params.messageID or req.body.id

    Message.find id, (err, found) ->
        return next err if err
        return next new NotFound "Message #{id}" unless found
        req.message = found
        next()

module.exports.fetchMaybe = (req, res, next) ->

    id = req.body.id
    if id then module.exports.fetch req, res, next
    else next()

# return a message's details
module.exports.details = (req, res, next) ->
    res.send req.message.toClientObject()

module.exports.attachment = (req, res, next) ->
    stream = req.message.getBinary req.params.attachment, (err) ->
        return next err if err

    if req.query?.download
        encodedFileName = encodeURIComponent req.params.attachment
        res.setHeader 'Content-disposition', """
            attachment; filename*=UTF8''#{encodedFileName}
        """

    stream.pipe res


module.exports.listByMailboxOptions = (req, res, next) ->
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

    else if sortField is 'from' or sortField is 'dest'
        before = if before then decodeURIComponent(before) else ''
        after = if after then decodeURIComponent(after) else {}
        pageAfter = if pageAfter then decodeURIComponent pageAfter

    else
        return next new BadRequest "Unsuported sort field #{sortField}"

    FLAGS_CONVERT =
        'seen'       : '\\Seen'
        'unseen'     : '!\\Seen'
        'flagged'    : '\\Flagged'
        'unflagged'  : '!\\Flagged'
        'answered'   : '\\Answered'
        'unanswered' : '!\\Answered'
        'attach'     : '\\Attachments'

    flagcode = req.query.flag
    if flagcode
        unless flag = FLAGS_CONVERT[flagcode]
            return next new BadRequest "Unsuported flag filter"
    else
        flag = null

    req.sortField  = sortField
    req.descending = descending
    req.before     = before
    req.sort       = sort
    req.after      = after
    req.pageAfter  = pageAfter
    req.flag       = flag
    req.flagcode   = flagcode
    next()


# list messages from a mailbox
# req.query possible
# sort = [+/-][date]
# flag in [seen, unseen, flagged, unflagged, answerred, unanswered]
module.exports.listByMailbox = (req, res, next) ->

    mailboxID = req.params.mailboxID

    Message.getResultsAndCount mailboxID,
        sortField    : req.sortField
        descending   : req.descending
        before       : req.before
        after        : req.after
        resultsAfter : req.pageAfter
        flag         : req.flag

    , (err, result) ->
        return next err if err

        messages = result.messages
        if messages.length is MSGBYPAGE
            last = messages[messages.length - 1]
            # for 'from' and 'dest', we use pageAfter as the number of records
            # to skip
            if req.sortField is 'from' or req.sortField is 'dest'
                pageAfter = messages.length + (parseInt(req.pageAfter, 10) or 0)
            else
                lastDate = last.date or new Date()
                pageAfter = lastDate.toISOString()

            links = next: "mailbox/#{mailboxID}/?" + querystring.stringify
                flag: req.flagcode
                sort: req.sort
                before: req.before
                after: req.after
                pageAfter: pageAfter

        else
            links = {}

        result.messages ?= []
        result.mailboxID = mailboxID
        result.messages = result.messages.map (msg) -> msg.toClientObject()
        result.links = links

        res.send result


# Middleware - parse the request form and buffer all its files
module.exports.parseSendForm = (req, res, next) ->
    form = new multiparty.Form(autoFields: true)

    nextonce = _.once next #this may be parano
    fields = {}
    files = {}

    form.on 'field', (name, value) ->
        fields[name] = value

    form.on 'part', (part) ->
        stream_to_buffer part, (err, bufs) ->
            return nextonce err if err

            files[part.name] =
                filename: part.filename
                headers: part.headers
                content: Buffer.concat bufs

        part.resume()

    form.on 'error', (err) ->
        nextonce err
    form.on 'close', ->
        req.body = JSON.parse fields.body
        req.files = files
        nextonce()
    form.parse req


# send a message
# at some point in the future, we might want to merge it with above
# to allow streaming of upload
module.exports.send = (req, res, next) ->
    log.debug "send"

    isDraft = req.body.isDraft
    delete req.body.isDraft

    message = req.body
    if message.html
        message.html = minify message.html, minifierOpts
    if message.text
        message.text = crlf.setLineEnding message.text.trim(), 'CRLF'

    proc = new SaveOrSendMessage
        account: ramStore.getAccount req.body.accountID
        previousState: req.message # can be null
        message: message
        newAttachments: req.files
        isDraft: isDraft

    proc.run (err) ->
        return next err if err
        out = proc.cozyMessage.toClientObject()
        out.isDraft = isDraft
        res.send out

# fetch messages with various methods
# expect one of conversationIDs, conversationID, or messageIDs in body
# attach the messages to req.messages
module.exports.batchFetch = (req, res, next) ->

    if Object.keys(req.body).length is 0
        req.body = req.query

    handleMessages = (err, messages) ->
        return next err if err
        req.messages = messages
        next()

    if req.body.messageID
        Message.find req.body.messageID, (err, message) ->
            handleMessages err, [message]

    else if req.body.conversationID
        Message.byConversationID req.body.conversationID, handleMessages

    else if req.body.messageIDs
        Message.findMultiple req.body.messageIDs, handleMessages

    else if req.body.conversationIDs
        Message.byConversationIDs req.body.conversationIDs, handleMessages

    else
        next new BadRequest """
            No conversationIDs, conversationID, or messageIDs in body.
        """

module.exports.batchSend = (req, res, next) ->
    messages = req.messages.filter (msg) -> return msg?
        .map (msg) -> msg?.toClientObject()
    return next new NotFound "No message found" if messages.length is 0
    res.send messages

# move several message to trash with one request
# expect req.messages
module.exports.batchTrash = (req, res, next) ->
    accountInstance = ramStore.getAccount(req.body.accountID)
    # the client should prevent this, but let's be safe
    unless accountInstance
        return next new BadRequest 'accountInstance'
    trashBoxId = accountInstance.trashMailbox
    # the client should prevent this, but let's be safe
    unless trashBoxId
        return next new AccountConfigError 'trashMailbox'

    process = new MessageMove
        messages: req.messages
        to: trashBoxId

    process.run (err) ->
        res.send process.updatedMessages


# add a flag to several messages
# expect req.body.flag
module.exports.batchAddFlag = (req, res, next) ->

    Message.batchAddFlag req.messages, req.body.flag, (err, updated) ->
        return next err if err
        res.send updated

# remove a flag from several messages
# expect req.body.flag
module.exports.batchRemoveFlag = (req, res, next) ->

    Message.batchRemoveFlag req.messages, req.body.flag, (err, updated) ->
        return next err if err
        res.send updated

# move several message with one request
# expect & req.messages
# aim :
#   - the conversation should not appears in from
#   - the conversation should appears in to
#   - drafts should stay in drafts
#   - messages in trash should stay in trash
module.exports.batchMove = (req, res, next) ->
    process = new MessageMove
        messages: req.messages
        to: req.body.to
        from: req.body.from

    process.run (err) ->
        res.send process.updatedMessages


module.exports.search = (req, res, next) ->

    return next new Error('search is disabled')

    params =
        query: req.query.search
        facets: accountID: {}

    if req.query.accountID
        params.filter =
            accountID: [[req.query.accountID, req.query.accountID]]

    params.numByPage = req.query.pageSize or 10
    params.numPage = req.query.page or 0

    Message.search params, (err, results) ->
        return next err if err
        accounts = {}
        for facet in results.facets when facet.key is 'accountID'
            for account in facet.value
                accounts[account.key] = account.value

        res.send
            accounts: accounts
            rows: results.map (msg) -> msg.toClientObject()


# fetch from IMAP and send the raw rfc822 message
module.exports.raw = (req, res, next) ->

    boxID = Object.keys(req.message.mailboxIDs)[0]
    uid = req.message.mailboxIDs[boxID]

    Mailbox.find boxID, (err, mailbox) ->
        return next err if err

        mailbox.doASAPWithBox (imap, imapbox, cbRelease) ->
            try imap.fetchOneMailRaw uid, cbRelease
            catch err then cbRelease err
        , (err, message) ->
            return next err if err
            # should be message/rfc822 but text/plain allow to read the
            # raw message in the browser
            res.type 'text/plain'
            res.send message
