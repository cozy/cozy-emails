{div, h3, h4, form, label, input, button, ul, li, a, span, i,
fieldset, legend} =
    React.DOM
classer = React.addons.classSet

MailboxList          = require './mailbox-list'
AccountActionCreator = require '../actions/account_action_creator'
RouterMixin = require '../mixins/router_mixin'
LAC  = require '../actions/layout_action_creator'
classer = React.addons.classSet

module.exports = React.createClass
    displayName: 'AccountConfig'

    _lastDiscovered: ''

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    _accountFields: [
        'id', 'label', 'name', 'login', 'password',
        'imapServer', 'imapPort', 'imapSSL', 'imapTLS',
        'smtpServer', 'smtpPort', 'smtpSSL', 'smtpTLS',
        'accountType', 'mailboxes', 'favoriteMailboxes',
        'draftMailbox', 'sentMailbox', 'trashMailbox'
    ]
    _accountSchema:
        properties:
            'label':
                allowEmpty: false
                #type: 'string'
            'name':
                allowEmpty: false
                #type: 'string'
            'login':
                allowEmpty: false
                #type: 'string'
            'password':
                allowEmpty: false
                #type: 'string'
            'imapServer':
                allowEmpty: false
                #type: 'string'
            'imapPort':
                allowEmpty: false
                #type: 'integer'
            'imapSSL':
                allowEmpty: true
                #type: 'boolean'
            'imapTLS':
                allowEmpty: true
                #type: 'boolean'
            'smtpServer':
                allowEmpty: false
                #type: 'string'
            'smtpPort':
                allowEmpty: false
                #type: 'integer'
            'smtpSSL':
                allowEmpty: true
                #type: 'boolean'
            'smtpTLS':
                allowEmpty: true
                #type: 'boolean'
            'draftMailbox':
                allowEmpty: true
                #type: 'string'
            'sentMailbox':
                allowEmpty: true
                #type: 'string'
            'trashMailbox':
                allowEmpty: true
                #type: 'string'
            'accountType':
                allowEmpty: true
                #type: 'string'

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->
        if @state.id
            titleLabel = t "account edit"
        else
            titleLabel = t "account new"


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

        div id: 'mailbox-config',
            h3 className: null, titleLabel

            if @props.tab?
                ul className: "nav nav-tabs", role: "tablist",
                    li className: tabAccountClass,
                        a
                            href: tabAccountUrl
                            t "account tab account"
                    li className: tabMailboxClass,
                        a
                            href: tabMailboxUrl
                            t "account tab mailboxes"

            if not @props.tab or @props.tab is 'account'
                @renderMain()
            else
                @renderMailboxes()

    renderError: ->
        if @props.error and @props.error.name is 'AccountConfigError'
            message = t 'config error ' + @props.error.field
            div className: 'alert alert-warning', message
        else if @props.error
            div className: 'alert alert-warning', @props.error.message
        else if Object.keys(@state.errors).length isnt 0
            div className: 'alert alert-warning', t 'account errors'

    renderMain: ->

        if @props.isWaiting then buttonLabel = 'Saving...'
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

        form className: 'form-horizontal',
            @renderError()
            fieldset null,
                legend null, t 'account identifiers'
            div className: 'form-group' + hasError('label'),

                label
                    htmlFor: 'mailbox-label',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t "account label"
                div className: 'col-sm-3',
                    input
                        id: 'mailbox-label',
                        name: 'mailbox-label',
                        valueLink: @linkState('label'),
                        type: 'text',
                        className: 'form-control',
                        placeholder: t "account name short"
                        onBlur: @validateForm
                getError 'label'

            div className: 'form-group' + hasError('name'),
                label
                    htmlFor: 'mailbox-name',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t "account user name"
                div className: 'col-sm-3',
                    input
                        id: 'mailbox-name',
                        name: 'mailbox-name',
                        valueLink: @linkState('name'),
                        type: 'text',
                        className: 'form-control',
                        placeholder: t "account user fullname"
                        onBlur: @validateForm
                getError 'name'

            div className: 'form-group' + hasError(['login', 'auth']),
                label
                    htmlFor: 'mailbox-email-address',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t "account address"
                div className: 'col-sm-3',
                    input
                        id: 'mailbox-email-address',
                        name: 'mailbox-email-address',
                        valueLink: @linkState('login'),
                        ref: 'login',
                        onBlur: @discover,
                        type: 'email',
                        className: 'form-control',
                        placeholder: t "account address placeholder"
                getError 'login'

            div className: 'form-group' + hasError(['password', 'auth']),
                label
                    htmlFor: 'mailbox-password',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t 'account password'
                div className: 'col-sm-3',
                    input
                        id: 'mailbox-password',
                        name: 'mailbox-password',
                        valueLink: @linkState('password'),
                        type: 'password',
                        className: 'form-control'
                        onBlur: @validateForm
                getError 'password'

            fieldset null,
                legend null, t 'account sending server'
                div className: 'form-group' +
                        hasError(['smtp', 'smtpServer', 'smtpPort']),
                    label
                        htmlFor: 'mailbox-smtp-server',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t "account sending server"
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-smtp-server',
                            name: 'mailbox-smtp-server',
                            valueLink: @linkState('smtpServer'),
                            type: 'text',
                            className: 'form-control',
                            placeholder: 'smtp.provider.tld'
                            onBlur: @validateForm
                div className: 'form-group',
                    label
                        htmlFor: 'mailbox-smtp-port',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t 'account port'
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-smtp-port',
                            name: 'mailbox-smtp-port',
                            valueLink: @linkState('smtpPort'),
                            type: 'text',
                            className: 'form-control'
                            onBlur: @_onSMTPPort,
                            onInput: => @setState(smtpManualPort: true)
                    getError 'smtpServer'
                    getError 'smtpPort'

                div className: 'form-group',
                    label
                        htmlFor: 'mailbox-smtp-ssl',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t 'account SSL'
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-smtp-ssl',
                            name: 'mailbox-smtp-ssl',
                            checkedLink: @linkState('smtpSSL'),
                            type: 'checkbox',
                            onClick: (ev) =>
                                @_onServerParam ev.target, 'smtp', 'ssl'
                div className: 'form-group',
                    label
                        htmlFor: 'mailbox-smtp-tls',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t 'account TLS'
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-smtp-tls',
                            name: 'mailbox-smtp-tls',
                            checkedLink: @linkState('smtpTLS'),
                            type: 'checkbox',
                            onClick: (ev) =>
                                @_onServerParam ev.target, 'smtp', 'tls'

            div className: 'hidden',
                label
                    htmlFor: 'account-type',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t 'account type'
                div className: 'col-sm-3',
                    input
                        id: 'account-type',
                        name: 'account-type',
                        ref: 'type',
                        valueLink: @linkState('accountType'),
                        type: 'text',
                        className: 'form-control'
                getError 'password'
            fieldset null,
                legend null, t 'account receiving server'
                div className: 'form-group' +
                        hasError(['imap', 'imapServer', 'imapPort']),
                    label
                        htmlFor: 'mailbox-imap-server',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t "account receiving server"
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-imap-server',
                            name: 'mailbox-imap-server',
                            valueLink: @linkState('imapServer'),
                            type: 'text',
                            className: 'form-control',
                            placeholder: 'imap.provider.tld'
                            onBlur: @validateForm
                div className: 'form-group',
                    label
                        htmlFor: 'mailbox-imap-port',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        'Port'
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-imap-port',
                            name: 'mailbox-imap-port',
                            valueLink: @linkState('imapPort'),
                            type: 'text',
                            className: 'form-control',
                            onBlur: @_onIMAPPort
                            onInput: => @setState(imapManualPort: true)
                    getError 'imapServer'
                    getError 'imapPort'

                div className: 'form-group',
                    label
                        htmlFor: 'mailbox-imap-ssl',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t 'account SSL'
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-imap-ssl',
                            name: 'mailbox-imap-ssl',
                            checkedLink: @linkState('imapSSL'),
                            type: 'checkbox',
                            onClick: (ev) =>
                                @_onServerParam ev.target, 'imap', 'ssl'
                div className: 'form-group',
                    label
                        htmlFor: 'mailbox-imap-tls',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t 'account TLS'
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-imap-tls',
                            name: 'mailbox-imap-tls',
                            checkedLink: @linkState('imapTLS'),
                            type: 'checkbox',
                            onClick: (ev) =>
                                @_onServerParam ev.target, 'imap', 'tls'

            fieldset null,
                legend null, t 'account actions'
            div className: '',
                div className: 'col-sm-offset-4',
                    button
                        className: 'btn btn-cozy',
                        onClick: @onSubmit, buttonLabel
                if @state.id?
                    fieldset null,
                        legend null, t 'account danger zone'
                        div className: 'col-sm-offset-4',
                            button
                                className: 'btn btn-default btn-danger btn-remove',
                                onClick: @onRemove,
                                t "account remove"

    renderMailboxes: ->
        favorites = @state.favoriteMailboxes
        if @state.mailboxes? and favorites?
            mailboxes = @state.mailboxes.map (mailbox, key) =>
                try
                    favorite = favorites.get(mailbox.get('id'))?
                    MailboxItem {accountID: @state.id, mailbox, favorite}
                catch error
                    console.log error, favorites
            .toJS()
        form className: 'form-horizontal',

            @renderError()
            @_renderMailboxChoice t('account draft mailbox'), "draftMailbox"
            @_renderMailboxChoice t('account sent mailbox'),  "sentMailbox"
            @_renderMailboxChoice t('account trash mailbox'), "trashMailbox"

            h4 className: 'config-title', t "account tab mailboxes"
            ul className: "folder-list list-unstyled boxes container",
                if mailboxes?
                    li className: 'row box title', key: 'title',
                        span
                            className: "col-xs-1",
                            ''
                        span
                            className: "col-xs-1",
                            ''
                        span
                            className: "col-xs-6",
                            ''
                        span
                            className: "col-xs-1",
                            ''
                        span
                            className: "col-xs-1 text-center",
                            t 'mailbox title total'
                        span
                            className: "col-xs-1 text-center",
                            t 'mailbox title unread'
                        span
                            className: "col-xs-1 text-center",
                            t 'mailbox title new'
                mailboxes
                li className: "row box new", key: 'new',
                    span
                        className: "col-xs-1 box-action add"
                        onClick: @addMailbox
                        title: t("mailbox title add"),
                            i className: 'fa fa-plus'
                    span
                        className: "col-xs-1 box-action cancel"
                        onClick: @undoMailbox
                        title: t("mailbox title add cancel"),
                            i className: 'fa fa-undo'
                    div className: 'col-xs-6',
                        input
                            id: 'newmailbox',
                            ref: 'newmailbox',
                            type: 'text',
                            className: 'form-control',
                            placeholder: t "account newmailbox placeholder"
                            onKeyDown: @onKeyDown
                    label
                        className: 'col-xs-2 text-center control-label',
                        t "account newmailbox parent"
                    div className: 'col-xs-2 text-center',
                        MailboxList
                            allowUndefined: true
                            mailboxes: @state.mailboxes
                            selectedMailbox: @state.newMailboxParent
                            onChange: (mailbox) =>
                                @setState newMailboxParent: mailbox

    onKeyDown: (evt) ->
        switch evt.key
            when "Enter"
                @addMailbox()

    _renderMailboxChoice: (labelText, box) ->
        if @state.id?
            div className: "form-group #{box}",
                label
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    labelText
                div className: 'col-sm-3',
                    MailboxList
                        allowUndefined: true
                        mailboxes: @state.mailboxes
                        selectedMailbox: @state[box]
                        onChange: (mailbox) =>
                            newState = {}
                            newState[box] = mailbox
                            @setState newState, =>
                                @onSubmit()

    _afterMount: ->
        # On error, scroll to message
        node = document.querySelector("#mailbox-config .alert")
        if node?
            node.scrollIntoView()

    componentDidMount: ->
        @_afterMount()

    componentDidUpdate: ->
        @_afterMount()

    doValidate: ->
        accountValue = {}
        init = (field) =>
            accountValue[field] = @state[field]
        init field for field in @_accountFields

        validOptions =
            additionalProperties: true

        valid = validate accountValue, @_accountSchema, validOptions

        return {accountValue, valid}

    validateForm: (event) ->
        if event?
            event.preventDefault()
        # If form contains errors, re-validate it every time the user updates
        # a field
        if Object.keys(@state.errors).length isnt 0
            {accountValue, valid} = @doValidate()
            if valid.valid
                @setState errors: {}
            else
                errors = {}
                setError = (error) ->
                    errors[error.property] = t "validate #{error.message}"
                setError error for error in valid.errors
                @setState errors: errors

    onSubmit: (event) ->
        if event?
            # prevents the page from reloading
            event.preventDefault()

        {accountValue, valid} = @doValidate()

        if valid.valid
            if @state.id?
                AccountActionCreator.edit accountValue, @state.id
            else
                AccountActionCreator.create accountValue, (account) =>
                    LAC.alertSuccess t "account creation ok"
                    @redirect
                        direction: 'first'
                        action: 'account.config'
                        parameters: [
                            account.get 'id'
                            'mailboxes'
                        ]
                        fullWidth: true
        else
            errors = {}
            setError = (error) ->
                errors[error.property] = t "validate #{error.message}"
            setError error for error in valid.errors
            @setState errors: errors

    onRemove: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        if window.confirm(t 'account remove confirm')
            AccountActionCreator.remove @state.id


    addMailbox: (event) ->
        event?.preventDefault()

        mailbox =
            label: @refs.newmailbox.getDOMNode().value.trim()
            accountID: @state.id
            parentID: @state.newMailboxParent

        AccountActionCreator.mailboxCreate mailbox, (error) ->
            if error?
                LAC.alertError "#{t("mailbox create ko")} #{error}"
            else
                LAC.alertSuccess t "mailbox create ok"

    undoMailbox: (event) ->
        event.preventDefault()

        @refs.newmailbox.getDOMNode().value = ''
        @setState newMailboxParent: null


    discover: (event) ->
        @validateForm event

        login = @state.login#@refs.login.getDOMNode().value.trim()

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
                    @setState infos
                    @validateForm()
            @_lastDiscovered = login

    _onServerParam: (target, server, type) ->
        if (server is 'imap' and @state.imapManualPort) or
        (server is 'smtp' and @state.smtpManualPort)
            # port has been set manually, don't update it
            return
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

    componentWillReceiveProps: (props) ->
        # prevents the form from changing during submission
        if props.selectedAccount and not props.isWaiting

            @setState @_accountToState props

    getInitialState: ->
        return @_accountToState null

    _accountToState: (props)->
        state =
            errors: {}
        if props?
            account = props.selectedAccount
            if props.error?
                if props.error.name is 'AccountConfigError'
                    field = props.error.field
                    state.errors[field] = t 'config error ' + field
        if account?
            for field in @_accountFields
                state[field] = account.get field
            state.newMailboxParent = null
            state.mailboxes         = props.mailboxes
            state.favoriteMailboxes = props.favoriteMailboxes
            if state.mailboxes.length is 0
                @redirect
                    direction: 'first'
                    action: 'account.config'
                    parameters: [@state.id, 'mailboxes']
        else if Object.keys(state.errors).length is 0
            init = (field) ->
                state[field] = ''
            init field for field in @_accountFields
            state.id       = null
            state.smtpPort = 465
            state.smtpSSL  = true
            state.smtpTLS  = false
            state.imapPort = 993
            state.imapSSL  = true
            state.imapTLS  = false
            state.accountType = 'IMAP'
            state.newMailboxParent  = null
            state.favoriteMailboxes = null

        return state

