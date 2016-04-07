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
SettingsStore        = require '../stores/settings_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

{AccountActions} = require '../constants/app_constants'

REQUIRED_FIELDS_NEW = [
    'label', 'name', 'login', 'password', 'imapServer', 'imapPort',
    'smtpServer', 'smtpPort', 'smtpMethod'
]

REQUIRED_FIELDS_EDIT = REQUIRED_FIELDS_NEW

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
        nstate.serverErrors      = AccountStore.getErrors()
        nstate.selectedAccount   = AccountStore.getSelected()
        nstate.isWaiting         = AccountStore.isWaiting()
        nstate.isChecking        = AccountStore.isChecking()
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

    isOauth: ->
        @state.selectedAccount?.get('oauthProvider')?

    isNew: ->
        not @state.selectedAccount?

    onTabChangesDoSubmit: (changes) ->
        @onTabChanges changes, => @onSubmit()


    # FIXME : normalement on devrait supprimer ça
    # car l'url change à chaque fois
    onTabChanges: (changes, callback = ->) ->
        nextstate =
            editedAccount: @state.editedAccount.merge(changes)
            errors: Immutable.Map()

        if @state.selectedAccount?
            validErrors = @getLocalValidationErrors nextstate.editedAccount
            nextstate.errors = Immutable.Map validErrors

        @setState nextstate, callback

    render: ->
        Container
            id: 'mailbox-config'
            expand: true,

            Title text: t if @isNew() then 'account new' else 'account edit'
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
                        editedAccount: @state.editedAccount
                        isWaiting: @state.isWaiting
                        checking: @state.isChecking
                        onSubmit: @onSubmit
                        errors: @state.errors

            if @state.editedAccount?.get('id')
                AccountDelete
                    editedAccount: @state.editedAccount

    getLocalValidationErrors: (accountWithChanges) ->
        out = {}
        requiredFields = if @isNew() then REQUIRED_FIELDS_NEW
        else REQUIRED_FIELDS_EDIT

        for field in requiredFields
            unless accountWithChanges.get(field)
                out[field] = t "validate must not be empty"

        return out

    # Form submission displays errors if form values are wrong.
    # If everything is ok, it runs the checking, the account edition and the
    # creation depending on the current state and if the user submitted it
    # with the check button.
    onSubmit: (event, check) ->
        event?.preventDefault()
        errors = @getLocalValidationErrors @state.editedAccount

        id = @state.editedAccount?.get('id')
        accountValue = @state.editedAccount.toJS()

        if Object.keys(errors).length > 0
            NotificationActionsCreator.alertError t 'account errors'
            @setState submitted: true, errors: Immutable.Map(errors)

        else if check is true
            AccountActionCreator.check accountValue, id

        else if id
            AccountActionCreator.edit accountValue, id

        else
            AccountActionCreator.create accountValue
