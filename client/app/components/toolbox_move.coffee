{div, ul, li, span, i, p, a, button} = React.DOM
LayoutActionCreator       = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
module.exports = ToolboxMove = React.createClass
    displayName: 'ToolboxMove'

    render: ->
        div className: 'btn-group btn-group-sm',
            button
                className: 'btn btn-default dropdown-toggle move',
                type: 'button',
                'data-toggle': 'dropdown',
                t 'mail action move',
                    span className: 'caret'
            ul
                className: 'dropdown-menu dropdown-menu-right',
                role: 'menu',
                    @props.mailboxes.map (mailbox, key) =>
                        @renderMailboxes mailbox, key
                    .toJS()

    renderMailboxes: (mailbox, key, conversation) ->
        # Don't display current mailbox
        if mailbox.get('id') is @props.selectedMailboxID
            return
        pusher = ""
        pusher += "--" for j in [1..mailbox.get('depth')] by 1
        li role: 'presentation', key: key,
            a
                role: 'menuitem',
                onClick: @props.onMove,
                'data-value': key,
                'data-conversation': conversation,
                "#{pusher}#{mailbox.get 'label'}"

