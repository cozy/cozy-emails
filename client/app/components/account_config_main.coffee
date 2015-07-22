{
    div, p, form, label, input, button, ul, li, a, span, i,
    fieldset, legend
} = React.DOM
classer = React.addons.classSet

AccountInput  = require './account_config_input'
AccountDelete = require './account_config_delete'
AccountActionCreator = require '../actions/account_action_creator'

RouterMixin = require '../mixins/router_mixin'
{Form, FieldSet, FormButtons, FormDropdown} = require './basic_components'


module.exports = AccountConfigMain = React.createClass
    displayName: 'AccountConfigMain'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]


    # Do not update component if nothing has changed.
    shouldComponentUpdate: (nextProps, nextState) ->
        isNextState = _.isEqual nextState, @state
        isNextProps = _.isEqual nextProps, @props
        return not (isNextState and isNextProps)


    getInitialState: ->
        state = {}
        state[key] = value for key, value of @props
        state.imapAdvanced = false
        state.smtpAdvanced = false
        return state


    componentWillReceiveProps: (props) ->
        state = {}
        state[key] = value for key, value of props

        if not @_lastDiscovered?
            # If editing account, init @_lastDiscovered with current domain
            # so we don't try to discover parameters if domain doesn't change
            login = state.login.value
            if state.id?.value? and login?.indexOf('@') >= 0
                @_lastDiscovered = login.split('@')[1]

        @setState state


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

        isOauth = @props.selectedAccount?.get('oauthProvider')?

        Form className: formClass,

            if isOauth
                p null, t 'account oauth'

            FieldSet text: t 'account identifiers'

            AccountInput
                name: 'label'
                value: @linkState('label').value
                errors: @state.errors
                onBlur: @props.onBlur

            AccountInput
                name: 'name'
                value: @linkState('name').value
                errors: @state.errors
                onBlur: @props.onBlur

            AccountInput
                name: 'login'
                value: @linkState('login').value
                errors: @state.errors
                type: 'email'
                errorField: ['login', 'auth']
                onBlur: @discover

            if not isOauth
                AccountInput
                    name: 'password'
                    value: @linkState('password').value
                    errors: @state.errors
                    type: 'password'
                    errorField: ['password', 'auth']
                    onBlur: @props.onBlur

            AccountInput
                name: 'accountType'
                className: 'hidden'
                value: @linkState('accountType').value
                errors: @state.errors

            if @state.displayGMAILSecurity
                url = "https://www.google.com/settings/security/lesssecureapps"
                [
                    FieldSet text: t 'gmail security tile'
                    p null, t('gmail security body', login: @state.login.value)
                    p null,
                        a
                            target: '_blank',
                            href: url
                            t 'gmail security link'
                ]


            if not isOauth
                @_renderReceivingServer()
            if not isOauth
                @_renderSendingServer()

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
                    onClick: @onCheck
                    icon: 'ellipsis-h'
                    text: t 'account check'
                ]

            if @props.selectedAccount?
                AccountDelete
                    selectedAccount: @props.selectedAccount


    _renderReceivingServer: ->
        advanced = if @state.imapAdvanced then 'hide' else 'show'
        div null,
            FieldSet text: t 'account receiving server'

            AccountInput
                name: 'imapServer'
                value: @linkState('imapServer').value
                errors: @state.errors
                errorField: ['imap', 'imapServer', 'imapPort']
                onBlur: @props.onBlur

            AccountInput
                name: 'imapPort'
                value: @linkState('imapPort').value
                errors: @state.errors
                onBlur: (event) =>
                    @_onIMAPPort(event)
                    @props.onBlur?()
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

            div
                className: "form-group advanced-imap-toggle",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable",
                    onClick: @toggleIMAPAdvanced,
                    t "account imap #{advanced} advanced"

            if @state.imapAdvanced
                AccountInput
                    name: 'imapLogin'
                    value: @linkState('imapLogin').value
                    errors: @state.errors
                    errorField: ['imap', 'imapServer', 'imapPort', 'imapLogin']


    _renderSendingServer: ->
        advanced = if @state.smtpAdvanced then 'hide' else 'show'
        div null,
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
                onBlur: @props.onBlur

            AccountInput
                name: 'smtpPort'
                value: @linkState('smtpPort').value
                errors: @state.errors
                errorField: ['smtp', 'smtpPort', 'smtpServer']
                onBlur: (event) =>
                    @_onSMTPPort(event)
                    @props.onBlur()
                onInput: =>
                    @setState smtpManualPort: true

            AccountInput
                name: 'smtpSSL'
                value: @linkState('smtpSSL').value
                errors: @state.errors
                errorField: ['smtp', 'smtpPort', 'smtpServer']
                type: 'checkbox'
                onClick: (ev) =>
                    @_onServerParam ev.target, 'smtp', 'ssl'

            AccountInput
                name: 'smtpTLS'
                value: @linkState('smtpTLS').value
                errors: @state.errors
                errorField: ['smtp', 'smtpPort', 'smtpServer']
                type: 'checkbox'
                onClick: (ev) =>
                    @_onServerParam ev.target, 'smtp', 'tls'

            div
                className: "form-group advanced-smtp-toggle",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable",
                    onClick: @toggleSMTPAdvanced,
                    t "account smtp #{advanced} advanced"

            if @state.smtpAdvanced
                FormDropdown
                    prefix: 'mailbox'
                    name: 'smtpMethod'
                    labelText: t "account smtpMethod"
                    defaultText: t "account smtpMethod #{@state.smtpMethod.value}"
                    values: ['NONE', 'CRAM-MD5', 'LOGIN', 'PLAIN']
                    onClick: @onMethodChange
                    methodPrefix: "account smtpMethod"
                    errorField: ['smtp', 'smtpAuth']

            if @state.smtpAdvanced
                AccountInput
                    name: 'smtpLogin'
                    value: @linkState('smtpLogin').value
                    errors: @state.errors
                    errorField: ['smtpAuth']

            if @state.smtpAdvanced
                AccountInput
                    name: 'smtpPassword'
                    value: @linkState('smtpPassword').value
                    type: 'password'
                    errors: @state.errors
                    errorField: ['smtpAuth']

    # Run form submission process described in parent component.
    # Check for errors before.
    onSubmit: (event) ->
        @props.onSubmit event, false


    # Run form submission process described in parent component. This one
    # checks that current parameters are working well.
    # Check for errors before.
    onCheck: (event) ->
        @props.onSubmit event, true


    onMethodChange: (event) ->
        @state.smtpMethod.requestChange event.target.dataset.value


    # Display or not SMTP advanced settings.
    toggleSMTPAdvanced: ->
        @setState smtpAdvanced: not @state.smtpAdvanced


    # Display or not IMAP advanced settings.
    toggleIMAPAdvanced: ->
        @setState imapAdvanced: not @state.imapAdvanced


    # Attempt to discover default values depending on target server.
    # The target server is guessed by the email given by the user.
    discover: (event) ->
        login = @state.login.value
        domain = login.split('@')[1] if login?.indexOf '@' >= 0

        if domain? and domain isnt @_lastDiscovered
            @_lastDiscovered = domain

            AccountActionCreator.discover domain, (err, provider) =>
                @setDefaultValues provider if not err?

        @props.onBlur?()


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

        @state.imapSSL.requestChange infos.imapSSL
        @state.imapTLS.requestChange infos.imapTLS


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

        @state.smtpSSL.requestChange infos.smtpSSL
        @state.smtpTLS.requestChange infos.smtpTLS

