{div, ul, li, span, i, p, a, button} = React.DOM
{MenuHeader, MenuItem} = require './basic_components'


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
                    MenuHeader null, t 'mail action move'
                    @renderMailboxes()


    renderMailboxes: ->
        for id, mbox of @props.mailboxes when id isnt @props.selectedMailboxID
            do (id) => # bind id to each mailbox
                MenuItem
                    key: id
                    className: "pusher pusher-#{mbox.depth}"
                    onClick: => @props.onMove id
                    mbox.label
