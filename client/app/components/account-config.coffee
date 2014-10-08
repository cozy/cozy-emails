{div, h3, form, label, input, button} = React.DOM
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
            }
        else
            return {
                label:        ''
                name:         ''
                login:        ''
                password:     ''
                smtpServer:   ''
                smtpPort:     587
                imapServer:   ''
                imapPort:     993
                draftMailbox: ''
                sentMailbox:  ''
                trashMailbox: ''
            }
