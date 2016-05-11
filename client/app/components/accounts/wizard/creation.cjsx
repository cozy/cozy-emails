{IMAP_OPTIONS}                  = require '../../../constants/defaults'
{Requests, ServersEncProtocols} = require '../../../constants/app_constants'

_     = require 'underscore'
React = require 'react'

Form    = require '../../basics/form'
Servers = require '../servers'

RequestsInFlightStore = require '../../../stores/requests_in_flight_store'

RouterGetter = require '../../../getters/router'

AccountActionCreator = require '../../../actions/account_action_creator'

StoreWatchMixin = require '../../../mixins/store_watch_mixin'


module.exports = AccountWizardCreation = React.createClass

    displayName: 'AccountWizardCreation'

    mixins: [
        StoreWatchMixin [RequestsInFlightStore]
    ]


    getInitialState: ->
        isOAuth: false


    # Build state form RequestsInFlightStore:
    # - is an autodiscover request in action, or a provider available?
    getStateFromStores: ->
        state    = {}
        discover = RouterGetter.getRequestStatus Requests.DISCOVER

        # autodiscover have returned a provider informations (an array of
        # settings): extract settings from given provider for IMAP and SMTP and
        # fill state
        if _.isArray discover
            state.isDiscoverable = true
            discover.forEach (provider) ->
                return unless provider.type in ['imap', 'smtp']

                socketType = provider.socketType.toLowerCase()
                security   = if socketType in ServersEncProtocols
                    socketType
                else 'none'

                _.extend state,
                    "#{provider.type}Server":   provider.hostname
                    "#{provider.type}Port":     +provider.port
                    "#{provider.type}Security": security

        # autodiscover failed (status response isnt a `2xx`), so set account to
        # note discoverable
        else if discover.status and not /^2/.test discover.status
            state.isDiscoverable = false

        # returns state whith its fallback default values.
        # `isChecking` need discover to be explicitely set to `true` (request
        # in flight)
        _.defaults state,
            isChecking:     discover is true
            isDiscoverable: true


    render: ->
        # `required`: needs email and password filled to enable submit button
        required = not(_.isEmpty(@state.email) or _.isEmpty(@state.password))

        <section className='settings'>
            <h1>{t('account wizard creation')}</h1>

            <Form ns="account-wizard-creation" className="content">
                <Form.Input type="text"
                            name="email"
                            label={t('account wizard creation email label')}
                            value={@state.email}
                            onChange={_.partial @updateState, 'email'} />
                <Form.Input type="password"
                            name="password"
                            label={t('account wizard creation password label')}
                            value={@state.password}
                            onChange={_.partial @updateState, 'password'} />

                {<p className="alert">{t('account wizard is not discoverable')}</p> unless @state.isDiscoverable}

                <Servers expanded={not @state.isDiscoverable}
                         legend={t('account wizard creation advanced parameters')}
                         onChange={@updateState}
                         {..._.omit @state, 'isOAuth', 'isDiscoverable', 'isChecking'} />

                <footer>
                    <nav>
                        <button type="submit"
                                onClick={@create}
                                disabled={not(required) or @state.isChecking}>
                            {t('account wizard creation save')}
                        </button>
                    </nav>
                </footer>
            </Form>
        </section>


    create: (event) ->
        event.preventDefault()

        [..., domain] = @state.email.split '@'
        AccountActionCreator.discover domain


    # Update state according to user inputs
    #
    # Can receive:
    # - an object conainting the new state to push to @state
    # - a key / event parameters combination
    updateState: (source, event) ->
        if _.isObject source
            nextState = source
        else
            {target: {value}} = event
            nextState = _.partial @_validateState, source, value
        @setState nextState


    _validateState: (source, value, previousState) ->
        # In case key is 'port', ensure the value type is a number
        value = +value if /port$/i.test source

        # prepare the state object
        (state = {})[source] = value

        # if key is email or password input, reflect the value in the
        # server's username / password fields, except if the value in
        # those field is already field with a different value.
        # This allow to bulk update each fields mapped to the username/
        # password field, and allow to input custom values in server's
        # sections if needed.
        if source in ['email', 'password']
            # Ensure previousState contains all required fields
            _.defaults previousState,
                imapUsername: undefined
                imapPassword: undefined
                smtpUsername: undefined
                smtpPassword: undefined

            # Extract values for filter
            re     = if source is 'email' then /username$/i else /password/i
            refVal = previousState[source]

            # Parse previousState and keep fields mapped to source w/ an
            # unaltered values
            extraState =_.chain previousState
                .pairs()
                .filter ([_key, _value]) ->
                    re.test(_key) and _value is refVal
                .map ([_key, ...]) ->
                    [_key, value]
                .object()
                .value()

        _.extend state, extraState
