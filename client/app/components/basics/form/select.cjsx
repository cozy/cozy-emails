_     = require 'underscore'
React = require 'react'


OPTION_SHAPE = React.PropTypes.shape
    value: React.PropTypes.any
    label: React.PropTypes.string


module.exports = BasicFormSelect = React.createClass

    displayName: 'BasicFormSelect'

    propTypes:
        name:    React.PropTypes.string.isRequired
        label:   React.PropTypes.string
        options: React.PropTypes.arrayOf(OPTION_SHAPE).isRequired

    contextTypes:
        ns: React.PropTypes.string


    render: ->
        slug = (if @context.ns then "#{@context.ns}-" else '') + @props.name
        props = _.pick @props, 'name', 'value', 'onChange'

        <label data-input={@props.type} htmlFor={slug}>
            {<span>{@props.label}</span> if @props.label}
            <select id={slug} {...props}>
                {<option value={option.value} key="#{slug}-option-#{key}">
                    {t(option.label)}
                </option> for option, key in @props.options}
            </select>
        </label>
