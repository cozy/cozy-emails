XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../libs/flux/dispatcher/dispatcher'
{ActionTypes} = require '../constants/app_constants'

AccountStore = require '../stores/account_store'

module.exports = AccountActionCreator =

    create: (value) ->
        AppDispatcher.dispatch
            type: ActionTypes.ADD_ACCOUNT_REQUEST
            value: {value}

        XHRUtils.createAccount value, (error, account) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.ADD_ACCOUNT_FAILURE
                    value: {error}

            else if not account?
                AppDispatcher.dispatch
                    type: ActionTypes.ADD_ACCOUNT_FAILURE
                    value: {error: 'no account returned from create'}

            else
                # If one special mailbox is not configured, the user must
                # select before doing anything.
                areMailboxesConfigured = account.sentMailbox? and \
                                         account.draftMailbox? and \
                                         account.trashMailbox?

                AppDispatcher.dispatch
                    type: ActionTypes.ADD_ACCOUNT_SUCCESS
                    value: {account, areMailboxesConfigured}

    edit: ({value, accountID}) ->
        newAccount = AccountStore.getByID(accountID).mergeDeep value

        AppDispatcher.dispatch
            type: ActionTypes.EDIT_ACCOUNT_REQUEST
            value: {value, newAccount}

        XHRUtils.editAccount newAccount, (error, rawAccount) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.EDIT_ACCOUNT_FAILURE
                    value: {error}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.EDIT_ACCOUNT_SUCCESS
                    value: {rawAccount}

    check: ({value, accountID}) ->
        if accountID?
            account = AccountStore.getByID accountID
            newAccount = account.mergeDeep(value).toJS()
        else
            newAccount = value

        AppDispatcher.dispatch
            type: ActionTypes.CHECK_ACCOUNT_REQUEST
            value: {value, newAccount}

        XHRUtils.checkAccount newAccount, (error, rawAccount) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.CHECK_ACCOUNT_FAILURE
                    value: {error}

            else
                AppDispatcher.dispatch
                    type: ActionTypes.CHECK_ACCOUNT_SUCCESS
                    value: {rawAccount}

    remove: (accountID) ->
        AppDispatcher.dispatch
            type: ActionTypes.REMOVE_ACCOUNT_REQUEST
            value: accountID
        XHRUtils.removeAccount accountID, (error) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.REMOVE_ACCOUNT_FAILURE
                    value: accountID
            else
                AppDispatcher.dispatch
                    type: ActionTypes.REMOVE_ACCOUNT_SUCCESS
                    value: accountID

    discover: (domain) ->
        AppDispatcher.dispatch
            type: ActionTypes.DISCOVER_REQUEST
            value: {domain}
        XHRUtils.accountDiscover domain, (error, provider) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.DISCOVER_FAILURE
                    value: {error, domain}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.DISCOVER_SUCCESS
                    value: {domain, provider}

    saveEditTab: (tab) ->
        AppDispatcher.dispatch
            type: ActionTypes.EDIT_ACCOUNT_TAB
            value: {tab}

    mailboxCreate: (inputValues) ->
        AppDispatcher.dispatch
            type: ActionTypes.MAILBOX_CREATE_REQUEST
            value: account
        XHRUtils.mailboxCreate inputValues, (error, account) ->
            unless error?
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_CREATE_SUCCESS
                    value: account
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_CREATE_FAILURE
                    value: account

    mailboxUpdate: (inputValues) ->
        AppDispatcher.dispatch
            type: ActionTypes.MAILBOX_UPDATE_REQUEST
            value: account
        XHRUtils.mailboxUpdate inputValues, (error, account) ->
            unless error?
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_UPDATE_SUCCESS
                    value: account
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_UPDATE_FAILURE
                    value: account

    mailboxDelete: (inputValues) ->
        AppDispatcher.dispatch
            type: ActionTypes.MAILBOX_DELETE_REQUEST
            value: account
        XHRUtils.mailboxDelete inputValues, (error, account) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_DELETE_FAILURE
                    value: account
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_DELETE_SUCCESS
                    value: account


    mailboxExpunge: (options) ->
        {accountID, mailboxID} = options

        # delete message from local store to refresh display,
        # we'll fetch them again on error
        AppDispatcher.dispatch
            type: ActionTypes.MAILBOX_EXPUNGE_REQUEST
            value: mailboxID

        XHRUtils.mailboxExpunge options, (error, account) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_EXPUNGE_FAILURE
                    value: {mailboxID, accountID, error}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_EXPUNGE_SUCCESS
                    value: {mailboxID, accountID}
