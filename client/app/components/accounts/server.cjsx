React = require 'react'

Form = require '../basics/form'


{ServersEncProtocols} = require '../../constants/app_constants'


module.exports = AccountServer = React.createClass

    displayName: 'AccountServer'

    propTypes:
        protocol: React.PropTypes.string.isRequired


    render: ->
        options = ServersEncProtocols.map (protocol) ->
            value: protocol
            label: t "server protocol #{protocol}"
        options.push {value: 'null', label: 'server protocol none'}

        <div className="content">
            <Form.Input type="text"
                        name="#{@props.protocol}-host"
                        label={t("account wizard creation #{@props.protocol} host")} />
            <Form.Input type="number"
                        name="#{@props.protocol}-port"
                        label={t("account wizard creation #{@props.protocol} port")}
                        value=143 />
            <Form.Select name="#{@props.protocol}-security"
                         label={t("account wizard creation #{@props.protocol} security")}
                         options=options
                         value='null' />
            <Form.Input type="text"
                        name="#{@props.protocol}-username"
                        label={t("account wizard creation #{@props.protocol} username")} />
            <Form.Input type="text"
                        name="#{@props.protocol}-password"
                        label={t("account wizard creation #{@props.protocol} password")} />
        </div>
