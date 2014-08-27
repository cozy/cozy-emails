{div, ul, li, span, i, p, h3, a} = React.DOM
Email = require './email'
classer = React.addons.classSet

RouterMixin = require '../mixins/RouterMixin'

module.exports = EmailThread = React.createClass
    displayName: 'EmailThread'

    mixins: [RouterMixin]

    render: ->
        if not @props.email? or not @props.thread
            return p null, t "app loading"

        expandUrl = @buildUrl
            direction: 'left'
            action: 'email'
            parameters: @props.email.get('id')
            fullWidth: true

        if window.router.previous?
            selectedMailboxID = @props.selectedMailbox.get 'id'
        else
            selectedMailboxID = @props.thread[0].mailbox

        collapseUrl = @buildUrl
            leftPanel:
                action: 'mailbox.emails'
                parameters: selectedMailboxID
            rightPanel:
                action: 'email'
                parameters: @props.thread[0].get('id')

        if @props.layout is 'full'
            closeUrl = @buildUrl
                direction: 'left'
                action: 'mailbox.emails'
                parameters: selectedMailboxID
                fullWidth: true
        else
            closeUrl = @buildClosePanelUrl @props.layout

        closeIcon = if @props.layout is 'full' then 'fa-th-list' else 'fa-times'

        div id: 'email-thread',

            # allows multiple email open but UI is not good enough
            #ul className: 'nav nav-tabs nav-justified',
            #    li className: 'active',
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', 'x'
            #    li null,
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', 'x'
            #    li null,
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', 'x'
            #    li null,
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', 'x'
            #    li null,
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', 'x'

            h3 null,
                a href: closeUrl, className: 'close-email hidden-xs hidden-sm',
                    i className:'fa ' + closeIcon
                @props.email.get 'subject'
                if @props.layout isnt 'full'
                    a href: expandUrl, className: 'expand hidden-xs hidden-sm',
                        i className: 'fa fa-arrows-h'
                else
                    a href: collapseUrl, className: 'close-email pull-right',
                        i className:'fa fa-compress'

            ul className: 'email-thread list-unstyled',
                for email, key in @props.thread
                    isLast = key is @props.thread.length - 1
                    Email {email, key, isLast}
