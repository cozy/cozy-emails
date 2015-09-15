{span, a, i} = React.DOM
MessageUtils   = require '../utils/message_utils'

Participant = React.createClass
    displayName: 'Participant'

    render: ->
        if not @props.address?
            span null
        else
            span
                className: 'address-item'
                'data-toggle': "tooltip"
                ref: 'participant'
                title: @props.address.address,
                key: @props.key,
                MessageUtils.displayAddress @props.address

    _initTooltip: ->
        if @props.tooltip and @refs.participant?
            MessageUtils.tooltip @refs.participant.getDOMNode(), @props.address, @props.onAdd

    componentDidMount: ->
        @_initTooltip()

    componentDidUpdate: ->
        @_initTooltip()

Participants = React.createClass
    displayName: 'Participants'

    render: ->
        span className: 'address-list',
            if @props.participants
                for address, key in @props.participants
                    span key: key, className: null,
                        Participant
                            key:     key,
                            address: address,
                            onAdd:   @props.onAdd,
                            tooltip: @props.tooltip
                        if key < ( @props.participants.length - 1)
                            span null, ', '

module.exports = Participants
