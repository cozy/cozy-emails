{
    div, p, h3, h4, form, label, input, button, ul, li, a, span, i,
    fieldset, legend
} = React.DOM
classer = React.addons.classSet

MailboxList          = require './mailbox-list'
AccountActionCreator = require '../actions/account_action_creator'
AccountInput = require './account_config_input'

RouterMixin = require '../mixins/router_mixin'
LAC  = require '../actions/layout_action_creator'
classer = React.addons.classSet


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
        state = @_propsToState(@props)
        state.smtpAdvanced = false
        return state


    componentWillReceiveProps: (props) ->
        @setState @_propsToState(props)


    render: ->
        if @props.isWaiting then buttonLabel = t 'account saving'
        else if @props.selectedAccount? then buttonLabel = t "account save"
        else buttonLabel = t "account add"


        hasError = (fields) =>
            if not Array.isArray fields
                fields = [ fields ]
            errors = fields.some (field) => @state.errors[field]?
            return if errors then ' has-error' else ''

        getError = (field) =>
            if @state.errors[field]?
                div
                    className: 'col-sm-5 col-sm-offset-2 control-label',
                    @state.errors[field]

        cancelUrl = @buildUrl
            direction: 'first'
            action: 'default'
            fullWidth: true

        formClass = classer
            'form-horizontal': true
            'form-account': true
            'waiting': @props.isWaiting
        form className: formClass, method: 'POST',
            @renderError()
            fieldset null,
                legend null, t 'account identifiers'

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

            if @state.displayGMAILSecurity
                fieldset null,
                    legend null, t 'gmail security tile'
                    p null, t 'gmail security body', login: @state.login.value
                    p null,
                        a
                            target: '_blank',
                            href: "https://www.google.com/settings/security/lesssecureapps"
                            t 'gmail security link'

            AccountInput
                name: 'accountType'
                value: @linkState('accountType').value
                errors: @state.errors

            fieldset null,
                legend null, t 'account receiving server'

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
                    onInput: => @setState(imapManualPort: true)

                AccountInput
                    name: 'imapSSL'
                    value: @linkState('imapSSL').value
                    errors: @state.errors
                    type: 'checkbox'
                    onClick: (ev) =>
                        @_onServerParam ev.target, 'imap', 'ssl'

                AccountInput
                    name: 'imapTLS'
                    value: @linkState('imapTLS').value
                    errors: @state.errors
                    type: 'checkbox'
                    onClick: (ev) =>
                        @_onServerParam ev.target, 'imap', 'tls'

            fieldset null,
                legend null, t 'account sending server'

                AccountInput
                    name: 'smtpServer'
                    value: @linkState('smtpServer').value
                    errors: @state.errors
                    errorField: ['smtp', 'smtpServer', 'smtpPort', 'smtpLogin', 'smtpPassword']

                AccountInput
                    name: 'smtpPort'
                    value: @linkState('smtpPort').value
                    errors: @state.errors
                    onBlur: @_onSMTPPort
                    onInput: => @setState(smtpManualPort: true)

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
                    div
                        key: "account-input-smtpMethod",
                        className: "form-group account-item-smtpMethod ",
                            label
                                htmlFor: "mailbox-smtpMethod",
                                className: "col-sm-2 col-sm-offset-2 control-label",
                                t "account smtpMethod"
                            div className: 'col-sm-3',
                                div className: "dropdown",
                                    button
                                        id: "mailbox-smtpMethod",
                                        name: "mailbox-smtpMethod",
                                        className: "btn btn-default dropdown-toggle"
                                        type: "button"
                                        "data-toggle": "dropdown",
                                        t "account smtpMethod #{@state.smtpMethod.value}"
                                    ul className: "dropdown-menu", role: "menu",
                                        ['PLAIN', 'NONE', 'LOGIN', 'CRAM-MD5'].map (method) =>
                                            li
                                                role: "presentation",
                                                    a
                                                        'data-value': method,
                                                        role: "menuitem",
                                                        onClick: @onMethodChange,
                                                        t "account smtpMethod #{method}"

                if @state.smtpAdvanced
                    AccountInput
                        name: 'smtpLogin'
                        value: @linkState('smtpLogin').value
                        errors: @state.errors
                        errorField: ['smtp', 'smtpServer', 'smtpPort', 'smtpLogin', 'smtpPassword']

                if @state.smtpAdvanced
                    AccountInput
                        name: 'smtpPassword'
                        value: @linkState('smtpPassword').value
                        type: 'password'
                        errors: @state.errors
                        errorField: ['smtp', 'smtpServer', 'smtpPort', 'smtpLogin', 'smtpPassword']

            fieldset null,
                legend null, t 'account actions'
            div className: '',
                div className: 'col-sm-offset-4',
                    button
                        className: 'btn btn-cozy action-save',
                        onClick: @props.onSubmit,
                        buttonLabel
                    if @state.id? and @state.id.value?
                        button
                            className: 'btn btn-cozy-non-default action-check',
                            onClick: @onCheck,
                            t 'account check'
                if @state.id? and @state.id.value?
                    fieldset null,
                        legend null, t 'account danger zone'
                        div className: 'col-sm-offset-4',
                            button
                                className: 'btn btn-default btn-danger btn-remove',
                                onClick: @onRemove,
                                t "account remove"


    # Check current parameters
    onCheck: (event) ->
        @props.onSubmit event, true


    onMethodChange: (event) ->
        @state.smtpMethod.requestChange event.target.dataset.value


    onRemove: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        if window.confirm(t 'account remove confirm')
            AccountActionCreator.remove @props.selectedAccount.get('id')


    toggleSMTPAdvanced: ->
        @setState smtpAdvanced: not @state.smtpAdvanced


    # Ask to main layout manager to display error as notification toasters.
    renderError: ->
        if @props?.error and @props.error.name is 'AccountConfigError'
            message = t 'config error ' + @props.error.field
            LAC.alertError message

        else if @props?.error
            LAC.alertError @props.error.message

        else if Object.keys(@state.errors).length isnt 0
            LAC.alertError t 'account errors'


    discover: (event) ->
        @props.validateForm event

        login = @state.login.value

        if login isnt @_lastDiscovered
            AccountActionCreator.discover login.split('@')[1],
            (err, provider) =>
                if not err?
                    infos = {}
                    getInfos = (server) ->
                        if server.type is 'imap' and not infos.imapServer?
                            infos.imapServer = server.hostname
                            infos.imapPort   = server.port
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
                            infos.smtpPort   = server.port
                            if server.socketType is 'SSL'
                                infos.smtpSSL = true
                                infos.smtpTLS = false
                            else if server.socketType is 'STARTTLS'
                                infos.smtpSSL = false
                                infos.smtpTLS = true
                            else if server.socketType is 'plain'
                                infos.smtpSSL = false
                                infos.smtpTLS = false
                    getInfos server for server in provider
                    if not infos.imapServer?
                        infos.imapServer = ''
                        infos.imapPort   = '993'
                    if not infos.smtpServer?
                        infos.smtpServer = ''
                        infos.smtpPort   = '465'
                    if not infos.imapSSL
                        switch infos.imapPort
                            when '993'
                                infos.imapSSL = true
                                infos.imapTLS = false
                            else
                                infos.imapSSL = false
                                infos.imapTLS = false
                    if not infos.smtpSSL
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
                    isGmail = infos.imapServer is 'imap.googlemail.com'
                    @setState displayGMAILSecurity: isGmail

                    for key, val of infos
                        @state[key].requestChange val
                    @props.validateForm()

            @_lastDiscovered = login


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


    _onIMAPPort: (ev) ->
        port = ev.target.value.trim()
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


    _onSMTPPort: (ev) ->
        port = ev.target.value.trim()
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
