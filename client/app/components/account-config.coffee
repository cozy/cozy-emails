{div, h3, h4, form, label, input, button, ul, li, a, span, i} = React.DOM
classer = React.addons.classSet

MailboxList   = require './mailbox-list'
AccountActionCreator = require '../actions/account_action_creator'

module.exports = React.createClass
    displayName: 'AccountConfig'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->
        titleLabel = if @props.selectedAccount? then t "account edit" else t "account new"

        if @props.isWaiting then buttonLabel = 'Saving...'
        else if @props.selectedAccount? then buttonLabel = t "account save"
        else buttonLabel = t "account add"

        div id: 'mailbox-config',
            h3 className: null, titleLabel

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

            if @props.selectedAccount?
                @_renderMailboxes()

    _renderMailboxes: ->
        mailboxes = @props.mailboxes.map (mailbox, key) =>
            MailboxItem {account: @props.selectedAccount, mailbox: mailbox}
        .toJS()
        div null,
            h4 className: "mailboxes", t "account mailboxes"

            form className: 'form-horizontal',
                div className: 'form-group',
                    label
                        htmlFor: 'newmailbox',
                        className: 'col-sm-2 control-label',
                        t "account newmailbox label"
                    div className: 'col-sm-2',
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
                    span className: "col-sm-1 control-label", onClick: @addMailbox,
                        i className: 'fa fa-plus'
            ul className: "list-unstyled boxes",
                mailboxes

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
            AccountActionCreator.edit accountValue, @props.selectedAccount.get 'id'
        else
            AccountActionCreator.create accountValue

    onRemove: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        if window.confirm(t 'account remove confirm')
            AccountActionCreator.remove @props.selectedAccount.get 'id'


    addMailbox: (event) ->
        event.preventDefault()

        mailbox =
            label: @refs.newmailbox.getDOMNode().value.trim()
            accountID: @props.selectedAccount.get 'id'
            parentID: @state.newMailboxParent

        AccountActionCreator.mailboxCreate mailbox

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
            @setState @_accountToState(props.selectedAccount)

    getInitialState: (forceDefault) ->
        return @_accountToState(@props.selectedAccount)

    _accountToState: (account)->
        if account?
            return {
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
            }
        else
            return {
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
            }

MailboxItem = React.createClass
    displayName: 'MailboxItem'

    propTypes:
        mailbox: React.PropTypes.object

    #getDefaultProps: ->
    #    return {}

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
                div className: "box",
                    input
                        className: "box-label form-control"
                        ref: 'label',
                        defaultValue: @props.mailbox.get 'label'
                        type: 'text'
                    span
                        className: "box-action"
                        onClick: @updateMailbox,
                        i className: 'fa fa-check'
                    span
                        className: "box-action"
                        onClick: @undoMailbox,
                        i className: 'fa fa-undo'
            else
                div className: "box",
                    span
                        className: "box-label"
                        "#{pusher}#{@props.mailbox.get 'label'}"
                    span
                        className: "box-action"
                        onClick: @editMailbox,
                        i className: 'fa fa-pencil'
                    span
                        className: "box-action"
                        onClick: @deleteMailbox,
                        i className: 'fa fa-trash-o'

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

        AccountActionCreator.mailboxUpdate mailbox

    deleteMailbox: (e) ->
        e.preventDefault()

        if window.confirm(t 'account confirm delbox')
            mailbox =
                mailboxID: @props.mailbox.get 'id'
                accountID: @props.account.get 'id'

            AccountActionCreator.mailboxDelete mailbox
