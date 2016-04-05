RouterActionCreator = require './actions/router_action_creator'
LayoutActionCreator = require './actions/layout_action_creator'
AccountActionCreator = require './actions/account_action_creator'

AppDispatcher = require './app_dispatcher'

{ActionTypes, MessageActions, AccountActions, SearchActions} = require './constants/app_constants'

_ = require 'lodash'

# MessageList :
# ?sort=asc&filters=&status=unseen&start=2016-02-27T23:00:00.000Z&end=2016-03-05T22:59:59.999Z

# Search :
# #account/3510d24990c596125ecc9e1fc800616a/mailbox/3510d24990c596125ecc9e1fc80064d3/search/?q=plop

class Router extends Backbone.Router

    routes:
        'mailbox/:mailboxID/*'                      : 'messageList'
        'account/new'                               : 'accountNew'
        'account/:accountID/config/:tab'            : 'accountEdit'
        # 'search/?q=:search'                         : 'search'
        # 'mailbox/:mailboxID/search/?q=:search'      : 'search'
        'mailbox/:mailboxID/new'                    : 'messageNew'
        'mailbox/:mailboxID/:messageID/edit'        : 'messageEdit'
        'mailbox/:mailboxID/:messageID/forward'     : 'messageForward'
        'mailbox/:mailboxID/:messageID/reply'       : 'messageReply'
        'mailbox/:mailboxID/:messageID/reply-all'   : 'messageReplyAll'
        'mailbox/:mailboxID/:messageID/*'           : 'messageShow'
        '/*'                                        : 'messageList'

    initialize: ->
        # Save Routes in Stores
        AppDispatcher.handleViewAction
            type: ActionTypes.ROUTES_INITIALIZE
            value: @

        # Start Navigation
        Backbone.history.start()

        # Display application
        _displayApplication()

    accountNew: ->
        RouterActionCreator.setAction AccountActions.CREATE
        AccountActionCreator.selectAccount()

    accountEdit: (accountID, tab) ->
        RouterActionCreator.setAction AccountActions.EDIT
        AccountActionCreator.saveEditTab tab
        AccountActionCreator.selectAccount accountID

    messageList: (mailboxID, query) ->
        RouterActionCreator.setAction MessageActions.SHOW_ALL
        LayoutActionCreator.updateMessageList {mailboxID, query}

    messageShow: (mailboxID, messageID, query) ->
        RouterActionCreator.setAction MessageActions.SHOW
        LayoutActionCreator.updateMessageList {mailboxID, messageID, query}

    messageEdit: (mailboxID, messageID) ->
        RouterActionCreator.setAction MessageActions.EDIT
        LayoutActionCreator.saveMessage {mailboxID, messageID}

    messageNew: (mailboxID) ->
        RouterActionCreator.setAction MessageActions.CREATE
        LayoutActionCreator.saveMessage {mailboxID}

    messageForward: (mailboxID, messageID) ->
        RouterActionCreator.setAction MessageActions.FORWARD
        LayoutActionCreator.saveMessage {mailboxID, messageID}

    messageReply: (mailboxID, messageID) ->
        RouterActionCreator.setAction MessageActions.REPLY
        LayoutActionCreator.saveMessage {mailboxID, messageID}

    messageReplyAll: (mailboxID, messageID) ->
        RouterActionCreator.setAction MessageActions.REPLY_ALL
        LayoutActionCreator.saveMessage {mailboxID, messageID}

    # search: (accountID, mailboxID, value) ->
    #     RouterActionCreator.setAction SearchActions.SHOW_ALL
    #     console.log 'Search', accountID, mailboxID, value

_displayApplication = ->
    React = require 'react'
    ReactDOM   = require 'react-dom'

    Application = React.createFactory require './components/application'
    ReactDOM.render Application(), document.querySelector '[role=application]'

module.exports = Router
