_     = require 'underscore'
React = require 'react'

{div, ul, li, span, a, button} = React.DOM
{Menu, MenuHeader, MenuItem, MenuDivider} = require('./basic_components').factories

ToolboxMailboxes = React.createFactory require './toolbox_mailboxes'

RouterActionCreator = require '../actions/router_action_creator'

{FlagsConstants} = require '../constants/app_constants'

# This component is used in 3 places
#  - for the conversation
#  - for the message
#  - at the top of the list on selection

module.exports = React.createClass
    displayName: 'ToolboxActions'

    doMark: (flag) ->
        {conversationID, messageIDs} = @props
        RouterActionCreator.mark {conversationID, messageIDs}, flag

    doDelete: ->
        {conversationID, messageIDs} = @props
        RouterActionCreator.delete {conversationID, messageIDs}

    render: ->
        Menu
            icon: 'fa-cog'
            direction: @props.direction

            MenuHeader key: 'header-conv', t 'mail action conversation'

            MenuItem
                key: 'conv-delete'
                onClick: @doDelete,
                t 'mail action conversation delete'

            # FIXME : missing props
            unless @props.isSeen
                MenuItem
                    key: 'conv-seen'
                    onClick: => @doMark FlagsConstants.SEEN
                    t 'mail action conversation seen'

            else
                MenuItem
                    key: 'conv-unseen'
                    onClick: => @doMark FlagsConstants.UNSEEN
                    t 'mail action conversation unseen'

            # FIXME : missing props
            unless @props.isFlagged
                MenuItem
                    key: 'conv-flagged'
                    onClick: => @doMark FlagsConstants.FLAGGED
                    t 'mail action conversation flagged'
            else
                MenuItem
                    key: 'conv-noflag'
                    onClick: => @doMark FlagsConstants.NOFLAG
                    t 'mail action conversation noflag'

            MenuHeader
                key: 'header-move',
                t 'mail action conversation move'

            ToolboxMailboxes()
