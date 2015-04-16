{
    div, p, h3, h4, form, label, input, button, ul, li, a, span, i,
    fieldset, legend
} = React.DOM
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
        'smtpLogin', 'smtpPassword', 'smtpMethod',
        'accountType'
    ]

    _mailboxesFields: [
        'id', 'mailboxes', 'favoriteMailboxes',
        'draftMailbox', 'sentMailbox', 'trashMailbox'
    ]

    _accountSchema:
        properties:
            'label': allowEmpty: false
            'name': allowEmpty: false
            'login': allowEmpty: false
            'password': allowEmpty: false
            'imapServer': allowEmpty: false
            'imapPort': allowEmpty: false
            'imapSSL': allowEmpty: true
            'imapTLS': allowEmpty: true
            'smtpServer': allowEmpty: false
            'smtpPort': allowEmpty: false
            'smtpSSL': allowEmpty: true
            'smtpTLS': allowEmpty: true
            'smtpLogin': allowEmpty: true
            'smtpMethod': allowEmpty: true
            'smtpPassword': allowEmpty: true
            'draftMailbox': allowEmpty: true
            'sentMailbox': allowEmpty: true
            'trashMailbox': allowEmpty: true
            'accountType': allowEmpty: true


    shouldComponentUpdate: (nextProps, nextState) ->
        isNextState = not _.isEqual nextState, @state
        isNextProps = not _.isEqual nextProps, @props
        return not (isNextState and isNextProps)


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

        mainOptions =
            isWaiting: @props.isWaiting
            selectedAccount: @props.selectedAccount
            validateForm: @validateForm
            onSubmit: @onSubmit
            errors: @state.errors

        for field in @_accountFields
            mainOptions[field] = @linkState(field)

        mailboxesOptions =
            error: @props.error
            errors: @state.errors
            onSubmit: @onSubmit

        for field in @_mailboxesFields
            mailboxesOptions[field] = @linkState(field)

        div id: 'mailbox-config', key: 'account-config-' + @props.selectedAccount?.get('id'),
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
                AccountConfigMain mainOptions
            else
                AccountConfigMailboxes mailboxesOptions

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
        init field for field in @_mailboxesFields

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

    onSubmit: (event, check) ->
        if event?
            # prevents the page from reloading
            event.preventDefault()

        {accountValue, valid} = @doValidate()

        if valid.valid
            if @state.id?
                if check is true
                    AccountActionCreator.check accountValue, @state.id
                else
                    AccountActionCreator.edit accountValue, @state.id
            else
                AccountActionCreator.create accountValue, (account) =>
                    LAC.notify t("account creation ok"),
                        autoclose: true
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

    componentWillReceiveProps: (props) ->
        # prevents the form from changing during submission
        if props.selectedAccount? and not props.isWaiting
            @setState @_accountToState props

        else
            if props.error?
                if props.error.name is 'AccountConfigError'
                    errors = {}
                    field = props.error.field
                    if field is 'auth'
                        errors['login']    = t 'config error auth'
                        errors['password'] = t 'config error auth'
                    else
                        errors[field] = t 'config error ' + field
                    @setState errors: errors
            else
                if not props.isWaiting and not _.isEqual(props, @props)
                    @setState @_accountToState null

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
                    if field is 'auth'
                        state.errors['login']    = t 'config error auth'
                        state.errors['password'] = t 'config error auth'
                    else
                        state.errors[field] = t 'config error ' + field
        if account?
            if @state.id isnt account.get('id')
                for field in @_accountFields
                    state[field] = account.get field
                state.smtpMethod = 'PLAIN' if not state.smtpMethod?
            for field in @_mailboxesFields
                state[field] = account.get field
            state.newMailboxParent = null
            state.mailboxes         = props.mailboxes
            state.favoriteMailboxes = props.favoriteMailboxes
            if state.mailboxes.length is 0
                props.tab = 'mailboxes'
        else if Object.keys(state.errors).length is 0
            init = (field) ->
                state[field] = ''
            init field for field in @_accountFields
            init field for field in @_mailboxesFields
            state.id          = null
            state.smtpPort    = 465
            state.smtpSSL     = true
            state.smtpTLS     = false
            state.smtpMethod  = 'PLAIN'
            state.imapPort    = 993
            state.imapSSL     = true
            state.imapTLS     = false
            state.accountType = 'IMAP'
            state.newMailboxParent  = null
            state.favoriteMailboxes = null

        return state


