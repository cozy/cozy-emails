React      = require 'react'
classNames = require 'classnames'

{
    div, p, form, label, input, button, ul, li, a, span, i,
    fieldset, legend
} = React.DOM

_ = require 'underscore'
Immutable = require 'immutable'

{   Form
    FieldSet
    FormButtons
    FormButton} = require('./basic_components').factories
AccountInput  = React.createFactory require './account_config_input'
AccountDelete = React.createFactory require './account_config_delete'
AccountActionCreator = require '../actions/account_action_creator'

RouterMixin = require '../mixins/router_mixin'

discovery2Fields = require '../utils/discovery_to_fields'


SMTP_OPTIONS =
    'NONE': t("account smtpMethod NONE")
    'CRAM-MD5': t("account smtpMethod CRAM-MD5")
    'LOGIN': t("account smtpMethod LOGIN")
    'PLAIN': t("account smtpMethod PLAIN")

GOOGLE_IMAP = ['imap.googlemail.com', 'imap.gmail.com']
TRIMMEDFIELDS = ['imapServer', 'imapPort', 'smtpServer', 'smtpPort']

module.exports = AccountConfigMain = React.createClass
    displayName: 'AccountConfigMain'

    mixins: [ RouterMixin ]

    propTypes:
        editedAccount: React.PropTypes.instanceOf(Immutable.Map).isRequired
        requestChange: React.PropTypes.func.isRequired
        isWaiting: React.PropTypes.bool.isRequired

    # Do not update component if nothing has changed.
    shouldComponentUpdate: (nextProps, nextState) ->
        isNextState = _.isEqual nextState, @state
        isNextProps = _.isEqual nextProps, @props
        return not (isNextState and isNextProps)

    getInitialState: ->
        domain = @props.editedAccount.get('login')?.split('@')[1]
        if @props.editedAccount.get('id') and domain
            @_lastDiscovered = domain

        return state =
            imapAdvanced: false
            smtpAdvanced: false

    makeLinkState: (field) ->
        cached = (@__cacheLS ?= {})[field]
        value =  @props.editedAccount.get(field) or ''
        if cached?.value is value then return cached
        else return @__cacheLS[field] =
            value: value
            requestChange: (value) =>
                @props.requestChange @makeChanges field, value

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
                @doDiscovery value?.split('@')[1]

        return changes

    componentWillReceiveProps: (props) ->
        hasErrorAndIsNot = (field, value = '') ->
            props.errors.get(field) and
            props.editedAccount.get(field) isnt value

        changes = {}
        changes.imapAdvanced = true if hasErrorAndIsNot 'imapLogin'
        changes.smtpAdvanced = true if hasErrorAndIsNot 'smtpLogin'
        changes.smtpAdvanced = true if hasErrorAndIsNot 'smtpPassword'
        changes.smtpAdvanced = true if hasErrorAndIsNot 'smtpMethod', 'PLAIN'

        @setState changes if changes.smtpAdvanced or changes.imapAdvanced


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
    toggleSMTPAdvanced: -> @setState smtpAdvanced: not @state.smtpAdvanced

    # Display or not IMAP advanced settings.
    toggleIMAPAdvanced: -> @setState imapAdvanced: not @state.imapAdvanced

    # Attempt to discover default values depending on target server.
    # The target server is guessed by the email given by the user.
    doDiscovery: (domain) ->
        if domain?.length > 3 and domain isnt @_lastDiscovered
            if @discoverTimeout
                @nextDiscover = domain
            else
                @discoverTimeout = setTimeout (=> @doDiscoveryNow domain), 2000


    doDiscoveryNow: (domain) ->
        AccountActionCreator.discover domain, (err, provider) =>
            unless err
                infos = discovery2Fields provider

                @props.requestChange infos

            if @nextDiscover
                @doDiscoveryNow @nextDiscover
                @nextDiscover = null
            else
                @discoverTimeout = null
