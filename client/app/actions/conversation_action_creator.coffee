AppDispatcher  = require '../app_dispatcher'
{ActionTypes}  = require '../constants/app_constants'
XHRUtils       = require '../utils/xhr_utils'
{MessageFlags} = require '../constants/app_constants'
LayoutActionCreator  = require './layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
AccountStore  = require "../stores/account_store"
MessageStore  = require '../stores/message_store'

doPatch = (conversationID, patches, callback) ->
    XHRUtils.conversationPatch conversationID, patches, (error, messages) ->
        if not error?
            AppDispatcher.handleViewAction
                type: ActionTypes.RECEIVE_RAW_MESSAGES
                value: messages
        if callback?
            callback error

module.exports =

    delete: (conversationID, callback) ->
        conversation = MessageStore.getConversation conversationID
        account = AccountStore.getByID(conversation.get(0).get 'accountID')
        trash   = account.get 'trashMailbox'
        if not trash? or trash is ''
            callback t('message delete no trash')
            return

        messages        = []
        messagesActions = []
        error           = ''
        conversation.map (message) ->
            mailboxIDs = message.get 'mailboxIDs'
            # Some messages of the conversation may already be in trash.
            # Do nothing if it is the case
            if not mailboxIDs[trash]?
                # action to allow undelete
                action =
                    id: message.get 'id'
                    from: Object.keys mailboxIDs
                    to: trash
                messagesActions.push action

                # move messages client-side to trash, to update UI
                # without waiting for server response
                msg = message.toJS()
                delete msg.mailboxIDs[id] for id of msg.mailboxIDs
                msg.mailboxIDs[trash] = -1
                messages.push msg

        .toJS()

        if error isnt ''
            callback error
            return

        # send requests ASAP
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
            msgOk = t('conversation delete ok', subject: messages[0].subject)
            LayoutActionCreator.notify msgOk, options
            if callback?
                callback error

        # Update datastore
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGES
            value: messages

        # Store action to allow undelete
        AppDispatcher.handleViewAction
            type: ActionTypes.CONVERSATION_ACTION
            value:
                messages: messagesActions

    move: (message, from, to, callback) ->
        if typeof message is 'string'
            message = MessageStore.getByID message
        # sometime, draft messages don't have a conversationID
        conversationID = message.get 'conversationID'
        if not conversationID?
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
            XHRUtils.conversationPatch msg.conversationID, patches,
                (error, messages) ->
                    if not error?
                        AppDispatcher.handleViewAction
                            type: ActionTypes.RECEIVE_RAW_MESSAGES
                            value: messages
                        options =
                            autoclose: true,
                            actions: [
                                label: t 'action undo'
                                onClick: -> MessageActionCreator.undelete()
                            ]
                        msgOk = t('conversation move ok',
                            subject: messages[0].subject)
                        LayoutActionCreator.notify msgOk, options
                    if callback?
                        callback error

            # move message without waiting for server response
            conversation = MessageStore.getConversation conversationID
            messages     = []
            conversation.map (message) ->
                msg = message.toJS()
                delete msg.mailboxIDs[from] for id of msg.mailboxIDs
                msg.mailboxIDs[to] = -1
                messages.push msg
            .toJS()
            AppDispatcher.handleViewAction
                type: ActionTypes.RECEIVE_RAW_MESSAGES
                value: messages

    seen: (conversationID, callback) ->
        conversation =
            flags: []
        observer = jsonpatch.observe conversation
        conversation.flags.push(MessageFlags.SEEN)
        patches = jsonpatch.generate observer
        doPatch conversationID, patches, callback

    unseen: (conversationID, callback) ->
        conversation =
            flags: [MessageFlags.SEEN]
        observer = jsonpatch.observe conversation
        conversation.flags = []
        patches = jsonpatch.generate observer
        doPatch conversationID, patches, callback

    flag: (conversationID, callback) ->
        conversation =
            flags: []
        observer = jsonpatch.observe conversation
        conversation.flags.push(MessageFlags.FLAGGED)
        patches = jsonpatch.generate observer
        doPatch conversationID, patches, callback

    noflag: (conversationID, callback) ->
        conversation =
            flags: [MessageFlags.FLAGGED]
        observer = jsonpatch.observe conversation
        conversation.flags = []
        patches = jsonpatch.generate observer
        doPatch conversationID, patches, callback

    fetch: (conversationID) ->
        XHRUtils.fetchConversation conversationID, (err, rawMessages) ->
            if not err?
                MessageActionCreator.receiveRawMessages rawMessages
