React = require 'react'

{span} = React.DOM

MessageUtils   = require '../utils/message_utils'
RouterGetter = require '../getters/router'

module.exports = React.createClass
    displayName: 'Participant'

    render: ->
        if not @props.address?
            span null
        else
            span
                className: 'address-item'
                'data-toggle': "tooltip"
                ref: 'participant'
                title: @props.address.address
                key: @props.key

                RouterGetter.highlightSearch(@props.name)...

    _initTooltip: ->
        if @props.tooltip and @refs.participant?
            MessageUtils.tooltip @refs.participant, @props.address, @props.onAdd

    componentDidMount: ->
        @_initTooltip()

    componentDidUpdate: ->
        @_initTooltip()
