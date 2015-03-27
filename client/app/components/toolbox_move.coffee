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
                className: 'btn btn-default dropdown-toggle fa fa-folder-open'
                type: 'button'
                'data-toggle': 'dropdown'
                ' '
                    span className: 'caret'
            ul
                className: "dropdown-menu dropdown-menu-#{direction}"
                role: 'menu',
                    @renderMailboxes()


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

