Process = require './_base'
async = require 'async'
Message = require '../models/message'
log = require('../utils/logging')(prefix: 'process:message_saving')
{NotFound, BadRequest, AccountConfigError} = require '../utils/errors'
{normalizeMessageID} = require('../utils/jwz_tools')
MailboxRefresh = require '../processes/mailbox_refresh'
Scheduler = require '../processes/_scheduler'
uuid = require 'uuid'
ramStore = require '../models/store_account_and_boxes'
_ = require 'lodash'

module.exports = class MessageMove extends Process

    initialize: (options, callback) ->

        @to = if Array.isArray(options.to) then options.to else [options.to]
        @from = options.from or null

        # ignore messages which are already in the destination set
        @messages = options.messages.filter (msg) =>
            boxes = Object.keys(msg.mailboxIDs)
            return _.xor(boxes, @to).length > 1

        @alreadyMoved = []
        @changes = {}
        ignores = null
        @fromBox    = ramStore.getMailbox @from
        @destBoxes  = @to.map (id) -> ramStore.getMailbox id
        @ignores    = ramStore.getIgnoredMailboxes()
        @destString = @to.join(',')

        log.debug "batchMove", @messages.length, @from, @to

        async.series [
            @moveImap
            @applyChangesInCozy
            @fetchNewUIDs
        ], (err) =>
            callback err, @updatedMessages

    moveImap: (callback) =>
        Message.doGroupedByBox @messages, @handleMoveOneBox, callback

    _messageInAllDestinations: (message) =>
        for box in @to
            if not message.mailboxIDs[box]?
                return false

        return true

    handleMoveOneBox: (imap, state, nextBox) =>

        currentBox = state.box

        if undefined in @destBoxes
            return nextBox new Error """
                One of destination boxes #{@destString} doesnt exist"""

        # skip destBox
        return nextBox null if currentBox in @destBoxes

        # if no from is provided, messages must be removed from
        # all boxes,  else if from is provided, messages must be
        # removed from fromBox
        mustRemove = currentBox is @fromBox or not @from
        moves = []
        expunges = []

        for message in state.messagesInBox
            id = message.id
            uid = message.mailboxIDs[currentBox.id]

            # the message is already in destination
            if @_messageInAllDestinations(message) or id in @alreadyMoved
                if mustRemove
                    expunges.push uid
                    @changes[id] ?= message.cloneMailboxIDs()
                    delete @changes[id][currentBox.id]

            # move draft to trash = delete draft
            else if message.isDraft() and @from is null
                expunges.push uid
                @changes[id] ?= message.cloneMailboxIDs()
                delete @changes[id][currentBox.id]

            # we need to move it
            else
                moves.push uid
                @alreadyMoved.push id
                @changes[id] ?= message.cloneMailboxIDs()
                delete @changes[id][currentBox.id]
                for destBox in @destBoxes
                    @changes[id][destBox.id] = -1

        log.debug "MOVING", moves, "FROM", currentBox.id, "TO", @destString
        log.debug "EXPUNGING", expunges, "FROM", currentBox.id

        paths = @destBoxes.map (box) -> box.path
        imap.multimove moves, paths, (err, result) ->
            return nextBox err if err
            imap.multiexpunge expunges, (err) ->
                return nextBox err if err
                nextBox null

    applyChangesInCozy: (callback) =>
        async.mapSeries @messages, (message, next) =>
            newMailboxIDs = @changes[message.id]
            @applyOneChangeInCozy message, newMailboxIDs, next
        , (err, result) =>
            return callback err if err
            @updatedMessages = result
            callback null

    applyOneChangeInCozy: (message, newMailboxIDs, callback) =>
        unless newMailboxIDs
            callback null, message
        else
            boxes = Object.keys(newMailboxIDs)
            if boxes.length is 0
                message.destroy (err) ->
                    callback err, {id: message.id, _deleted: true}
            else
                data =
                    mailboxIDs: newMailboxIDs
                    ignoreInCount: boxes.some (id) => @ignores[id]

                message.updateAttributes data, (err) ->
                    callback err, message

    fetchNewUIDs: (callback) =>
        return callback null, [] if @updatedMessages.length is 0
        return callback null, [] unless @destBoxes?

        # assume there was not so many changes
        # we need to refresh the destboxes to fetch new uids
        # 100 is arbitrary
        limitByBox = Math.max(100, @messages.length*2)
        refreshes = @destBoxes.map (mailbox) ->
            new MailboxRefresh {mailbox, limitByBox}

        Scheduler.scheduleMultiple refreshes, (err) =>
            callback err, @updatedMessages
