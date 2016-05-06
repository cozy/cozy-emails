React = require 'react'


module.exports = BasicFormFieldset = React.createClass

    displayName: 'BasicFormFieldset'

    propTypes:
        expanded: React.PropTypes.bool
        legend:   React.PropTypes.string

    getInitialState: ->
        expanded: if @props.expanded is null then true else @props.expanded


    render: ->
        <fieldset aria-expanded={@state.expanded}>
            {<legend onClick={@toggleExpand}>{@props.legend}</legend> if @props.legend}
            {@props.children}
        </fieldset>


    toggleExpand: ->
        @setState expanded: !@state.expanded if @props.expanded isnt null
