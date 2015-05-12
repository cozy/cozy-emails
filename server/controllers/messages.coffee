Message     = require '../models/message'
Account     = require '../models/account'
Mailbox     = require '../models/mailbox'
{NotFound, BadRequest, AccountConfigError} = require '../utils/errors'
{MSGBYPAGE} = require '../utils/constants'
_ = require 'lodash'
async = require 'async'
querystring = require 'querystring'
multiparty = require 'multiparty'
stream_to_buffer = require '../utils/stream_to_array'
log = require('../utils/logging')(prefix: 'controllers:mesage')
ImapReporter = require '../imap/reporter'

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

    else if sortField is 'subject' or sortField is 'from' or sortField is 'dest'
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
# sort = [+/-][date/subject]
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
            if req.sortField is 'subject'
                pageAfter = last.normSubject
            # for 'from' and 'dest', we use pageAfter as the number of records to skip
            else if req.sortField is 'from' or req.sortField is 'dest'
                pageAfter = messages.length + (parseInt(req.pageAfter, 10) or 0)
            else
                lastDate = last.date or new Date()
                pageAfter = lastDate.toISOString()

            links = next: "/mailbox/#{mailboxID}?" + querystring.stringify
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


# when editing a draft, some attachments are in the DS, some in RAM
# put them all in RAM so we can build the draft to store in IMAP.
contentToBuffer = (req, attachment, callback) ->
    filename = attachment.generatedFileName

    # file in the DS, from a previous save of the draft
    # cache it and pass around
    if attachment.url
        fileStream = req.message.getBinary filename, (err) ->
            log.error "Attachment streaming error", err if err

        # we buffer the attachment in RAM to be used in the mailbuilder
        bufferer = new stream_to_buffer.Bufferer callback
        fileStream.pipe bufferer

    # file just uploaded, take the buffer from the multipart req
    # content is a buffer
    else if req.files[filename]
        callback null, req.files[filename].content

    else
        callback new BadRequest 'Attachment #{filename} unknown'

