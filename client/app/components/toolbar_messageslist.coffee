React = require 'react'

{aside, i, button} = React.DOM

FiltersToolbarMessagesList = React.createFactory require './toolbar_messageslist_filters'
ActionsToolbarMessagesList = React.createFactory require './toolbar_messageslist_actions'
SearchBar                  = React.createFactory require './search_bar'

LayoutActionCreator = require '../actions/layout_action_creator'
RouterActionCreator = require '../actions/router_action_creator'


module.exports = ToolbarMessagesList = React.createClass
    displayName: 'ToolbarMessagesList'

    propTypes:
        accountID:            React.PropTypes.string
        mailboxID:            React.PropTypes.string
        messages:             React.PropTypes.object.isRequired
        selection:            React.PropTypes.array.isRequired
        isAllSelected:        React.PropTypes.bool.isRequired

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
                    settings:             @props.settings
                    mailboxID:            @props.mailboxID
                    messages:             @props.messages
                    selection:            @props.selection
                    isAllSelected:        @props.isAllSelected
            else
                FiltersToolbarMessagesList
                    accountID: @props.accountID
                    mailboxID: @props.mailboxID
                    filter: @props.filter

            SearchBar()
