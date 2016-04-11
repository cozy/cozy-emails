AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes} = require '../constants/app_constants'

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
            else
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
        timestamp = Date.now()
        XHRUtils.batchMove target, from, to, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_MOVE_FAILURE
                    value: {target, ref, error}
            else
                msg.updated = timestamp for msg in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_MOVE_SUCCESS
                    value: {target, ref, updated}


    mark: (target, action) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, action}


module.exports = MessageActionCreator
