Backbone = require 'backbone'
React    = require 'react'
ReactDOM = require 'react-dom'

RouterStore = require './stores/router_store'

RouterActionCreator = require './actions/router_action_creator'
NotificationActionCreator = require './actions/notification_action_creator'

AppDispatcher = require './libs/flux/dispatcher/dispatcher'

{ActionTypes, MessageActions, AccountActions, SearchActions} = require './constants/app_constants'

Polyglot = require 'node-polyglot'
moment   = require 'moment'

# MessageList :
# ?sort=asc&filters=&status=unseen&start=2016-02-27T23:00:00.000Z&end=2016-03-05T22:59:59.999Z

# Search :
# #account/3510d24990c596125ecc9e1fc800616a/mailbox/3510d24990c596125ecc9e1fc80064d3/search/?q=plop

class Router extends Backbone.Router

    routes:
        'mailbox/:mailboxID(?:query)':                              'messageList'
        'account/new':                                              'accountNew'
        'account/:accountID/settings/:tab':                         'accountEdit'
        # 'search/?q=:search':                                      'search'
        # 'mailbox/:mailboxID/search/?q=:search':                   'search'
        'mailbox/:mailboxID/new':                                   'messageNew'
        'mailbox/:mailboxID/:messageID/edit':                       'messageEdit'
        'mailbox/:mailboxID/:messageID/forward':                    'messageForward'
        'mailbox/:mailboxID/:messageID/reply':                      'messageReply'
        'mailbox/:mailboxID/:messageID/reply-all':                  'messageReplyAll'
        'mailbox/:mailboxID/:conversationID/:messageID(?:query)':   'messageShow'
        '':                                                         'defaultView'


    initialize: ->
        _setLocale()

        # Save Routes in Stores
        AppDispatcher.dispatch
            type: ActionTypes.ROUTES_INITIALIZE
            value: @

        # Display application
        _displayApplication()

        # Start Navigation
        Backbone.history.start()


    defaultView: ->
        url = if (mailboxID = RouterStore.getMailboxID())
        then "mailbox/#{mailboxID}"
        else "account/new"

        @navigate url, trigger: true


    accountNew: ->
        _dispatch {action: AccountActions.CREATE}


    accountEdit: (accountID, tab) ->
        _dispatch {action: AccountActions.EDIT, accountID, tab}


    messageList: (mailboxID, query) ->
        _dispatch {action: MessageActions.SHOW_ALL, mailboxID}, query


    messageShow: (mailboxID, conversationID, messageID, query) ->
        _dispatch {action: MessageActions.SHOW, mailboxID, conversationID, messageID}, query


    messageEdit: (mailboxID, messageID) ->
        _dispatch {action: MessageActions.EDIT, mailboxID, messageID}


    messageNew: (mailboxID) ->
        _dispatch {action: MessageActions.CREATE, mailboxID}


    messageForward: (mailboxID, messageID) ->
        _dispatch {action: MessageActions.FORWARD, mailboxID, messageID}


    messageReply: (mailboxID, messageID) ->
        _dispatch {action: MessageActions.REPLY, mailboxID, messageID}


    messageReplyAll: (mailboxID, messageID) ->
        _dispatch {action: MessageActions.REPLY_ALL, mailboxID, messageID}


    # search: (accountID, mailboxID, value) ->
    #     RouterActionCreator.setAction SearchActions.SHOW_ALL
    #     console.log 'Search', accountID, mailboxID, value


# Dispatch payload with extracted query if available
_dispatch = (payload, query) ->
    payload.query = _parseQuery query if query

    # Always get freshest data as possible
    if payload.action in [MessageActions.SHOW_ALL, MessageActions.SHOW]
        RouterActionCreator.refreshMailbox payload

    # Get all informations to display application
    if payload.action in [MessageActions.SHOW_ALL, MessageActions.SHOW]
        RouterActionCreator.getCurrentPage()

    # Get all messages from conversation
    if payload.action is MessageActions.SHOW
        RouterActionCreator.getConversation payload.conversationID

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


# update locate (without saving it into settings)
_setLocale = (lang) ->
    lang ?= window.locale or window.navigator.language or 'en'
    moment.locale lang
    locales = {}
    try
        locales = require "./locales/#{lang}"
    catch err
        console.log err
        locales = require "./locales/en"
    polyglot = new Polyglot()
    # we give polyglot the data
    polyglot.extend locales
    # handy shortcut
    window.t = polyglot.t.bind polyglot

module.exports = Router
