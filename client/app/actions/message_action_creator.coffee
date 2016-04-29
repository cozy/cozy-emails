AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes, MessageFlags, FlagsConstants} = require '../constants/app_constants'

XHRUtils      = require '../utils/xhr_utils'

MessageStore  = require '../stores/message_store'

refCounter = 1

MessageActionCreator =

    receiveRawMessages: (messages) ->
        AppDispatcher.dispatch
            type: ActionTypes.RECEIVE_RAW_MESSAGES
            value: messages

    receiveRawMessage: (message) ->
        AppDispatcher.dispatch
            type: ActionTypes.RECEIVE_RAW_MESSAGE
            value: message

    send: (action, message) ->
        conversationID = message.conversationID

        # Message should have a html content
        # event if it is a simple text
        unless message.composeInHTML
            message.html = message.text

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_SEND_REQUEST
            value: message

        XHRUtils.messageSend message, (error, message) =>
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_SEND_FAILURE
                    value: {error, action, message}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_SEND_SUCCESS
                    value: {action, message}


    # set conv to true to update current conversation ID
    setCurrent: (messageID, conv) ->
        if messageID? and typeof messageID isnt 'string'
            messageID = messageID.get 'id'
        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_CURRENT
            value:
                messageID: messageID

    # Immediately synchronise some messages with the server
    # Used if one of the action fail
    recover: (target, ref) ->
        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_RECOVER_REQUEST
            value: {ref}

        XHRUtils.batchFetch target, (err, messages) ->
            if err
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_RECOVER_FAILURE
                    value: {ref}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_RECOVER_SUCCESS
                    value: {ref}


    # Delete message(s)
    # target:
    #  - messageID or messageIDs or conversationIDs or conversationIDs
    delete: (target) ->
        ref = refCounter++

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_TRASH_REQUEST
            value: {target, ref}

        # send request
        ts = Date.now()
        XHRUtils.batchDelete target, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_TRASH_FAILURE
                    value: {target, ref, error}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
                return

            msg.updated = ts for msg in updated
            AppDispatcher.dispatch
                type: ActionTypes.MESSAGE_TRASH_SUCCESS
                value: {target, ref, updated}

    move: (target, from, to) ->
        ref = refCounter++
        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_MOVE_REQUEST
            value: {target, ref, from, to}

        # send request
        ts = Date.now()
        XHRUtils.batchMove target, from, to, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_MOVE_FAILURE
                    value: {target, ref, error}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                msg.updated = ts for msg in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_MOVE_SUCCESS
                    value: {target, ref, updated}


    mark: (target, flagAction) ->
        ref = refCounter++

        switch flagAction
            when FlagsConstants.SEEN
                op = 'batchAddFlag'
                flag = FlagsConstants.SEEN
            when FlagsConstants.FLAGGED
                op = 'batchAddFlag'
                flag = FlagsConstants.FLAGGED
            when FlagsConstants.UNSEEN
                op = 'batchRemoveFlag'
                flag = FlagsConstants.SEEN
            when FlagsConstants.NOFLAG
                op = 'batchRemoveFlag'
                flag = FlagsConstants.FLAGGED
            else
                throw new Error "Wrong usage : unrecognized FlagsConstants"

        ts = Date.now()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, ref, op, flag, flagAction}

        XHRUtils[op] target, flag, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, ref, error, op, flag, flagAction}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                msg.updated = ts for msg in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, ref, updated, op, flag, flagAction}

    undo: (ref) ->

        request = MessageStore.getUndoableRequest ref
        {messages, type, from, to, target, trashBoxID} = request
        reverseAction = []

        oldto = if type is 'move' then to else trashBoxID
        bydest = {}
        # messages are the old messages
        messages.forEach (message) ->
            dest = (boxid for boxid, uid of message.get('mailboxIDs'))
            destString = dest.sort().join(',')
            bydest[destString] ?= {to: dest, from: oldto, messageIDs: []}
            bydest[destString].messageIDs.push message.get('id')

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_UNDO_START
            value: {ref}

        _loopSeries bydest, (request, dest, next) ->
            {to, from, messageIDs} = request
            target = {messageIDs, silent: true}
            MessageActionCreator.move target, from, to, next
        , (error) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_UNDO_FAILURE
                    value: {ref}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_UNDO_SUCCESS
                    value: {ref}


_loopSeries = (obj, iterator, done) ->
    keys = Object.keys(obj)
    i = 0
    do step = ->
        key = keys[i]
        iterator obj[key], key, (err) ->
            return done err if err
            return done null if ++i is keys.length
            step()

module.exports = MessageActionCreator
