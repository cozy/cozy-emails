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

    DEFAULT_PORTS:
        imap:
            ssl:      993
            starttls: 143
            none:     143
        smtp:
            ssl:      465
            starttls: 587
            none:     25


    DEFAULT_SECURITY: 'starttls'


    SECURITY_OPTS: ServersEncProtocols
        .map (protocol) ->
            value: protocol
            label: t "server protocol #{protocol}"
        .concat
            value: 'none'
            label: 'server protocol none'


    REDIRECT_DELAY: 5000


    # TODO : list params that arer needed
    # document the code!
    getServersProps: (state) ->
        expanded: state.expanded
        legend: t 'account wizard creation advanced parameters'


    # FIXME: QUID de isAccountDiscoverable ?!
    isExpanded: () ->



    # Take a state identifier (key), its value, and the previousState.
    # It ensures the type is right with PropTypes, and manage auto-filling for
    # associated keys (logins / passwords).
    validateState: (nextState={}, previousState={}) ->
        fields = {}
        previousFields = {}
        expanded = false

        protocolKeys = _.keys @DEFAULT_PORTS

        for key, value of nextState.fields
            # In case key is 'port',
            # ensure the value type is a number
            value = +value if /port$/i.test key

            # Only override port if it isn't a custom one
            # (be careful to convert type from state to be a number)
            # if not nextState.port? and not previousState.port?
            if 'security' is (params = key.split('-'))[1]?.toLowerCase()
                protocol = params[0]
                portValue = nextState.fields["#{protocol}Port"]
                portValue ?= previousFields["#{protocol}Port"]

                if portValue in _.values @DEFAULT_PORTS[protocol]
                    fields["#{protocol}Port"] = +@DEFAULT_PORTS[protocol][value]


            # Make sure that property is in camelCase
            # ie. imap-port -> imapPort
            key = _toCamelCase key if params.length > 1

            # prepare the state object
            fields[key] = value

            # if key is login or password input, reflect the value in the
            # server's username / password fields, except if the value in
            # those field is already field with a different value.
            # This allow to bulk update each fields mapped to the username/
            # password field, and allow to input custom values in server's
            # sections if needed.
            if key in ['login', 'password']
                # Ensure previousState contains all required fields
                _.defaults previousState.fields,
                    imapLogin       : undefined
                    imapPassword    : undefined
                    smtpLogin       : undefined
                    smtpPassword    : undefined

                # Extract values for filter
                re     = new RegExp "#{key}$", 'i'
                refVal = previousState.fields[key]

                # Parse previousState and
                # keep fields mapped to key
                # with unaltered values
                previousFields = _.chain previousState.fields
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
            if key is 'login' and
                    not(previousState.fields.imapServer or
                    previousState.fields.smtpServer)

                expanded = true

        _.extend {}, {fields: previousFields}, {fields, expanded}


    # Take a given state:
    # - removes unwanted keys for the final config (state-only concerned)
    # - bind desired keys (about security concerns) to the given state (here, it
    # translates from the <select> choice to DS Model's boolean fields).
    # - extract name and label from the mail login field (aka email identifier)

    # FIXME : should be done into getters instead?!
    # FIXME : missing comment to explain state
    # ie. type? if object: properties?
    sanitizeConfig: (state) ->
        excludes = [
            'OAuth'
            'alert'
            'success'
            'enableSubmit'
            'imapSecurity'
            'smtpSecurity'
        ]
        [name, ...] = state.login.split '@'

        _.extend _.omit(state, excludes),
            label    : state.login
            name     : name
            imapSSL  : state.imapSecurity is 'ssl'
            imapTLS  : state.imapSecurity is 'starttls'
            smtpSSL  : state.smtpSecurity is 'ssl'
            smtpTLS  : state.smtpSecurity is 'starttls'


    # Parses an array of providers as returned
    # by the Mozilla TB discovery
    # service to extract IMAP/SMTP settings.
    getProviderProps: (providers) ->
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


    # @context : 'imap' or 'smtp'
    # Return unprefixed props
    # to the Server component
    filterPropsByProvider: (props={}, protocol) ->
        isCustomized = props.login isnt props["#{protocol}Login"] or
            props.password isnt props["#{protocol}Password"]

        toValueLink = (name) ->
            # Each property is stored
            # into a different name into the state
            # protocol value is needed to complete the whole name
            property = _toCamelCase [protocol, name].join('-')
            return props.toValueLink property

        return {
            login: toValueLink 'login'
            password: toValueLink 'password'
            server: toValueLink 'server'
            port: toValueLink 'port'
            security: toValueLink 'security'

            protocol: protocol
            isCustomized: isCustomized
        }



_toCamelCase = (name, prefix) ->
    result = []

    props = name.split '-'

    # Sometime a prefix is needed
    props.push prefix if prefix?

    # Do not capitalize first word
    result.push props[0].toLowerCase() if props.length > 1

    # Capitalize other words
    for property, index in props when index
        upper = property.substring(0, 1).toUpperCase()
        lower = property.substring(1, property.length).toLowerCase()
        result.push [upper, lower].join('')

    return result.join('')
