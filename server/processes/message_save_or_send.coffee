Process = require './_base'
async = require 'async'
Message = require '../models/message'
stream_to_buffer = require '../utils/stream_to_array'
log = require('../utils/logging')(prefix: 'process:message_saving')
{NotFound, BadRequest, AccountConfigError} = require '../utils/errors'
{normalizeMessageID} = require('../utils/jwz_tools')
uuid = require 'uuid'
ramStore = require '../models/store_account_and_boxes'

# @TODO : this feels brittle
isDSAttachment = (attachment) -> attachment.url?

module.exports = class SaveOrSendMessage extends Process

    code: 'message-save-or-send'

    initialize: (options, done) =>

        @message = options.message
        @oldVersion = options.previousState
        @account = options.account
        @draftMailbox = ramStore.getMailbox @account.draftMailbox
        @sentMailbox = ramStore.getMailbox @account.sentMailbox

        @isDraft = options.isDraft
        @newAttachments = options.newAttachments

        @previousUID = @message.mailboxIDs?[@draftMailbox.id]

        @message.conversationID ?= uuid.v4()
        @message.attachments ?= []
        @message.flags = ['\\Seen']
        @message.flags.push '\\Draft' if @isDraft

        @message.content = @message.text
        @attachmentsClean = @message.attachments
        @attachmentsWithBuffers = []

        err = @validateParameters()
        if err
            return done err

        else
            async.series [
                @fetchForwardedMessage
                @gatherAttachments
                @sendMessageSMTP
                @removeOldDraftImap
                @addToDraftOrSentImap
                @createOrUdateCozy
                @attachNewBinaries
                @removeOldBinaries
            ], done

    validateParameters: =>
        if @isDraft or @oldVersion
            if not @account.draftMailbox
                return new AccountConfigError 'draftMailbox'
            else if not @draftMailbox
                new NotFound """
                    Account #{@account.id} draftbox #{@account.draftMailbox}"""
            else return null

        else
            if not @account.sentMailbox
                return new AccountConfigError 'sentMailbox'
            else if not @sentMailbox
                return new NotFound """
                    Account #{@account.id} sentbox #{@account.sentMailbox}"""
            else return null

    fetchForwardedMessage: (callback) =>

        hasDSAttachments = @message.attachments.some isDSAttachment

        if hasDSAttachments and not @oldVersion
            # this is a forward with attachments
            log.debug "fetching forwarded original"
            Message.find @message.inReplyTo, (err, found) =>
                return callback err if err
                if not found then return callback new Error """
                        Not Found Fwd #{@message.inReplyTo}"""

                @forwardedMessage = found
                callback null
        else
            callback null

    # when editing a draft, some attachments are in the DS, some in RAM
    # put them all in RAM so we can build the draft to store in IMAP.
    _gatherOne: (attachment, callback) =>
        filename = attachment.generatedFileName
        sourceMsg = @forwardedMessage or @oldVersion

        handleBuffer = (contentBuffer) =>
            @attachmentsWithBuffers.push
                content            : contentBuffer
                filename           : attachment.fileName
                cid                : attachment.contentId
                contentType        : attachment.contentType
                contentDisposition : attachment.contentDisposition
            callback null

        # file in the DS, from a previous save of the draft
        # cache it and pass around
        if attachment.url
            fileStream = sourceMsg.getBinary filename, (err) ->
                log.error "Attachment streaming error", err if err

            # we buffer the attachment in RAM to be used in the mailbuilder
            bufferer = new stream_to_buffer.Bufferer (err, buffer) =>
                return callback err if err
                handleBuffer buffer

            fileStream.pipe bufferer

        # file just uploaded, take the buffer from the multipart req
        # content is a buffer
        else if @newAttachments[filename]
            handleBuffer @newAttachments[filename].content

        else
            callback new BadRequest 'Attachment #{filename} unknown'


    gatherAttachments: (callback) =>
        log.debug "gathering attachments"
        attachmentsWithBuffers = []

        async.eachSeries @message.attachments, @_gatherOne, (err) =>
            @message.attachments = @attachmentsWithBuffers
            callback err


    sendMessageSMTP: (callback) =>
        return callback null if @isDraft

        log.debug "send#sending"
        @account.sendMessage @message, (err, info) =>
            return callback err if err
            @message.headers['message-id'] = info.messageId
            @message.messageID = normalizeMessageID info.messageId
            callback null


    removeOldDraftImap: (callback) =>
        return callback null unless @previousUID

        log.debug "send#remove_old"
        @draftMailbox.imap_removeMail @previousUID, callback


    addToDraftOrSentImap: (callback) =>

        if @isDraft
            @destinationBox = @draftMailbox
            add = @account.imap_createMail.bind @account, @draftMailbox

        else
            @destinationBox = @sentMailbox
            add = @sentMailbox.imap_createMailNoDuplicate
                                            .bind @sentMailbox, @account

        add @message, (err, uid) =>
            @uidInDest = uid
            callback err

    createOrUdateCozy: (callback) =>
        log.debug "send#cozy_create"
        @message.attachments = @attachmentsClean
        @message.text = @message.content
        delete @message.content
        # use Date.now to ensure UID is unique
        @uidInDest = Date.now() if @account.isTest()
        @message.mailboxIDs = {}
        @message.mailboxIDs[@destinationBox.id] = @uidInDest
        @message.date = new Date().toISOString()

        if @forwardedMessage
            log.debug "send#linking"
            @message.binary = {}
            for attachment in @message.attachments
                filename = attachment.generatedFileName
                if filename of @forwardedMessage.binary
                    binaryReference = @forwardedMessage.binary[filename]
                    @message.binary[filename] = binaryReference

        Message.updateOrCreate @message, (err, updated) =>
            return callback err if err
            @cozyMessage = updated
            callback null

    attachNewBinaries: (callback) =>
        log.debug "send#attaching"
        async.eachSeries Object.keys(@newAttachments), (name, next) =>
            buffer = @newAttachments[name].content
            @cozyMessage.attachBinary buffer, name: name, next
        , callback

    removeOldBinaries: (callback) =>
        log.debug "send#removeBinary"
        @cozyMessage.binary ?= {}
        remainingAttachments = @cozyMessage.attachments.map (file) ->
            file.generatedFileName

        async.eachSeries Object.keys(@cozyMessage.binary), (name, next) =>
            if name in remainingAttachments
                setImmediate next
            else
                @cozyMessage.removeBinary name, next
        , callback
