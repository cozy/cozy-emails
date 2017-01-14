_     = require 'underscore'
React = require 'react'

{div, ul, li, span, i, p, a, button} = React.DOM

{MenuHeader} = require('./basic_components').factories
ToolboxMailboxes = React.createFactory require './toolbox_mailboxes'

ToolboxMove = React.createClass
    displayName: 'ToolboxMove'

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
                    ToolboxMailboxes()

module.exports = ToolboxMove
