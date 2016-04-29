_ = require 'lodash'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

RouterStore = require '../stores/router_store'
XHRUtils = require '../utils/xhr_utils'

{ActionTypes, MessageActions, SearchActions} = require '../constants/app_constants'

_pages = {}
_nextURL = {}

RouterActionCreator =

    gotoCurrentPage: (params={}) ->
        {url, page} = params

        # Always load messagesList
        action = MessageActions.SHOW_ALL
        timestamp = (new Date()).toISOString()
        url ?= RouterStore.getCurrentURL {action}
        page ?= _getPage()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {url, timestamp, page}

        XHRUtils.fetchMessagesByFolder url, (error,result) =>
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, url, timestamp, page}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {result, url, timestamp, page}

                # Save messagesLength per page
                # to get the correct pageAfter param
                # for getNext handles
                _setNextURL result

                # Missing Messages into Conversation
                messageID = RouterStore.getMessageID()
                length = RouterStore.getConversationLength {messageID}
                conversation = RouterStore.getConversation messageID
                if (length and conversation?.length) and conversation?.length isnt length
                    conversationID = conversation[0].get 'conversationID'
                    @getConversation conversationID

                # Fetch missing messages
                if RouterStore.isMissingMessages()
                    @gotoNextPage()


    gotoNextPage: ->
        url = _getNextURL()
        page = _addPage()
        @gotoCurrentPage {url, page}


    gotoCompose: (params={}) ->
        {messageID, mailboxID} = params
        action = MessageActions.NEW
        mailboxID ?= RouterStore.getMailboxID()
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, messageID, action}


    gotoMessage: (params={}) ->
        {messageID, mailboxID, action} = params
        messageID ?= RouterStore.getMessageID()
        mailboxID ?= RouterStore.getMailboxID()
        action ?= MessageActions.SHOW
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {messageID, mailboxID, action}


    closeMessage: (params={}) ->
        {mailboxID} = params
        mailboxID ?= RouterStore.getMailboxID()
        action = MessageActions.SHOW_ALL
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, action}


    showMessageList: (params={}) ->
        @closeMessage params


    getConversation: (conversationID) ->
        page = _getPage()
        timestamp = (new Date()).toISOString()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {conversationID, timestamp, page}

        XHRUtils.fetchConversation {conversationID}, (error, messages) =>
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, conversationID, timestamp, page}
            else
                result = {messages}
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {result, conversationID, timestamp, page}


    addFilter: (params) ->
        filter = {}
        separator = ','
        filters = RouterStore.getFilter()

        for key, value of params
            # Toggle filter value
            # Add value if it doesnt exist
            # Remove if from filters otherwhise
            tmp = filters[key]
            tmp = tmp.split separator if _.isString filters[key]
            value = decodeURIComponent value

            if 'flags' is key
                tmp ?= []
                if -1 < tmp.indexOf value
                    tmp = _.without tmp, value
                else
                    tmp.push value
                filter[key] = tmp?.join separator
            else
                filter[key] = value

        # FIXME : use distacher instead
        # then into routerStore, use navigate
        @navigate url: RouterStore.getCurrentURL {filter, isServer: false}


    searchAll: (params={}) ->
        {query} = params
        action = SearchActions.SHOW_ALL
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {query, action}


_getPageKey = ->
    mailboxID = RouterStore.getMailboxID()
    query = RouterStore.getQuery()
    "#{mailboxID}#{query}"


_getPage = ->
    key = _getPageKey()
    _pages[key] ?= -1
    _pages[key]


_addPage = ->
    key = _getPageKey()
    _pages[key] ?= -1
    ++_pages[key]


_getNextURI = ->
    key = _getPageKey()
    page = _getPage() + 1
    "#{key}-#{page}"


_getNextURL = ->
    key = _getNextURI()
    _nextURL[key]


# Get URL from last fetch result
# not from the list that is not reliable
_setNextURL = ({messages}) ->
    key = _getNextURI()

    # Do not overwrite result
    # that has no reasons to changes
    if _nextURL[key] is undefined
        action = MessageActions.SHOW_ALL
        filter = pageAfter: _.last(messages)?.date
        _nextURL[key] = RouterStore.getCurrentURL {filter, action}


module.exports = RouterActionCreator
