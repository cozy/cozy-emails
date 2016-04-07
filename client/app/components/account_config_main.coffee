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

    componentWillReceiveProps: (props) ->
        _hasErrorAndIsNot = (field, value = '') ->
            props.errors.get(field) and
            props.editedAccount.get(field) isnt value

        imapAdvanced = _hasErrorAndIsNot('imapLogin') or
                        _hasErrorAndIsNot('smtpLogin') or
                        _hasErrorAndIsNot('smtpPassword') or
                        _hasErrorAndIsNot('smtpMethod', 'PLAIN')

        @setState @getStateFromStores {imapAdvanced}


    getStateFromStores: (props={}) ->
        {domain} = _getLoginInfos @props?.editedAccount.get('login')

        return {
            lastDiscovered: domain if domain
            imapAdvanced: props.imapAdvanced or false
            smtpAdvanced: props.smtpAdvanced or false
        }


    makeLinkState: (field) ->
        cached = (@__cacheLS ?= {})[field]
        value =  @props.editedAccount.get(field) or ''
        if cached?.value is value then return cached
        else return @__cacheLS[field] =
            value: value
            requestChange: (value) =>
                @makeChanges field, value

    makeChanges: (field, value) ->
        changes = {}

        if field in TRIMMEDFIELDS and value.trim
            value = value.trim()

        changes[field] = value

        switch field
            when 'imapPort'
                changes.imapSSL = value is '993'
                changes.imapTLS = false
            when 'smtpPort'
                changes.smtpSSL = value is '465'
                changes.smtpTLS = value is '587'
            when 'imapSSL'
                unless @state.imapManualPort
                    changes.imapPort = if value then '993' else '143'
            when 'smtpSSL'
                unless @state.smtpManualPort
                    changes.smtpPort = if value then '465' else '25'
            when 'smtpTLS'
                unless @state.smtpManualPort
                    changes.smtpPort = if value then '587' else '25'
            when 'login'
                @doDiscovery value

        return changes


    buildButtonLabel: ->
        action = if @props.isWaiting then 'saving'
        else if @props.editedAccount.get('id') then 'save'
        else 'add'

        return t "account #{action}"

    buildInput: (field, options = {}) ->
        options.name ?= field
        options.key = "account-config-field-#{field}"
        options.valueLink ?= @makeLinkState field
        options.error ?= @props.errors?.get field
        return AccountInput options

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
        if domain isnt @state.lastDiscovered
            AccountActionCreator.discover domain
