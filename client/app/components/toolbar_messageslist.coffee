React = require 'react'

{aside, i, button} = React.DOM

ActionsToolbarMessagesList = React.createFactory require './toolbar_messageslist_actions'
LayoutActionCreator = require '../actions/layout_action_creator'

module.exports = ToolbarMessagesList = React.createClass
    displayName: 'ToolbarMessagesList'

    selectAll: ->
        LayoutActionCreator.selectAll()

    render: ->
        checkboxState = if @props.isAllSelected then 'fa-check-square-o'
        else if @props.selection?.length then 'fa-minus-square-o'
        else 'fa-square-o'

        aside role: 'toolbar',

            # Select all Checkbox
            button
                role:                     'menuitem'
                onClick:                  @selectAll

                i className: "fa #{checkboxState}"

            if @props.selection?.length
                ActionsToolbarMessagesList
                    mailboxID:            @props.mailboxID
                    messages:             @props.messages
                    selection:            @props.selection
                    isAllSelected:        @props.isAllSelected
