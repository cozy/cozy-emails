{div, h3, h4, form, label, input, button, ul, li, a, span, i, fieldset, legend} =
    React.DOM
classer = React.addons.classSet

MailboxList   = require './mailbox-list'
AccountActionCreator = require '../actions/account_action_creator'
RouterMixin = require '../mixins/router_mixin'
LAC  = require '../actions/layout_action_creator'
classer = React.addons.classSet

module.exports = React.createClass
    displayName: 'AccountConfig'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    _accountFields: [
        'id', 'label', 'name', 'login', 'password',
        'imapServer', 'imapPort', 'imapSSL', 'imapTLS',
        'smtpServer', 'smtpPort', 'smtpSSL', 'smtpTLS',
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

    shouldComponentUpdate: (nextProps, nextState) ->
        if not Immutable.is(nextState, @state)
            return true
        else
            if not nextProps.selectedAccount?
                should = nextProps.layout isnt @props.layout or
                    nextProps.error     isnt @props.error or
                    nextProps.isWaiting isnt @props.isWaiting
            else
                should = nextProps.layout isnt @props.layout or
                    nextProps.error     isnt @props.error or
                    nextProps.isWaiting isnt @props.isWaiting or
                    not Immutable.is(nextProps.selectedAccount, @props.selectedAccount) or
                    not Immutable.is(nextProps.mailboxes, @props.mailboxes) or
                    not Immutable.is(nextProps.favoriteMailboxes, @props.favoriteMailboxes)
        return should

    render: ->
        if @props.selectedAccount?
            titleLabel = t "account edit"
        else
            titleLabel = t "account new"

        classes = {}
        ['account', 'mailboxes'].map (e) =>
            classes[e] = classer active: @state.tab is e

        div id: 'mailbox-config',
            h3 className: null, titleLabel

            if @state.tab?
                ul className: "nav nav-tabs", role: "tablist",
                    li className: classes['account'],
                        a
                            'data-target': 'account'
                            onClick: @tabChange,
                            t "account tab account"
                    li className: classes['mailboxes'],
                        a
                            'data-target': 'mailboxes'
                            onClick: @tabChange,
                            t "account tab mailboxes"

            if not @state.tab or @state.tab is 'account'
                @renderMain()
            if @state.tab is 'mailboxes'
                @renderMailboxes()

    renderMain: ->

        if @props.isWaiting then buttonLabel = 'Saving...'
        else if @props.selectedAccount? then buttonLabel = t "account save"
        else buttonLabel = t "account add"

        renderError = =>
            if @props.error and @props.error.name is 'AccountConfigError'
                message = t 'config error ' + @props.error.field
                div className: 'alert alert-warning', message
            else if @props.error
                console.log @props.error.stack
                div className: 'alert alert-warning', @props.error.message

        hasError = (field) =>
            if @state.errors[field]?
                return ' has-error'
            else
                return ''
        getError = (field) =>
            if @state.errors[field]?
                div className: 'col-sm-5 col-sm-offset-2 control-label', @state.errors[field]

        form className: 'form-horizontal',
            renderError()
            div className: 'form-group' + hasError('label'),

                label
                    htmlFor: 'mailbox-label',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t "account label"
                div className: 'col-sm-3',
                    input id: 'mailbox-label',
                    valueLink: @linkState('label'),
                    type: 'text',
                    className: 'form-control',
                    placeholder: t "account name short"
                getError 'label'

            div className: 'form-group' + hasError('name'),
                label
                    htmlFor: 'mailbox-name',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t "account user name"
                div className: 'col-sm-3',
                    input
                        id: 'mailbox-name',
                        valueLink: @linkState('name'),
                        type: 'text',
                        className: 'form-control',
                        placeholder: t "account user fullname"
                getError 'name'

            div className: 'form-group' + hasError('login') + hasError('auth'),
                label
                    htmlFor: 'mailbox-email-address',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t "account address"
                div className: 'col-sm-3',
                    input
                        id: 'mailbox-email-address',
                        valueLink: @linkState('login'),
                        ref: 'login',
                        onBlur: @discover,
                        type: 'email',
                        className: 'form-control',
                        placeholder: t "account address placeholder"
                getError 'login'

            div className: 'form-group' + hasError('password') + hasError('auth'),
                label
                    htmlFor: 'mailbox-password',
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t 'account password'
                div className: 'col-sm-3',
                    input
                        id: 'mailbox-password',
                        valueLink: @linkState('password'),
                        type: 'password',
                        className: 'form-control'
                getError 'password'

            fieldset null,
                legend null, t 'account sending server'
                div className: 'form-group' + hasError('smtp') + hasError('smtpServer') + hasError('smtpPort'),
                    label
                        htmlFor: 'mailbox-smtp-server',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t "account sending server"
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-smtp-server',
                            valueLink: @linkState('smtpServer'),
                            type: 'text',
                            className: 'form-control',
                            placeholder: 'smtp.provider.tld'
                    label
                        htmlFor: 'mailbox-smtp-port',
                        className: 'col-sm-1 control-label',
                        t 'account port'
                    div className: 'col-sm-1',
                        input
                            id: 'mailbox-smtp-port',
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
                        className: 'col-sm-4 control-label',
                        t 'account SSL'
                    div className: 'col-sm-1',
                        input
                            id: 'mailbox-smtp-ssl',
                            checkedLink: @linkState('smtpSSL'),
                            type: 'checkbox',
                            className: 'form-control'
                            onClick: (ev) => @_onServerParam ev.target, 'smtp', 'ssl'
                    label
                        htmlFor: 'mailbox-smtp-tls',
                        className: 'col-sm-2 control-label',
                        t 'account TLS'
                    div className: 'col-sm-1',
                        input
                            id: 'mailbox-smtp-tls',
                            checkedLink: @linkState('smtpTLS'),
                            type: 'checkbox',
                            className: 'form-control'
                            onClick: (ev) => @_onServerParam ev.target, 'smtp', 'tls'

            fieldset null,
                legend null, t 'account receiving server'
                div className: 'form-group' + hasError('imap') + hasError('imapServer') + hasError('imapPort'),
                    label
                        htmlFor: 'mailbox-imap-server',
                        className: 'col-sm-2 col-sm-offset-2 control-label',
                        t "account receiving server"
                    div className: 'col-sm-3',
                        input
                            id: 'mailbox-imap-server',
                            valueLink: @linkState('imapServer'),
                            type: 'text',
                            className: 'form-control',
                            placeholder: 'imap.provider.tld'
                    label
                        htmlFor: 'mailbox-imap-port',
                        className: 'col-sm-1 control-label',
                        'Port'
                    div className: 'col-sm-1',
                        input
                            id: 'mailbox-imap-port',
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
                        className: 'col-sm-4 control-label',
                        t 'account SSL'
                    div className: 'col-sm-1',
                        input
                            id: 'mailbox-imap-ssl',
                            checkedLink: @linkState('imapSSL'),
                            type: 'checkbox',
                            className: 'form-control'
                            onClick: (ev) => @_onServerParam ev.target, 'imap', 'ssl'
                    label
                        htmlFor: 'mailbox-imap-tls',
                        className: 'col-sm-2 control-label',
                        t 'account TLS'
                    div className: 'col-sm-1',
                        input
                            id: 'mailbox-imap-tls',
                            checkedLink: @linkState('imapTLS'),
                            type: 'checkbox',
                            className: 'form-control'
                            onClick: (ev) => @_onServerParam ev.target, 'imap', 'tls'

            div className: 'form-group',
                div className: 'col-sm-offset-2 col-sm-5 text-right',
                    if @props.selectedAccount?
                        button
                            className: 'btn btn-cozy',
                            onClick: @onRemove,
                            t "account remove"
                    button
                        className: 'btn btn-cozy',
                        onClick: @onSubmit, buttonLabel

    renderMailboxes: ->
        favorites = @props.favoriteMailboxes
        if @props.mailboxes?
            mailboxes = @props.mailboxes.map (mailbox, key) =>
                favorite = true if favorites.get(mailbox.get('id'))
                MailboxItem {account: @props.selectedAccount, mailbox, favorite}
            .toJS()
        form className: 'form-horizontal',

            @_renderMailboxChoice 'account draft mailbox', "draftMailbox"
            @_renderMailboxChoice 'account sent mailbox',  "sentMailbox"
            @_renderMailboxChoice 'account trash mailbox', "trashMailbox"

            h4 null, t "account tab mailboxes"
            ul className: "list-unstyled boxes",
                mailboxes
                li null
                    div className: "box edited",
                        span
                            className: "box-action"
                            onClick: @addMailbox
                            title: t("mailbox title add"),
                                i className: 'fa fa-plus'
                        span
                            className: "box-action"
                            onClick: @undoMailbox
                            title: t("mailbox title add cancel"),
                                i className: 'fa fa-undo'
                        div null,
                            input
                                id: 'newmailbox',
                                ref: 'newmailbox',
                                type: 'text',
                                className: 'form-control',
                                placeholder: t "account newmailbox placeholder"
                        label
                            className: 'col-sm-1 control-label',
                            t "account newmailbox parent"
                        div className: 'col-sm-1',
                            MailboxList
                                allowUndefined: true
                                mailboxes: @props.mailboxes
                                selectedMailbox: @state.newMailboxParent
                                onChange: (mailbox) =>
                                    @setState newMailboxParent: mailbox

    _renderMailboxChoice: (labelText, box) ->
        if @props.selectedAccount?
            div className: 'form-group',
                label
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    t labelText
                div className: 'col-sm-3',
                    MailboxList
                        allowUndefined: true
                        mailboxes: @props.mailboxes
                        selectedMailbox: @state[box]
                        onChange: (mailbox) =>
                            newState = {}
                            newState[box] = mailbox
                            @setState newState


    onSubmit: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        accountValue = {}
        init = (field) =>
            accountValue[field] = @state[field]
        init field for field in @_accountFields

        validOptions =
            additionalProperties: true

        valid = validate accountValue, @_accountSchema, validOptions

        if valid.valid
            @setState errors: {}
            afterCreation = (id) =>
                @setState tab: 'mailboxes'


            if @props.selectedAccount?
                AccountActionCreator.edit accountValue,
                    @props.selectedAccount.get 'id'
            else
                AccountActionCreator.create accountValue, afterCreation
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
            AccountActionCreator.remove @props.selectedAccount.get 'id'


    tabChange: (e) ->
        e.preventDefault
        @setState tab: e.target.dataset.target


    addMailbox: (event) ->
        event.preventDefault()

        mailbox =
            label: @refs.newmailbox.getDOMNode().value.trim()
            accountID: @props.selectedAccount.get 'id'
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


    discover: ->
        login = @refs.login.getDOMNode().value.trim()

        AccountActionCreator.discover login.split('@')[1], (err, provider) =>
            if not err?
                infos = {}
                getInfos = (server) ->
                    if server.type is 'imap' and not infos.imapServer?
                        infos.imapServer = server.hostname
                        infos.imapPort   = server.port
                    if server.type is 'smtp' and not infos.smtpServer?
                        infos.smtpServer = server.hostname
                        infos.smtpPort   = server.port
                getInfos server for server in provider
                if not infos.imapServer?
                    infos.imapServer = ''
                    infos.imapPort   = '993'
                if not infos.smtpServer?
                    infos.smtpServer = ''
                    infos.smtpPort   = '465'
                switch infos.imapPort
                    when '993'
                        infos.imapSSL = true
                        infos.imapTLS = false
                    else
                        infos.imapSSL = false
                        infos.imapTLS = false
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
        console.log port, infos
        @setState infos

    componentWillReceiveProps: (props) ->


        # prevents the form from changing during submission
        if not props.isWaiting
            # display the account values
            if not props.selectedAccount? or
            @state.id isnt props.selectedAccount.get 'id'
                tab = "account"
            else
                tab = @state.tab
            if props.selectedAccount?
                @setState @_accountToState(tab)
            else
                state =
                    tab: null
                    errors: {}
                if props.error?
                    if props.error.name is 'AccountConfigError'
                        field = props.error.field
                        state.errors[field] = t 'config error ' + field
                @setState state

    getInitialState: (forceDefault) ->
        return @_accountToState("account")

    _accountToState: (tab)->
        account = @props.selectedAccount
        state =
            errors: {}
        if @props.error?
            if @props.error.name is 'AccountConfigError'
                field = @props.error.field
                errors[field] = t 'config error ' + @props.field
        if account?
            init = (field) ->
                state[field] = account.get field
            init field for field in @_accountFields
            state.newMailboxParent = null
            state.tab = tab
        else
            init = (field) ->
                state[field] = ''
            init field for field in @_accountFields
            state.smtpPort = 465
            state.smtpSSL  = true
            state.smtpTLS  = false
            state.imapPort = 993
            state.imapSSL  = true
            state.imapTLS  = false
            state.newMailboxParent = null
            state.tab = null

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
        "#{pusher}#{@props.mailbox.get 'label'}"
        if @state.favorite
            favoriteClass = "fa fa-eye"
            favoriteTitle = t "mailbox title favorite"
        else
            favoriteClass = "fa fa-eye-slash"
            favoriteTitle = t "mailbox title not favorite"
        li key: key,
            if @state.edited
                div className: "box edited",
                    span
                        className: "box-action"
                        onClick: @updateMailbox
                        title: t("mailbox title edit save"),
                            i className: 'fa fa-check'
                    span
                        className: "box-action"
                        onClick: @undoMailbox
                        title: t("mailbox title edit cancel"),
                            i className: 'fa fa-undo'
                    input
                        className: "box-label form-control"
                        ref: 'label',
                        defaultValue: @props.mailbox.get 'label'
                        type: 'text'
            else
                div className: "box",
                    span
                        className: "box-action",
                        onClick: @editMailbox,
                        title: t("mailbox title edit"),
                            i className: 'fa fa-pencil'
                    span
                        className: "box-action",
                        onClick: @deleteMailbox,
                        title: t("mailbox title delete"),
                            i className: 'fa fa-trash-o'
                    span
                        className: "box-label",
                        onClick: @editMailbox,
                        "#{pusher}#{@props.mailbox.get 'label'}"
                    span
                        className: "box-action",
                        title: favoriteTitle
                        onClick: @toggleFavorite,
                            i className: favoriteClass

    editMailbox: (e) ->
        e.preventDefault()
        @setState edited: true

    undoMailbox: (e) ->
        e.preventDefault()
        @setState edited: false

    updateMailbox: (e) ->
        e.preventDefault()

        mailbox =
            label: @refs.label.getDOMNode().value.trim()
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.account.get 'id'

        AccountActionCreator.mailboxUpdate mailbox, (error) ->
            if error?
                LAC.alertError "#{t("mailbox update ko")} #{error}"
            else
                LAC.alertSuccess t "mailbox update ok"

    toggleFavorite: (e) ->

        mailbox =
            favorite: not @state.favorite
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.account.get 'id'

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
                accountID: @props.account.get 'id'

            AccountActionCreator.mailboxDelete mailbox, (error) ->
                if error?
                    LAC.alertError "#{t("mailbox delete ko")} #{error}"
                else
                    LAC.alertSuccess t "mailbox delete ok"
