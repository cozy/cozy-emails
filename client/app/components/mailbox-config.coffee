{div, h3, form, label, input, button} = React.DOM
classer = React.addons.classSet

FluxChildMixin = Fluxxor.FluxChildMixin React

module.exports = React.createClass
    displayName: 'MailboxConfig'

    mixins: [
        FluxChildMixin # makes `@getFlux()` available
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->
        # width depends on layout: one panel or full width
        inputClass = if @props.layout is 'full' then 'col-sm-3' else 'col-sm-6'
        portClass = if @props.layout is 'full' then 'col-sm-1' else 'col-sm-2'
        labelClass = if @props.layout is 'full' then 'col-sm-2 col-sm-offset-2' else 'col-sm-3'
        labelClass = "#{labelClass} control-label"

        titleLabel = if @props.initialMailboxConfig? then 'Edit mailbox' else 'New mailbox'

        if @props.isWaiting then buttonLabel = 'Saving...'
        else if @props.initialMailboxConfig? then buttonLabel = 'Edit'
        else buttonLabel = 'Add'

        div id: 'mailbox-new',
            h3 className: null, titleLabel

            if @props.error
                div className: 'error', @props.error

            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'mailbox-label', className: labelClass, 'Label'
                    div className: inputClass,
                        input id: 'mailbox-label', valueLink: @linkState('label'), type: 'text', className: 'form-control', placeholder: 'A short mailbox name'
                div className: 'form-group',
                    label htmlFor: 'mailbox-name', className: labelClass, 'Your name'
                    div className: inputClass,
                        input id: 'mailbox-name', valueLink: @linkState('name'), type: 'text', className: 'form-control', placeholder: 'Your name, as it will be displayed'
                div className: 'form-group',
                    label htmlFor: 'mailbox-email-address', className: labelClass, 'Email address'
                    div className: inputClass,
                        input id: 'mailbox-email-address', valueLink: @linkState('email'), type: 'email', className: 'form-control', placeholder: 'Your email address'
                div className: 'form-group',
                    label htmlFor: 'mailbox-password', className: labelClass, 'Password'
                    div className: inputClass,
                        input id: 'mailbox-password', valueLink: @linkState('password'), type: 'password', className: 'form-control'

                div className: 'form-group',
                    label htmlFor: 'mailbox-smtp-server', className: labelClass, 'Sending server'
                    div className: inputClass,
                        input id: 'mailbox-smtp-server', valueLink: @linkState('smtpServer'), type: 'text', className: 'form-control', placeholder: 'smtp.provider.tld'
                    label htmlFor: 'mailbox-smtp-port', className: 'col-sm-1 control-label', 'Port'
                        div className: portClass,
                            input id: 'mailbox-smtp-port', valueLink: @linkState('smtpPort'), type: 'text', className: 'form-control'

                div className: 'form-group',
                    label htmlFor: 'mailbox-imap-server', className: labelClass, 'Receiving server'
                    div className: inputClass,
                        input id: 'mailbox-imap-server', valueLink: @linkState('imapServer'), type: 'text', className: 'form-control', placeholder: 'imap.provider.tld'
                    label htmlFor: 'mailbox-imap-port', className: 'col-sm-1 control-label', 'Port'
                    div className: portClass,
                        input id: 'mailbox-imap-port', valueLink: @linkState('imapPort'), type: 'text', className: 'form-control'

                div className: 'form-group',
                    div className: 'col-sm-offset-5 col-sm-1',
                        button className: 'btn btn-cozy', onClick: @onRemove, 'Remove'
                    div className: 'col-sm-2',
                        button className: 'btn btn-cozy', onClick: @onSubmit, buttonLabel
    onSubmit: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        mailboxValue = @state

        if @props.initialMailboxConfig?
            mailboxValue.id = @props.initialMailboxConfig.id
            @getFlux().actions.mailbox.edit @state
        else
            @getFlux().actions.mailbox.create @state

    onRemove: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        @getFlux().actions.mailbox.remove @props.initialMailboxConfig.id

    componentWillReceiveProps: (props) ->

        # prevents the form from changing during submission
        if not props.isWaiting
            # display the mailbox values
            if props.initialMailboxConfig?
                @setState props.initialMailboxConfig
            else # reset the form if it is on 'new mailbox' page
                @setState @getInitialState true


    getInitialState: (forceDefault) ->
        if @props.initialMailboxConfig and not forceDefault
            return {
                label: @props.initialMailboxConfig.label
                name: @props.initialMailboxConfig.name
                email: @props.initialMailboxConfig.email
                password: @props.initialMailboxConfig.password
                smtpServer: @props.initialMailboxConfig.smtpServer
                smtpPort: @props.initialMailboxConfig.smtpPort
                imapServer: @props.initialMailboxConfig.imapServer
                imapPort: @props.initialMailboxConfig.imapPort
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

