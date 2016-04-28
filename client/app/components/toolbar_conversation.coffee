React = require 'react'
{nav} = React.DOM

ToolboxActions       = React.createFactory require './toolbox_actions'

module.exports = React.createClass
    displayName: 'ToolbarConversation'

    propTypes:
        conversationID : React.PropTypes.string

    render: ->
        nav className: 'toolbar toolbar-conversation btn-toolbar',
            ToolboxActions
                key             : 'ToolboxActions-' + @props.conversationID
                direction       : 'right'
                conversationID  : @props.conversationID
