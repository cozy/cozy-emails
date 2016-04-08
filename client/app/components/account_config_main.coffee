React      = require 'react'

_ = require 'underscore'
Immutable = require 'immutable'

{div, p, ul, li, a, i} = React.DOM
{Form, FieldSet, FormButtons, FormButton} = require('./basic_components').factories
classNames = require 'classnames'

AccountInput  = React.createFactory require './account_config_input'
AccountActionCreator = require '../actions/account_action_creator'


SMTP_OPTIONS =
    'NONE': t("account smtpMethod NONE")
    'CRAM-MD5': t("account smtpMethod CRAM-MD5")
    'LOGIN': t("account smtpMethod LOGIN")
    'PLAIN': t("account smtpMethod PLAIN")

GOOGLE_IMAP = ['imap.googlemail.com', 'imap.gmail.com']
TRIMMEDFIELDS = ['imapServer', 'imapPort', 'smtpServer', 'smtpPort']


_getLoginInfos = (login) ->
    index0 = login.indexOf '@'
    return {
        alias: login.substring 0, index0
        domain: login.substring index0 + 1, login.length
    }

module.exports = AccountConfigMain = React.createClass
    displayName: 'AccountConfigMain'

    getInitialState: ->
        @getStateFromStores()

    componentWillReceiveProps: (nextProps) ->
        # Define Advanced
        _hasErrorAndIsNot = (field, value = '') =>
            nextProps.errors.get(field) and
            nextProps.editedAccount.get(field) isnt value

        imapAdvanced = _hasErrorAndIsNot('imapLogin') or
                        _hasErrorAndIsNot('smtpLogin') or
                        _hasErrorAndIsNot('smtpPassword') or
                        _hasErrorAndIsNot('smtpMethod', 'PLAIN')

        @setState @getStateFromStores {imapAdvanced}
        nextProps

    handleChange: (field, value) ->
        nextProps = {}
        value = value.trim() if field in TRIMMEDFIELDS and value.trim
        nextProps[field] = value

        @setState @getStateFromStores nextProps

        @doDiscovery value if 'login' is field


    getStateFromStores: (nextState={}) ->
        {domain} = _getLoginInfos @props?.editedAccount.get('login')

        if domain
            nextState.lastDiscovered = domain

        # Define Ports
        if nextState.imapPort isnt undefined
            nextState.imapSSL = value is '993'
            nextState.imapTLS = false

        else if nextState.smtpPort isnt undefined
            nextState.smtpSSL = value is '465'
            nextState.smtpTLS = value is '587'

        unless nextState.imapManualPort
            if nextState.imapSSL isnt undefined
                nextState.imapPort = if nextState.imapSSL then '993' else '143'

        unless nextState.smtpManualPort
            if nextState.smtpSSL isnt undefined
                nextState.smtpPort = if nextState.smtpSSL then '465' else '25'
            else if nextState.smtpTLS isnt undefined
                nextState.smtpPort = if nextState.smtpTLS then '587' else '25'

        nextState

    buildButtonLabel: ->
        action = if @props.isWaiting then 'saving'
        else if @props.editedAccount.get('id') then 'save'
        else 'add'

        return t "account #{action}"


    buildInput: (field) ->
        AccountInput
            name: field
            key: "account-config-field-#{field}"
            valueLink:
              value: @state[field]
              requestChange: (value) =>
                  @handleChange field, value
            error: @props.errors?.get field

    render: ->
        formClass = classNames
            'form-horizontal': true
            'form-account': true
            'waiting': @props.isWaiting

        isOauth = @props.editedAccount?.get('oauthProvider')?

        Form className: formClass,

            if isOauth
                p null, t 'account oauth'

            FieldSet text: t('account identifiers'),
                @buildInput 'label'
                @buildInput 'name'
                @buildInput 'login' #, type: 'email'

                unless isOauth
                    @buildInput 'password', type: 'password'

            @buildInput 'accountType', className: 'hidden'

            # Display gmail warning if IMAP server is Gmail.
            if @props.editedAccount.get('imapServer') in GOOGLE_IMAP
                @_renderGMAILSecurity()
            unless isOauth
                @_renderReceivingServer()
            unless isOauth
                @_renderSendingServer()

            @_renderButtons()

    _renderReceivingServer: ->
        advanced = if @state.imapAdvanced then 'hide' else 'show'

        FieldSet text: t('account receiving server'),

            @buildInput 'imapServer'
            @buildInput 'imapPort'
            @buildInput 'imapSSL', type: 'checkbox'
            @buildInput 'imapTLS', type: 'checkbox'

            div
                className: "form-group advanced-imap-toggle",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable",
                    onClick: @toggleIMAPAdvanced,
                    t "account imap #{advanced} advanced"

            if @state.imapAdvanced
                @buildInput 'imapLogin'


    _renderSendingServer: ->
        advanced = if @state.smtpAdvanced then 'hide' else 'show'
        FieldSet text: t('account sending server'),
            @buildInput 'smtpServer'
            @buildInput 'smtpPort'
            @buildInput 'smtpSSL', type: 'checkbox'
            @buildInput 'smtpTLS', type: 'checkbox'

            div
                className: "form-group advanced-smtp-toggle",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable",
                    onClick: @toggleSMTPAdvanced,
                    t "account smtp #{advanced} advanced"

            if @state.smtpAdvanced
                @buildInput 'smtpMethod',
                    type: 'dropdown'
                    options: SMTP_OPTIONS
                    allowUndefined: true

            if @state.smtpAdvanced
                @buildInput 'smtpLogin'

            if @state.smtpAdvanced
                @buildInput 'smtpPassword',
                    type: 'password'

    _renderGMAILSecurity: ->
        url = "https://www.google.com/settings/security/lesssecureapps"
        login = @props.editedAccount.get('login') or t 'the account to connect'
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
        if @props.errors.size is 0
            FieldSet text: t('account actions'),
                FormButtons null,
                    FormButton
                            class: 'action-save'
                            contrast: true
                            icon: 'save'
                            spinner: @props.isWaiting
                            onClick: @onSubmit
                            text: @buildButtonLabel()
                    FormButton
                            class: 'action-check'
                            spinner: @props.checking
                            onClick: @onCheck
                            icon: 'ellipsis-h'
                            text: t 'account check'


    # Run form submission process described in parent component.
    # Check for errors before.
    onSubmit: (event) -> @props.onSubmit event, false

    # Run form submission process described in parent component. This one
    # checks that current parameters are working well.
    # Check for errors before.
    onCheck: (event) -> @props.onSubmit event, true

    # Display or not SMTP advanced settings.
    toggleSMTPAdvanced: ->
        @setState smtpAdvanced: not @state.smtpAdvanced

    # Display or not IMAP advanced settings.
    toggleIMAPAdvanced: ->
        @setState imapAdvanced: not @state.imapAdvanced

    # Attempt to discover default values depending on target server.
    # The target server is guessed by the email given by the user.
    doDiscovery: (login) ->
        {domain} = _getLoginInfos login
        if domain?.length > 3 and domain isnt @state.lastDiscovered
            AccountActionCreator.discover domain
