{ActionTypes, OAuthDomains} = require '../constants/app_constants'

_ = require 'underscore'

AccountsUtils = require '../libs/accounts'
XHRUtils      = require '../libs/xhr'

AccountGetter = require '../getters/account'


###
FIXME: making sagas with default Flux lib is a little bit tricky. Currently,
       adding a new account is splited in 3 parts : 1/ (optionnal) try to
       discover params ; 2/ check the authentication against servers ; 3/ create
       account in the DS.
       We choose a temporary solution to automate call to next step on success
       by calling actions directly inside ActionCreator. This is a not so good
       pattern, so we need to fix it later when transitioning to a more modern
       store framework (like Redux + Sagas).
###

module.exports = AccountActionCreator = (dispatch, state) ->

    create: ({value}) ->
        dispatch
            type: ActionTypes.ADD_ACCOUNT_REQUEST
            value: {value}

        XHRUtils.createAccount value, (error, account) ->
            if error?
                dispatch
                    type: ActionTypes.ADD_ACCOUNT_FAILURE
                    value: {error}

            else if not account?
                dispatch
                    type: ActionTypes.ADD_ACCOUNT_FAILURE
                    value: {error: 'no account returned from create'}

            else
                # If one special mailbox is not configured, the user must
                # select before doing anything.
                areMailboxesConfigured = account.sentMailbox? and \
                                         account.draftMailbox? and \
                                         account.trashMailbox?

                dispatch
                    type: ActionTypes.ADD_ACCOUNT_SUCCESS
                    value: {account, areMailboxesConfigured}


    edit: ({value, accountID}) ->
        newAccount = AccountGetter.getByID(state, accountID).mergeDeep value

        dispatch
            type: ActionTypes.EDIT_ACCOUNT_REQUEST
            value: {value, newAccount}

        XHRUtils.editAccount newAccount, (error, rawAccount) ->
            if error?
                dispatch
                    type: ActionTypes.EDIT_ACCOUNT_FAILURE
                    value: {error}
            else
                dispatch
                    type: ActionTypes.EDIT_ACCOUNT_SUCCESS
                    value: {rawAccount}

    check: ({value: account, accountID}) ->
        if accountID
            account = AccountGetter.getByID(state,accountID)
            .mergeDeep(account).toJS()

        # Extract domain from login field, to compare w/ know OAuth-aware
        # domains
        [..., domain] = account.login.split '@'

        dispatch
            type: ActionTypes.CHECK_ACCOUNT_REQUEST
            value: {account}

        XHRUtils.checkAccount account, (error, res) ->
            if error?
                dispatch
                    type: ActionTypes.CHECK_ACCOUNT_FAILURE
                    value:
                        error: error
                        oauth: domain if domain in _.keys OAuthDomains

            else
                AccountActionCreator.create value: account
                dispatch
                    type: ActionTypes.CHECK_ACCOUNT_SUCCESS
                    value: {res}

    remove: (accountID) ->
        dispatch
            type: ActionTypes.REMOVE_ACCOUNT_REQUEST
            value: accountID
        XHRUtils.removeAccount accountID, (error) ->
            if error
                dispatch
                    type: ActionTypes.REMOVE_ACCOUNT_FAILURE
                    value: {accountID}
            else
                dispatch
                    type: ActionTypes.REMOVE_ACCOUNT_SUCCESS
                    value: {accountID}

    discover: (domain, config) ->
        dispatch
            type: ActionTypes.DISCOVER_ACCOUNT_REQUEST
            value: {domain}

        XHRUtils.accountDiscover domain, (error, provider) ->
            if error
                dispatch
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

                dispatch
                    type: ActionTypes.DISCOVER_ACCOUNT_SUCCESS
                    value: {domain, provider}

    # FIXME: move this elsewhere
    # Action is not a getter/setter!
    saveEditTab: (tab) ->
        dispatch
            type: ActionTypes.EDIT_ACCOUNT_TAB
            value: {tab}


    mailboxCreate: (mailbox) ->
        dispatch
            type: ActionTypes.MAILBOX_CREATE_REQUEST
            value: mailbox
        XHRUtils.mailboxCreate mailbox, (error, mailbox) ->
            unless error?
                dispatch
                    type: ActionTypes.MAILBOX_CREATE_SUCCESS
                    value: mailbox
            else
                dispatch
                    type: ActionTypes.MAILBOX_CREATE_FAILURE
                    value: mailbox


    mailboxUpdate: (mailbox) ->
        dispatch
            type: ActionTypes.MAILBOX_UPDATE_REQUEST
            value: mailbox
        XHRUtils.mailboxUpdate mailbox, (error, mailbox) ->
            unless error?
                dispatch
                    type: ActionTypes.MAILBOX_UPDATE_SUCCESS
                    value: mailbox
            else
                dispatch
                    type: ActionTypes.MAILBOX_UPDATE_FAILURE
                    value: mailbox



    mailboxDelete: (account) ->
        dispatch
            type: ActionTypes.MAILBOX_DELETE_REQUEST
            value: account
        XHRUtils.mailboxDelete account, (error, account) ->
            if error?
                dispatch
                    type: ActionTypes.MAILBOX_DELETE_FAILURE
                    value: account
            else
                dispatch
                    type: ActionTypes.MAILBOX_DELETE_SUCCESS
                    value: account


    mailboxExpunge: (options) ->
        {accountID, mailboxID} = options

        # delete message from local store to refresh display,
        # we'll fetch them again on error
        dispatch
            type: ActionTypes.MAILBOX_EXPUNGE_REQUEST
            value: mailboxID

        XHRUtils.mailboxExpunge options, (error) ->
            if error
                dispatch
                    type: ActionTypes.MAILBOX_EXPUNGE_FAILURE
                    value: {mailboxID, accountID, error}
            else
                dispatch
                    type: ActionTypes.MAILBOX_EXPUNGE_SUCCESS
                    value: {mailboxID, accountID}
