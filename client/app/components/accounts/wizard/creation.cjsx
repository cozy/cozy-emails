{IMAP_OPTIONS} = require '../../../constants/defaults'
{OAuthDomains} = require '../../../constants/app_constants'

_             = require 'underscore'
React         = require 'react'
ReactDOM      = require 'react-dom'
AccountsUtils = require '../../../libs/accounts'

Form    = require '../../basics/form'
Servers = require '../servers'

reduxStore = require '../../../redux_store'
RequestsGetter = require '../../../getters/requests'


# @TODO in this file
#  - separate account props from commonent state
#           (state.account instanceof Account)
#  - make account state part of the redux store ?
#  - state.mailboxID is poorly named
#           (its used to determine if we are editing / done)

# Top var for redirect timeout
redirectTimer = undefined


module.exports = AccountWizardCreation = React.createClass

    displayName: 'AccountWizardCreation'

    componentWillReceiveProps: () ->
        appstate = reduxStore.getState()
        account  = RequestsGetter.getAccountCreationSuccess(appstate)?.account
        discover = RequestsGetter.getAccountCreationDiscover(appstate)

        state =
            isBusy:         RequestsGetter.isAccountCreationBusy(appstate)
            isDiscoverable: RequestsGetter.isAccountDiscoverable(appstate)
            alert:          RequestsGetter.getAccountCreationAlert(appstate)
            OAuth:          RequestsGetter.isAccountOAuth(appstate)

        state.mailboxID = account.inboxMailbox if account
        _.extend state, AccountsUtils.parseProviders discover if discover

        @setState(state);

    componentWillUpdate: (nextProps, nextState) ->
        # Only enable submit when a request isnt performed in background and
        # if required fields (email / password) are filled
        nextState.enableSubmit = not nextState.isBusy and
            not _.isEmpty(nextState.login) and
            not _.isEmpty(nextState.password)

        # Enable auto-redirect only on update after an ADD_ACCOUNT_SUCCESS
        redirectTimer = setTimeout ->
            if RequestsGetter.getAccountCreationSuccess(reduxStore.getState())
                @props.doCloseModal nextState.mailboxID
        , 5000 if nextState.mailboxID


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
                                     ref="success"
                                     name="redirect"
                                     onClick={@close}>
                                {t('account wizard creation success')}
                            </button> if @state.mailboxID}

                            {<button name="cancel"
                                     ref="cancel"
                                     type="button"
                                     onClick={@close}>
                                {t('app cancel')}
                            </button> if @props.hasAccount and not @state.mailboxID}
                            {<button type="submit"
                                     form="account-wizard-creation"
                                     aria-busy={@state.isBusy}
                                     disabled={not @state.enableSubmit}>
                                {t('account wizard creation save')}
                            </button> unless @state.mailboxID}
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
            @props.doAccountDiscover domain, AccountsUtils.sanitizeConfig @state
        else
            @props.doAccountCheck
                value: AccountsUtils.sanitizeConfig @state


    # Disable autodiscover when advanced settings are expanded
    onExpand: (expanded) ->
        @setState isDiscoverable: !expanded


    # Close the modal when:
    # 1/ click on the modal backdrop
    # 2/ click on the cancel button
    # 3/ click on the success button
    #
    # The close action only occurs if the click event is on one of the
    # aforementioned element and if there's already one account available
    # (otherwise this setting step is mandatory).
    close: (event) ->
        disabled  = not @props.hasAccount
        success   = event.target is @refs.success
        backdrops = event.target in [ReactDOM.findDOMNode(@), @refs.cancel]

        return if not success and (disabled or not(backdrops))

        event.stopPropagation()
        event.preventDefault()

        # Disable auto-redirect
        clearTimeout redirectTimer

        # Redirect to mailboxID if available, will automatically fallback to
        # current mailbox if no mailboxID is given (cancel case)
        @props.doCloseModal @state.mailboxID


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
