React = require 'react'

Form   = require '../basics/form'
Server = require './server'


module.exports = AccountServers = React.createClass

    displayName: 'AccountServers'

    propTypes:
        expanded: React.PropTypes.bool
        legend:   React.PropTypes.string


    render: ->
        <Form.Fieldset {...@props}>
            <Server protocol="imap" />
            <Server protocol="smtp" />
        </Form.Fieldset>
