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
GOOGLE_EMAIL = ['googlemail.com', 'gmail.com']

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
        @getStateFromStores
            action: if @props.isWaiting then 'saving'
            else if account?.get 'id' then 'save' else 'add'
            isOauth: account?.get('oauthProvider')?
            isGmail: account?.get('imapServer') in GOOGLE_IMAP
            imapPort: '993'
            imapSSL: true
            imapTLS: false
            smtpPort: 465
            smtpSSL: true

    componentWillReceiveProps: (nextProps) ->
        # Define Advanced
        _hasErrorAndIsNot = (field, value = '') =>
            nextProps.errors.get(field) and
            nextProps.editedAccount.get(field) isnt value

        imapAdvanced = _hasErrorAndIsNot('imapLogin') or
                        _hasErrorAndIsNot('smtpLogin') or
                        _hasErrorAndIsNot('smtpPassword') or
                        _hasErrorAndIsNot('smtpMethod', 'PLAIN')

        if nextProps.editedAccount?
            @setState @getStateFromStores {imapAdvanced}
        nextProps

    handleChange: (name, value) ->
        nextProps = {}
        value = value.trim() if name in TRIMMEDFIELDS and value.trim
        nextProps[name] = value

        if 'login' is name
            {domain} = _getLoginInfos value
            nextProps.domain = domain

        @setState @getStateFromStores nextProps


    getStateFromStores: (nextState={}) ->
        # Toggle SSL : change ImapPort
        if nextState.imapSSL is false
            nextState.imapPort = '143'
        else if nextState.imapSSL is true
            nextState.imapPort = '993'

        # SMTP config
        isSmtpSSL = @state?.smtpSSL and nextState.smtpSSL is undefined
        if nextState.smtpSSL or isSmtpSSL
            nextState.smtpPort = '465'
        else
            nextState.smtpPort = '25'

        # Overwrite Smtp port if TLS is (ever) selected
        isSmtpTLS = @state?.smtpTLS and nextState.smtpTLS is undefined
        if nextState.smtpTLS or isSmtpTLS
            nextState.smtpPort = '587'

        # Check domain from login
        if _.isString nextState.domain
            gmailDomain = _.find GOOGLE_EMAIL, (value) ->
                -1 < nextState.domain.indexOf value
            nextState.isGmail = gmailDomain?

        nextState

    componentDidMount: ->
        @dispatchDiscover()

    componentDidUpdate: ->
        @dispatchDiscover()

    buildInput: (name, attributes={}) ->
        _defaultAttributes =
            name: name
            key: "account-config-field-#{name}"
            valueLink:
              value: @state[name]
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

            # Display gmail warning if IMAP server is Gmail.
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
            @buildInput 'imapPort'
            @buildInput 'imapSSL', type: 'checkbox'
            @buildInput 'imapTLS', type: 'checkbox'

            div
                className: "form-group advanced-imap-toggle",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable",
                    onClick: => @setState imapAdvanced: not @state.imapAdvanced
                    t "account imap #{className} advanced"

            if @state.imapAdvanced
                @buildInput 'imapLogin'


    _renderSendingServer: ->
        className = if @state.smtpAdvanced then 'hide' else 'show'
        FieldSet text: t('account sending server'),
            @buildInput 'smtpServer'
            @buildInput 'smtpPort'
            @buildInput 'smtpSSL', type: 'checkbox'
            @buildInput 'smtpTLS', type: 'checkbox'

            div
                className: "form-group advanced-smtp-toggle",
                a
                    className: "col-sm-3 col-sm-offset-2 control-label clickable"
                    onClick: => @setState smtpAdvanced: not @state.smtpAdvanced
                    t "account smtp #{className} advanced"

            if @state.smtpAdvanced
                @buildInput 'smtpMethod',
                    type: 'dropdown'
                    options: SMTP_OPTIONS
                    allowUndefined: true

                @buildInput 'smtpLogin'

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
                    # Run form submission process described in parent component.
                    # Check for errors before.
                    FormButton
                        class: 'action-save'
                        contrast: true
                        icon: 'save'
                        spinner: @props.isWaiting
                        onClick: (event) => @props.onSubmit event, false
                        text: t "account #{@state.action}"

                    # Run form submission process described in parent component. This one
                    # checks that current parameters are working well.
                    # Check for errors before.
                    FormButton
                        class: 'action-check'
                        spinner: @props.checking
                        onClick: (event) => @props.onSubmit event, true
                        icon: 'ellipsis-h'
                        text: t 'account check'

    dispatchDiscover: ->
        # Attempt to discover default values depending on target server.
        # The target server is guessed by the email given by the user.
        if @state.domain?.length > 3
            AccountActionCreator.discover @state.domain
