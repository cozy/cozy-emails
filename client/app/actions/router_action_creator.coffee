_ = require 'lodash'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

RouterStore = require '../stores/router_store'

Notification = require '../libs/notification'

XHRUtils = require '../libs/xhr'

{ActionTypes, MessageActions, SearchActions} = require '../constants/app_constants'

_pages = {}
_nextURL = {}


RouterActionCreator =
    # Refresh Emails from Server
    # This is a read data pattern
    # ActionCreator is a write data pattern
    refreshMailbox: ({mailboxID, deep}) ->
        deep ?= true

        AppDispatcher.dispatch
            type: ActionTypes.REFRESH_REQUEST
            value: {mailboxID, deep}

        XHRUtils.refreshMailbox mailboxID, {deep}, (error, updated) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.REFRESH_FAILURE
                    value: {mailboxID, error, deep}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.REFRESH_SUCCESS
                    value: {mailboxID, updated, deep}


    gotoCurrentPage: (params={}) ->
        {url} = params

        # Always load messagesList
        action = MessageActions.SHOW_ALL
        timestamp = (new Date()).toISOString()
        url ?= RouterStore.getCurrentURL {action}

        oldMessages = RouterStore.getMessagesList()
        oldPageAfter = oldMessages?.last()?.get 'date'

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {url, timestamp}

        XHRUtils.fetchMessagesByFolder url, (error, result) =>
            # Save messagesLength per page
            # to get the correct pageAfter param
            # for getNext handles
            {messages} = result
            pageKey = _getPageKey()
            pageAfter = _.last(messages)?.date

            # Sometimes MessageList content
            # has more reslts than request has
            if oldPageAfter? and oldPageAfter < pageAfter
                pageAfter = oldPageAfter
                messages = oldMessages
                lastPage = RouterStore.getLastPage pageKey

            # Prepare next load
            _setNextURL {pageAfter}

            messages ?= []
            lastPage ?= {
                page: _getPage()
                key: pageKey
                start: _.last(messages)?.date
                isComplete: _getNextURL() is undefined
            }

            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, url, timestamp, lastPage}
            else
                # Update Realtime
                lastMessage = _.last result?.messages
                mailboxID = lastMessage?.mailboxID
                before = lastMessage?.date or timestamp
                Notification.setServerScope {mailboxID, before}

                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {result, url, timestamp, lastPage}

                # Fetch missing messages
                isMissingMessages = not RouterStore.isPageComplete()
                if RouterStore.hasNextPage() and isMissingMessages
                    @gotoNextPage()


    gotoNextPage: ->
        if (url = _getNextURL())?
            @gotoCurrentPage {url}


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


    gotoPreviousMessage: ->
        message = RouterStore.gotoPreviousMessage()
        messageID = message?.get 'id'
        mailboxID = message?.get 'mailboxID'
        @gotoMessage {messageID, mailboxID}


    gotoNextMessage: ->
        message = RouterStore.gotoNextMessage()
        messageID = message?.get 'id'
        mailboxID = message?.get 'mailboxID'
        @gotoMessage {messageID, mailboxID}


    gotoPreviousConversation: ->
        message = RouterStore.getNextConversation()
        messageID = message?.get 'id'
        mailboxID = message?.get 'mailboxID'
        @gotoMessage {messageID, mailboxID}


    gotoNextConversation: ->
        message = RouterStore.getNextConversation()
        messageID = message?.get 'id'
        mailboxID = message?.get 'mailboxID'
        @gotoMessage {messageID, mailboxID}



    closeConversation: (params={}) ->
        {mailboxID} = params
        mailboxID ?= RouterStore.getMailboxID()
        action = MessageActions.SHOW_ALL
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, action}


    showMessageList: (params={}) ->
        @closeConversation params


    getConversation: (conversationID) ->
        timestamp = (new Date()).toISOString()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {conversationID, timestamp}

        XHRUtils.fetchConversation {conversationID}, (error, messages) =>
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, conversationID, timestamp}
            else
                result = {messages}

                # Update Realtime
                lastMessage = _.last messages
                mailboxID = lastMessage?.mailboxID
                before = lastMessage?.date or timestamp
                Notification.setServerScope {mailboxID, before}

                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {result, conversationID, timestamp}


    mark: (target, action) ->
        timestamp = Date.now()

        AppDispatcher.dispatch
        type: ActionTypes.MESSAGE_FLAGS_REQUEST
        value: {target, action}

        XHRUtils.batchFlag {target, action}, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, error, action}
            else
                message.updated = timestamp for message in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, updated, action}

    # Delete message(s)
    # target:
    # - messageID or
    # - messageIDs or
    # - conversationIDs or
    # - conversationIDs
    deleteMessage: (target={}) ->
        timestamp = Date.now()
        target.messageID ?= RouterStore.getMessageID()
        target.accountID ?= RouterStore.getAccountID()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_TRASH_REQUEST
            value: {target}

        # send request
        XHRUtils.batchDelete target, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_TRASH_FAILURE
                    value: {target, error}
            else
                message.updated = timestamp for message in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_TRASH_SUCCESS
                    value: {target, updated}


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
    "#mailbox/#{mailboxID}#{query}"


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
    page = _getPage()
    "#{key}-#{page}"


_getNextURL = ->
    key = _getNextURI()
    _nextURL[key]


_getPreviousURI = ->
    if (page = _getPage()) > 0
        key = _getPageKey()
        "#{key}-#{--page}"


_getPreviousURL = ->
    if (key = _getPreviousURI())?
        return _nextURL[key]


# Get URL from last fetch result
# not from the list that is not reliable
_setNextURL = ({pageAfter}) ->
    page = _addPage()
    key = _getNextURI()

    # Do not overwrite result
    # that has no reasons to changes
    if _getNextURL() is undefined
        action = MessageActions.SHOW_ALL
        filter = {pageAfter}

        value = RouterStore.getCurrentURL {filter, action}
        previousValue = _getPreviousURL()
        if not previousValue? or previousValue isnt value
            _nextURL[key] = value


module.exports = RouterActionCreator
