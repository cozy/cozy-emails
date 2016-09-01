{MessageActions, AccountActions,
DefaultActions} = require './constants/app_constants'
_ = require 'lodash'

exports.BACKBONE_ROUTES =
    '': DefaultActions.DEFAULT
    'mailbox/:mailboxID(?:filter)': MessageActions.SHOW_ALL
    'account/new': AccountActions.CREATE
    'account/:accountID/settings/:tab': AccountActions.EDIT
    'mailbox/:mailboxID/new': MessageActions.CREATE
    'mailbox/:mailboxID/:messageID/edit': MessageActions.EDIT
    'mailbox/:mailboxID/:messageID/forward': MessageActions.FORWARD
    'mailbox/:mailboxID/:messageID/reply': MessageActions.REPLY
    'mailbox/:mailboxID/:messageID/reply-all': MessageActions.REPLY_ALL
    'mailbox/:mailboxID/:conversationID/:messageID(?:filter)':
                                                            MessageActions.SHOW


# Prepare routes for the various formats we need
exports.ROUTE_BY_ACTION = {}
for pattern, action of exports.BACKBONE_ROUTES
    params = pattern.match(/:\w+/g) or []
    params = params.map (param) -> param.substring(1) # drop colon before param
    exports.ROUTE_BY_ACTION[action] = [action, pattern, params]


exports.makeURL = (action, params, forServer) ->
    route = exports.ROUTE_BY_ACTION[action]
    unless route
        throw new Error('Router.makeURL called with wrong action : ' +
                        action)

    [action, pattern, paramsNames] = route

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
