XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

AccountStore = require '../stores/account_store'
LayoutActionCreator = null
MessageActionCreator = require './message_action_creator'

alertError = (error) ->
    LayoutActionCreator = require '../actions/layout_action_creator'
    if error.name is 'AccountConfigError'
        message = t "config error #{error.field}"
        LayoutActionCreator.alertError message
    else
        # try to handle every possible case
        message = error.message or error.name or error
        LayoutActionCreator.alertError message

module.exports = AccountActionCreator =

    create: (inputValues, afterCreation) ->
        AccountActionCreator._setNewAccountWaitingStatus true

        XHRUtils.createAccount inputValues, (error, account) ->
            if error? or not account?
                AccountActionCreator._setNewAccountError error
                if error?
                    alertError error
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.ADD_ACCOUNT
                    value: account

                afterCreation(AccountStore.getByID account.id)


    edit: (inputValues, accountID, callback) ->
        AccountActionCreator._setNewAccountWaitingStatus true

        account = AccountStore.getByID accountID
        newAccount = account.mergeDeep inputValues

        XHRUtils.editAccount newAccount, (error, rawAccount) ->
            if error?
                AccountActionCreator._setNewAccountError error
                alertError error
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.EDIT_ACCOUNT
                    value: rawAccount
                LayoutActionCreator = require '../actions/layout_action_creator'
                LayoutActionCreator.notify t('account updated'), autoclose: true
                callback?()

    check: (inputValues, accountID, cb) ->
        if accountID?
            account = AccountStore.getByID accountID
            newAccount = account.mergeDeep(inputValues).toJS()
        else
            newAccount = inputValues

        XHRUtils.checkAccount newAccount, (error, rawAccount) ->
            if error?
                AccountActionCreator._setNewAccountError error
                alertError error
            else
                LayoutActionCreator = require '../actions/layout_action_creator'
                LayoutActionCreator.notify t('account checked'), autoclose: true
            if cb?
                cb error, rawAccount

    remove: (accountID) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.REMOVE_ACCOUNT
            value: accountID
        XHRUtils.removeAccount accountID
        LayoutActionCreator = require '../actions/layout_action_creator'
        LayoutActionCreator.notify t('account removed'), autoclose: true
        window.router.navigate '', trigger: true

    _setNewAccountWaitingStatus: (status) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.NEW_ACCOUNT_WAITING
            value: status

    _setNewAccountError: (errorMessage) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.NEW_ACCOUNT_ERROR
            value: errorMessage

    selectAccount: (accountID, mailboxID) ->
        changed = AccountStore.selectedIsDifferentThan accountID, mailboxID

        AppDispatcher.handleViewAction
            type: ActionTypes.SELECT_ACCOUNT
            value:
                accountID: accountID
                mailboxID: mailboxID

        selected = AccountStore.getSelected()
        supportRFC4551 = selected?.get('supportRFC4551')

        if mailboxID? and changed and supportRFC4551
            MessageActionCreator.refreshMailbox(mailboxID)

    discover: (domain, callback) ->
        XHRUtils.accountDiscover domain, (err, infos) ->
            if not infos?
                infos = []
            callback err, infos

    mailboxCreate: (inputValues, callback) ->
        XHRUtils.mailboxCreate inputValues, (error, account) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_CREATE
                    value: account
            if callback?
                callback error

    mailboxUpdate: (inputValues, callback) ->
        XHRUtils.mailboxUpdate inputValues, (error, account) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_UPDATE
                    value: account
            if callback?
                callback error


    mailboxDelete: (inputValues, callback) ->
        XHRUtils.mailboxDelete inputValues, (error, account) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_DELETE
                    value: account
            if callback?
                callback error

    mailboxExpunge: (inputValues, callback) ->
        # delete message from local store to refresh display, we'll fetch them
        # again on error
        AppDispatcher.handleViewAction
            type: ActionTypes.MAILBOX_EXPUNGE
            value: inputValues.mailboxID

        XHRUtils.mailboxExpunge inputValues, (error, account) ->
            if callback?
                callback error
