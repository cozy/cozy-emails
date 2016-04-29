React = require 'react'

{div, i, button} = React.DOM
{Tooltips}       = require '../constants/app_constants'

ToolboxActions = React.createFactory require './toolbox_actions'
ToolboxMove    = React.createFactory require './toolbox_move'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
RouterActionCreator = require '../actions/router_action_creator'

module.exports = ActionsToolbarMessagesList = React.createClass
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
                direction:            'left'
                mode:                 'conversation'
                onMark:               @onMark
                onConversationDelete: @onConversationDelete
                onConversationMark:   @onConversationMark
                onConversationMove:   @onConversationMove


    onDelete: ->
        messageIDs = @props.selection
        MessageActionCreator.delete {messageIDs}


    onMove: (to) ->
        from = @props.mailboxID
        MessageActionCreator.move options, from, to


    onMark: (flag) ->
        MessageActionCreator.mark options, flag


    onConversationDelete: ->
        @onDelete true


    # FIXME : déplacer ces logiques dans
    # les actionsCreator
    onConversationMove: (to) ->
        @onMove to

    # FIXME : déplacer ces logiques dans
    # les actionsCreator
    onConversationMark: (flag) ->
        @onMark flag
