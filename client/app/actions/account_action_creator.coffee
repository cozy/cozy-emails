{ActionTypes, OAuthDomains} = require '../constants/app_constants'

_ = require 'underscore'

AccountsUtils = require '../libs/accounts'
AppDispatcher = require '../libs/flux/dispatcher/dispatcher'
XHRUtils      = require '../libs/xhr'

AccountStore = require '../stores/account_store'
RouterStore  = require '../stores/router_store'



module.exports = AccountActionCreator =

    create: ({value}) ->
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

                modalTimer = setTimeout ->
                    AppDispatcher.dispatch
                        type: ActionTypes.CLOSE_MODAL,
                        value: {id: account.id, mailboxID: account.inboxMailbox}
                , 5000

                # We pass the timer so we can store and clear it in RouterStore
                AppDispatcher.dispatch
                    type: ActionTypes.ADD_ACCOUNT_SUCCESS
                    value: {account, areMailboxesConfigured, modalTimer}


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

    check: ({value: account, accountID}) ->
        if accountID
            account = AccountStore.getByID(accountID).mergeDeep(account).toJS()

        # Extract domain from login field, to compare w/ know OAuth-aware
        # domains
        [..., domain] = account.login.split '@'

        AppDispatcher.dispatch
            type: ActionTypes.CHECK_ACCOUNT_REQUEST
            value: {account}

        XHRUtils.checkAccount account, (error, res) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.CHECK_ACCOUNT_FAILURE
                    value:
                        error: error
                        oauth: domain if domain in _.keys OAuthDomains

            else
                AccountActionCreator.create value: account
                AppDispatcher.dispatch
                    type: ActionTypes.CHECK_ACCOUNT_SUCCESS
                    value: {res}

    remove: (accountID) ->
        AppDispatcher.dispatch
            type: ActionTypes.REMOVE_ACCOUNT_REQUEST
            value: accountID
        XHRUtils.removeAccount accountID, (error) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.REMOVE_ACCOUNT_FAILURE
                    value: {accountID}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.REMOVE_ACCOUNT_SUCCESS
                    value: {accountID}

    discover: (domain, config) ->
        AppDispatcher.dispatch
            type: ActionTypes.DISCOVER_ACCOUNT_REQUEST
            value: {domain}

        XHRUtils.accountDiscover domain, (error, provider) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.DISCOVER_ACCOUNT_FAILURE
                    value: {error, domain}

            # When discovering success, trigger the check auth action directly.
            # First, extend the minimal config (from view component) w/
            # providers from discovery and sanitize this new config (using the
            # same methods the view component uses by exploiting same mixins).
            # Also, dispatch a success event for the discovery action.
            else
                servers = AccountsUtils.parseProviders provider
                config  = AccountsUtils.sanitizeConfig _.extend config, servers

                AccountActionCreator.check value: config

                AppDispatcher.dispatch
                    type: ActionTypes.DISCOVER_ACCOUNT_SUCCESS
                    value: {domain, provider}

    saveEditTab: (tab) ->
        AppDispatcher.dispatch
            type: ActionTypes.EDIT_ACCOUNT_TAB
            value: {tab}


    mailboxCreate: (mailbox) ->
        AppDispatcher.dispatch
            type: ActionTypes.MAILBOX_CREATE_REQUEST
            value: mailbox
        XHRUtils.mailboxCreate mailbox, (error, mailbox) ->
            unless error?
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_CREATE_SUCCESS
                    value: mailbox
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_CREATE_FAILURE
                    value: mailbox


    mailboxUpdate: (mailbox) ->
        AppDispatcher.dispatch
            type: ActionTypes.MAILBOX_UPDATE_REQUEST
            value: mailbox
        XHRUtils.mailboxUpdate inputValues, (error, mailbox) ->
            unless error?
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_UPDATE_SUCCESS
                    value: mailbox
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MAILBOX_UPDATE_FAILURE
                    value: mailbox


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
