RouterActionCreator = require './actions/router_action_creator'
LayoutActionCreator = require './actions/layout_action_creator'

ApplicationGetter = require './getters/application'

AppDispatcher = require './app_dispatcher'

{ActionTypes} = require './constants/app_constants'

_ = require 'lodash'

# MessageList :
# ?sort=asc&filters=&status=unseen&start=2016-02-27T23:00:00.000Z&end=2016-03-05T22:59:59.999Z

# Search :
# #account/3510d24990c596125ecc9e1fc800616a/mailbox/3510d24990c596125ecc9e1fc80064d3/search/?q=plop

class Router extends Backbone.Router

    routes:
        'mailbox/:mailboxID/*'                      : 'messageList'
        'account/new'                               : 'accountNew'
        'account/:accountID/config/:tab'            : 'accountConfig'
        'search/?q=:search'                         : 'search'
        'mailbox/:mailboxID/search/?q=:search'      : 'search'
        'mailbox/:mailboxID/:messageID/*'           : 'messageShow'
        'mailbox/:mailboxID/:messageID/edit'        : 'messageEdit'
        'mailbox/:mailboxID/new'                    : 'messageNew'
        'mailbox/:mailboxID/:messageID/forward'     : 'messageForward'
        'mailbox/:mailboxID/:messageID/reply'       : 'messageReply'
        'mailbox/:mailboxID/:messageID/reply-all'   : 'messageReplyAll'
        '/*'                                        : 'messageList'

    initialize: ->
        # Save Routes in Stores
        AppDispatcher.handleViewAction
            type: ActionTypes.SAVE_ROUTES
            value: @

        # Start Navigation
        Backbone.history.start()

        # Display application
        _displayApplication()


    navigate: (url, options={}) ->
        # Get Callback to execute
        # to force Stores update
        if options.update
            parameters = null
            routeCallback = _.find @routes, (callback, pattern) =>
                pattern = @_routeToRegExp '#' + pattern
                route = new RegExp pattern, 'gi'
                if url.match route
                    parameters = @_extractParameters route, url
                    return true
            if routeCallback
                @[routeCallback].apply @, parameters

        super url, options

    accountNew: (accountID) ->
        RouterActionCreator.setAction 'account.new'
        console.log 'new account', accountID

    accountConfig: (accountID) ->
        RouterActionCreator.setAction 'account.new'
        console.log 'GOTO account', accountID

    messageList: (mailboxID, query) ->
        RouterActionCreator.setAction 'message.list'
        console.log 'messageList', mailboxID, query
        LayoutActionCreator.updateMessageList {mailboxID, query}

    messageShow: (mailboxID, messageID, query) ->
        RouterActionCreator.setAction 'message.show'
        LayoutActionCreator.updateMessageList {mailboxID, messageID, query}

    messageEdit: (messageID) ->
        RouterActionCreator.setAction 'message.edit'
        console.log 'Compose', 'action=edit', 'id=', messageID

    messageNew: ->
        RouterActionCreator.setAction 'message.new'
        console.log 'Compose', 'action=new'

    messageForward: (messageID) ->
        RouterActionCreator.setAction 'message.forward'
        console.log 'Compose', 'action=forward', 'id=', messageID

    messageReply: (messageID) ->
        RouterActionCreator.setAction 'message.reply'
        console.log 'Compose', 'action=reply', 'id=', messageID

    messageReplyAll: (messageID) ->
        RouterActionCreator.setAction 'message.reply.all'
        console.log 'Compose', 'action=reply-all', 'id=', messageID

    search: (accountID, mailboxID, value) ->
        RouterActionCreator.setAction 'search'
        console.log 'Search', accountID, mailboxID, value

_displayApplication = ->
    React = require 'react'
    ReactDOM   = require 'react-dom'

    Application = React.createFactory require './components/application'
    props = ApplicationGetter.getProps 'application'
    ReactDOM.render Application(props), document.querySelector '[role=application]'

module.exports = Router
