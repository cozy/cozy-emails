React      = require 'react'

_ = require 'underscore'
Immutable = require 'immutable'

{div, p, ul, li, a, i} = React.DOM
{Form, FieldSet, FormButtons, FormButton} = require('./basic_components').factories
classNames = require 'classnames'

AccountInput  = React.createFactory require './account_config_input'
AccountActionCreator = require '../actions/account_action_creator'

GOOGLE_EMAIL = ['googlemail.com', 'gmail.com']
TRIMMEDFIELDS = ['imapServer', 'imapPort', 'smtpServer', 'smtpPort']

module.exports = AccountConfigMain = React.createClass
    displayName: 'AccountConfigMain'

    getDefaultProps: ->
        imapPort: '993'
        imapSSL: true
        imapTLS: false
        smtpPort: '465'
        smtpSSL: true
        imapAdvanced: false


    getInitialState: ->
        @getStateFromStores()


    componentWillReceiveProps: (nextProps) ->
        @setState @getStateFromStores nextProps


    handleChange: (name, value) ->
        nextProps = {}
        value = value.trim() if name in TRIMMEDFIELDS and value.trim
        nextProps[name] = value
        @props.requestChange nextProps


    getStateFromStores: (nextProps=@props) ->
        _isError = (field, value = '') ->
            nextProps.errors.get(field) and
            nextProps.editedAccount.get(field) isnt value

        # Check domain from login
        login = nextProps.account?.get 'login'
        if login and -1 < (index0 = login.indexOf '@')
            domain = login.substring index0 + 1, login.length

        # isGmail : test login
        if _.isString domain
            test = _.find GOOGLE_EMAIL, (value) -> -1 < domain.indexOf value
            isGmail = test?

        nextState =
            imapPort:       @props.account.get 'imapPort'
            imapSSL:        @props.account.get 'imapSSL'
            smtpPort:       @props.account.get 'smtpPort'
            smtpSSL:        @props.account.get 'smtpSSL'
            smtpTLS:        @props.account.get 'smtpTLS'
            imapPort:       @props.account.get 'imapPort'
            isOauth:        @props.account.get('oauthProvider')?
            domain:         domain
            isGmail:        isGmail
            imapAdvanced:   _isError('imapLogin') or
                            _isError('smtpLogin') or
                            _isError('smtpPassword') or
                            _isError('smtpMethod', 'PLAIN')

        # Toggle SSL : change ImapPort
        if nextState.imapSSL is false
            nextState.imapPort = '143'
        else if nextState.imapSSL is true
            nextState.imapPort = '993'

        # SMTP config
        isSmtpSSL = @state?.smtpSSL and nextState.smtpSSL is undefined
        smtpPort = if nextState.smtpSSL or isSmtpSSL then '465' else '25'
        nextState.smtpPort = smtpPort

        # Overwrite Smtp port if TLS is (ever) selected
        isSmtpTLS = @state?.smtpTLS and nextState.smtpTLS is undefined
        nextState.smtpPort = '587' if nextState.smtpTLS or isSmtpTLS

        nextState

    componentDidMount: ->
        @dispatchDiscover()


    componentDidUpdate: ->
        @dispatchDiscover()


    buildInput: (name, attributes={}) ->
        value = @state[name]
        value = @props.account.get(name) if _.isUndefined(value)
        _defaultAttributes =
            name: name
            key: "account-config-field-#{name}"
            valueLink:
              value: value
              requestChange: (value) =>
                  @handleChange name, value
            error: @props.errors?.get name
        AccountInput _.extend {}, _defaultAttributes, attributes


    render: ->
        formClass = classNames
            'form-horizontal': true
            'form-account': true
            'waiting': @props.isWaiting

        Form className: formClass,

            if @state.isOauth
                p null, t 'account oauth'

            FieldSet text: t('account identifiers'),
                @buildInput 'label'
                @buildInput 'name'
                @buildInput 'login'

            unless @state.isOauth
                @buildInput 'password', type: 'password'

            @buildInput 'accountType', className: 'hidden'

            # Display gmail warning
            # if IMAP server is Gmail.
            if @state.isGmail
                @_renderGMAILSecurity()

            unless @state.isOauth
                @_renderReceivingServer()

            unless @state.isOauth
                @_renderSendingServer()

            @_renderButtons()


    _renderReceivingServer: ->
        className = if @state.imapAdvanced then 'hide' else 'show'

        FieldSet text: t('account receiving server'),
            @buildInput 'imapServer'

            div
                className: "form-group advanced-imap-toggle",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable",
                    onClick: => @setState imapAdvanced: not @state.imapAdvanced
                    t "account imap #{className} advanced"

            if @state.imapAdvanced
                @buildInput 'imapPort'

            if @state.imapAdvanced
                @buildInput 'imapSSL', type: 'checkbox'

            if @state.imapAdvanced
                @buildInput 'imapTLS', type: 'checkbox'

            if @state.imapAdvanced
                @buildInput 'imapLogin'


    _renderSendingServer: ->
        className = if @state.smtpAdvanced then 'hide' else 'show'
        FieldSet text: t('account sending server'),
            @buildInput 'smtpServer'

            div
                className: "form-group advanced-smtp-toggle",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable"
                    onClick: => @setState smtpAdvanced: not @state.smtpAdvanced
                    t "account smtp #{className} advanced"

            if @state.smtpAdvanced
                @buildInput 'smtpPort'

            if @state.smtpAdvanced
                @buildInput 'smtpSSL', type: 'checkbox'

            if @state.smtpAdvanced
                @buildInput 'smtpTLS', type: 'checkbox'

            if @state.smtpAdvanced
                @buildInput 'smtpMethod',
                    type: 'dropdown'
                    options: {
                        'NONE': t("account smtpMethod NONE")
                        'CRAM-MD5': t("account smtpMethod CRAM-MD5")
                        'LOGIN': t("account smtpMethod LOGIN")
                        'PLAIN': t("account smtpMethod PLAIN")
                    }
                    allowUndefined: true

            if @state.smtpAdvanced
                @buildInput 'smtpLogin'

            if @state.smtpAdvanced
                @buildInput 'smtpPassword',
                    type: 'password'


    _renderGMAILSecurity: ->
        url = "https://www.google.com/settings/security/lesssecureapps"
        login = @props.account.get('login') or t 'the account to connect'
        FieldSet text: t('gmail security tile'),
            p null, t 'gmail security body'
            ul null,
                li null,
                    t 'gmail security link'
                    a target: '_blank', href: url, url
                li null, t 'gmail security ensure account', {login}
                li null, t 'gmail security allow less secure'
            p null,
                t('gmail security body 2'),
                a
                    target: '_blank'
                    href: 'https://accounts.google.com/DisplayUnlockCaptcha'
                    t 'gmail security link 2'


    _renderButtons: ->
        action = if @props.isWaiting then 'saving'
        else if @props.account?.get 'id' then 'save' else 'add'
        FieldSet text: t('account actions'),
            FormButtons null,
                # Run form submission process described in parent component.
                # Check for errors before.
                FormButton
                    class: 'action-save'
                    contrast: true
                    icon: 'save'
                    spinner: @props.isWaiting
                    onClick: (event) => @props.onSubmit event, false
                    text: t "account #{action}"

                # Run form submission process described in parent component. This one
                # checks that current parameters are working well.
                # Check for errors before.
                FormButton
                    class: 'action-check'
                    spinner: @props.checking
                    onClick: (event) => @props.onSubmit event, true
                    icon: 'ellipsis-h'
                    text: t 'account check'


    # FIXME : discover is dispatched
    # event when account is removed
    dispatchDiscover: ->
        # # Attempt to discover default values depending on target server.
        # # The target server is guessed by the email given by the user.
        # if @state.domain?.length > 3
        #     AccountActionCreator.discover @state.domain
