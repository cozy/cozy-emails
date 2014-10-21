async       = require 'async'
Message     = require '../models/message'
Account     = require '../models/account'
Mailbox     = require '../models/mailbox'
{HttpError, WrongConfigError} = require '../utils/errors'
Client      = require('request-json').JsonClient
jsonpatch   = require 'fast-json-patch'
nodemailer  = require 'nodemailer'
Promise     = require 'bluebird'
htmlToText  = require 'html-to-text'
sanitizer   = require 'sanitizer'
ImapProcess = require '../processes/imap_processes'

htmlToTextOptions =
    tables: true
    wordwrap: 80
# The data system listens to localhost:9101
dataSystem = new Client 'http://localhost:9101/'

# In production we must authenticate the application
if process.env.NODE_ENV in ['production', 'test']
    user = process.env.NAME
    password = process.env.TOKEN
    dataSystem.setBasicAuth user, password

formatMessage = (message) ->
    if message.html?
        message.html = sanitizer.sanitize message.html, (value) -> value.toString()

    if not message.text?
        message.text = htmlToText.fromString message.html, htmlToTextOptions

    return message

# list messages from a mailbox
# require numPage & numByPage params
module.exports.listByMailboxId = (req, res, next) ->

    # @TODO : add query parameters for sort & pagination
    options =
        numPage: req.params.numPage - 1
        numByPage: req.params.numByPage

    Promise.all [
        Message.getByMailboxAndDate req.params.mailboxID, options
        Message.countByMailbox req.params.mailboxID
        Message.countReadByMailbox req.params.mailboxID
    ]
    .spread (messages, count, read) ->
        res.send 200,
            mailboxID: req.params.mailboxID
            messages: messages.map formatMessage
            count: count
            unread: count - read

    .catch next

# get a message and attach it to req.message
module.exports.fetch = (req, res, next) ->
    Message.findPromised req.params.messageID
    .then (message) ->
        if message then req.message = message
        else throw new HttpError 404, 'Not Found'
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

    # find the account and draftbox
    Account.findPromised message.accountID
    .then (account) ->
        Mailbox.findPromised account.draftMailbox
        .then (draftBox) -> return [account, draftBox]

    .spread (account, draftBox) ->

        # remove the old version if necessary
        removeOld = ->
            uid = message.mailboxIDs?[draftBox?.id]
            if uid then ImapProcess.remove account, draftBox, uid
            else Promise.resolve()

        message.flags = ['\\Seen']

        if message.isDraft
            out = removeOld()
            .then ->
                unless draftBox
                    throw new WrongConfigError('need a draftbox')

                message.flags.push '\\Draft'
                ImapProcess.createMail account, draftBox, message

        else
            # send before deleting draft
            out = account.sendMessagePromised message
            .then (info) -> message.headers['message-id'] = info.messageId
            .then -> removeOld()
            .then -> Mailbox.findPromised account.sentMailbox
            .then (sentBox) ->
                ImapProcess.createMail account, sentBox, message

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
        next new HttpError 400, '`query` body field is mandatory'
    else
        # we add one temporary because the search doesn't return the
        # number of results so we can't paginate properly
        numPageCheat = parseInt(req.params.numPage) * parseInt(req.params.numByPage) + 1
        Message.searchPromised
            query: req.params.query
            numPage: req.params.numPage
            numByPage: numPageCheat
        .then (messages) -> res.send 200, messages.map formatMessage
        .catch next

# Temporary routes for testing purpose
module.exports.index = (req, res, next) ->
    Message.request 'all', {}, (err, messages) ->
        if err? then next err
        else
            async.each messages, (message, callback) ->
                message.index ['subject', 'text'], callback
            , (err) ->
                if err? then next err
                else res.send 200, 'Indexation OK'

module.exports.del = (req, res, next) ->

    Account.findPromised req.message.accountID
    .then (account) ->
        trashID = account.trashMailbox
        throw new WrongConfigError 'need define trash' unless trashID

        # build a patch that remove from all mailboxes and add to trash
        patch = Object.keys(req.message.mailboxIDs)
        .filter (boxid) -> boxid isnt trashID
        .map (boxid) -> op: 'remove', path: "/mailboxIDs/#{boxid}"

        patch.push op: 'add', path: "/mailboxIDs/#{trashID}"

        req.message.applyPatchOperations patch

    .then -> res.send 200, req.message
    .catch next

module.exports.conversationDelete = (req, res, next) ->

    # @TODO : Delete Conversation

    res.send 200, []


module.exports.conversationPatch = (req, res, next) ->

    Message.byConversationID req.params.conversationID
    .then (messages) ->
        # @TODO : be smarter : dont remove message from sent folder, ...
        Promise.serie messages, (msg) ->
            msg.applyPatchOperations req.body

        .then -> res.send 200, messages

    .catch next
