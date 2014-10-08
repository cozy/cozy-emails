XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

AccountStore = require '../stores/account_store'

module.exports = AccountActionCreator =

    create: (inputValues) ->
        AccountActionCreator._setNewAccountWaitingStatus true

        XHRUtils.createAccount inputValues, (error, account) ->
            # set a timeout to simulate the "waiting" state
            AccountActionCreator._setNewAccountWaitingStatus false
            console.log "THERE", account
            if error? or not account?
                AccountActionCreator._setNewAccountError error
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.ADD_ACCOUNT
                    value: account

    edit: (inputValues, accountID) ->
        AccountActionCreator._setNewAccountWaitingStatus true

        account = AccountStore.getByID accountID
        newAccount = account.mergeDeep inputValues

        XHRUtils.editAccount newAccount, (error, rawAccount) ->
            AccountActionCreator._setNewAccountWaitingStatus false
            if error?
                AccountActionCreator._setNewAccountError error
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.EDIT_ACCOUNT
                    value: rawAccount


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

    discover: (domain, callback) ->
        XHRUtils.accountDiscover domain, (err, infos) ->
            if not infos?
                infos = []
            callback err, infos

    mailboxCreate: (inputValues) ->
        XHRUtils.mailboxCreate inputValues, (error, account) ->
            if error? or not account?
                # @TODO
                console.log "error"
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_CREATE
                    value: account

    mailboxUpdate: (inputValues) ->
        XHRUtils.mailboxUpdate inputValues, (error, acount) ->
            if error? or not account?
                # @TODO
                console.log "error", error, account
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_UPDATE
                    value: account


    mailboxDelete: (inputValues) ->
        XHRUtils.mailboxDelete inputValues, (error, account) ->
            if error? or not account?
                # @TODO
                console.log "error"
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_DELETE
                    value: account
