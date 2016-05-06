{IMAP_OPTIONS} = require '../../../constants/defaults'

_     = require 'underscore'
React = require 'react'

Form    = require '../../basics/form'
Servers = require '../servers'


module.exports = AccountWizardCreation = React.createClass

    displayName: 'AccountWizardCreation'


    getInitialState: ->
        isOAuth:        false
        isDiscoverable: true
        email:          undefined
        password:       undefined
        imapServer:     undefined
        imapPort:       undefined
        imapSecurity:   undefined
        imapUsername:   undefined
        imapPassword:   undefined
        smtpServer:     undefined
        smtpPort:       undefined
        smtpSecurity:   undefined
        smtpUsername:   undefined
        smtpPassword:   undefined


    render: ->
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

                <Servers expanded={!@state.isDiscoverable}
                         legend={t('account wizard creation advanced parameters')}
                         onChange={@updateState}
                         {..._.omit @state, 'isOAuth', 'isDiscoverable'} />
            </Form>

            <footer>
                <nav>
                    <a role="button" onClick={@create}>{t('account wizard creation save')}</a>
                </nav>
            </footer>
        </section>


    create: ->
        console.debug @state


    # Update state according to user inputs
    #
    # Can receive:
    # - an object conainting the new state to push to @state
    # - a key / event parameters combination
    updateState: (key, event) ->
        if _.isObject key
            nextState = key

        else
            # extract value from event.target
            {target: {value}} = event
            # In case key is 'port', ensure the value type is a number
            value = +value if /port$/i.test key
            # prepare the nextState object
            (nextState = {})[key] = value

            # if key is email or password input, reflect the value in the
            # server's username / password fields, except if the value in those
            # field is already field with a different value.
            # This allow to bulk update each fields mapped to the username /
            # password field, and allow to input custom values in server's
            # sections if needed.
            if key in ['email', 'password']
                refKey = if key is 'email' then /username$/i else /password$/i
                refVal = @state[key]
                _.chain @state
                    .pairs()
                    .filter ([_key, _value]) ->
                        refKey.test(_key) and _value is refVal
                    .each ([_key, ...]) ->
                        nextState[_key] = value
                    .value()

        @setState nextState
