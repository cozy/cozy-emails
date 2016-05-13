{ServersEncProtocols} = require '../constants/app_constants'

_ = require 'underscore'


module.exports =

    # Take a state identifier (key), its value, and the previousState.
    # It ensures the type is right with PropTypes, and manage auto-filling for
    # associated keys (logins / passwords).
    validateAccountState: (key, value, previousState) ->
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
            _.defaults previousState,
                imapLogin:    undefined
                imapPassword: undefined
                smtpLogin:    undefined
                smtpPassword: undefined

            # Extract values for filter
            re     = new RegExp "#{key}$", 'i'
            refVal = previousState[key]

            # Parse previousState and keep fields mapped to key w/ an
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
