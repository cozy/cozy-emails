{ActionTypes}   = require '../constants/app_constants'
XHRUtils        = require '../libs/xhr'

MessageActionCreator =

    receiveRawMessages: (dispatch, messages) ->
        dispatch
            type: ActionTypes.RECEIVE_RAW_MESSAGES
            value: messages


    receiveRawMessage: (dispatch, message) ->
        dispatch
            type: ActionTypes.RECEIVE_RAW_MESSAGE
            value: message


    displayImages: (dispatch, {messageID, displayImages=true})->
        dispatch
            type: ActionTypes.SETTINGS_UPDATE_REQUEST
            value: {messageID, displayImages}


    send: (dispatch, action, message) ->
        # Message should have a html content
        # event if it is a simple text
        unless message.composeInHTML
            message.html = message.text

        dispatch
            type: ActionTypes.MESSAGE_SEND_REQUEST
            value: message

        XHRUtils.messageSend message, (error, message) ->
            if error?
                dispatch
                    type: ActionTypes.MESSAGE_SEND_FAILURE
                    value: {error, action, message}
            else
                dispatch
                    type: ActionTypes.MESSAGE_SEND_SUCCESS
                    value: {action, message}


    markMessage: (dispatch, target, flags) ->
        timestamp = Date.now()

        dispatch
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, flags, timestamp}

        XHRUtils.batchFlag {target, action: flags}, (error, updated) ->
            if error
                dispatch
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, error, flags, timestamp}
            else
                dispatch
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, updated, flags, timestamp}


    # Delete message(s)
    # target:
    # - messageID or
    # - messageIDs or
    # - conversationIDs or
    # - conversationIDs
    deleteMessage: (dispatch, target={}) ->
        {messageID, accountID} = target
        return if not messageID? or not accountID?

        timestamp = Date.now()
        target = {messageID, accountID}

        dispatch
            type: ActionTypes.MESSAGE_TRASH_REQUEST
            value: {target}

        # send request
        XHRUtils.batchDelete target, (error, updated=[]) ->
            if error
                dispatch
                    type: ActionTypes.MESSAGE_TRASH_FAILURE
                    value: {target, error, updated}
            else
                message.updated = timestamp for message in updated
                dispatch
                    type: ActionTypes.MESSAGE_TRASH_SUCCESS
                    value: {target, updated}

module.exports = MessageActionCreator
