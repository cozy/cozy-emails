{IMAP_OPTIONS} = require '../../../constants/defaults'
{Requests
RequestStatus
OAuthDomains} = require '../../../constants/app_constants'

_           = require 'underscore'
React       = require 'react'
ReactDOM    = require 'react-dom'

Form    = require '../../basics/form'
Servers = require '../servers'

RequestsInFlightStore = require '../../../stores/requests_in_flight_store'

RouterGetter = require '../../../getters/router'

AccountActionCreator = require '../../../actions/account_action_creator'
RouterActionCreator = require '../../../actions/router_action_creator'

StoreWatchMixin = require '../../../mixins/store_watch_mixin'
AccountMixin    = require '../../../mixins/account_mixin'


ALERTS =
    'DISCOVER_FAILED': 'DISCOVER_FAILED'
    'CHECK_FAILED':    'CHECK_FAILED'
    'CREATE_FAILED':   'CREATE_FAILED'


module.exports = AccountWizardCreation = React.createClass

    displayName: 'AccountWizardCreation'

    mixins: [
        StoreWatchMixin [RequestsInFlightStore]
        AccountMixin
    ]


    # Build state form RequestsInFlightStore:
    # - is an autodiscover request in action, or a provider available?
    getStateFromStores: ->
        state       = {}
        discoverReq = RouterGetter.getRequestStatus Requests.DISCOVER_ACCOUNT
        checkReq    = RouterGetter.getRequestStatus Requests.CHECK_ACCOUNT
        createReq   = RouterGetter.getRequestStatus Requests.ADD_ACCOUNT

        isBusy = RequestStatus.INFLIGHT in [
            discoverReq.status
            checkReq.status
            createReq.status
        ]

        # Account creation step
        if createReq.status is RequestStatus.SUCCESS
            _.extend state,
                success: true

        else if createReq.status is RequestStatus.ERROR
            _.extend state,
                alert: ALERTS.CREATE_FAILED

        # Check account failed
        # - set error message
        # - if domain is one of known OAuth-aware domain, display reminder about
        # OAuth token
        if checkReq.status is RequestStatus.ERROR
            {oauth} = checkReq.res
            _.extend state,
                alert: ALERTS.CHECK_FAILED
                OAuth: oauth

        # Autodiscover have returned a provider informations (an array of
        # settings): extract settings from given provider for IMAP and SMTP
        # and fill state
        if discoverReq.status is RequestStatus.SUCCESS
            _.extend state,
                isDiscoverable: true
                @parseProviders discoverReq.res

        # autodiscover failed : switch to manual config and set an alert only if
        # checkReq.status isn't already performed
        else if discoverReq.status is RequestStatus.ERROR and
        checkReq.status is null
            _.extend state,
                alert: ALERTS.DISCOVER_FAILED
                isDiscoverable: false


        # returns state with its fallback default values.
        #
        # `isDiscoverable` is true by default since no check has been performed
        # (else, it means a previous config - discovered or manual - was
        # submitted and discovering must be manually set by closing advanced
        # settings panel)
        _.defaults state,
            isBusy:         isBusy
            isDiscoverable: checkReq.status is null
            alert:          null


    componentWillUpdate: (nextProps, nextState) ->
        # Only enable submit when a request isnt performed in background and
        # if required fields (email / password) are filled
        nextState.enableSubmit = not nextState.isBusy and
            not _.isEmpty(nextState.login) and
            not _.isEmpty(nextState.password)


    render: ->
        <div role='complementary' onClick={@close}>
            <section className='settings'>
                <h1>{t('account wizard creation')}</h1>

                <Form ns="account-wizard-creation"
                        className="content"
                        onClick={@create}>

                    <Form.Input type="text"
                                name="login"
                                label={t('account wizard creation login label')}
                                value={@state.login}
                                onChange={_.partial @updateState, 'login'} />
                    <Form.Input type="password"
                                name="password"
                                label={t('account wizard creation password label')}
                                value={@state.password}
                                onChange={_.partial @updateState, 'password'} />

                    {<div className="alert">
                        <p>{t("account wizard alert #{@state.alert}")}</p>
                        {<p>
                            {t("account wizard alert oauth")}
                            <a href={OAuthDomains[@state.OAuth]} target="_blank">{t("account wizard alert oauth link label")}</a>.
                        </p> if @state.OAuth}
                    </div> if @state.alert}

                    <Servers expanded={not @state.isDiscoverable}
                             legend={t('account wizard creation advanced parameters')}
                             onExpand={@onExpand}
                             onChange={@updateState}
                             {..._.omit @state, 'isOAuth', 'isDiscoverable', 'isBusy'} />

                    <footer>
                        <nav>
                            {<button type="submit"
                                    disabled={not @state.enableSubmit}>
                                {t('account wizard creation save')}
                            </button> unless @state.success}
                            {<a href="#" className="alert success">
                                {t('account wizard creation success')}
                            </a> if @state.success}
                            {<button type="close"
                                    disabled={not @props.hasDefaultAccount}>
                                {t 'app cancel'}
                            </button>}
                        </nav>
                    </footer>
                </Form>
            </section>
        </div>


    # Account creation steps:
    # - reset alerts
    # - trigger action:
    #   1/ if `isDiscoverable` feature is enable, perform a discover action
    #   2/ if not, directly check auth
    create: (event) ->
        event.preventDefault()

        @setState alert: null

        if @state.isDiscoverable
            [..., domain] = @state.login.split '@'
            AccountActionCreator.discover domain, @sanitizeConfig @state
        else
            AccountActionCreator.check value: @sanitizeConfig @state


    # Disable autodiscover when advanced settings are expanded
    onExpand: (expanded) ->
        @setState isDiscoverable: !expanded


    close: (event) ->
        isDisabled = @props.hasDefaultAccount
        isContainer = event.target is ReactDOM.findDOMNode @
        isCloseButton = 'close' is event.target.getAttribute 'type'
        return if isDisabled and not isContainer and not isCloseButton

        event.preventDefault()

        RouterActionCreator.closeModal()


    # Update state according to user inputs
    #
    # Can receive:
    # - an object conainting the new state to push to @state
    # - a key / event parameters combination that'll be validated
    updateState: (source, event) ->
        if _.isObject source
            @setState source
        else
            {target: {value}} = event
            @setState _.partial @validateAccountState, source, value
