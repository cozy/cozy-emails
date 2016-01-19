XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

AccountStore = require '../stores/account_store'
LayoutActionCreator = null
MessageActionCreator = require './message_action_creator'

getLAC = ->
    LayoutActionCreator ?= require '../actions/layout_action_creator'
    return LayoutActionCreator

module.exports = AccountActionCreator =

    create: (inputValues, afterCreation) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.ADD_ACCOUNT_REQUEST
            value: {inputValues}

        XHRUtils.createAccount inputValues, (error, account) ->
            if error? or not account?
                AppDispatcher.handleViewAction
                    type: ActionTypes.ADD_ACCOUNT_FAILURE
                    value: {error}

            else if not account?
                AppDispatcher.handleViewAction
                    type: ActionTypes.ADD_ACCOUNT_FAILURE
                    value: {error: 'no account returned from create'}

            else
                # If one special mailbox is not configured, the user must
                # select before doing anything.
                areMailboxesConfigured = account.sentMailbox? and \
                                         account.draftMailbox? and \
                                         account.trashMailbox?

                AppDispatcher.handleViewAction
                    type: ActionTypes.ADD_ACCOUNT_SUCCESS
                    value: {account, areMailboxesConfigured}

                {id, inboxMailbox} = account
                if areMailboxesConfigured
                    filters = "sort/-date/nofilter/-/before/-/after/-"
                    url = "account/#{id}/mailbox/#{inboxMailbox}/#{filters}"
                else
                    url = "account/#{id}/config/mailboxes"

                window.router.navigate url, trigger: true


    edit: (inputValues, accountID, callback) ->
        newAccount = AccountStore.getByID(accountID).mergeDeep inputValues

        AppDispatcher.handleViewAction
            type: ActionTypes.EDIT_ACCOUNT_REQUEST
            value: {inputValues, newAccount}

        XHRUtils.editAccount newAccount, (error, rawAccount) ->
            if error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.EDIT_ACCOUNT_FAILURE
                    value: {error}
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.EDIT_ACCOUNT_SUCCESS
                    value: {rawAccount}

                callback?()

    check: (inputValues, accountID, cb) ->
        if accountID?
            account = AccountStore.getByID accountID
            newAccount = account.mergeDeep(inputValues).toJS()
        else
            newAccount = inputValues

        AppDispatcher.handleViewAction
            type: ActionTypes.CHECK_ACCOUNT_REQUEST
            value: {inputValues, newAccount}

        XHRUtils.checkAccount newAccount, (error, rawAccount) ->
            if error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.CHECK_ACCOUNT_FAILURE
                    value: {error}

            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.CHECK_ACCOUNT_SUCCESS
                    value: {rawAccount}

            cb? error, rawAccount

    remove: (accountID) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.REMOVE_ACCOUNT
            value: accountID
        XHRUtils.removeAccount accountID, (error) ->
        getLAC().notify t('account removed'), autoclose: true
        window.router.navigate '', trigger: true

    ensureSelected: (accountID, mailboxID) =>
        if AccountStore.selectedIsDifferentThan accountID, mailboxID
            AccountActionCreator.selectAccount accountID, mailboxID

    selectDefaultIfNoneSelected: () =>
        selectedAccount = AccountStore.getSelected()
        defaultAccount = AccountStore.getDefault()
        if not selectedAccount? and defaultAccount
            AccountActionCreator.selectAccount defaultAccount.get 'id'

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

    selectAccountForMessage: (message) =>
        # if there isn't a selected account (page loaded directly),
        # select the message's account
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount? and message?.accountID
            AccountActionCreator.selectAccount message.accountID

    discover: (domain, callback) ->
        XHRUtils.accountDiscover domain, callback

    mailboxCreate: (inputValues, callback) ->
        XHRUtils.mailboxCreate inputValues, (error, account) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_CREATE
                    value: account

                getLAC().alertSuccess t("mailbox create ok")

            else
                message = "#{t("mailbox create ko")} #{error.message or error}"
                getLAC().alertError message

            callback? error

    mailboxUpdate: (inputValues, callback) ->
        XHRUtils.mailboxUpdate inputValues, (error, account) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_UPDATE
                    value: account

                getLAC().alertSuccess t("mailbox update ok"),
            else
                message = "#{t("mailbox update ko")} #{error.message or error}"
                getLAC().alertError message
                    autoclose: true

            callback? error


    mailboxDelete: (inputValues, callback) ->
        XHRUtils.mailboxDelete inputValues, (error, account) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_DELETE
                    value: account
            if callback?
                callback error

    mailboxExpunge: (options) ->

        {accountID, mailboxID} = options

        # delete message from local store to refresh display, we'll fetch them
        # again on error
        AppDispatcher.handleViewAction
            type: ActionTypes.MAILBOX_EXPUNGE
            value: mailboxID

        XHRUtils.mailboxExpunge options, (error, account) ->

            if error?
                getLAC().alertError """
                    #{t("mailbox expunge ko")} #{error.message or error}
                """

                # if user hasn't switched to another box, refresh display
                unless AccountStore.selectedIsDifferentThan accountID, mailboxID
                    parameters = MessageStore.getQueryParams()
                    parameters.accountID = accountID
                    parameters.mailboxID = mailboxID
                    getLAC().showMessageList {parameters}

            else
                getLAC().notify t("mailbox expunge ok"),
                    autoclose: true
