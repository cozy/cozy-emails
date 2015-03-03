{div, ul, li, span, i, p, a, button} = React.DOM
module.exports = ToolboxMove = React.createClass
    displayName: 'ToolboxMove'

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))

    render: ->
        direction = if @props.direction is 'right' then 'right' else 'left'
        div className: 'menu-move btn-group btn-group-sm',
            button
                className: 'btn btn-default dropdown-toggle move',
                type: 'button',
                'data-toggle': 'dropdown',
                t 'mail action move',
                    span className: 'caret'
            ul
                className: 'dropdown-menu dropdown-menu-' + direction,
                role: 'menu',
                    for key, mailbox of @props.mailboxes when key isnt @props.selectedMailboxID
                        @renderMailboxes mailbox, key

    renderMailboxes: (mailbox, key) ->
        pusher = ""
        pusher += "--" for j in [1..mailbox.depth] by 1
        li role: 'presentation', key: key,
            a
                role: 'menuitem',
                onClick: @props.onMove,
                'data-value': key,
                "#{pusher}#{mailbox.label}"

