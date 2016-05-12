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
        # update internal state w/ passed props
        @setState expanded: nextProps.expanded if @state?.expanded is null


    render: ->
        <fieldset aria-expanded={@state?.expanded or @props.expanded}>
            {<legend onClick={@toggleExpand}>{@props.legend}</legend> if @props.legend}
            {@props.children}
        </fieldset>


    toggleExpand: ->
        @setState (state, props) ->
            expanded = if state?.expanded isnt null
                !state.expanded
            else
                !@props.expanded

            props.onExpand expanded if props.onExpand
            expanded: expanded
