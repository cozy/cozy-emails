XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

AccountStore = require '../stores/account_store'
RouterStore = require '../stores/router_store'

LayoutActionCreator = require '../actions/layout_action_creator'
NotificationActionsCreator = require '../actions/notification_action_creator'
MessageActionCreator = require './message_action_creator'
RouterActionCreator = require './router_action_creator'

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

                RouterActionCreator.navigate {url}


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
        NotificationActionsCreator.alert t('account removed'), autoclose: true
        RouterActionCreator.navigate url: ''

    ensureSelected: (accountID, mailboxID) =>
        if AccountStore.selectedIsDifferentThan accountID, mailboxID
            AccountActionCreator.selectAccount accountID, mailboxID

    selectAccount: (accountID) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SELECT_ACCOUNT
            value: {accountID}

    saveEditTab: (tab) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.EDIT_ACCOUNT_TAB
            value: {tab}

    mailboxCreate: (inputValues, callback) ->
        XHRUtils.mailboxCreate inputValues, (error, account) ->
            unless error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_CREATE
                    value: account

                NotificationActionsCreator.alertSuccess t("mailbox create ok")

            else
                message = "#{t("mailbox create ko")} #{error.message or error}"
                NotificationActionsCreator.alertError message

            callback? error

    mailboxUpdate: (inputValues, callback) ->
        XHRUtils.mailboxUpdate inputValues, (error, account) ->
            unless error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MAILBOX_UPDATE
                    value: account

                NotificationActionsCreator.alertSuccess t("mailbox update ok"),
            else
                message = "#{t("mailbox update ko")} #{error.message or error}"
                NotificationActionsCreator.alertError message
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

        # delete message from local store to refresh display,
        # we'll fetch them again on error
        AppDispatcher.handleViewAction
            type: ActionTypes.MAILBOX_EXPUNGE
            value: mailboxID

        XHRUtils.mailboxExpunge options, (error, account) ->
            # FIXME : handle redirect

            # if error?
            #     NotificationActionsCreator.alertError """
            #         #{t("mailbox expunge ko")} #{error.message or error}
            #     """
            #
            #     # if user hasn't switched to another box, refresh display
            #     unless AccountStore.selectedIsDifferentThan accountID, mailboxID
            #         parameters = RouterStore.getFilter()
            #         parameters.accountID = accountID
            #         parameters.mailboxID = mailboxID
            #         LayoutActionCreator.updateessageList {parameters}
            #
            # else
            #     NotificationActionsCreator.alert t("mailbox expunge ok"),
            #         autoclose: true
