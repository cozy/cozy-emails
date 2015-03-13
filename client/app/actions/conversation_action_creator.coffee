AppDispatcher  = require '../app_dispatcher'
{ActionTypes}  = require '../constants/app_constants'
XHRUtils       = require '../utils/xhr_utils'
{MessageFlags} = require '../constants/app_constants'
LayoutActionCreator  = require './layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
AccountStore  = require "../stores/account_store"
MessageStore  = require '../stores/message_store'

module.exports =

    delete: (conversationID, callback) ->
        conversation = MessageStore.getConversation conversationID
        account = AccountStore.getByID(conversation.get(0).get 'accountID')
        trash   = account.get 'trashMailbox'
        messages = conversation.map (message) ->
            action =
                id: message.get 'id'
                from: Object.keys(message.get 'mailboxIDs')
                to: trash
        .toJS()
        AppDispatcher.handleViewAction
            type: ActionTypes.CONVERSATION_ACTION
            value:
                messages: messages
        XHRUtils.conversationDelete conversationID, (error, messages) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGES
                    value: messages
            options =
                autoclose: true,
                actions: [
                    label: t 'conversation undelete'
                    onClick: -> MessageActionCreator.undelete()
                ]
            LayoutActionCreator.notify t('conversation delete ok'), options
            if callback?
                callback error

    move: (message, from, to, callback) ->
        # sometime, draft messages don't have a conversationID
        if not (message.get 'conversationID')?
            MessageActionCreator.move message, from, to, callback
        else
            msg = message.toJSON()
            AppDispatcher.handleViewAction
                type: ActionTypes.CONVERSATION_ACTION
                value:
                    id: msg.conversationID
                    from: from
                    to: to
            observer = jsonpatch.observe msg
            delete msg.mailboxIDs[from]
            msg.mailboxIDs[to] = -1
            patches = jsonpatch.generate observer
            XHRUtils.conversationPatch msg.conversationID, patches, (error, messages) ->
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
