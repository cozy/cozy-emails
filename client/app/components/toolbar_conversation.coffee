React = require 'react'

ToolboxActions       = React.createFactory require './toolbox_actions'

module.exports = React.createClass
    displayName: 'ToolbarConversation'

    propTypes:
        conversationID      : React.PropTypes.string

    render: ->
        nav className: 'toolbar toolbar-conversation btn-toolbar',
            ToolboxActions
                key             : 'ToolboxActions-' + @props.conversationID
                direction       : 'right'
                accountID       : @props.accountID
                conversationID  : @props.conversationID
