React = require 'react'
Immutable = require 'immutable'

{span} = React.DOM

TooltipUtils = require '../libs/participant_tooltip'

ContactActionCreator = require '../actions/contact_action_creator'
ContactFormat = require '../libs/format_adress'

# @TODO : this component should use React to manage its tootip
# @TODO : To be discussed, should this component be boundToStore

module.exports = React.createClass
    displayName: 'Participant'

    propTypes:
        address:  React.PropTypes.shape(
            address: React.PropTypes.string.isRequired,
            name: React.PropTypes.string
        ),
        tooltip:  React.PropTypes.bool.isRequired
        contacts: React.PropTypes.instanceOf(Immutable.Map).isRequired

    render: ->
        if not @props.address?
            span null
        else
            span
                className: 'address-item'
                'data-toggle': "tooltip"
                ref: 'participant'
                title: @props.address.address

                [ContactFormat.displayAddress(@props.address)]...

    _initTooltip: ->
        if @props.tooltip and @refs.participant?
            TooltipUtils.tooltip(@refs.participant, @props.address,
                @props.contacts.get(@props.address.address),
                ContactActionCreator.createContact)

    componentDidMount: ->
        @_initTooltip()

    componentDidUpdate: ->
        @_initTooltip()
