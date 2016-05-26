###

Accounts lib
===

This library is a simple set of helpers functions useful for parsing and
validating account's related data (such as components states or requests
responses).

###

{ServersEncProtocols} = require '../constants/app_constants'

_ = require 'underscore'


module.exports =

    # Take a state identifier (key), its value, and the previousState.
    # It ensures the type is right with PropTypes, and manage auto-filling for
    # associated keys (logins / passwords).
    validateState: (key, value, pState) ->
        # In case key is 'port', ensure the value type is a number
        value = +value if /port$/i.test key

        # prepare the state object
        (state = {})[key] = value

        # if key is login or password input, reflect the value in the
        # server's username / password fields, except if the value in
        # those field is already field with a different value.
        # This allow to bulk update each fields mapped to the username/
        # password field, and allow to input custom values in server's
        # sections if needed.
        if key in ['login', 'password']
            # Ensure previousState contains all required fields
            _.defaults pState,
                imapLogin:    undefined
                imapPassword: undefined
                smtpLogin:    undefined
                smtpPassword: undefined

            # Extract values for filter
            re     = new RegExp "#{key}$", 'i'
            refVal = pState[key]

            # Parse previousState and keep fields mapped to key w/ an
            # unaltered values
            extraState =_.chain pState
                .pairs()
                .filter ([_key, _value]) ->
                    re.test(_key) and _value is refVal
                .map ([_key, ...]) ->
                    [_key, value]
                .object()
                .value()

        # If the modified field is 'login' and servers field are empty, we
        # assume the user just fix a typo in its email address after a failed
        # autodiscover request, so we smartly re-enable it to perform another
        # aiutodiscover test.
        if key is 'login' and not(pState.imapServer or pState.smtpServer)
            (discoveryState = {})['isDiscoverable'] = true

        _.extend state, extraState, discoveryState


    # Parses an array of providers as returned by the Mozilla TB discovery
    # service to extract IMAP/SMTP settings.
    parseProviders: (providers) ->
        state = {}
        providers.forEach (provider) ->
            return unless provider.type in ['imap', 'smtp']

            socketType = provider.socketType.toLowerCase()
            security   = if socketType in ServersEncProtocols
                socketType
            else 'none'

            _.extend state,
                "#{provider.type}Server":   provider.hostname
                "#{provider.type}Port":     +provider.port
                "#{provider.type}Security": security
        return state


    # Take a given state:
    # - removes unwanted keys for the final config (state-only concerned)
    # - bind desired keys (about security concerns) to the given state (here, it
    # translates from the <select> choice to DS Model's boolean fields).
    # - extract name and label from the mail login field (aka email identifier)
    sanitizeConfig: (state) ->
        excludes = [
            'alert'
            'isBusy'
            'isDiscoverable'
            'success'
            'enableSubmit'
            'imapSecurity'
            'smtpSecurity'
        ]
        [name, ...] = state.login.split '@'

        _.extend _.omit(state, excludes),
            label:   state.login
            name:    name
            imapSSL: state.imapSecurity is 'ssl'
            imapTLS: state.imapSecurity is 'starttls'
            smtpSSL: state.smtpSecurity is 'ssl'
            smtpTLS: state.smtpSecurity is 'starttls'
