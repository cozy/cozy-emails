_     = require 'underscore'
React = require 'react'

Form   = require '../basics/form'
Server = require './server'

AccountsLib = require '../../libs/accounts'


module.exports = AccountServers = React.createClass

    displayName: 'AccountServers'

    propTypes:
        expanded    : React.PropTypes.bool
        legend      : React.PropTypes.string
        onExpand    : React.PropTypes.func
        toValueLink : React.PropTypes.func
        onChange    : React.PropTypes.func

    render: ->
        console.log 'SERVERS', @props
        <Form.Fieldset expanded={ @props.expanded } legend={ @props.legend } onExpand={ @props.onExpand }>
            <Server {...AccountsLib.filterPropsByProvider @props, 'imap'} />
            <Server {...AccountsLib.filterPropsByProvider @props, 'smtp'} />
        </Form.Fieldset>
