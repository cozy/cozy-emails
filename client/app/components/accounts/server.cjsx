_          = require 'underscore'
React      = require 'react'
classnames = require 'classnames'

Form = require '../basics/form'

AccountsLib = require '../../libs/accounts'

# FIXME : move state into props
# the "brain" should be the main container
# State should belongs to main container
# not to its cascading children


module.exports = AccountServer = React.createClass

    displayName: 'AccountServer'

    propTypes:
        protocol            : React.PropTypes.oneOf(_.keys AccountsLib.DEFAULT_PORTS).isRequired
        server              : React.PropTypes.object # ReactLink Object
        port                : React.PropTypes.object # ReactLink Object
        security            : React.PropTypes.object # ReactLink Object
        login               : React.PropTypes.object # ReactLink Object
        password            : React.PropTypes.object # ReactLink Object


    render: ->
        console.log 'SERVER', @props.port, @props.security
        <div className={classnames 'content', 'server', customized: @props.isCustomized}>

            <h2>{@props.protocol}</h2>

            <Form.Input type="text"
                        name="#{@props.protocol}-host"
                        label={t("account wizard creation #{@props.protocol} host")}
                        value={@props.server.value}
                        onChange={@props.server.requestChange} />

            <Form.Input type="number"
                        name="#{@props.protocol}-port"
                        label={t("account wizard creation #{@props.protocol} port")}
                        value={@props.port.value}
                        onChange={@props.port.requestChange} />

            <Form.Select name="#{@props.protocol}-security"
                         label={t("account wizard creation #{@props.protocol} security")}
                         options={AccountsLib.SECURITY_OPTS}
                         value={@props.security.value}
                         onChange={@props.security.requestChange} />

            <Form.Input type="text"
                        name="#{@props.protocol}-login"
                        label={t("account wizard creation #{@props.protocol} login")}
                        value={@props.login.value}
                        onChange={@props.login.requestChange} />

            <Form.Input type="password"
                        name="#{@props.protocol}-password"
                        label={t("account wizard creation #{@props.protocol} password")}
                        value={@props.password.value}
                        onChange={@props.password.requestChange} />
        </div>
