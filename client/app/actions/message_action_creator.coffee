AppDispatcher = require '../app_dispatcher'
Constants = require '../constants/app_constants'
{ActionTypes, MessageFlags, FlagsConstants} = Constants
XHRUtils      = require '../utils/xhr_utils'
AccountStore  = require "../stores/account_store"
MessageStore  = require '../stores/message_store'
refCounter=1

module.exports = MessageActionCreator =

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
            callback? error, message

    # set conv to true to update current conversation ID
    setCurrent: (messageID, conv) ->
        if messageID? and typeof messageID isnt 'string'
            messageID = messageID.get 'id'
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_CURRENT
            value:
                messageID: messageID
                conv: conv

    fetchConversation: (conversationID) ->
        XHRUtils.fetchConversation conversationID, (err, rawMessages) ->
            if not err?
                MessageActionCreator.receiveRawMessages rawMessages

    # Immediately synchronise some messages with the server
    # Used if one of the action fail
    recover: (target, ref) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_RECOVER_REQUEST
            value: {ref, op, flag, flagAction}

        XHRUtils.batchFetch target, (err, messages) ->
            if err
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_RECOVER_FAILURE
                    value: {ref, op, flag, flagAction}
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_RECOVER_SUCCESS
                    value: {ref, op, flag, flagAction}

    refreshMailbox: (mailboxID) ->
        unless AccountStore.isMailboxRefreshing(mailboxID)
            AppDispatcher.handleViewAction
                type: ActionTypes.REFRESH_REQUEST
                value: {mailboxID}

            XHRUtils.refreshMailbox mailboxID, (error) ->
                if err?
                    AppDispatcher.handleViewAction
                       type: ActionTypes.REFRESH_FAILURE
                       value: {mailboxID, error}
                else
                    AppDispatcher.handleViewAction
                        type: ActionTypes.REFRESH_SUCCESS
                        value: {mailboxID}

    # Delete message(s)
    # target:
    #  - messageID or messageIDs or conversationIDs or conversationIDs
    #  - isDraft?
    #  - silent? (don't display confirmation message when deleting
    #    an empty draft)
    delete: (target, callback) ->
        ref = refCounter++
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_TRASH_REQUEST
            value: {target, ref}

        ts = Date.now()
        # send request
        XHRUtils.batchDelete target, (error, updated) =>
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_TRASH_FAILURE
                    value: {target, ref, error}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                msg.updated = ts for msg in updated
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_TRASH_SUCCESS
                    value: {target, ref, updated}


    move: (target, from, to, callback) ->
        ref = refCounter++
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_MOVE_REQUEST
            value: {target, ref, from, to}

        ts = Date.now()
        # send request
        XHRUtils.batchMove target, from, to, (error, updated) =>
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_MOVE_FAILURE
                    value: {target, ref, error}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                msg.updated = ts for msg in updated
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_MOVE_SUCCESS
                    value: {target, ref, updated}


    mark: (target, flagAction, callback) ->
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

        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, ref, op, flag, flagAction}

        ts = Date.now()

        XHRUtils[op] target, flag, (error, updated) =>
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, ref, error, op, flag, flagAction}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                msg.updated = ts for msg in updated
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, ref, updated, op, flag, flagAction}

    undo: ->

        lastBatch = MessageStore.getPrevAction()
        if lastBatch
            done = 0
            for action in lastBatch.actions
                options = {messageID: action.id, undeleting: true}
                done++
                @move options, action.to, action.from, (err) ->
                    if err
                        LAC.notify t('undo ko')
                    else if --done is 0
                        LAC.notify t('undo ok'),
                            autoclose: true
        else
            LAC.notify t('undo unavailable')

# circular, import after
LAC = require './layout_action_creator'
