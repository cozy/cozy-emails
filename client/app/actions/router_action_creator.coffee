_ = require 'lodash'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

RouterStore = require '../stores/router_store'

XHRUtils = require '../utils/xhr_utils'

{ActionTypes, MessageActions} = require '../constants/app_constants'

_pages = {}
_nextURL = {}

RouterActionCreator =

    getCurrentPage: (params={}) ->
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
                else if RouterStore.isMissingMessages()
                    @getNextPage()


    getNextPage: ->
        url = _getNextURL()
        page = _addPage()
        @getCurrentPage {url, page}


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


    navigate: (params={}) ->
        {url} = params
        url ?= RouterStore.getURL params

        if url
            # Update URL && context
            router = RouterStore.getRouter()
            router.navigate url, trigger: true


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
        filter = pageAfter: _.last(messages)?.date
        _nextURL[key] = RouterStore.getCurrentURL {filter}


module.exports = RouterActionCreator
