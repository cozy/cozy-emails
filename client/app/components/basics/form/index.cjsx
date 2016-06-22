React = require 'react'


module.exports = BasicsForm = React.createClass

    displayName: 'BasicForm'

    propTypes:
        ns:     React.PropTypes.string.isRequired
        method: React.PropTypes.oneOf ['GET', 'POST']

    childContextTypes:
        ns: React.PropTypes.string


    getChildContext: ->
        ns: @props.ns


    render: ->
        <form id={@props.ns} method={@props.method or 'POST'} {..._.omit @props, 'ns', 'method'}>
            {@props.children}
        </form>


BasicsForm.Fieldset = require './fieldset'
BasicsForm.Input    = require './input'
BasicsForm.Select   = require './select'
