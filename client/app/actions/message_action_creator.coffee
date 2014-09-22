AppDispatcher        = require '../app_dispatcher'
{ActionTypes}        = require '../constants/app_constants'
XHRUtils             = require '../utils/xhr_utils'


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
                    type: ActionTypes.MESSAGE_SEND
                    value: message
            callback error

    delete: (message, callback) ->
        XHRUtils.messageDelete message.get('id'), (error, message) ->
            if not(error?)
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_DELETE
                    value: message
            callback error

    move: (message, from, to, callback) ->
        msg = message.toObject()
        observer = jsonpatch.observe msg
        delete msg.mailboxIDs[from]
        msg.mailboxIDs[to] = -1
        patches = jsonpatch.generate observer
        XHRUtils.messagePatch message.get('id'), patches, (error, message) ->
            if not(error?)
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGE
                    value: message
            callback error

    updateFlag: (message, callback) ->
        msg = message.toObject()
        observer = jsonpatch.observe msg
        # TODO : update flags
        patches = jsonpatch.generate observer
        XHRUtils.messagePatch message.get('id'), patches, (error, message) ->
            if not(error?)
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FLAG
                    value: message
            callback error
