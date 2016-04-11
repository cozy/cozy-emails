Backbone = require 'backbone'
React    = require 'react'
ReactDOM = require 'react-dom'

RouterActionCreator  = require './actions/router_action_creator'
LayoutActionCreator  = require './actions/layout_action_creator'
AccountActionCreator = require './actions/account_action_creator'

AppDispatcher = require './app_dispatcher'

{ActionTypes, MessageActions, AccountActions, SearchActions} = require './constants/app_constants'


# MessageList :
# ?sort=asc&filters=&status=unseen&start=2016-02-27T23:00:00.000Z&end=2016-03-05T22:59:59.999Z

# Search :
# #account/3510d24990c596125ecc9e1fc800616a/mailbox/3510d24990c596125ecc9e1fc80064d3/search/?q=plop

class Router extends Backbone.Router

    routes:
        'mailbox/:mailboxID(?:query)':             'messageList'
        'account/new':                             'accountNew'
        'account/:accountID/settings/:tab':        'accountEdit'
        # 'search/?q=:search'                         : 'search'
        # 'mailbox/:mailboxID/search/?q=:search'      : 'search'
        'mailbox/:mailboxID/new':                  'messageNew'
        'mailbox/:mailboxID/:messageID/edit':      'messageEdit'
        'mailbox/:mailboxID/:messageID/forward':   'messageForward'
        'mailbox/:mailboxID/:messageID/reply':     'messageReply'
        'mailbox/:mailboxID/:messageID/reply-all': 'messageReplyAll'
        'mailbox/:mailboxID/:messageID(?:query)':  'messageShow'
        # FIXME: set redirect to inbox of first account
        # '(?:query)':                               'messageList'


    initialize: ->
        # Save Routes in Stores
        AppDispatcher.dispatch
            type: ActionTypes.ROUTES_INITIALIZE
            value: @

        # Start Navigation
        Backbone.history.start()

        # Display application
        _displayApplication()


    accountNew: ->
        # RouterActionCreator.setAction AccountActions.CREATE
        # AccountActionCreator.selectAccount()
        _dispatch {action: AccountActions.CREATE}


    accountEdit: (accountID, tab) ->
        # RouterActionCreator.setAction AccountActions.EDIT
        # AccountActionCreator.saveEditTab tab
        # AccountActionCreator.selectAccount accountID
        _dispatch {action: AccountActions.EDIT, accountID, tab}


    messageList: (mailboxID, query) ->
        # RouterActionCreator.setAction MessageActions.SHOW_ALL
        # LayoutActionCreator.updateMessageList {mailboxID, query}
        _dispatch {action: MessageActions.SHOW_ALL, mailboxID}, query


    messageShow: (mailboxID, messageID, query) ->
        # RouterActionCreator.setAction MessageActions.SHOW
        # LayoutActionCreator.updateMessageList {mailboxID, messageID, query}
        _dispatch {action: MessageActions.SHOW, mailboxID, messageID}, query


    messageEdit: (mailboxID, messageID) ->
        # RouterActionCreator.setAction MessageActions.EDIT
        # LayoutActionCreator.saveMessage {mailboxID, messageID}
        _dispatch {action: MessageActions.EDIT, mailboxID, messageID}


    messageNew: (mailboxID) ->
        # RouterActionCreator.setAction MessageActions.CREATE
        # LayoutActionCreator.saveMessage {mailboxID}
        _dispatch {action: MessageActions.CREATE, mailboxID}


    messageForward: (mailboxID, messageID) ->
        # RouterActionCreator.setAction MessageActions.FORWARD
        # LayoutActionCreator.saveMessage {mailboxID, messageID}
        _dispatch {action: MessageActions.FORWARD, mailboxID}


    messageReply: (mailboxID, messageID) ->
        # RouterActionCreator.setAction MessageActions.REPLY
        # LayoutActionCreator.saveMessage {mailboxID, messageID}
        _dispatch {action: MessageActions.REPLY, mailboxID}


    messageReplyAll: (mailboxID, messageID) ->
        # RouterActionCreator.setAction MessageActions.REPLY_ALL
        # LayoutActionCreator.saveMessage {mailboxID, messageID}
        _dispatch {action: MessageActions.REPLY_ALL, mailboxID}


    # search: (accountID, mailboxID, value) ->
    #     RouterActionCreator.setAction SearchActions.SHOW_ALL
    #     console.log 'Search', accountID, mailboxID, value


# Dispatch payload with extracted query if available
_dispatch = (payload, query) ->
    payload.query = _parseQuery query if query
    AppDispatcher.dispatch
        type: ActionTypes.ROUTE_CHANGE
        value: payload


# Extract params from q queryString to an object that map `key` > `value`.
# Extracted values can be:
# - a simple string: `?foo=bar` > {foo: 'bar'}
# - an array (comma separator): `?foo=bar,23` > {foo: ['bar', '23']}
# - an object (colon separator): `?foo=dest:asc` > {foo: {dest: 'asc'}}
# - a boolean mapped to true: `?foo` > {foo: true}
_parseQuery = (query) ->
    params = {}
    parts = query.split '&'
    for part in parts
        [param, value] = part.split '='
        params[param] = if /,/g.test value
            value.split ','
        else if /:/.test value
            [arg, val] = value.split ':'
            (obj = {})[arg] = val
            obj
        else
            value or true
    return params


_displayApplication = ->
    Application = React.createFactory require './components/application'
    ReactDOM.render Application(), document.querySelector '[role=application]'


module.exports = Router
