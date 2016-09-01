{IMAP_OPTIONS}  = require '../../../constants/defaults'
{OAuthDomains}  = require '../../../constants/app_constants'

_               = require 'underscore'
React           = require 'react'
ReactDOM        = require 'react-dom'
AccountsLib     = require '../../../libs/accounts'

LinkedStateMixin = require 'react-addons-linked-state-mixin'

Form    = require '../../basics/form'
Servers = require '../servers'

# @TODO in this file
#  - separate account props from commonent state
#           (state.account instanceof Account)
#  - make account state part of the redux store ?
#  - state.mailboxID is poorly named
#           (its used to determine if we are editing / done)

# FIXME: QUID du target _blank (faille de secu)

# Top var for redirect timeout
redirectTimer = undefined

_getInitialState = ->
    defaultSecurityValue = 'starttls'
    return {
        account: null
        mailboxID: null

        OAuth: null

        alert: null

        isBusy: false
        disable: true

        # Auto-open form if discover have failed
        # otherwise keep close
        # Don't forget manual opening
        expanded: false
        discover: false

        fields:
            login: null
            password: null

            imapHost: null
            imapPort: AccountsLib.DEFAULT_PORTS.imap[defaultSecurityValue]
            imapSecurity: defaultSecurityValue
            imapLogin: null

            smtpHost: null
            smtpPort: AccountsLib.DEFAULT_PORTS.smtp[defaultSecurityValue]
            smtpSecurity: defaultSecurityValue
            smtpLogin: null
    }


module.exports = AccountWizardCreation = React.createClass

    displayName: 'AccountWizardCreation'

    mixins: [LinkedStateMixin]

    # TODO: voir quelles props sont à déplacer dans le state
    # formValues
    propTypes:
        doAccountDiscover   : React.PropTypes.func.isRequired
        doAccountCheck      : React.PropTypes.func.isRequired
        doCloseModal        : React.PropTypes.func.isRequired


    # TODO: lister les clés désirées
    getInitialState: ->
        _getInitialState()


    componentDidMount: ->
        # Select first field of the form
        ReactDOM.findDOMNode(@).querySelector('[name=login]')?.focus()


    componentWillUpdate: (nextProps, nextState) ->
        # Update state
        AccountsLib.mergeWithStore nextState

        # Enable auto-redirect only on update
        # after an ADD_ACCOUNT_SUCCESS
        if nextState.mailboxID
            redirectTimer = setTimeout ->
                @props.doCloseModal nextState.mailboxID
            , AccountsLib.REDIRECT_DELAY


    toValueLink: (name) ->
        value: @state.fields[name]
        requestChange: @onFieldChange


    render: ->
        console.log 'RENDER', @state
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
                                    value={@state.fields.login}
                                    onChange={@onFieldChange} />

                        <Form.Input type="password"
                                    name="password"
                                    label={t('account wizard creation password label')}
                                    value={@state.fields.password}
                                    onChange={@onFieldChange} />

                        {<div className="alert">
                            <p>
                                {t("account wizard alert #{@state.alert.status}")}
                            </p>
                            {<p>
                                {t("account wizard error #{@state.alert.type}")}
                            </p> if @state.alert.type}
                            {<p>
                                {t("account wizard alert oauth")}
                                <a href={OAuthDomains[@state.OAuth]} target="_blank">
                                    {t("account wizard alert oauth link label")}
                                </a>.
                            </p> if @state.OAuth}
                        </div> if @state.alert}

                        <Servers expanded={@state.expanded}
                                toValueLink={@toValueLink}
                                legend={t 'account wizard creation advanced parameters'} />
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
                            </button> unless @state.mailboxID}

                            {<button type="submit"
                                     form="account-wizard-creation"
                                     aria-busy={@state.isBusy}
                                     disabled={@state.disable}>
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
    #   1/ if `expanded` feature is enable, perform a discover action
    #   2/ if not, directly check auth
    create: (event) ->
        event.preventDefault() if event?

        { expanded, fields: {imapServer, smtpServer} } = @state
        value = AccountsLib.sanitizeConfig @state

        # Extract domain from login field,
        # to compare w/ know OAuth-aware domains
        [..., domain] = @state.fields.login.split '@'

        if @state.expanded and not(imapServer or smtpServer)
            @props.doAccountDiscover {domain, value}
        else
            @props.doAccountCheck {domain, value}


    # Close the modal when:
    # 1/ click on the modal backdrop
    # 2/ click on the cancel button
    # 3/ click on the success button
    #
    # The close action only occurs if the click event is on one of the
    # aforementioned element and if there's already one account available
    # (otherwise this setting step is mandatory).
    close: (event) ->
        disabled  = @state.disable
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


    onFieldChange: (event) ->
        {target: {value, name}} = event
        (source = {})[name] = value

        previousFields = @state.fields
        nextFields = _.extend {}, previousFields, source

        @updateState {fields: nextFields}


    updateState: (nextState) ->
        state = AccountsLib.validateState nextState, @state

        @setState state
