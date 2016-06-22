{IMAP_OPTIONS} = require '../../../constants/defaults'
{OAuthDomains} = require '../../../constants/app_constants'

_             = require 'underscore'
React         = require 'react'
ReactDOM      = require 'react-dom'
AccountsUtils = require '../../../libs/accounts'

Form    = require '../../basics/form'
Servers = require '../servers'

RequestsStore = require '../../../stores/requests_store'

RequestsGetter = require '../../../getters/requests'

AccountActionCreator = require '../../../actions/account_action_creator'
RouterActionCreator = require '../../../actions/router_action_creator'

StoreWatchMixin = require '../../../mixins/store_watch_mixin'


module.exports = AccountWizardCreation = React.createClass

    displayName: 'AccountWizardCreation'

    mixins: [
        StoreWatchMixin [RequestsStore]
    ]


    # Build state from RequestsStore through RequestsGetter
    getStateFromStores: ->
        account  = RequestsGetter.getAccountCreationSuccess()?.account
        discover = RequestsGetter.getAccountCreationDiscover()

        state =
            isBusy:         RequestsGetter.isAccountCreationBusy()
            isDiscoverable: RequestsGetter.isAccountDiscoverable()
            alert:          RequestsGetter.getAccountCreationAlert()
            OAuth:          RequestsGetter.isAccountOAuth()

        state.success = _.partial @redirect, account if account
        _.extend state, AccountsUtils.parseProviders discover if discover

        return state


    componentWillUpdate: (nextProps, nextState) ->
        # Only enable submit when a request isnt performed in background and
        # if required fields (email / password) are filled
        nextState.enableSubmit = not nextState.isBusy and
            not _.isEmpty(nextState.login) and
            not _.isEmpty(nextState.password)


    componentDidMount: ->
        ReactDOM.findDOMNode(@).querySelector('[name=login]').focus()


    render: ->
        <div role='complementary' className="backdrop" onClick={@close}>
            <div className="backdrop-wrapper">
                <section className='settings'>
                    <h1>{t('account wizard creation')}</h1>

                    <Form ns="account-wizard-creation"
                            className="content"
                            onSubmit={@create}>

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
                            <p>
                                {t("account wizard alert #{@state.alert.status}")}
                            </p>
                            {<p>
                                {t("account wizard error #{@state.alert.type}")}
                            </p> if @state.alert.type}
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
                    </Form>

                    <footer>
                        <nav>
                            {<button className="success"
                                     name="redirect"
                                     onClick={@state.success}>
                                {t('account wizard creation success')}
                            </button> if @state.success}

                            {<button name="cancel"
                                     type="button"
                                     onClick={@close}>
                                {t('app cancel')}
                            </button> if @props.hasDefaultAccount and not @state.success}
                            {<button type="submit"
                                     form="account-wizard-creation"
                                     aria-busy={@state.isBusy}
                                     disabled={not @state.enableSubmit}>
                                {t('account wizard creation save')}
                            </button> unless @state.success}
                        </nav>
                    </footer>
                </section>
            </div>
        </div>


    # Account creation steps:
    # - reset alerts
    # - trigger action:
    #   1/ if `isDiscoverable` feature is enable, perform a discover action
    #   2/ if not, directly check auth
    create: (event) ->
        event.preventDefault()

        if @state.isDiscoverable and not(@state.imapServer or @state.smtpServer)
            [..., domain] = @state.login.split '@'
            AccountActionCreator.discover domain,
                AccountsUtils.sanitizeConfig @state
        else
            AccountActionCreator.check
                value: AccountsUtils.sanitizeConfig @state


    # Disable autodiscover when advanced settings are expanded
    onExpand: (expanded) ->
        @setState isDiscoverable: !expanded


    # Close the modal when:
    # 1/ click on the modal backdrop
    # 2/ click on the cancel button
    #
    # The close action only occurs if the click event is on one of the
    # aforementioned element and if there's already one account available
    # (otherwise this setting step is mandatory).
    close: (event) ->
        isDisabled    = not @props.hasDefaultAccount
        isContainer   = event.target is ReactDOM.findDOMNode @
        isCloseButton = event.target.name is 'cancel'
        return if isDisabled or not(isContainer or isCloseButton)

        event.stopPropagation()
        event.preventDefault()

        RouterActionCreator.closeModal()


    # Redirect on success to the freshly created account's mailbox
    redirect: (account) ->
        RouterActionCreator.showMessageList mailboxID: account.inboxMailbox


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
            @setState _.partial AccountsUtils.validateState, source, value
