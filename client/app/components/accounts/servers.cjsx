_     = require 'underscore'
React = require 'react'

Form   = require '../basics/form'
Server = require './server'


module.exports = AccountServers = React.createClass

    displayName: 'AccountServers'

    propTypes:
        expanded: React.PropTypes.bool
        legend:   React.PropTypes.string
        onExpand: React.PropTypes.func
        onChange: React.PropTypes.func


    render: ->
        <Form.Fieldset {..._.pick @props, 'expanded', 'legend', 'onExpand'}>
            <Server {...@_getPropsForContext 'imap'} />
            <Server {...@_getPropsForContext 'smtp'} />
        </Form.Fieldset>


    # Return unprefixed props to the Server component
    _getPropsForContext: (ctx) ->
        isCustomized = @props.login isnt @props["#{ctx}Login"] or
            @props.password isnt @props["#{ctx}Password"]

        props =
            protocol:    ctx
            server:       @props["#{ctx}Server"]
            port:         @props["#{ctx}Port"]
            security:     @props["#{ctx}Security"]
            login:        @props["#{ctx}Login"]
            password:     @props["#{ctx}Password"]
            isCustomized: isCustomized
            onChange:     @props.onChange
