React = require 'react/addons'
{div, h3, form, label, input, button} = React.DOM
classer = React.addons.classSet

MailboxActionCreator = require '../actions/MailboxActionCreator'

module.exports = React.createClass
    displayName: 'MailboxConfig'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->
        titleLabel = if @props.initialMailboxConfig? then t "mailbox edit" else t "mailbox new"

        if @props.isWaiting then buttonLabel = 'Saving...'
        else if @props.initialMailboxConfig? then buttonLabel = 'Edit'
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
                        input id: 'mailbox-email-address', valueLink: @linkState('email'), type: 'email', className: 'form-control', placeholder: t "mailbox address placeholder"
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
                        if @props.initialMailboxConfig?
                            button className: 'btn btn-cozy', onClick: @onRemove, t "mailbox remove"
                        button className: 'btn btn-cozy', onClick: @onSubmit, buttonLabel
    onSubmit: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        mailboxValue = @state
        if @props.initialMailboxConfig?
            mailboxValue.id = @props.initialMailboxConfig.get 'id'
            MailboxActionCreator.edit @state
        else
            MailboxActionCreator.create @state

    onRemove: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        MailboxActionCreator.remove @props.initialMailboxConfig.get 'id'

    componentWillReceiveProps: (props) ->
        # prevents the form from changing during submission
        if not props.isWaiting
            # display the mailbox values
            if props.initialMailboxConfig?
                @setState props.initialMailboxConfig.toJS()
            else # reset the form if it is on 'new mailbox' page
                @setState @getInitialState true


    getInitialState: (forceDefault) ->
        if @props.initialMailboxConfig? and not forceDefault
            return {
                label: @props.initialMailboxConfig.get 'label'
                name: @props.initialMailboxConfig.get 'name'
                email: @props.initialMailboxConfig.get 'email'
                password: @props.initialMailboxConfig.get 'password'
                smtpServer: @props.initialMailboxConfig.get 'smtpServer'
                smtpPort: @props.initialMailboxConfig.get 'smtpPort'
                imapServer: @props.initialMailboxConfig.get 'imapServer'
                imapPort: @props.initialMailboxConfig.get 'imapPort'
            }
        else
            return {
                label: ''
                name: ''
                email: ''
                password: ''
                smtpServer: ''
                smtpPort: 993
                imapServer: ''
                imapPort: 465
            }

