{div, h3, h4, form, label, input, button, ul, li, a, span, i} = React.DOM
classer = React.addons.classSet

MailboxList   = require './mailbox-list'
AccountActionCreator = require '../actions/account_action_creator'
LAC  = require '../actions/layout_action_creator'

classer = React.addons.classSet

module.exports = React.createClass
    displayName: 'AccountConfig'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

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

        if @props.error
            div className: 'error', @props.error

        form className: 'form-horizontal',
            div className: 'form-group',
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
            div className: 'form-group',
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
            div className: 'form-group',
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
            div className: 'form-group',
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

            div className: 'form-group',
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
                    'Port'
                        div
                            className: 'col-sm-1',
                        input
                            id: 'mailbox-smtp-port',
                            valueLink: @linkState('smtpPort'),
                            type: 'text',
                            className: 'form-control'

            div className: 'form-group',
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
                        className: 'form-control'

            @_renderMailboxChoice 'account draft mailbox', "draftMailbox"
            @_renderMailboxChoice 'account sent mailbox',  "sentMailbox"
            @_renderMailboxChoice 'account trash mailbox', "trashMailbox"

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
        mailboxes = @props.mailboxes.map (mailbox, key) =>
            favorite = true if favorites.get(mailbox.get('id'))
            MailboxItem {account: @props.selectedAccount, mailbox, favorite}
        .toJS()
        div null,

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

        accountValue = @state
        accountValue.draftMailbox = accountValue.draftMailbox
        accountValue.sentMailbox  = accountValue.sentMailbox
        accountValue.trashMailbox = accountValue.trashMailbox

        if @props.selectedAccount?
            AccountActionCreator.edit accountValue,
                @props.selectedAccount.get 'id'
        else
            AccountActionCreator.create accountValue

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
                    infos.imapPort   = ''
                if not infos.smtpServer?
                    infos.smtpServer = ''
                    infos.smtpPort   = ''
                @setState infos


    componentWillReceiveProps: (props) ->
        # prevents the form from changing during submission
        if not props.isWaiting
            # display the account values
            if @state.id isnt props.selectedAccount.get 'id'
                tab = "account"
            else
                tab = @state.tab
            @setState @_accountToState(props.selectedAccount, tab)

    getInitialState: (forceDefault) ->
        return @_accountToState(@props.selectedAccount, "account")

    _accountToState: (account, tab)->
        if account?
            return {
                id:           account.get 'id'
                label:        account.get 'label'
                name:         account.get 'name'
                login:        account.get 'login'
                password:     account.get 'password'
                smtpServer:   account.get 'smtpServer'
                smtpPort:     account.get 'smtpPort'
                imapServer:   account.get 'imapServer'
                imapPort:     account.get 'imapPort'
                draftMailbox: account.get 'draftMailbox'
                sentMailbox:  account.get 'sentMailbox'
                trashMailbox: account.get 'trashMailbox'
                newMailboxParent: null
                tab: tab
            }
        else
            return {
                id:           null
                label:        ''
                name:         ''
                login:        ''
                password:     ''
                smtpServer:   ''
                smtpPort:     993
                imapServer:   ''
                imapPort:     465
                draftMailbox: ''
                sentMailbox:  ''
                trashMailbox: ''
                newMailboxParent: null
                tab: null
            }

MailboxItem = React.createClass
    displayName: 'MailboxItem'

    propTypes:
        mailbox: React.PropTypes.object

    componentWillReceiveProps: (props) ->
        @setState edited: false

    getInitialState: ->
        return {
            edited: false
        }

    render: ->
        pusher = ""
        pusher += "--" for j in [1..@props.mailbox.get('depth')] by 1
        key = @props.mailbox.get 'id'
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
                    input
                        ref: 'favorite',
                        defaultChecked: @props.favorite,
                        onChange: @toggleFavorite,
                        type: 'checkbox',
                        className: 'box-action'

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
            favorite: @refs.favorite.getDOMNode().checked
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.account.get 'id'

        AccountActionCreator.mailboxUpdate mailbox, (error) ->
            if error?
                LAC.alertError "#{t("mailbox update ko")} #{error}"
            else
                LAC.alertSuccess t "mailbox update ok"

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
