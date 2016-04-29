React = require 'react'

{div, i, button} = React.DOM
{Tooltips = require '../constants/app_constants'

ToolboxActions = React.createFactory require './toolbox_actions'

MessageActionCreator = require '../actions/message_action_creator'


module.exports = React.createClass
    displayName: 'ActionsToolbarMessagesList'

    render: ->
        div role: 'group',
            button
                role:                     'menuitem'
                onClick:                  @onDelete
                'aria-disabled':          true
                'aria-describedby':       Tooltips.DELETE_SELECTION
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-trash-o'

            ToolboxActions
                key        : 'ToolboxActions-' + @props.conversationID
                direction  : 'left'
                messageIDs : @props.selection

     onDelete: ->
          messageIDs = @props.selection
          MessageActionCreator.delete {messageIDs}
