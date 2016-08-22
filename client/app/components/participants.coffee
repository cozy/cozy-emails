React = require 'react'
Immutable = require 'immutable'
{span} = React.DOM
Participant = React.createFactory require './participant'

module.exports =  React.createClass
    displayName: 'Participants'

    propTypes:
        participants: React.PropTypes.arrayOf(React.PropTypes.shape(
            address: React.PropTypes.string.isRequired,
            name: React.PropTypes.string
        )).isRequired
        tooltip:  React.PropTypes.bool.isRequired
        contacts: React.PropTypes.instanceOf(Immutable.Map).isRequired


    render: ->
        span className: 'address-list',
            for address, index in @props.participants
                span null,
                    Participant
                        key: "participants-#{address}"
                        address : address
                        contacts: @props.contacts
                        tooltip : @props.tooltip
                    if index < ( @props.participants.length - 1)
                        span null, ', '
