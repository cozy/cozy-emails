AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'
XHRUtils      = require '../utils/xhr_utils'
AccountStore  = require "../stores/account_store"
MessageStore  = require '../stores/message_store'

module.exports =

    receiveRawMessages: (messages) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGES
            value: messages

    receiveRawMessage: (message) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGE
            value: message

    setFetching: (fetching) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_FETCHING
            value: fetching

    send: (message, callback) ->
        XHRUtils.messageSend message, (error, message) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_SEND
                    value: message
            if callback?
                callback error, message

    delete: (message, callback) ->
        LayoutActionCreator = require './layout_action_creator'
        doDelete = (message) =>
            if typeof message is "string"
                message = MessageStore.getByID message
            # Move message to Trash folder
            account = AccountStore.getByID(message.get 'accountID')
            if not account?
                console.log "No account with id #{message.get 'accountID'} for message #{message.get 'id'}"
                LayoutActionCreator.alertError t 'app error'
                return
            trash = account.get 'trashMailbox'
            msg = message.toJSON()
            if not trash? or trash is ''
                LayoutActionCreator.alertError t 'message delete no trash'
            else if msg.mailboxIDs[trash]?
                LayoutActionCreator.alertError t 'message delete already'
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_ACTION
                    value:
                        id: message.get 'id'
                        from: Object.keys(msg.mailboxIDs)
                        to: trash
                observer = jsonpatch.observe msg
                delete msg.mailboxIDs[id] for id of msg.mailboxIDs
                msg.mailboxIDs[trash] = -1
                patches = jsonpatch.generate observer
                XHRUtils.messagePatch message.get('id'), patches, (err, message) =>
                    if not err?
                        AppDispatcher.handleViewAction
                            type: ActionTypes.MESSAGE_DELETE
                            value: msg
                    else
                        LayoutActionCreator.alertError "#{t("message action delete ko")} #{err}"
                    if not mass
                        options =
                            autoclose: true,
                            actions: [
                                label: t 'message undelete'
                                onClick: => @undelete()
                            ]
                        LayoutActionCreator.notify t('message action delete ok', subject: msg.subject), options
                        if callback?
                            callback err
        if Array.isArray message
            mass = true
            message.forEach doDelete
            if callback?
                callback()
        else
            mass = false
            doDelete message

    move: (message, from, to, callback) ->
        LayoutActionCreator = require './layout_action_creator'
        if from is to
            LayoutActionCreator.alertWarning t 'message move already'
            callback()
            return
        if typeof message is "string"
            message = MessageStore.getByID message
        msg = message.toJSON()
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_ACTION
            value:
                id: message.get 'id'
                from: from
                to: to
        observer = jsonpatch.observe msg
        delete msg.mailboxIDs[from]
        msg.mailboxIDs[to] = -1
        patches = jsonpatch.generate observer
        XHRUtils.messagePatch message.get('id'), patches, (error, message) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_RAW_MESSAGE
                    value: msg
            if callback?
                callback error

    undelete: ->
        LayoutActionCreator = require './layout_action_creator'
        action = MessageStore.getPrevAction()
        if action?
            if action.target is 'message'
                message = MessageStore.getByID action.id
                action.from.forEach (from) =>
                    @move message, action.to, from, (err) ->
                        if not err?
                            LayoutActionCreator.notify t('message undelete ok')
            else
                LayoutActionCreator.alertError t 'app unimplemented'
        else
            LayoutActionCreator.alertError t 'message undelete error'

    updateFlag: (message, flags, callback) ->
        msg = message.toJSON()
        patches = jsonpatch.compare {flags: msg.flags}, {flags}
        XHRUtils.messagePatch message.get('id'), patches, (error, messageUpdated) ->
            if not error?
                if not _.isEqual(flags, messageUpdated.flags)
                    AppDispatcher.handleViewAction
                        type: ActionTypes.RECEIVE_RAW_MESSAGE
                        value: messageUpdated
            if callback?
                callback error

        # dont wait for server response to display update
        setTimeout ->
            messageUpdated = message.toJS()
            messageUpdated.flags = flags
            AppDispatcher.handleViewAction
                type: ActionTypes.RECEIVE_RAW_MESSAGE
                value: messageUpdated
        , 0

    # set conv to true to update current conversation ID
    setCurrent: (messageID, conv) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_CURRENT
            value:
                messageID: messageID
                conv: conv
