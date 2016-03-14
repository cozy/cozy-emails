
LayoutActionCreator = require '../actions/layout_action_creator'

AccountStore = require './stores/account_store'

{ActionTypes} = require '../constants/app_constants'

PREFIX_ACCOUNT = 'account/:accountID/mailbox/:mailboxID'

# MessageList :
# ?sort=asc&filters=&status=unseen&start=2016-02-27T23:00:00.000Z&end=2016-03-05T22:59:59.999Z

# Search :
# #account/3510d24990c596125ecc9e1fc800616a/mailbox/3510d24990c596125ecc9e1fc80064d3/search/?q=plop

__routes = {}

class Router extends Backbone.Router

    routes:
        '/*'                                    : 'messageList'
        'account/new'                           : 'accountEdit'
        'account/:accountID/config/:tab'        : 'accountNew'
        'search/?q=:search'                     : 'search'
        ':messageID'                            : 'messageShow'
        ':messageID/edit'                       : 'messageEdit'
        'new'                                   : 'messageNew'
        ':messageID/forward'                    : 'messageForward'
        ':messageID/reply'                      : 'messageReply'
        ':messageID/reply-all'                  : 'messageReplyAll'

    initialize: (args...) ->

        @routes = _getContextualRoutes.call @
        __routes = @routes
        # AccountID && mailboxID routes
        # TODO : test this
        # FIXME : récupérer accountID et mailboxID Default
        # lorsque les params ne sont pas précisés dans l'url
        # _.extend @routes, _getContextualRoutes.call @
        # console.log @routes
        # TODO : add all routes here
        # should be soon removed

        @_bindRoutes()

        Backbone.history.start()

    accountEdit: (accountID, tab) ->
        unless accountID
            accountID = AccountStore.getDefault()?.get 'id'
            tab = 'account'

        LayoutActionCreator.setRoute 'account.edit'
        console.log 'GOTO account', accountID, tab

    accountNew: ->
        LayoutActionCreator.setRoute 'account.new'
        # TODO : mettre ça dans les getters
        # accountID = AccountStore.getDefault()?.get 'id'
        # tab = 'account'
        console.log 'GOTO account new'

    messageList: (accountID, mailboxID, query) ->
        params = _getURLparams query
        LayoutActionCreator.setRoute 'message.list'
        LayoutActionCreator.showMessageList {accountID, mailboxID, params}

    # TODO : récupérer les noms des actions dans les constantes
    # TODO : éditer les conversation également ici

    # Récupérer conversationID du store lorsque l'on fetch le message
    messageShow: (accountID, mailboxID, messageID) ->
        LayoutActionCreator.setRoute 'message.show'
        LayoutActionCreator.showMessageList {accountID, mailboxID, messageID}

    # Récupérer conversationID du store lorsque l'on fetch le message
    messageEdit: (messageID) ->
        LayoutActionCreator.setRoute 'message.edit'
        console.log 'Compose', 'action=edit', 'id=', messageID

    # Récupérer conversationID du store lorsque l'on fetch le message
    messageNew: ->
        LayoutActionCreator.setRoute 'message.new'
        console.log 'Compose', 'action=new'

    # TODO : récupérer les noms des actions dans les constantes
    messageForward: (messageID) ->
        LayoutActionCreator.setRoute 'message.forward'
        console.log 'Compose', 'action=forward', 'id=', messageID

    # TODO : récupérer les noms des actions dans les constantes
    messageReply: (messageID) ->
        LayoutActionCreator.setRoute 'message.reply'
        console.log 'Compose', 'action=reply', 'id=', messageID

    # TODO : récupérer les noms des actions dans les constantes
    messageReplyAll: (messageID) ->
        LayoutActionCreator.setRoute 'message.reply.all'
        console.log 'Compose', 'action=reply-all', 'id=', messageID

    # TODO : récupérer les noms des actions dans les constantes
    search: (accountID, mailboxID, value) ->
        LayoutActionCreator.setRoute 'search'
        console.log 'Search', accountID, mailboxID, value

    # Static call
    buildUrl: (params) =>
        action = params.action or 'message.list'
        name = _toCamelCase action

        if -1 < (index = _.values(__routes).indexOf(name))
            route = _.keys(__routes)[index]
            return route.replace /\:\w*/gi, (match) ->
                # Get Route pattern of action
                # Replace param name by its value
                param = match.substring 1, match.length
                params[param] or ''
        return '/'

_toCamelCase = (value) ->
    return value.replace /\.(\w)*/gi, (match) ->
        part1 = match.substring 1, 2
        part2 = match.substring 2, match.length
        return part1.toUpperCase() + part2

_getURLparams = (query = '') ->
    params = query.match /([\w]+=[\w,]+)+/gi
    return unless params?.length

    result = {}
    _.each params, (param) ->
        param = param.split '='
        if -1 < (value = param[1]).indexOf ','
            value = value.split ','
        result[param[0]] = value
    result

_getContextualRoutes = ->
    _transform = (route) ->
        unless -1 < route.indexOf 'account'
            route = '/' + route unless route.indexOf('/') is 0
            return PREFIX_ACCOUNT + route
        return route

    result = {}
    _.forEach @routes, (callback, route) ->
        route = _transform route
        result[route] = callback
    result

module.exports = Router
