React = require 'react'

{span} = React.DOM

MessageUtils   = require '../utils/message_utils'
SearchGetter = require '../getters/search'

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

                SearchGetter.highlightSearch(@props.name)...

    _initTooltip: ->
        if @props.tooltip and @refs.participant?
            MessageUtils.tooltip @refs.participant, @props.address, @props.onAdd

    componentDidMount: ->
        @_initTooltip()

    componentDidUpdate: ->
        @_initTooltip()
