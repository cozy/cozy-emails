React     = require 'react'
{div} = React.DOM

Immutable = require 'immutable'

AccountActionCreator = require '../actions/account_action_creator'
NotificationActionsCreator = require '../actions/notification_action_creator'

RouterGetter = require '../getters/router'

{Container, Title, Tabs} = require('./basic_components').factories
AccountDelete = React.createFactory require './account_config_delete'
AccountConfigMain = React.createFactory require './account_config_main'
AccountConfigMailboxes = React.createFactory require './account_config_mailboxes'
AccountConfigSignature = React.createFactory require './account_config_signature'

AccountStore         = require '../stores/account_store'
RouterStore         = require '../stores/router_store'
SettingsStore        = require '../stores/settings_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

{AccountActions} = require '../constants/app_constants'

REQUIRED_FIELDS = [
    'label', 'name', 'login', 'password', 'imapServer', 'imapPort',
    'smtpServer', 'smtpPort', 'smtpMethod'
]

TABS = ['account', 'mailboxes', 'signature']

module.exports = React.createClass
    displayName: 'AccountConfig'

    mixins: [
        StoreWatchMixin [SettingsStore, AccountStore]
    ]

    _lastDiscovered: ''

    getStateFromStores: ->
        nstate = {}

        # dont overwrite editedAccount when stores state changed
        nstate.serverErrors      = RouterStore.getErrors()
        nstate.selectedAccount   = RouterStore.getAccount()
        nstate.isWaiting         = RouterStore.isWaiting()
        nstate.isChecking        = RouterStore.isChecking()
        nstate.tab               = RouterGetter.getSelectedTab()

        unless (nstate.editedAccount = nstate.selectedAccount)
            nstate.editedAccount = AccountStore.makeEmptyAccount()

        unless @state
            nstate.isWaiting = false
            nstate.errors = Immutable.Map()
        else
            # the account has changed from the server
            if @state.selectedAccount isnt nstate.selectedAccount
                nedited = @state.editedAccount.merge nstate.selectedAccount
                nstate.editedAccount = nedited

            # new errors from the server
            if @state.serverErrors isnt nstate.serverErrors
                nstate.errors = nstate.serverErrors

        return nstate

    isNew: ->
        not @state.selectedAccount?

    onTabChangesDoSubmit: (changes) ->
        @onTabChanges changes
        @onSubmit()

    onTabChanges: (changes) ->
        nextstate =
            editedAccount: @state.editedAccount.merge changes
            errors: Immutable.Map()
        if @state.selectedAccount?
            validErrors = @getLocalValidationErrors nextstate.editedAccount
            nextstate.errors = Immutable.Map validErrors

        @setState nextstate

    render: ->
        title = if @isNew() then 'account new' else 'account edit'
        Container
            id: 'mailbox-config'
            expand: true,

            Title text: t title
            if (accountID = @state.editedAccount.get('id'))
                Tabs tabs: TABS.map (name) =>
                    class: if @state.tab is name then 'active' else ''
                    text: t "account tab #{name}"
                    url: RouterGetter.getURL
                        action: AccountActions.EDIT
                        accountID: accountID
                        tab: name

            switch @state.tab

                when 'signature'
                    AccountConfigSignature
                        account: @state.editedAccount
                        editedAccount: @state.editedAccount
                        requestChange: @onTabChanges
                        onSubmit: @onSubmit
                        errors: @state.errors
                        saving: false

                when 'mailboxes'
                    AccountConfigMailboxes
                        editedAccount: @state.editedAccount
                        requestChange: @onTabChangesDoSubmit
                        nomailboxesError: @state.errors
                        onSubmit: @onSubmit
                        errors: @state.errors

                else
                    AccountConfigMain
                        account: @state.editedAccount
                        requestChange: @onTabChanges
                        isWaiting: @state.isWaiting
                        checking: @state.isChecking
                        onSubmit: @onSubmit
                        errors: @state.errors

            if @state.editedAccount?.get('id')
                AccountDelete
                    editedAccount: @state.editedAccount

    getLocalValidationErrors: (accountWithChanges) ->
        out = {}
        requiredFields = REQUIRED_FIELDS

        for field in requiredFields
            unless accountWithChanges.get(field)
                out[field] = t "validate must not be empty"

        return out

    # Form submission displays errors if form values are wrong.
    # If everything is ok, it runs the checking, the account edition and the
    # creation depending on the current state and if the user submitted it
    # with the check button.
    onSubmit: (event, isCheck) ->
        event?.preventDefault()

        errors = @getLocalValidationErrors @state.editedAccount
        if Object.keys(errors).length
            NotificationActionsCreator.alertError t 'account errors'
            @setState submitted: true, errors: Immutable.Map(errors)
            return

        accountID = @state.editedAccount?.get('id')
        value = @state.editedAccount.toJS()
        if isCheck
            AccountActionCreator.check {accountID, value}
        else if accountID
            AccountActionCreator.edit {accountID, value}
        else
            AccountActionCreator.create {value}
