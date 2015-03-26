{div, ul, li, span, a, button} = React.DOM

{MessageFlags, FlagsConstants} = require '../constants/app_constants'


module.exports = ToolboxActions = React.createClass
    displayName: 'ToolboxActions'

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))

    render: ->
        direction = if @props.direction is 'right' then 'right' else 'left'
        div className: 'menu-action btn-group btn-group-sm',
            button
                className: 'btn btn-default dropdown-toggle fa fa-cog'
                type: 'button'
                'data-toggle': 'dropdown'
                ' '
                    span className: 'caret'
            ul
                className: "dropdown-menu dropdown-menu-#{direction}"
                role: 'menu',
                    @renderMarkActions()...
                    li role: 'presentation', className: 'divider'
                    @renderRawActions()...
                    li role: 'presentation', className: 'divider'
                    li
                        role:      'presentation'
                        className: 'dropdown-header'
                        t 'mail action conversation move'
                    @renderMailboxes()


    renderMarkActions: ->
        seen = if @props.isSeen
            value: FlagsConstants.SEEN
            label: t 'mail mark read'
        else
            value: FlagsConstants.UNSEEN
            label: t 'mail mark unread'

        flag = if @props.isFlagged
            value: FlagsConstants.FLAGGED
            label: t 'mail mark fav'
        else
            value: FlagsConstants.NOFLAG
            label: t 'mail mark nofav'

        [
            li
                role:      'presentation'
                className: 'dropdown-header'
                t 'mail action mark'
            li role: 'presentation',
                a
                    role:    'menuitemu'
                    onClick: @props.onMark
                    value:   seen.value
                    seen.label
            li role: 'presentation',
                a
                    role:    'menuitemu'
                    onClick: @props.onMark
                    value:   flag.value
                    flag.label
        ]


    renderRawActions: ->
        items = []

        items.push li
            role:      'presentation'
            className: 'dropdown-header'
            t 'mail action more'

        if @props.messageID?
            items.push li role: 'presentation',
                a
                    onClick:           @props.onHeaders
                    'data-message-id': @props.messageID
                    t 'mail action headers'

        if @props.message?
            items.push li role: 'presentation',
                a
                    href:   "raw/#{@props.message.get 'id'}"
                    target: '_blank'
                    t 'mail action raw'

        items.push li role: 'presentation',
            a
                onClick:       @props.onConversation,
                'data-action': 'delete',
                t 'mail action conversation delete'

        items.push li role: 'presentation',
            a
                onClick:       @props.onConversation,
                'data-action': 'seen',
                t 'mail action conversation seen'

        items.push li role: 'presentation',
            a
                onClick:       @props.onConversation,
                'data-action': 'unseen',
                t 'mail action conversation unseen'

        return items


    renderMailboxes: ->
        for id, mbox of @props.mailboxes when id isnt @props.selectedMailboxID
            @renderMailbox mbox, id


    renderMailbox: (mbox, id) ->
        li
            role: 'presentation'
            key: id,
                a
                    className: "pusher pusher-#{mbox.depth}"
                    role: 'menuitem'
                    onClick: @props.onMove
                    'data-value': id
                    mbox.label
