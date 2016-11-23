React = require 'react'

INPUT_TYPES = [
    'text'
    'password'
    'number'
]


module.exports = BasicFormInput = React.createClass

    displayName: 'BasicFormInput'

    propTypes:
        name:  React.PropTypes.string.isRequired
        type:  React.PropTypes.oneOf(INPUT_TYPES).isRequired
        label: React.PropTypes.string

    contextTypes:
        ns: React.PropTypes.string


    render: ->
        slug = (if @context.ns then "#{@context.ns}-" else '') + @props.name

        <label data-input={@props.type} htmlFor={slug}>
            {<span>{@props.label}</span> if @props.label}
            <input id={slug} {...@props} />
        </label>
