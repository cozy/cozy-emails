AppDispatcher        = require '../AppDispatcher'
{ActionTypes}        = require '../constants/AppConstants'
XHRUtils             = require '../utils/XHRUtils'


module.exports =

    receiveRawMessages: (messages) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGES
            value: messages

    receiveRawMessage: (message) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGE
            value: message

    send: (message, callback) ->
        XHRUtils.messageSend message, (error, message) ->
            if not(error?)
                AppDispatcher.handleViewAction
                    type: ActionTypes.SEND_MESSAGE
                    value: message
            callback error

    delete: (message, callback) ->
        XHRUtils.messageDelete message.get('id'), (error, message) ->
            if not(error?)
                AppDispatcher.handleViewAction
                    type: ActionTypes.DELETE_MESSAGE
                    value: message
            callback error
