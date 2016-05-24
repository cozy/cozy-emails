_     = require 'underscore'
React = require 'react'

Form = require '../basics/form'


{ServersEncProtocols} = require '../../constants/app_constants'

DEFAULT_PORTS =
    imap:
        ssl:      993
        starttls: 993
        none:     143
    smtp:
        ssl:      465
        starttls: 587
        none:     25


module.exports = AccountServer = React.createClass

    displayName: 'AccountServer'

    propTypes:
        _protocol: React.PropTypes.oneOf(_.keys DEFAULT_PORTS).isRequired
        server:    React.PropTypes.string
        port:      React.PropTypes.number
        security:  React.PropTypes.string
        login:     React.PropTypes.string
        password:  React.PropTypes.string
        onChange:  React.PropTypes.func


    # Port should be update according to the selected security option, so
    # component keep an internal state responsible to update port <> security
    # (see AccountServer.prototype.onSecurityChange)
    #
    # Component so uses a default initialState bound to no security protocol and
    # according port.
    getInitialState: ->
        port:     @props.port or DEFAULT_PORTS[@props._protocol].none
        security: @props.security or 'none'


    componentWillReceiveProps: (nextProps) ->
        # update internal state accordingly to pqassed props
        @setState
            port:     nextProps.port
            security: nextProps.security


    componentDidMount: ->
        # force globalState to update according to defaults values computed from
        # initialState
        @setGlobalState @state


    render: ->
        <div className="content server">
            <h2>{@props._protocol}</h2>
            <Form.Input type="text"
                        name="#{@props._protocol}-host"
                        label={t("account wizard creation #{@props._protocol} host")}
                        value={@props.server}
                        onChange={_.partial @props.onChange, "#{@props._protocol}Server"} />
            <Form.Input type="number"
                        name="#{@props._protocol}-port"
                        label={t("account wizard creation #{@props._protocol} port")}
                        value={@state.port}
                        onChange={_.partial @props.onChange, "#{@props._protocol}Port"} />
            <Form.Select name="#{@props._protocol}-security"
                         label={t("account wizard creation #{@props._protocol} security")}
                         options={@_securityOptions()}
                         value={@state.security}
                         onChange={@onSecurityChange} />
            <Form.Input type="text"
                        name="#{@props._protocol}-login"
                        label={t("account wizard creation #{@props._protocol} login")}
                        value={@props.login}
                        onChange={_.partial @props.onChange, "#{@props._protocol}Login"} />
            <Form.Input type="password"
                        name="#{@props._protocol}-password"
                        label={t("account wizard creation #{@props._protocol} password")}
                        value={@props.password}
                        onChange={_.partial @props.onChange, "#{@props._protocol}Password"} />
        </div>


    # When security setting change, port should be updated accordingly to the
    # selected security option, except if it's a custom port already filled
    #
    # Component manage an internal state responsible of this binding and reflect
    # it to the globalState.
    onSecurityChange: ({target: {value}}) ->
        nextState = security: value

        # Only override port if it isn't a custom one
        # (be careful to convert type from state to be a number)
        if +@state.port in _.values DEFAULT_PORTS[@props._protocol]
            nextState['port'] = DEFAULT_PORTS[@props._protocol][value]

        @setState nextState
        # also pass modified props (internal state) to globalState
        @setGlobalState nextState


    setGlobalState: (state) ->
        protocol    = @props._protocol
        globalState = {}
        # prefix all key names with the protocol for globalState
        _.each state, (value, key) ->
            globalState["#{protocol}#{key[0].toUpperCase()}#{key.slice 1}"] = value
        @props.onChange globalState


    _securityOptions: ->
        ServersEncProtocols
            .map (protocol) ->
                value: protocol
                label: t "server protocol #{protocol}"
            .concat
                value: 'none'
                label: 'server protocol none'
