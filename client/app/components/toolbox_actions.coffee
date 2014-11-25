{div, ul, li, span, i, p, a, button} = React.DOM
{MessageFlags, FlagsConstants} = require '../constants/app_constants'

module.exports = ToolboxActions = React.createClass
    displayName: 'ToolboxActions'

    render: ->
        div className: 'btn-group btn-group-sm',
            button
                className: 'btn btn-default dropdown-toggle more',
                type: 'button',
                'data-toggle': 'dropdown',
                t 'mail action more',
                    span className: 'caret'
            ul className: 'dropdown-menu dropdown-menu-right', role: 'menu',
                li
                    role: 'presentation',
                    t 'mail action mark'
                if (not @props.isSeen?) or @props.isSeen is true
                    li null,
                        a
                            role: 'menuitem',
                            onClick: @props.onMark,
                            'data-value': FlagsConstants.SEEN,
                            t 'mail mark read'
                if (not @props.isSeen?) or @props.isSeen is false
                    li null,
                        a role: 'menuitem',
                        onClick: @props.onMark,
                        'data-value': FlagsConstants.UNSEEN,
                        t 'mail mark unread'
                if (not @props.isFlagged?) or @props.isFlagged is true
                    li null,
                        a
                            role: 'menuitem',
                            onClick: @props.onMark,
                            'data-value': FlagsConstants.FLAGGED,
                            t 'mail mark fav'
                if (not @props.isFlagged?) or @props.isFlagged is false
                    li null,
                        a
                            role: 'menuitem',
                            onClick: @props.onMark,
                            'data-value': FlagsConstants.NOFLAG,
                            t 'mail mark nofav'
                li role: 'presentation', className: 'divider'
                if @props.messageID?
                    li role: 'presentation',
                        a
                            onClick: @props.onHeaders,
                            'data-message-id': @props.messageID,
                            t 'mail action headers'
                li role: 'presentation',
                    a
                        onClick: @props.onConversation,
                        'data-action' : 'delete',
                        t 'mail action conversation delete'
                li role: 'presentation',
                    a
                        onClick: @props.onConversation,
                        'data-action' : 'seen',
                        t 'mail action conversation seen'
                li role: 'presentation',
                    a
                        onClick: @props.onConversation,
                        'data-action' : 'unseen',
                        t 'mail action conversation unseen'
                li role: 'presentation', className: 'divider'
                li
                    role: 'presentation',
                    t 'mail action conversation move'
                @props.mailboxes.map (mailbox, key) =>
                    @renderMailboxes mailbox, key, true
                .toJS()
                li role: 'presentation', className: 'divider'

    renderMailboxes: (mailbox, key, conversation) ->
        # Don't display current mailbox
        if mailbox.get('id') is @props.selectedMailboxID
            return
        pusher = ""
        pusher += "--" for j in [1..mailbox.get('depth')] by 1
        li role: 'presentation', key: key,
            a
                role: 'menuitem',
                onClick: @onMove,
                'data-value': key,
                'data-conversation': conversation,
                "#{pusher}#{mailbox.get 'label'}"

