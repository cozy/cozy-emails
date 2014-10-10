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
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_SEND
                    value: message
            if callback?
                callback error, message

    delete: (message, account, callback) ->
        # Move message to Trash folder
        trash = account.get 'trashMailbox'
        if not trash?
            LayoutActionCreator  = require './layout_action_creator'
            LayoutActionCreator.alertError t 'message idelete no trash'
        else
            msg = message.toObject()
            observer = jsonpatch.observe msg
            delete msg.mailboxIDs[id] for id of msg.mailboxIDs
            msg.mailboxIDs[trash] = -1
            patches = jsonpatch.generate observer
            XHRUtils.messagePatch message.get('id'), patches, (error, message) ->
                if not error?
                    AppDispatcher.handleViewAction
                        type: ActionTypes.MESSAGE_DELETE
                        value: message
                if callback?
                    callback error

    move: (message, from, to, callback) ->
        msg = message.toObject()
        observer = jsonpatch.observe msg
        delete msg.mailboxIDs[from]
        msg.mailboxIDs[to] = -1
        patches = jsonpatch.generate observer
        XHRUtils.messagePatch message.get('id'), patches, (error, message) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGE
                    value: message
            if callback?
                callback error

    updateFlag: (message, flags, callback) ->
        msg = message.toObject()
        patches = jsonpatch.compare {flags: msg.flags}, {flags}
        XHRUtils.messagePatch message.get('id'), patches, (error, message) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGE
                    value: message
            if callback?
                callback error
