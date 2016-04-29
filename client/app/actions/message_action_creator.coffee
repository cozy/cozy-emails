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


module.exports = MessageActionCreator
