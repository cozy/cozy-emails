### global t ###
Immutable = require 'immutable'

{ActionTypes, AlertLevel} = require '../constants/app_constants'


_uniqID = 1
AUTOCLOSETIMER = 2000

###
    Private API
###

Notification = Immutable.Record
    id: undefined
    message: ""
    level: ActionTypes.INFO
    errors: []
    autoclose: true
    actions: []



notify = (state, level, message, options) ->
    if not message? or message.toString().trim() is ''
        # Throw an error to get the stack trace in server logs
        throw new Error 'Empty notification'

    id = "taskid-#{_uniqID++}"
    notif = new Notification(
        id: id
        message: message.toString()
        level: level
    ).merge options

    # @TODO this should be somewhere else
    unless options?.waitConfirmation
        setTimeout ->
            require('../redux_store').dispatch
                type: ActionTypes.CLICKED_TASK_OK
                value: id
        , AUTOCLOSETIMER

    return state.set(id, notif)


_makeMessage = (target, actionAndOK, errMsg)->
    subject = target?.subject

    if target.messageID and target.isDraft
        type = 'draft'
    else if target.messageID
        type = 'message'
    else if target.conversationID
        type = 'conversation'
    else if target.conversationIDs
        type = 'conversations'
        smart_count = target.conversationIDs.length
    else if target.messageIDs
        type = 'messages'
        smart_count = target.messageIDs.length
    else if target.messages
        smart_count = target.messages.length
        type = if smart_count > 1 then 'messages' else 'message'
        subject = target.messages[0].subject
    else
        throw new Error 'Wrong Usage : unrecognized target'

    return t "#{type} #{actionAndOK}",
        error: errMsg
        subject: subject or ''
        smart_count: smart_count


DEFAULT_STATE = Immutable.Map()

module.exports = (state = DEFAULT_STATE, action) ->

    switch action.type

        when ActionTypes.CLEAR_TOASTS
            return DEFAULT_STATE

        when ActionTypes.CLICKED_TASK_OK
            taskid = action.value
            return state.remove taskid

        when ActionTypes.SETTINGS_UPDATE_FAILURE
            {error} = action.value
            message = t('settings save error') + error
            return notify state, AlertLevel.ERROR, message

        when ActionTypes.MAILBOX_CREATE_SUCCESS
            return notify state, AlertLevel.SUCCESS, t("mailbox create ok")

        when ActionTypes.MAILBOX_CREATE_FAILURE
            message = "#{t("mailbox create ko")} #{error.message or error}"
            return notify state, AlertLevel.ERROR, message

        when ActionTypes.MAILBOX_UPDATE_SUCCESS
            return notify state, AlertLevel.SUCCESS, t("mailbox update ok")

        when ActionTypes.MAILBOX_UPDATE_FAILURE
            message = "#{t("mailbox update ko")} #{error.message or error}"
            return notify state, AlertLevel.ERROR, message

        when ActionTypes.MAILBOX_EXPUNGE_SUCCESS
            return notify state, AlertLevel.INFO, t("mailbox expunge ok")

        when ActionTypes.MAILBOX_EXPUNGE_FAILURE
            {error} = action.value
            return notify state, AlertLevel.ERROR, """
                #{t("mailbox expunge ko")} #{error.message or error}
            """

        when ActionTypes.REMOVE_ACCOUNT_SUCCESS
            return notify state, AlertLevel.ERROR, t('account removed')

        when ActionTypes.MESSAGE_SEND_FAILURE
            {error, action} = action.value
            if ActionTypes.MESSAGE_SEND_REQUEST is action
                msgKo = t "message action sent ko"
            else
                msgKo = t "message action draft ko"
            return notify state, AlertLevel.ERROR, "#{msgKo} #{error}"


        when ActionTypes.MESSAGE_TRASH_SUCCESS
            {target} = action.value
            message = _makeMessage target, 'delete ok'
            return notify state, AlertLevel.INFO, message

        when ActionTypes.MESSAGE_TRASH_FAILURE
            {target, error} = action.value
            message = _makeMessage target, 'delete ko', error
            return notify state, AlertLevel.ERROR, message, error

        when ActionTypes.MESSAGE_MOVE_SUCCESS
            {updated, silent} = action.value
            unless silent
                message = _makeMessage updated, 'move ok'
                return notify state, AlertLevel.INFO, message

        when ActionTypes.MESSAGE_MOVE_FAILURE
            {target, error} = action.value
            message = _makeMessage target, 'move ko', error
            return notify state, AlertLevel.ERROR, message, error


        # dont display a notification for MESSAGE_FLAG_SUCCESS
        when ActionTypes.MESSAGE_FLAGS_FAILURE
            {target, error} = action.value
            message = _makeMessage target, 'flag ko', error
            return notify state, AlertLevel.ERROR, message, error

        when ActionTypes.MESSAGE_FETCH_FAILURE
            {error} = action.value
            message = t 'message fetch failure'
            return notify state, AlertLevel.ERROR, message, error

        when ActionTypes.EDIT_ACCOUNT_SUCCESS
            return notify state, AlertLevel.INFO, t 'account updated'

        when ActionTypes.REFRESH_FAILURE
            {error} = action.value
            # @FIXME there was a wait AccountStore here
            # maybe we should merge these reducers

            if error.name is 'AccountConfigError'
                message = t "config error #{error.field}"
            else
                message = error.message or error.name or error

                message = message
            return notify state, AlertLevel.ERROR, message, error

        when ActionTypes.CREATE_CONTACT_SUCCESS
            {error, result} = action.value
            message = t 'contact create success',
                contact: result?.name or result?.address
            return notify state, AlertLevel.ERROR, message, error

        when ActionTypes.CREATE_CONTACT_FAILURE
            {error} = action.value
            message = t 'contact create error', {error}
            return notify state, AlertLevel.ERROR, message, error

        when ActionTypes.RECEIVE_REFRESH_NOTIF
            {message} = action.value
            message = "#{t 'notif new title'} #{message}"
            return notify state, AlertLevel.INFO, message

    return state
