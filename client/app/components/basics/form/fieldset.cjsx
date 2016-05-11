React = require 'react'


module.exports = BasicFormFieldset = React.createClass

    displayName: 'BasicFormFieldset'

    propTypes:
        expanded: React.PropTypes.bool
        legend:   React.PropTypes.string


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
        @setState (state) ->
            expanded: if state?.expanded isnt null
                !state.expanded
            else
                !@props.expanded
