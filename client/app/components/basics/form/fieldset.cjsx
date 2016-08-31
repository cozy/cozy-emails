React = require 'react'


module.exports = BasicFormFieldset = React.createClass

    displayName: 'BasicFormFieldset'

    propTypes:
        expanded: React.PropTypes.bool
        legend:   React.PropTypes.string
        onExpand: React.PropTypes.func


    getInitialState: ->
        expanded: if @props.expanded is null then true else @props.expanded


    componentWillReceiveProps: (nextProps) ->
        @setState expanded: nextProps.expanded


    render: ->
        <fieldset aria-expanded={@state.expanded}>
            {<legend onClick={@toggleExpand}
                     onKeyDown={@toggleExpand}
                     tabIndex="0">{@props.legend}</legend> if @props.legend}
            {@props.children}
        </fieldset>


    toggleExpand: (event) ->
        return if event.keyCode and event.keyCode not in [13, 32]
        @setState (state, props) ->
            expanded = if state?.expanded isnt null
                !state.expanded
            else
                !@props.expanded

            props.onExpand expanded if props.onExpand
            expanded: expanded
