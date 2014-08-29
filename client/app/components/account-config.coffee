{div, h3, form, label, input, button} = React.DOM
classer = React.addons.classSet

AccountActionCreator = require '../actions/AccountActionCreator'

module.exports = React.createClass
    displayName: 'AccountConfig'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->
        titleLabel = if @props.initialAccountConfig? then t "mailbox edit" else t "mailbox new"

        if @props.isWaiting then buttonLabel = 'Saving...'
        else if @props.initialAccountConfig? then buttonLabel = 'Edit'
        else buttonLabel = t "mailbox add"

        div id: 'mailbox-config',
            h3 className: null, titleLabel

            if @props.error
                div className: 'error', @props.error

            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'mailbox-label', className: 'col-sm-2 col-sm-offset-2 control-label', t "mailbox label"
                    div className: 'col-sm-3',
                        input id: 'mailbox-label', valueLink: @linkState('label'), type: 'text', className: 'form-control', placeholder: t "mailbox name short"
                div className: 'form-group',
                    label htmlFor: 'mailbox-name', className: 'col-sm-2 col-sm-offset-2 control-label', t "mailbox user name"
                    div className: 'col-sm-3',
                        input id: 'mailbox-name', valueLink: @linkState('name'), type: 'text', className: 'form-control', placeholder: t "mailbox user fullname"
                div className: 'form-group',
                    label htmlFor: 'mailbox-email-address', className: 'col-sm-2 col-sm-offset-2 control-label', t "mailbox address"
                    div className: 'col-sm-3',
                        input id: 'mailbox-email-address', valueLink: @linkState('login'), type: 'email', className: 'form-control', placeholder: t "mailbox address placeholder"
                div className: 'form-group',
                    label htmlFor: 'mailbox-password', className: 'col-sm-2 col-sm-offset-2 control-label', t 'mailbox password'
                    div className: 'col-sm-3',
                        input id: 'mailbox-password', valueLink: @linkState('password'), type: 'password', className: 'form-control'

                div className: 'form-group',
                    label htmlFor: 'mailbox-smtp-server', className: 'col-sm-2 col-sm-offset-2 control-label', t "mailbox sending server"
                    div className: 'col-sm-3',
                        input id: 'mailbox-smtp-server', valueLink: @linkState('smtpServer'), type: 'text', className: 'form-control', placeholder: 'smtp.provider.tld'
                    label htmlFor: 'mailbox-smtp-port', className: 'col-sm-1 control-label', 'Port'
                        div className: 'col-sm-1',
                            input id: 'mailbox-smtp-port', valueLink: @linkState('smtpPort'), type: 'text', className: 'form-control'

                div className: 'form-group',
                    label htmlFor: 'mailbox-imap-server', className: 'col-sm-2 col-sm-offset-2 control-label', t "mailbox receiving server"
                    div className: 'col-sm-3',
                        input id: 'mailbox-imap-server', valueLink: @linkState('imapServer'), type: 'text', className: 'form-control', placeholder: 'imap.provider.tld'
                    label htmlFor: 'mailbox-imap-port', className: 'col-sm-1 control-label', 'Port'
                    div className: 'col-sm-1',
                        input id: 'mailbox-imap-port', valueLink: @linkState('imapPort'), type: 'text', className: 'form-control'

                div className: 'form-group',
                    div className: 'col-sm-offset-2 col-sm-5 text-right',
                        if @props.initialAccountConfig?
                            button className: 'btn btn-cozy', onClick: @onRemove, t "mailbox remove"
                        button className: 'btn btn-cozy', onClick: @onSubmit, buttonLabel
    onSubmit: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        accountValue = @state
        if @props.initialAccountConfig?
            AccountActionCreator.edit accountValue, @props.initialAccountConfig.get 'id'
        else
            AccountActionCreator.create accountValue

    onRemove: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        AccountActionCreator.remove @props.initialAccountConfig.get 'id'

    componentWillReceiveProps: (props) ->
        # prevents the form from changing during submission
        if not props.isWaiting
            # display the account values
            if props.initialAccountConfig?
                @setState props.initialAccountConfig.toJS()
            else # reset the form if it is on 'new account' page
                @setState @getInitialState true


    getInitialState: (forceDefault) ->
        if @props.initialAccountConfig? and not forceDefault
            return {
                label: @props.initialAccountConfig.get 'label'
                name: @props.initialAccountConfig.get 'name'
                login: @props.initialAccountConfig.get 'login'
                password: @props.initialAccountConfig.get 'password'
                smtpServer: @props.initialAccountConfig.get 'smtpServer'
                smtpPort: @props.initialAccountConfig.get 'smtpPort'
                imapServer: @props.initialAccountConfig.get 'imapServer'
                imapPort: @props.initialAccountConfig.get 'imapPort'
            }
        else
            return {
                label: ''
                name: ''
                login: ''
                password: ''
                smtpServer: ''
                smtpPort: 993
                imapServer: ''
                imapPort: 465
            }

