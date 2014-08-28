XHRUtils = require '../utils/XHRUtils'
AppDispatcher = require '../AppDispatcher'
MailboxStore = require '../stores/MailboxStore'
{ActionTypes} = require '../constants/AppConstants'

module.exports = AccountActionCreator =

    create: (inputValues) ->
        AccountActionCreator._setNewAccountWaitingStatus true

        XHRUtils.createAccount inputValues, (error, account) ->
            # set a timeout to simulate the "waiting" state
            setTimeout ->
                AccountActionCreator._setNewAccountWaitingStatus false
                if error?
                    AccountActionCreator._setNewAccountError error
                else
                   AppDispatcher.handleViewAction
                        type: ActionTypes.ADD_ACCOUNT
                        value: account
            , 2000

    edit: (inputValues) ->
        AccountActionCreator._setNewAccountWaitingStatus true
        XHRUtils.editAccount inputValues, (error, account) ->
            # set a timeout to simulate the "waiting" state
            setTimeout ->
                AccountActionCreator._setNewAccountWaitingStatus false
                if error?
                    AccountActionCreator._setNewAccountError error
                else
                   AppDispatcher.handleViewAction
                        type: ActionTypes.EDIT_ACCOUNT
                        value: account
            , 2000

    remove: (accountID) ->
       AppDispatcher.handleViewAction
            type: ActionTypes.REMOVE_ACCOUNT
            value: accountID
        XHRUtils.removeAccount accountID
        window.router.navigate '', true

    _setNewAccountWaitingStatus: (status) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.NEW_ACCOUNT_WAITING
            value: status

    _setNewAccountError: (errorMessage) ->
       AppDispatcher.handleViewAction
            type: ActionTypes.NEW_ACCOUNT_ERROR
            value: errorMessage

    selectAccount: (accountID) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SELECT_ACCOUNT
            value: accountID
