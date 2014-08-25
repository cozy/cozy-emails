XHRUtils = require '../utils/XHRUtils'
AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'

module.exports = MailboxActionCreator =

    create: (inputValues) ->
        MailboxActionCreator._setNewMailboxWaitingStatus true

        XHRUtils.createMailbox inputValues, (error, mailbox) =>
            setTimeout ->
                MailboxActionCreator._setNewMailboxWaitingStatus false
                if error?
                    MailboxActionCreator._setNewMailboxError error
                else
                   AppDispatcher.handleViewAction
                        type: ActionTypes.ADD_MAILBOX
                        value: mailbox
            , 2000

    edit: (inputValues) ->
        MailboxActionCreator._setNewMailboxWaitingStatus true
        XHRUtils.editMailbox inputValues, (error, mailbox) =>
            setTimeout ->
                MailboxActionCreator._setNewMailboxWaitingStatus false
                if error?
                    MailboxActionCreator._setNewMailboxError error
                else
                   AppDispatcher.handleViewAction
                        type: ActionTypes.EDIT_MAILBOX
                        value: mailbox
            , 2000

    remove: (mailboxID) ->
       AppDispatcher.handleViewAction
            type: ActionTypes.REMOVE_MAILBOX
            value: mailboxID
        XHRUtils.removeMailbox mailboxID
        window.router.navigate '', true

    _setNewMailboxWaitingStatus: (status) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.NEW_MAILBOX_WAITING
            value: status

    _setNewMailboxError: (errorMessage) ->
       AppDispatcher.handleViewAction
            type: ActionTypes.NEW_MAILBOX_ERROR
            value: errorMessage

    selectMailbox: (mailboxID) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SELECT_MAILBOX
            value: mailboxID