React = require 'react'

{span} = React.DOM

Participant = React.createFactory require './participant'

ContactGetter = require '../getters/contact'

module.exports = React.createClass
    displayName: 'Participants'

    render: ->
        span className: 'address-list',
            for address, index in @props.participants
                span key: "participants-#{index}",
                    Participant
                        key     : "participants-#{index}-#{address}"
                        address : address
                        onAdd   : @props.onAdd
                        tooltip : @props.tooltip
                        name    : ContactGetter.displayAddress(address)
                    if index < ( @props.participants.length - 1)
                        span null, ', '