# send a message
# at some point in the future, we might want to merge it with above
# to allow streaming of upload
module.exports.send = (req, res, next) ->
    log.debug "send"

    message = req.body
    account = req.account
    files = req.files

    message.attachments ?= []
    message.flags = ['\\Seen']
    isDraft = message.isDraft
    delete message.isDraft
    if isDraft
        message.flags.push '\\Draft'

    message.content = message.text
    message.attachments_backup = message.attachments

    previousUID = message.mailboxIDs?[account.draftMailbox]

    steps = []


    steps.push (cb) ->
        log.debug "gathering attachments"
        async.mapSeries message.attachments, (attachment, cbMap) ->
            contentToBuffer req, attachment, (err, content) ->
                return cbMap err if err
                return cbMap null,
                    content            : content
                    filename           : attachment.fileName
                    cid                : attachment.contentId
                    contentType        : attachment.contentType
                    contentDisposition : attachment.contentDisposition

        , (err, cacheds) ->
            return cb err if err
            message.attachments = cacheds
            cb()

    draftBox = null
    sentBox = null
    destination = null
    jdbMessage = null
    uidInDest = null

    unless isDraft
        # Send the message first
        steps.push (cb) ->
            log.debug "send#sending"
            account.sendMessage message, (err, info) ->
                return cb err if err
                message.headers['message-id'] = info.messageId
                cb null

        #  Get the sent box
        steps.push (cb) ->
            log.debug "send#getsentbox"
            id = account.sentMailbox
            Mailbox.find id, (err, box) ->
                return cb err if err
                unless box
                    err = new NotFound "Account #{account.id} sentbox #{id}"
                    return cb err
                sentBox = box
                cb()

    # If we will need the draftbox
    if previousUID or isDraft
        steps.push (cb) ->
            log.debug "send#getdraftbox"
            id = account.draftMailbox
            Mailbox.find id, (err, box) ->
                return cb err if err
                unless box
                    err = new NotFound "Account #{account.id} draftbox #{id}"
                    return cb err
                draftBox = box
                cb()

    # Remove the message from draft (imap)
    if previousUID
        steps.push (cb) ->
            log.debug "send#remove_old"
            draftBox.imap_removeMail previousUID, cb


    # Add the message to draft or sent folder (imap)
    if isDraft
        steps.push (cb) ->
            destination = draftBox
            log.debug "send#add_to_draft"
            account.imap_createMail draftBox, message, (err, uid) ->
                return cb err if err
                uidInDest = uid
                cb null


    else
        log.debug "send#add_to_sent"
        steps.push (cb) ->
            destination = sentBox
            # check if message already created by IMAP/SMTP (gmail)
            sentBox.imap_createMailNoDuplicate account, message, (err, uid) ->
                return cb err if err
                uidInDest = uid
                cb null

    steps.push (cb) ->
        log.debug "send#cozy_create"
        message.attachments = message.attachments_backup
        message.text = message.content
        delete message.attachments_backup
        delete message.content
        # use Date.now to ensure UID is unique
        uidInDest = Date.now() if account.isTest()
        message.mailboxIDs = {}
        message.mailboxIDs[destination.id] = uidInDest
        message.date = new Date().toISOString()

        Message.updateOrCreate message, (err, updated) ->
            return cb err if err
            jdbMessage = updated
            cb null

    steps.push (cb) ->
        log.debug "send#attaching"
        async.eachSeries Object.keys(files), (name, cbLoop) ->
            buffer = files[name].content
            buffer.path = encodeURI name
            jdbMessage.attachBinary buffer, name: name, cbLoop
        , cb

    steps.push (cb) ->
        log.debug "send#removeBinary"
        jdbMessage.binary ?= {}
        remainingAttachments = jdbMessage.attachments.map (file) ->
            file.generatedFileName

        async.eachSeries Object.keys(jdbMessage.binary), (name, cbLoop) ->
            if name in remainingAttachments
                cbLoop null
            else
                jdbMessage.removeBinary name, cbLoop
        , cb


    async.series steps, (err) ->
        return next err if err
        return next new Error('Server error') unless jdbMessage

        # returns the message as the client expect it (with isDraft property)
        out = jdbMessage.toClientObject()
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
    messages = req.messages.map (msg) -> msg.toClientObject()
    res.send messages

# move several message to trash with one request
# expect req.account & req.messages
module.exports.batchTrash = (req, res, next) ->
    # the client should prevent this, but let's be safe
    unless req.account.trashMailbox
        return next new AccountConfigError 'trashMailbox'

    async.mapSeries req.messages, (message, cb) ->
        if message.mailboxIDs[req.account.trashMailbox]?
            # message is already in trash
            cb null, message

        else if message.isDraft req.account.draftMailbox
            # message is a draft
            message.imapcozy_destroy (err) ->
                cb err, {id: message.id, _deleted: true}

        else
            # "normal" message, move it to trash
            message.moveToTrash req.account, cb

    , (err, updatedMessages) ->
        return next err if err
        res.send updatedMessages

# add a flag to several messages
# expect req.body.flag
module.exports.batchAddFlag = (req, res, next) ->

    async.mapSeries req.messages, (message, cb) ->
        message.addFlag req.body.flag, cb
    , (err, updatedMessages) ->
        return next err if err
        res.send updatedMessages

# remove a flag from several messages
# expect req.body.flag
module.exports.batchRemoveFlag = (req, res, next) ->
    async.mapSeries req.messages, (message, cb) ->
        message.removeFlag req.body.flag, cb
    , (err, updatedMessages) ->
        return next err if err
        res.send updatedMessages

# move several message with one request
# expect req.account & req.messages
# aim :
#   - the conversation should not appears in from
#   - the conversation should appears in to
#   - drafts should stay in drafts
#   - messages in trash should stay in trash
module.exports.batchMove = (req, res, next) ->

    to = req.body.to
    from = req.body.from

    async.mapSeries req.messages, (message, cb) ->
        # dont move message that are not in from box
        unless message.mailboxIDs[from]?
            cb null, message

        else
            message.move from, to, cb

    , (err, updatedMessages) ->
        return next err if err
        res.send updatedMessages


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
