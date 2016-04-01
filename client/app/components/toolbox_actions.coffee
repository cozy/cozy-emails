_     = require 'underscore'
React = require 'react'

{div, ul, li, span, a, button} = React.DOM
{Menu, MenuHeader, MenuItem, MenuDivider} = require('./basic_components').factories

ToolboxMailboxes = React.createFactory require './toolbox_mailboxes'

{FlagsConstants} = require '../constants/app_constants'

# This component is used in 3 places
#  - for the conversation
#  - for the message
#  - at the top of the list on selection

module.exports = React.createClass
    displayName: 'ToolboxActions'

    propTypes:
        # is the message or all messages flagged
        isFlagged            : React.PropTypes.bool
        # is the message or all messages seen
        isSeen               : React.PropTypes.bool
        # id of the message we are working on (empty for conversation)
        messageID            : React.PropTypes.string
        # handlers for action
        onConversationDelete : React.PropTypes.func.isRequired
        onConversationMark   : React.PropTypes.func.isRequired
        onConversationMove   : React.PropTypes.func.isRequired
        onHeaders            : React.PropTypes.func
        onMark               : React.PropTypes.func

    render: ->
        Menu
            icon: 'fa-cog'
            direction: 'left'

            MenuHeader key: 'header-conv', t 'mail action conversation'

            MenuItem
                key: 'conv-delete'
                onClick: @props.onConversationDelete,
                t 'mail action conversation delete'

            unless @props.isSeen
                MenuItem
                    key: 'conv-seen'
                    onClick: @props.onConversationMark
                    onClickValue: FlagsConstants.SEEN
                    t 'mail action conversation seen'

            unless @props.isSeen
                MenuItem
                    key: 'conv-unseen'
                    onClick: @props.onConversationMark
                    onClickValue: FlagsConstants.UNSEEN
                    t 'mail action conversation unseen'

            unless @props.isFlagged
                MenuItem
                    key: 'conv-flagged'
                    onClick: @props.onConversationMark
                    onClickValue: FlagsConstants.FLAGGED
                    t 'mail action conversation flagged'
            else
                MenuItem
                    key: 'conv-noflag'
                    onClick: @props.onConversationMark
                    onClickValue: FlagsConstants.NOFLAG
                    t 'mail action conversation noflag'

            MenuHeader
                key: 'header-move',
                t 'mail action conversation move'

            ToolboxMailboxes()
