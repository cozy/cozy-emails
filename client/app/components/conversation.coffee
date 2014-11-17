{div, ul, li, span, i, p, h3, a} = React.DOM
Message = require './message'
classer = React.addons.classSet

RouterMixin = require '../mixins/router_mixin'

module.exports = React.createClass
    displayName: 'Conversation'

    mixins: [RouterMixin]

    propTypes:
        message           : React.PropTypes.object
        conversation      : React.PropTypes.array
        selectedAccount   : React.PropTypes.object.isRequired
        layout            : React.PropTypes.string.isRequired
        selectedMailboxID : React.PropTypes.string.isRequired
        mailboxes         : React.PropTypes.object.isRequired
        settings          : React.PropTypes.object.isRequired
        accounts          : React.PropTypes.object.isRequired

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->
        if not @props.message? or not @props.conversation
            return p null, t "app loading"

        expandUrl = @buildUrl
            direction: 'first'
            action: 'message'
            parameters: @props.message.get 'id'
            fullWidth: true

        if window.router.previous?
            try
                selectedAccountID = @props.selectedAccount.get 'id'
            catch
                selectedAccountID = @props.conversation[0].mailbox
        else
            selectedAccountID = @props.conversation[0].mailbox

        collapseUrl = @buildUrl
            firstPanel:
                action: 'account.mailbox.messages'
                parameters: selectedAccountID
            secondPanel:
                action: 'message'
                parameters: @props.conversation[0].get 'id'

        if @props.layout is 'full'
            closeUrl = @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: selectedAccountID
                fullWidth: true
        else
            closeUrl = @buildClosePanelUrl @props.layout

        closeIcon = if @props.layout is 'full' then 'fa-th-list' else 'fa-times'
        inConversation = @props.conversation.length > 1

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
                a
                    href: closeUrl,
                    className: 'close-conversation hidden-xs hidden-sm',
                        i className:'fa ' + closeIcon
                @props.message.get 'subject'
                if @props.layout isnt 'full'
                    a
                        href: expandUrl,
                        className: 'expand hidden-xs hidden-sm',
                            i className: 'fa fa-arrows-h'
                else
                    a
                        href: collapseUrl,
                        className: 'close-conversation pull-right',
                            i className:'fa fa-compress'

            ul className: 'thread list-unstyled',
                for message, key in @props.conversation
                    active = @props.message.get('id') is message.get('id')
                    Message
                        accounts: @props.accounts
                        active: active
                        inConversation: inConversation
                        key: key
                        mailboxes: @props.mailboxes
                        message: message
                        nextID: @props.nextID
                        prevID: @props.prevID
                        selectedAccount: @props.selectedAccount
                        selectedMailboxID: @props.selectedMailboxID
                        settings: @props.settings