AccountConfigMailboxes = React.createClass
    displayName: 'AccountConfigMailboxes'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))

    _propsToState: (props) ->
        state = props
        state.mailboxesFlat = {}
        if state.mailboxes.value isnt ''
            state.mailboxes.value.map (mailbox, key) ->
                id = mailbox.get 'id'
                state.mailboxesFlat[id] = {}
                ['id', 'label', 'depth'].map (prop) ->
                    state.mailboxesFlat[id][prop] = mailbox.get prop
            .toJS()
        return state

    getInitialState: ->
        @_propsToState(@props)

    componentWillReceiveProps: (props) ->
        @setState @_propsToState(props)

    render: ->
        favorites = @state.favoriteMailboxes.value
        if @state.mailboxes.value isnt '' and favorites isnt ''
            mailboxes = @state.mailboxes.value.map (mailbox, key) =>
                try
                    favorite = favorites.get(mailbox.get('id'))?
                    MailboxItem {accountID: @state.id.value, mailbox, favorite}
                catch error
                    console.error error, favorites
            .toJS()
        form className: 'form-horizontal',

            @renderError()
            h4 className: 'config-title', t "account special mailboxes"
            @_renderMailboxChoice t('account draft mailbox'), "draftMailbox"
            @_renderMailboxChoice t('account sent mailbox'),  "sentMailbox"
            @_renderMailboxChoice t('account trash mailbox'), "trashMailbox"

            h4 className: 'config-title', t "account mailboxes"
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
                            mailboxes: @state.mailboxesFlat
                            selectedMailboxID: @state.newMailboxParent
                            onChange: (mailbox) =>
                                @setState newMailboxParent: mailbox

    renderError: ->
        if @props.error and @props.error.name is 'AccountConfigError'
            message = t 'config error ' + @props.error.field
            div className: 'alert alert-warning', message
        else if @props.error
            div className: 'alert alert-warning', @props.error.message
        else if Object.keys(@state.errors).length isnt 0
            div className: 'alert alert-warning', t 'account errors'

    _renderMailboxChoice: (labelText, box) ->
        if @state.id? and @state.mailboxes.value isnt ''
            errorClass = if @state[box].value? then '' else 'has-error'
            div className: "form-group #{box} #{errorClass}",
                label
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    labelText
                div className: 'col-sm-3',
                    MailboxList
                        allowUndefined: true
                        mailboxes: @state.mailboxesFlat
                        selectedMailboxID: @state[box].value
                        onChange: (mailbox) =>
                            # requestChange is asynchroneous, so we need
                            # to also call setState to only call onSubmet
                            # once state has really been updated
                            @state[box].requestChange mailbox
                            newState = {}
                            newState[box] =
                                value = mailbox
                            @setState newState, =>
                                @props.onSubmit()

    onKeyDown: (evt) ->
        switch evt.key
            when "Enter"
                @addMailbox()

    addMailbox: (event) ->
        event?.preventDefault()

        mailbox =
            label: @refs.newmailbox.getDOMNode().value.trim()
            accountID: @state.id.value
            parentID: @state.newMailboxParent

        AccountActionCreator.mailboxCreate mailbox, (error) =>
            if error?
                LAC.alertError "#{t("mailbox create ko")} #{error}"
            else
                LAC.notify t("mailbox create ok"),
                    autoclose: true
                @refs.newmailbox.getDOMNode().value = ''

    undoMailbox: (event) ->
        event.preventDefault()

        @refs.newmailbox.getDOMNode().value = ''
        @setState newMailboxParent: null

MailboxItem = React.createClass
    displayName: 'MailboxItem'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    propTypes:
        mailbox: React.PropTypes.object

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))

    #componentWillReceiveProps: (props) ->
    #    @setState edited: false

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

        AccountActionCreator.mailboxUpdate mailbox, (error) =>
            if error?
                LAC.alertError "#{t("mailbox update ko")} #{error}"
            else
                LAC.notify t("mailbox update ok"),
                    autoclose: true
                @setState edited: false

    toggleFavorite: (e) ->
        mailbox =
            favorite: not @state.favorite
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.accountID

        AccountActionCreator.mailboxUpdate mailbox, (error) ->
            if error?
                LAC.alertError "#{t("mailbox update ko")} #{error}"
            else
                LAC.notify t("mailbox update ok"),
                    autoclose: true

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
                    LAC.notify t("mailbox delete ok"),
                        autoclose: true

AccountInput = React.createClass
    displayName: 'AccountInput'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    getInitialState: ->
        return @props

    componentWillReceiveProps: (props) ->
        @setState props

    render: ->
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

        name = @props.name
        type = @props.type or 'text'
        errorField = @props.errorField or name

        div
            key: "account-input-#{name}",
            className: "form-group account-item-#{name} " + hasError(errorField),
                label
                    htmlFor: "mailbox-#{name}",
                    className: "col-sm-2 col-sm-offset-2 control-label",
                    t "account #{name}"
                div className: 'col-sm-3',
                    if type isnt 'checkbox'
                        input
                            id: "mailbox-#{name}",
                            name: "mailbox-#{name}",
                            valueLink: @linkState('value').value,
                            type: type,
                            className: 'form-control',
                            placeholder: if (type is 'text' or type is 'email') then t("account #{name} short") else null
                            onBlur: @props.onBlur or null#@props.validateForm
                            onInput: @props.onInput or null
                    else
                        input
                            id: "mailbox-#{name}",
                            name: "mailbox-#{name}",
                            checkedLink: @linkState('value').value,
                            type: type,
                            onClick: @props.onClick
                getError name
