{
    div, p, h3, h4, form, label, input, button, ul, li, a, span, i,
    fieldset, legend
} = React.DOM
classer = React.addons.classSet

MailboxList          = require './mailbox-list'
AccountActionCreator = require '../actions/account_action_creator'
AccountInput = require './account_config_input'

RouterMixin = require '../mixins/router_mixin'
LayoutActionCreator = require '../actions/layout_action_creator'
{Form, FieldSet, FormButtons, FormDropdown} = require './basic_components'


state = null

module.exports = AccountConfigMain = React.createClass
    displayName: 'AccountConfigMain'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]


    # Do not update component twice if it is already updating.
    shouldComponentUpdate: (nextProps, nextState) ->
        isNextState = not _.isEqual nextState, @state
        isNextProps = not _.isEqual nextProps, @props
        return not (isNextState and isNextProps)


    _propsToState: (props) ->
        state = props
        return state


    getInitialState: ->
        state = @_propsToState @props
        state.smtpAdvanced = false
        return state


    componentWillReceiveProps: (props) ->
        @setState @_propsToState(props)


    buildButtonLabel: ->
        if @props.isWaiting
            buttonLabel = t 'account saving'

        else if @props.selectedAccount?
            buttonLabel = t "account save"

        else
            buttonLabel = t "account add"

        return buttonLabel


    render: ->
        buttonLabel = @buildButtonLabel()

        formClass = classer
            'form-horizontal': true
            'form-account': true
            'waiting': @props.isWaiting

        Form className: formClass,

            FieldSet text: t 'account identifiers'

            AccountInput
                name: 'label'
                value: @linkState('label').value
                errors: @state.errors
                validateForm: @props.validateForm

            AccountInput
                name: 'name'
                value: @linkState('name').value
                errors: @state.errors
                validateForm: @props.validateForm

            AccountInput
                name: 'login'
                value: @linkState('login').value
                errors: @state.errors
                type: 'email'
                errorField: ['login', 'auth']
                validateForm: @props.validateForm
                onBlur: @discover

            AccountInput
                name: 'password'
                value: @linkState('password').value
                errors: @state.errors
                type: 'password'
                errorField: ['password', 'auth']
                validateForm: @props.validateForm

            AccountInput
                name: 'accountType'
                value: @linkState('accountType').value
                errors: @state.errors

            if @state.displayGMAILSecurity
                FieldSet text: t 'gmail security tile'
                p null, t('gmail security body', login: @state.login.value)
                p null,
                    a
                        target: '_blank',
                        href: "https://www.google.com/settings/security/lesssecureapps"
                        t 'gmail security link'


            FieldSet text: t 'account receiving server'

            AccountInput
                name: 'imapServer'
                value: @linkState('imapServer').value
                errors: @state.errors
                errorField: ['imap', 'imapServer', 'imapPort']

            AccountInput
                name: 'imapPort'
                value: @linkState('imapPort').value
                errors: @state.errors
                onBlur: @_onimapPort
                onInput: =>
                    @setState imapManualPort: true

            AccountInput
                name: 'imapSSL'
                value: @linkState('imapSSL').value
                errors: @state.errors
                type: 'checkbox'
                onClick: (event) =>
                    @_onServerParam event.target, 'imap', 'ssl'

            AccountInput
                name: 'imapTLS'
                value: @linkState('imapTLS').value
                errors: @state.errors
                type: 'checkbox'
                onClick: (event) =>
                    @_onServerParam event.target, 'imap', 'tls'


            FieldSet text: t 'account sending server'

            AccountInput
                name: 'smtpServer'
                value: @linkState('smtpServer').value
                errors: @state.errors
                errorField: [
                    'smtp'
                    'smtpServer'
                    'smtpPort'
                    'smtpLogin'
                    'smtpPassword'
                ]

            AccountInput
                name: 'smtpPort'
                value: @linkState('smtpPort').value
                errors: @state.errors
                onBlur: @_onSMTPPort
                onInput: =>
                    @setState smtpManualPort: true

            AccountInput
                name: 'smtpSSL'
                value: @linkState('smtpSSL').value
                errors: @state.errors
                type: 'checkbox'
                onClick: (ev) =>
                    @_onServerParam ev.target, 'smtp', 'ssl'

            AccountInput
                name: 'smtpTLS'
                value: @linkState('smtpTLS').value
                errors: @state.errors
                type: 'checkbox'
                onClick: (ev) =>
                    @_onServerParam ev.target, 'smtp', 'tls'

            div
                className: "form-group",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable",
                    onClick: @toggleSMTPAdvanced,
                    t "account smtp #{if @state.smtpAdvanced then 'hide' else 'show'} advanced"

            if @state.smtpAdvanced
                FormDropdown
                    prefix: 'mailbox'
                    name: 'smtpMethod'
                    labelText: t "account smtpMethod"
                    defaultText: t "account smtpMethod #{@state.smtpMethod.value}"
                    values: ['CRAM-MD5', 'LOGIN', 'NONE', 'PLAIN']
                    onClick: @onMethodChange
                    methodPrefix: "account smtpMethod"

            if @state.smtpAdvanced
                AccountInput
                    name: 'smtpLogin'
                    value: @linkState('smtpLogin').value
                    errors: @state.errors
                    errorField: [
                        'smtp'
                        'smtpServer'
                        'smtpPort'
                        'smtpLogin'
                        'smtpPassword'
                    ]

            if @state.smtpAdvanced
                AccountInput
                    name: 'smtpPassword'
                    value: @linkState('smtpPassword').value
                    type: 'password'
                    errors: @state.errors
                    errorField: [
                        'smtp'
                        'smtpServer'
                        'smtpPort'
                        'smtpLogin'
                        'smtpPassword'
                    ]

            FieldSet text: t 'account actions'
            FormButtons
                buttons: [
                    class: 'action-save'
                    contrast: true
                    default: false
                    danger: false
                    spinner: false
                    icon: 'save'
                    onClick: @onSubmit
                    text: buttonLabel
                ,
                    class: 'action-check'
                    contrast: false
                    default: false
                    danger: false
                    spinner: @props.checking
                    icon: 'ellipsis-h'
                    text: t 'account check'
                ]

            if @props.selectedAccount?
                FieldSet text: t 'account danger zone'

            if @props.selectedAccount?
                FormButtons
                    buttons: [
                        class: 'btn-remove'
                        contrast: false
                        default: true
                        danger: true
                        onClick: @onRemove
                        spinner: false
                        icon: 'trash'
                        text: t "account remove"
                    ]

    # Ask to main layout manager to display error as notification toasters.
    renderError: ->
        if @props?.error and @props.error.name is 'AccountConfigError'
            message = t "config error #{@props.error.field}"
            LayoutActionCreator.alertError message

        else if @props?.error
            LayoutActionCreator.alertError @props.error.message

        else if Object.keys(@state.errors).length isnt 0
            LayoutActionCreator.alertError t 'account errors'


    # Run form submission process described in parent component.
    # Check for errors before.
    onSubmit: (event) ->
         @renderError()
         @props.onSubmit event, false


    # Run form submission process described in parent component. This one
    # checks that current parameters are working well.
    # Check for errors before.
    onCheck: (event) ->
        @renderError()
        @props.onSubmit event, true


    onMethodChange: (event) ->
        @state.smtpMethod.requestChange event.target.dataset.value


    # Ask for confirmation before running remove operation.
    onRemove: (event) ->
        event.preventDefault() if event?

        if window.confirm(t 'account remove confirm')
            AccountActionCreator.remove @props.selectedAccount.get('id')


    # Display or not SMTP advanced settings.
    toggleSMTPAdvanced: ->
        @setState smtpAdvanced: not @state.smtpAdvanced


    # Display or not IMAP advanced settings.
    toggleIMAPAdvanced: ->
        @setState imapAdvanced: not @state.imapAdvanced


    # Attempt to discover default values depending on target server.
    # The target server is guessed by the email given by the user.
    discover: (event) ->
        @props.validateForm event

        login = @state.login.value
        domain = login.split('@')[1] if login?.indexOf '@' >= 0

        if domain isnt @_lastDiscovered
            @_lastDiscovered = domain

            AccountActionCreator.discover domain, (err, provider) =>
                @setDefaultValues provider if not err?


    # Set default values based on ones given in parameter.
    setDefaultValues: (provider) ->
        infos = {}

        # Set values depending on given providers.
        for server in provider

            if server.type is 'imap' and not infos.imapServer?
                infos.imapServer = server.hostname
                infos.imapPort = server.port

                if server.socketType is 'SSL'
                    infos.imapSSL = true
                    infos.imapTLS = false

                else if server.socketType is 'STARTTLS'
                    infos.imapSSL = false
                    infos.imapTLS = true

                else if server.socketType is 'plain'
                    infos.imapSSL = false
                    infos.imapTLS = false

            if server.type is 'smtp' and not infos.smtpServer?
                infos.smtpServer = server.hostname
                infos.smtpPort = server.port

                if server.socketType is 'SSL'
                    infos.smtpSSL = true
                    infos.smtpTLS = false

                else if server.socketType is 'STARTTLS'
                    infos.smtpSSL = false
                    infos.smtpTLS = true

                else if server.socketType is 'plain'
                    infos.smtpSSL = false
                    infos.smtpTLS = false

        # Set default values if providers didn't give required infos.

        unless infos.imapServer?
            infos.imapServer = ''
            infos.imapPort   = '993'

        unless infos.smtpServer?
            infos.smtpServer = ''
            infos.smtpPort   = '465'

        unless infos.imapSSL
            switch infos.imapPort
                when '993'
                    infos.imapSSL = true
                    infos.imapTLS = false
                else
                    infos.imapSSL = false
                    infos.imapTLS = false

        unless infos.smtpSSL
            switch infos.smtpPort
                when '465'
                    infos.smtpSSL = true
                    infos.smtpTLS = false
                when '587'
                    infos.smtpSSL = false
                    infos.smtpTLS = true
                else
                    infos.smtpSSL = false
                    infos.smtpTLS = false

        # Display gmail warning if selected provider is Gmail.
        isGmail = infos.imapServer is 'imap.googlemail.com'
        @setState displayGMAILSecurity: isGmail

        # Apply built values to current state
        @state[key].requestChange val for key, val of infos

        # Run form validation.
        @props.validateForm()


    # Configure port automatically depending on selected paramerters.
    _onServerParam: (target, server, type) ->

        # port has been set manually, don't update it
        if not((server is 'imap' and @state.imapManualPort) or
        (server is 'smtp' and @state.smtpManualPort))

            if server is 'smtp'

                if type is 'ssl' and target.checked
                    @setState smtpPort: 465

                else if type is 'tls' and target.checked
                    @setState smtpPort: 587

            else

                if target.checked
                    @setState imapPort: 993

                else
                    @setState imapPort: 143


    # Force IMAP parameters when IMAP port changes.
    _onIMAPPort: (event) ->
        port = event.target.value.trim()
        infos =
            imapPort: port

        switch port

            when '993'
                infos.imapSSL = true
                infos.imapTLS = false

            else
                infos.imapSSL = false
                infos.imapTLS = false

        @setState infos


    # Force SMTP parameters when SMTP port changes.
    _onSMTPPort: (event) ->
        port = event.target.value.trim()
        infos = {}

        switch port

            when '465'
                infos.smtpSSL = true
                infos.smtpTLS = false

            when '587'
                infos.smtpSSL = false
                infos.smtpTLS = true

            else
                infos.smtpSSL = false
                infos.smtpTLS = false

        @setState infos