MailboxItem = React.createClass
    displayName: 'MailboxItem'

    propTypes:
        mailbox: React.PropTypes.object

    componentWillReceiveProps: (props) ->
        @setState edited: false

    getInitialState: ->
        return {
            edited: false
            favorite: @props.favorite
        }

    render: ->
        pusher = ""
        pusher += "    " for j in [1..@props.mailbox.get('depth')] by 1
        key = @props.mailbox.get 'id'
        if @state.favorite
            favoriteClass = "fa fa-eye mailbox-visi-yes"
            favoriteTitle = t "mailbox title favorite"
        else
            favoriteClass = "fa fa-eye-slash mailbox-visi-no"
            favoriteTitle = t "mailbox title not favorite"
        nbTotal  = @props.mailbox.get('nbTotal') or 0
        nbUnread = @props.mailbox.get('nbUnread') or 0
        nbRecent = @props.mailbox.get('nbRecent') or 0
        classItem = classer
            'row': true
            'box': true
            'box-item': true
            edited: @state.edited
        if @state.edited
            li className: classItem, key: key,
                span
                    className: "col-xs-1 box-action save"
                    onClick: @updateMailbox
                    title: t("mailbox title edit save"),
                        i className: 'fa fa-check'
                span
                    className: "col-xs-1 box-action cancel"
                    onClick: @undoMailbox
                    title: t("mailbox title edit cancel"),
                        i className: 'fa fa-undo'
                input
                    className: "col-xs-6 box-label"
                    ref: 'label',
                    defaultValue: @props.mailbox.get 'label'
                    type: 'text'
                    onKeyDown: @onKeyDown,
        else
            li className: classItem, key: key,
                span
                    className: "col-xs-1 box-action edit",
                    onClick: @editMailbox,
                    title: t("mailbox title edit"),
                        i className: 'fa fa-pencil'
                span
                    className: "col-xs-1 box-action delete",
                    onClick: @deleteMailbox,
                    title: t("mailbox title delete"),
                        i className: 'fa fa-trash-o'
                span
                    className: "col-xs-6 box-label",
                    onClick: @editMailbox,
                    "#{pusher}#{@props.mailbox.get 'label'}"
                span
                    className: "col-xs-1 box-action favorite",
                    title: favoriteTitle
                    onClick: @toggleFavorite,
                        i className: favoriteClass
                span
                    className: "col-xs-1 text-center box-count box-total",
                    nbTotal
                span
                    className: "col-xs-1 text-center box-count box-unread",
                    nbUnread
                span
                    className: "col-xs-1 text-center box-count box-new",
                    nbRecent

    onKeyDown: (evt) ->
        switch evt.key
            when "Enter"
                @updateMailbox()

    editMailbox: (e) ->
        e.preventDefault()
        @setState edited: true

    undoMailbox: (e) ->
        e.preventDefault()
        @setState edited: false

    updateMailbox: (e) ->
        e?.preventDefault()

        mailbox =
            label: @refs.label.getDOMNode().value.trim()
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.accountID

        AccountActionCreator.mailboxUpdate mailbox, (error) ->
            if error?
                LAC.alertError "#{t("mailbox update ko")} #{error}"
            else
                LAC.alertSuccess t "mailbox update ok"

    toggleFavorite: (e) ->

        mailbox =
            favorite: not @state.favorite
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.accountID

        AccountActionCreator.mailboxUpdate mailbox, (error) ->
            if error?
                LAC.alertError "#{t("mailbox update ko")} #{error}"
            else
                LAC.alertSuccess t "mailbox update ok"

        @setState favorite: not @state.favorite

    deleteMailbox: (e) ->
        e.preventDefault()

        if window.confirm(t 'account confirm delbox')
            mailbox =
                mailboxID: @props.mailbox.get 'id'
                accountID: @props.accountID

            AccountActionCreator.mailboxDelete mailbox, (error) ->
                if error?
                    LAC.alertError "#{t("mailbox delete ko")} #{error}"
                else
                    LAC.alertSuccess t "mailbox delete ok"
