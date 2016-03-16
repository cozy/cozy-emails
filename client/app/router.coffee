
LayoutActionCreator = require './actions/layout_action_creator'

RouteGetter = require './getters/router'

{ActionTypes} = require './constants/app_constants'

_ = require 'lodash'


# MessageList :
# ?sort=asc&filters=&status=unseen&start=2016-02-27T23:00:00.000Z&end=2016-03-05T22:59:59.999Z

# Search :
# #account/3510d24990c596125ecc9e1fc800616a/mailbox/3510d24990c596125ecc9e1fc80064d3/search/?q=plop


PREFIX_ACCOUNT = 'account/:accountID/mailbox/:mailboxID'
ROUTES =
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

class Router extends Backbone.Router

    routes: RouteGetter.getPrefixedRoute ROUTES, PREFIX_ACCOUNT

    initialize: ->
        Backbone.history.start()

    accountEdit: (accountID, tab) ->
        unless accountID
            accountID = RouteGetter.get('accountID')
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
        params = RouteGetter.getURLparams query
        LayoutActionCreator.setRoute 'message.list', {accountID, mailboxID, params}
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

module.exports = Router
