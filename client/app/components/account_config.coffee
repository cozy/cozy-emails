{
    div, p, h3, h4, form, label, input, button, ul, li, a, span, i,
    fieldset, legend, img
} = React.DOM
classer = React.addons.classSet

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator = require '../actions/layout_action_creator'

RouterMixin = require '../mixins/router_mixin'
AccountConfigMain = require './account_config_main'

{Container, Title, Tabs} = require './basic_components'
AccountConfigMailboxes = require './account_config_mailboxes'
classer = React.addons.classSet


module.exports = React.createClass
    displayName: 'AccountConfig'

    _lastDiscovered: ''

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    _accountFields: [
        'id'
        'label'
        'name'
        'login'
        'password'
        'imapServer'
        'imapPort'
        'imapSSL'
        'imapTLS'
        'imapLogin'
        'smtpServer'
        'smtpPort'
        'smtpSSL'
        'smtpTLS'
        'smtpLogin'
        'smtpPassword'
        'smtpMethod'
        'accountType'
    ]

    _mailboxesFields: [
        'id'
        'mailboxes'
        'favoriteMailboxes'
        'draftMailbox'
        'sentMailbox'
        'trashMailbox'
    ]


    _accountSchema:
        properties:
            label: allowEmpty: false
            name: aLlowEmpty: false
            login: allowEmpty: false
            password: allowEmpty: false
            imapServer: allowEmpty: false
            imapPort: allowEmpty: false
            imapSSL: allowEmpty: true
            imapTLS: allowEmpty: true
            smtpServer: allowEmpty: false
            smtpPort: allowEmpty: false
            smtpSSL: allowEmpty: true
            smtpTLS: allowEmpty: true
            smtpLogin: allowEmpty: true
            smtpMethod: allowEmpty: true
            smtpPassword: allowEmpty: true
            draftMailbox: allowEmpty: true
            sentMailbox: allowEmpty: true
            trashMailbox: allowEmpty: true
            accountType: allowEmpty: true


    getInitialState: ->
        return @accountToState null


    shouldComponentUpdate: (nextProps, nextState) ->
        isNextState = _.isEqual nextState, @state
        isNextProps = _.isEqual nextProps, @props
        return not (isNextState and isNextProps)


    componentWillReceiveProps: (props) ->
        # prevents the form from changing during submission
        if props.selectedAccount? and not props.isWaiting
            @setState @accountToState props

        else

            if props.error?

                if props.error.name is 'AccountConfigError'
                    errors = {}
                    field = props.error.field

                    if field is 'auth'
                        errors.login = t 'config error auth'
                        errors.password = t 'config error auth'

                    else
                        errors[field] = t 'config error ' + field

                    @setState errors: errors
            else

                if not props.isWaiting and not _.isEqual(props, @props)
                    @setState @accountToState null


    render: ->
        mainOptions = @buildMainOptions()
        mailboxesOptions = @buildMailboxesOptions()
        titleLabel = @buildTitleLabel()
        tabParams = @buildTabParams()

        Container
            id: 'mailbox-config'
            key: "account-config-#{@props.selectedAccount?.get 'id'}"
        ,
            Title text: titleLabel
            if @props.tab?
                Tabs tabs: tabParams
            if not @props.tab or @props.tab is 'account'
                AccountConfigMain mainOptions
            else
                AccountConfigMailboxes mailboxesOptions


    # Build options shared by both tabs.
    buildMainOptions: (options) ->

        options =
            isWaiting: @props.isWaiting
            selectedAccount: @props.selectedAccount
            validateForm: @validateForm
            onSubmit: @onSubmit
            errors: @state.errors
            checking: @state.checking

        options[field] = @linkState field for field in @_accountFields

        return options


    # Build options required by mailbox tab.
    buildMailboxesOptions: (options) ->

        options =
            error: @props.error
            errors: @state.errors
            onSubmit: @onSubmit

        options[field] = @linkState field for field in @_mailboxesFields

        return options


    # Build tab panel title depending if we show the component for a new
    # account or for an edition.
    buildTitleLabel: ->
        if @state.id
            titleLabel = t "account edit"
        else
            titleLabel = t "account new"
        TitleLabel


    # Build tab navigation depending if we show the component for a new
    # account or for an edition (no tab navigation if we are in a creation
    # mode).
    buildTabParams: ->
        tabAccountClass = tabMailboxClass = ''
        tabAccountUrl = tabMailboxUrl = null

        if not @props.tab or @props.tab is 'account'
            tabAccountClass = 'active'
            tabMailboxUrl = @buildUrl
                direction: 'first'
                action: 'account.config'
                parameters: [@state.id, 'mailboxes']

        else
            tabMailboxClass = 'active'
            tabAccountUrl = @buildUrl
                direction: 'first'
                action: 'account.config'
                parameters: [@state.id, 'account']

        tabs = [
                class: tabAccountClass
                url: tabAccountUrl
                text: t "account tab account"
            ,
                class: tabMailboxClass
                url: tabMailboxUrl
                text: t "account tab mailboxes"
        ]

        return tabs


    # Form submission displays errors if form values are wrong.
    # If everything is ok, it runs the checking, the account edition and the
    # creation depending on the current state and if the user submitted it
    # with the check button.
    onSubmit: (event, check) ->
        event.preventDefault() if event?

        {accountValue, valid} = @validateForm()

        if valid.valid

            if check is true
                @checkAccount accountValue

            else if @state.id?
                @editAccount accountValue

            else
                @createAccount accountValue


    # Check wether form values are right. Then it displays or remove dispayed
    # errors dependning on the result.
    # To achieve that, it changes the state of the current component.
    # Returns form values and the valid object as result.
    validateForm: (event) ->
        event.preventDefault() if event?

        valid = valid: null
        accountValue = null

        if Object.keys(@state.errors).length isnt 0
            {accountValue, valid} = @doValidate()

            if valid.valid
                @setState errors: {}

            else
                errors = {}
                for error in valid.errors
                    errors[error.property] = t "validate #{error.message}"

                if Object.keys(errors).length > 0
                    LayoutActionCreator.alertError t 'account errors'

                @setState errors: errors

        return {accountValue, valid}


    # Check if all fields are valid. It returns an object with field values and
    # an object that lists all errors.
    doValidate: ->
        accountValue = {}
        accountValue[field] = @state[field] for field in @_accountFields
        accountValue[field] = @state[field] for field in @_mailboxesFields

        validOptions =
            additionalProperties: true
        valid = validate accountValue, @_accountSchema, validOptions

        return {accountValue, valid}


    # Run the account checking operation.
    checkAccount: (values) ->
        @setState checking: true
        AccountActionCreator.check values, @state.id, =>
            @setState checking: false


    # Save modification to the server.
    editAccount: (values) ->
        AccountActionCreator.edit values, @state.id


    # Create a new account and redirect user to the message list of this
    # account.
    createAccount: (values) ->
        AccountActionCreator.create values, (account) =>
            msg = t("account creation ok")

            LayoutActionCreator.notify msg,
                autoclose: true

            @redirect
                direction: 'first'
                action: 'account.config'
                parameters: [
                    account.get 'id'
                    'mailboxes'
                ]
                fullWidth: true


    # Build state from prop values.
    accountToState: (props) ->
        state =
            errors: {}

        if props?
            account = props.selectedAccount
            @buildErrorState state, props

        if account?
            @buildAccountState state, props, account

        else if Object.keys(state.errors).length is 0
            state = @buildDefaultState state

        return state


    # Set errors at state level.
    buildErrorState: (state, props) ->

        if props.error?

            if props.error.name is 'AccountConfigError'
                field = props.error.field

                if field is 'auth'
                    state.errors.login    = t 'config error auth'
                    state.errors.password = t 'config error auth'

                else
                    state.errors[field] = "#{t('config error ')}#{field}"


    # Build state based on current account values.
    buildAccountState: (state, props, account) ->

        if @state.id isnt account.get('id')

            state[field] = account.get field for field in @_accountFields
            state.smtpMethod = 'PLAIN' if not state.smtpMethod?

        state[field] = account.get field for field in @_mailboxesFields

        state.newMailboxParent = null
        state.mailboxes = props.mailboxes
        state.favoriteMailboxes = props.favoriteMailboxes

        props.tab = 'mailboxes' if state.mailboxes.length is 0


    # Build default state (required for account creation).
    buildDefaultState: ->
        state =
            errors: {}

        state[field] = '' for field in @_accountFields
        state[field] = '' for field in @_mailboxesFields
        state.id = null
        state.smtpPort = 465
        state.smtpSSL = true
        state.smtpTLS = false
        state.smtpMethod = 'PLAIN'
        state.imapPort = 993
        state.imapSSL = true
        state.imapTLS = false
        state.accountType = 'IMAP'
        state.newMailboxParent  = null
        state.favoriteMailboxes = null

        return state

