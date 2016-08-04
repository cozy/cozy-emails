{MessageActions, AccountActions} = require './constants/app_constants'
_ = require 'lodash'

ROUTES = [
    [MessageActions.SHOW_ALL, 'messageList',
        'mailbox/:mailboxID(?:filter)'
    ]
    [AccountActions.CREATE, 'accountNew',
        'account/new'
    ]
    [AccountActions.EDIT, 'accountEdit',
        'account/:accountID/settings/:tab'
    ]
    [MessageActions.CREATE, 'messageNew',
        'mailbox/:mailboxID/new'
    ]
    [MessageActions.EDIT, 'messageEdit',
        'mailbox/:mailboxID/:messageID/edit'
    ]
    [MessageActions.FORWARD, 'messageForward',
        'mailbox/:mailboxID/:messageID/forward'
    ]
    [MessageActions.REPLY, 'messageReply',
        'mailbox/:mailboxID/:messageID/reply'
    ]
    [MessageActions.REPLY_ALL, 'messageReplyAll',
        'mailbox/:mailboxID/:messageID/reply-all'
    ]
    [MessageActions.SHOW, 'messageShow',
        'mailbox/:mailboxID/:conversationID/:messageID(?:filter)']
]

# Prepare routes for the various formats we need
BACKBONE_ROUTES = {}
ROUTE_BY_NAME = {}
ROUTE_BY_ACTION = {}
for route in ROUTES
    [action, name, pattern] = route
    BACKBONE_ROUTES[pattern] = name
    params = pattern.match(/:\w+/g) or []
    params = params.map (param) -> param.substring(1) # drop colon before param
    route.push(params)
    ROUTE_BY_NAME[name] = route
    ROUTE_BY_ACTION[action] = route


makeURL = (action, params, forServer) ->
    route = ROUTE_BY_ACTION[action]
    unless route
        throw new Error('Router.makeURL called with wrong action : ' +
                        action)

    [action, name, pattern, paramsNames] = route

    for name in paramsNames when name isnt 'filter' and not params[name]?
        throw new Error('Router.makeURL called with wrong parameters, ' +
                        'Lacking param ' + name + ' for route ' + action )

    url = pattern
    for key, value of params when key isnt 'filter'
        url = url.replace(':' + key, value)

    if params.filter
        query = _.compact _.map params.filter, (value, key) ->
            # Server Side request:
            # Flags query doesnt exist
            key = 'flag' if forServer and key is 'flags'
            value = value.join '&' if _.isArray value
            return key + '=' + value

        query = '?' + encodeURI query.join '&' if query.length
    else
        query = ''

    prefix = if forServer then '' else '#'
    query = '/' + query if forServer

    return prefix + url.replace(/\(\?:filter\)$/, query)

module.exports = {BACKBONE_ROUTES, makeURL, ROUTE_BY_NAME}
