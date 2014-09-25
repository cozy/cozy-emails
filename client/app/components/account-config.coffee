{div, h3, form, label, input, button} = React.DOM
classer = React.addons.classSet

MailboxList   = require './mailbox-list'
AccountStore         = require '../stores/account_store'
AccountActionCreator = require '../actions/account_action_creator'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

module.exports = React.createClass
    displayName: 'AccountConfig'

    mixins: [
        StoreWatchMixin [AccountStore]
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->
        titleLabel = if @props.initialAccountConfig? then t "account edit" else t "account new"

        if @props.isWaiting then buttonLabel = 'Saving...'
        else if @props.initialAccountConfig? then buttonLabel = t "account save"
        else buttonLabel = t "account add"

        if @props.initialAccountConfig?
            mailboxes = @props.initialAccountConfig.get 'mailboxes'

        div id: 'mailbox-config',
            h3 className: null, titleLabel

            if @props.error
                div className: 'error', @props.error

            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'mailbox-label', className: 'col-sm-2 col-sm-offset-2 control-label', t "account label"
                    div className: 'col-sm-3',
                        input id: 'mailbox-label', valueLink: @linkState('label'), type: 'text', className: 'form-control', placeholder: t "account name short"
                div className: 'form-group',
                    label htmlFor: 'mailbox-name', className: 'col-sm-2 col-sm-offset-2 control-label', t "account user name"
                    div className: 'col-sm-3',
                        input id: 'mailbox-name', valueLink: @linkState('name'), type: 'text', className: 'form-control', placeholder: t "account user fullname"
                div className: 'form-group',
                    label htmlFor: 'mailbox-email-address', className: 'col-sm-2 col-sm-offset-2 control-label', t "account address"
                    div className: 'col-sm-3',
                        input id: 'mailbox-email-address', valueLink: @linkState('login'), ref: 'login', onBlur: @discover, type: 'email', className: 'form-control', placeholder: t "account address placeholder"
                div className: 'form-group',
                    label htmlFor: 'mailbox-password', className: 'col-sm-2 col-sm-offset-2 control-label', t 'account password'
                    div className: 'col-sm-3',
                        input id: 'mailbox-password', valueLink: @linkState('password'), type: 'password', className: 'form-control'

                div className: 'form-group',
                    label htmlFor: 'mailbox-smtp-server', className: 'col-sm-2 col-sm-offset-2 control-label', t "account sending server"
                    div className: 'col-sm-3',
                        input id: 'mailbox-smtp-server', valueLink: @linkState('smtpServer'), type: 'text', className: 'form-control', placeholder: 'smtp.provider.tld'
                    label htmlFor: 'mailbox-smtp-port', className: 'col-sm-1 control-label', 'Port'
                        div className: 'col-sm-1',
                            input id: 'mailbox-smtp-port', valueLink: @linkState('smtpPort'), type: 'text', className: 'form-control'

                div className: 'form-group',
                    label htmlFor: 'mailbox-imap-server', className: 'col-sm-2 col-sm-offset-2 control-label', t "account receiving server"
                    div className: 'col-sm-3',
                        input id: 'mailbox-imap-server', valueLink: @linkState('imapServer'), type: 'text', className: 'form-control', placeholder: 'imap.provider.tld'
                    label htmlFor: 'mailbox-imap-port', className: 'col-sm-1 control-label', 'Port'
                    div className: 'col-sm-1',
                        input id: 'mailbox-imap-port', valueLink: @linkState('imapPort'), type: 'text', className: 'form-control'

                if @props.initialAccountConfig?
                    div className: 'form-group',
                        label className: 'col-sm-2 col-sm-offset-2 control-label', t 'account draft mailbox'
                        div className: 'col-sm-3',
                            MailboxList
                                selectedAccount: @props.initiaAccountConfig
                                mailboxes: mailboxes
                                selectedMailbox: @state.draftMailbox
                                onChange: (mailbox) => @setState 'draftMailbox': mailbox

                if @props.initialAccountConfig?
                    div className: 'form-group',
                        label className: 'col-sm-2 col-sm-offset-2 control-label', t 'account sent mailbox'
                        div className: 'col-sm-3',
                            MailboxList
                                selectedAccount: @props.initiaAccountConfig
                                mailboxes: mailboxes
                                selectedMailbox: @state.sentMailbox
                                onChange: (mailbox) => @setState 'sentMailbox': mailbox

                if @props.initialAccountConfig?
                    div className: 'form-group',
                        label className: 'col-sm-2 col-sm-offset-2 control-label', t 'account trash mailbox'
                        div className: 'col-sm-3',
                            MailboxList
                                selectedAccount: @props.initiaAccountConfig
                                mailboxes: mailboxes
                                selectedMailbox: @state.trashMailbox
                                onChange: (mailbox) => @setState 'trashMailbox': mailbox

                div className: 'form-group',
                    div className: 'col-sm-offset-2 col-sm-5 text-right',
                        if @props.initialAccountConfig?
                            button className: 'btn btn-cozy', onClick: @onRemove, t "account remove"
                        button className: 'btn btn-cozy', onClick: @onSubmit, buttonLabel

    onSubmit: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        accountValue = @state
        accountValue.draftMailbox = accountValue.draftMailbox?.get 'id'
        accountValue.sentMailbox  = accountValue.sentMailbox?.get 'id'
        accountValue.trashMailbox = accountValue.trashMailbox?.get 'id'

        if @props.initialAccountConfig?
            AccountActionCreator.edit accountValue, @props.initialAccountConfig.get 'id'
        else
            AccountActionCreator.create accountValue

    onRemove: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        AccountActionCreator.remove @props.initialAccountConfig.get 'id'


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
            @setState @_accountToState(props.initialAccountConfig)



    getStateFromStores: ->
        return @_accountToState(@props.initialAccountConfig)

    _accountToState: (account)->
        if account?
            mailboxes = account.get 'mailboxes'
            draft = account.get 'draftMailbox'
            if draft?
                draftMailbox = mailboxes.get draft
            sent = account.get 'sentMailbox'
            if sent?
                sentMailbox = mailboxes.get sent
            trash = account.get 'trashMailbox'
            if trash?
                trashMailbox = mailboxes.get trash

            return {
                label:        account.get 'label'
                name:         account.get 'name'
                login:        account.get 'login'
                password:     account.get 'password'
                smtpServer:   account.get 'smtpServer'
                smtpPort:     account.get 'smtpPort'
                imapServer:   account.get 'imapServer'
                imapPort:     account.get 'imapPort'
                draftMailbox: draftMailbox or mailboxes.first()
                sentMailbox:  sentMailbox  or mailboxes.first()
                trashMailbox: trashMailbox or mailboxes.first()
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
            }
