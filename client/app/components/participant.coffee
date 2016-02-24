React = require 'react'

{span} = React.DOM
MessageUtils   = require '../utils/message_utils'


module.exports = Participant = React.createClass
    displayName: 'Participant'

    render: ->
        name = MessageUtils.displayAddress @props.address

        if not @props.address?
            span null
        else
            span
                className: 'address-item'
                'data-toggle': "tooltip"
                ref: 'participant'
                title: @props.address.address
                key: @props.key

                MessageUtils.highlightSearch(name)...

    _initTooltip: ->
        if @props.tooltip and @refs.participant?
            MessageUtils.tooltip @refs.participant, @props.address, @props.onAdd

    componentDidMount: ->
        @_initTooltip()

    componentDidUpdate: ->
        @_initTooltip()
