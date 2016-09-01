React      = require 'react'
Immutable = require 'immutable'

colorhash = require '../libs/colorhash'
{i, img} = React.DOM


# This components render an avatar for a given message
module.exports = React.createClass
    displayName: 'Avatar'

    propTypes:
        contacts: React.PropTypes.instanceOf(Immutable.Map).isRequired
        participant: React.PropTypes.shape(
            address: React.PropTypes.string.isRequired,
            name: React.PropTypes.string
        )

    makeInitial: ->
        if @props.participant?.name then @props.participant?.name[0]
        else @props.participant?.address[0]

    makeColor: ->
        colorhash "#{@props.participant?.name} <#{@props.participant?.address}>"

    render: ->
        avatar = @props.contacts.get(@props.participant.address)?.get('avatar')
        if avatar?
            img
                className: 'avatar '  + @props.className or '',
                src: avatar
        else
            i
                className: 'avatar placeholder ' + @props.className or ''
                style: {backgroundColor: @makeColor()},
                @makeInitial()
