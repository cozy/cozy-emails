AppDispatcher   = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes}   = require '../constants/app_constants'
XHRUtils        = require '../libs/xhr'

MessageGetters  = require '../getters/message'

MessageActionCreator =

    receiveRawMessages: (messages) ->
        AppDispatcher.dispatch
            type: ActionTypes.RECEIVE_RAW_MESSAGES
            value: messages


    receiveRawMessage: (message) ->
        AppDispatcher.dispatch
            type: ActionTypes.RECEIVE_RAW_MESSAGE
            value: message


    displayImages: ({messageID, displayImages=true})->
        AppDispatcher.dispatch
            type: ActionTypes.SETTINGS_UPDATE_REQUEST
            value: {messageID, displayImages}


    send: (action, message) ->
        # Message should have a html content
        # event if it is a simple text
        unless message.composeInHTML
            message.html = message.text

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_SEND_REQUEST
            value: message

        XHRUtils.messageSend message, (error, message) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_SEND_FAILURE
                    value: {error, action, message}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_SEND_SUCCESS
                    value: {action, message}


    mark: (target, flags) ->
        timestamp = Date.now()

        # Do not mark a removed message
        {messageID} = target
        if messageID and not (message = MessageGetters.getByID messageID)
            return

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, flags, timestamp}

        XHRUtils.batchFlag {target, action: flags}, (error, updated) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, error, flags, timestamp}
            else
                # Update _conversationLength value
                # that is only displayed by the server
                # with method fetchMessagesByFolder
                # FIXME: should be sent by server

                # FIXME: clent shouldnt add this information
                # it shoul be done server side
                updated = {messages: [message]}
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, updated, flags, timestamp}


    # Delete message(s)
    # target:
    # - messageID or
    # - messageIDs or
    # - conversationIDs or
    # - conversationIDs
    deleteMessage: (target={}) ->
        {messageID, accountID} = target
        return if not messageID? or not accountID?

        timestamp = Date.now()
        target = {messageID, accountID}

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_TRASH_REQUEST
            value: {target}

        # send request
        XHRUtils.batchDelete target, (error, updated=[]) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_TRASH_FAILURE
                    value: {target, error, updated}
            else
                message.updated = timestamp for message in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_TRASH_SUCCESS
                    value: {target, updated}

module.exports = MessageActionCreator
