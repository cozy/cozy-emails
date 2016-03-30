React = require 'react'

{MenuItem} = require('./basic_components').factories
{span} = React.DOM
RouterGetter = require '../getters/router'

module.exports = React.createClass
    displayName: 'ToolboxMailboxes'

    getDefaultProps: ->
        mailboxID = RouterGetter.getCurrentMailbox()?.get 'id'
        mailboxes = RouterGetter.getMailboxes()?.filter (mailbox, id) ->
            id isnt mailboxID
        {mailboxes}

    render: ->
        result = @props.mailboxes.map (mailbox, id) =>
            # console.log 'MenuItem', id
            MenuItem
                # onClick: @props.onMove
                # onClickValue: id
                key: 'menuItem-' + id
                className: "pusher pusher-#{mailbox.get('depth')}"
                mailbox.get('label')
        return span  result.toArray()
