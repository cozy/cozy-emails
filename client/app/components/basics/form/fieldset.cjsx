React = require 'react'


module.exports = BasicFormFieldset = React.createClass

    displayName: 'BasicFormFieldset'

    propTypes:
        expanded: React.PropTypes.bool
        legend:   React.PropTypes.string


    render: ->
        <fieldset aria-expanded={@props.expanded or true}>
            {<legend>{@props.legend}</legend> if @props.legend}
            {@props.children}
        </fieldset>
