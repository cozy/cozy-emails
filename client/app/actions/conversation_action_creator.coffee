AppDispatcher  = require '../app_dispatcher'
{ActionTypes}  = require '../constants/app_constants'
XHRUtils       = require '../utils/xhr_utils'
{MessageFlags} = require '../constants/app_constants'

module.exports =

    delete: (conversationID, callback) ->
        XHRUtils.conversationDelete conversationID, (error, messages) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGES
                    value: messages
            if callback?
                callback error

    move: (conversationID, to, callback) ->
        conversation =
            mailboxIDs: []
        observer = jsonpatch.observe conversation
        conversation.mailboxIDs.push to
        patches = jsonpatch.generate observer
        XHRUtils.conversationPatch conversationID, patches, (error, messages) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGES
                    value: messages
            if callback?
                callback error

    seen: (conversationID, flags, callback) ->
        conversation =
            flags: []
        observer = jsonpatch.observe conversation
        conversation.flags.push(MessageFlags.SEEN)
        patches = jsonpatch.generate observer
        XHRUtils.conversationPatch conversationID, patches, (error, messages) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGES
                    value: messages
            if callback?
                callback error

    unseen: (conversationID, flags, callback) ->
        conversation =
            flags: [MessageFlags.SEEN]
        observer = jsonpatch.observe conversation
        conversation.flags = []
        patches = jsonpatch.generate observer
        XHRUtils.conversationPatch conversationID, patches, (error, messages) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGES
                    value: messages
            if callback?
                callback error
