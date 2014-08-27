React = require 'react/addons'

{div, ul, li, span, i, p, h3, a} = React.DOM
Message = require './message'
classer = React.addons.classSet

RouterMixin = require '../mixins/RouterMixin'

module.exports = React.createClass
    displayName: 'Conversation'

    mixins: [RouterMixin]

    render: ->
        if not @props.message? or not @props.conversation
            return p null, t "app loading"

        expandUrl = @buildUrl
            direction: 'left'
            action: 'message'
            parameters: @props.message.get 'id'
            fullWidth: true

        if window.router.previous?
            selectedAccountID = @props.selectedAccount.get 'id'
        else
            selectedAccountID = @props.conversation[0].mailbox

        collapseUrl = @buildUrl
            leftPanel:
                action: 'account.messages'
                parameters: selectedAccountID
            rightPanel:
                action: 'message'
                parameters: @props.conversation[0].get 'id'

        if @props.layout is 'full'
            closeUrl = @buildUrl
                direction: 'left'
                action: 'account.messages'
                parameters: selectedAccountID
                fullWidth: true
        else
            closeUrl = @buildClosePanelUrl @props.layout

        closeIcon = if @props.layout is 'full' then 'fa-th-list' else 'fa-times'

        div className: 'conversation',

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
                a href: closeUrl, className: 'close-conversation hidden-xs hidden-sm',
                    i className:'fa ' + closeIcon
                @props.message.get 'subject'
                if @props.layout isnt 'full'
                    a href: expandUrl, className: 'expand hidden-xs hidden-sm',
                        i className: 'fa fa-arrows-h'
                else
                    a href: collapseUrl, className: 'close-conversation pull-right',
                        i className:'fa fa-compress'

            ul className: 'thread list-unstyled',
                for message, key in @props.conversation
                    isLast = key is @props.conversation.length - 1
                    Message {message, key, isLast}
