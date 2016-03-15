React = require 'react'

{span} = React.DOM

Participant = React.createFactory require './participant'


module.exports = Participants = React.createClass
    displayName: 'Participants'

    render: ->
        span className: 'address-list',
            if @props.participants
                for address, key in @props.participants
                    span key: key,
                        Participant
                            key:     key,
                            address: address,
                            onAdd:   @props.onAdd,
                            tooltip: @props.tooltip
                        if key < ( @props.participants.length - 1)
                            span null, ', '
