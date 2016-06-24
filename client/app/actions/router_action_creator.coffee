_ = require 'lodash'
Immutable = require 'immutable'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

RouterStore     = require '../stores/router_store'
RequestsStore   = require '../stores/requests_store'
MessageStore = require '../stores/message_store'

Notification = require '../libs/notification'

XHRUtils = require '../libs/xhr'

{ActionTypes,
MessageActions,
SearchActions,
FlagsConstants,
MessageFilter,
MessageFlags} = require '../constants/app_constants'

_pages = {}
_nextURL = {}
_currentRequest = null


RouterActionCreator =
    # Refresh Emails from Server
    # This is a read data pattern
    # ActionCreator is a write data pattern
    refreshMailbox: ({mailboxID, deep}) ->
        return unless (mailboxID ?= RouterStore.getMailboxID())
        deep ?= true
        silent = true

        AppDispatcher.dispatch
            type: ActionTypes.REFRESH_REQUEST
            value: {mailboxID, deep, silent}

        XHRUtils.refreshMailbox mailboxID, {deep, silent}, (error, updated) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.REFRESH_FAILURE
                    value: {mailboxID, error}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.REFRESH_SUCCESS
                    value: {mailboxID, updated}


    getCurrentPage: (params={}) ->
        {url} = params
        url ?= RouterStore.getCurrentURL {action}

        _currentRequest = url

        # Always load messagesList
        action = MessageActions.SHOW_ALL
        timestamp = (new Date()).toISOString()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {url, timestamp}

        XHRUtils.fetchMessagesByFolder url, (error, result) =>
            # Save messagesLength per page
            # to get the correct pageAfter param
            # for getNext handles
            pageAfter = _.last(result.messages)?.date

            # Sometimes MessageList content
            # has more reslts than request has
            oldLastPage = RouterStore.getLastPage()
            if oldLastPage?.start? and oldLastPage.start < pageAfter
                pageAfter = oldLastPage.start
                lastPage = oldLastPage

            unless lastPage?
                # Prepare next load
                _setNextURL {pageAfter}

                lastPage = {
                    page: _getPage()
                    start: pageAfter
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
                # otherwhise if message doesnt exist anymore
                # ie. removed from outside (socketEvent)
                # ie. navigate with history
                # - try to select nearestMessage
                # - if not select current MessageList
                # - if no messageList go to default mailbox
                isPageComplete = RouterStore.isPageComplete()
                hasNextPage = RouterStore.hasNextPage()
                if hasNextPage and not isPageComplete
                    @gotoNextPage()


    gotoNextPage: ->
        if (url = _getNextURL())?
            @getCurrentPage {url}


    gotoCompose: (params={}) ->
        {messageID, mailboxID} = params

        action = MessageActions.NEW
        mailboxID ?= RouterStore.getMailboxID messageID

        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, messageID, action}


    # Get last message unread
    # or get last message if not
    gotoConversation: (params={}) ->
        {conversationID} = params

        # 1rst: load all messages from conversation
        @getConversation conversationID

        # 2nd: redirect to conversation
        messageID = RouterStore.getMessageID conversationID
        @gotoMessage {conversationID, messageID}


    gotoMessage: (message={}) ->
        {conversationID, messageID, mailboxID, filter} = message

        messageID ?= RouterStore.getMessageID()
        mailboxID ?= RouterStore.getMailboxID messageID
        query = filter or RouterStore.getFilter()

        unless messageID
            action = MessageActions.SHOW_ALL
            AppDispatcher.dispatch
                type: ActionTypes.ROUTE_CHANGE
                value: {mailboxID, action, query}
        else
            action = MessageActions.SHOW
            AppDispatcher.dispatch
                type: ActionTypes.ROUTE_CHANGE
                value: {conversationID, messageID, mailboxID, action, query}


    gotoPreviousConversation: ->
        message = RouterStore.getNextConversation()
        @gotoMessage message?.toJS()


    gotoNextConversation: ->
        message = RouterStore.getNextConversation()
        @gotoMessage message?.toJS()


    closeConversation: (params={}) ->
        {mailboxID} = params
        mailboxID ?= RouterStore.getMailboxID()
        action = MessageActions.SHOW_ALL
        query = RouterStore.getFilter()
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, action, query}


    closeModal: ->
        return unless (mailboxID = RouterStore.getMailboxID())?

        # Load last messages
        @refreshMailbox {mailboxID}

        # Display defaultMailbox
        action = MessageActions.SHOW_ALL
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, action}


    showMessageList: (params={}) ->
        @closeConversation params


    getConversation: (conversationID) ->
        conversationID ?= RouterStore.getConversationID()
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
                # Apply filters to messages
                # to upgrade conversationLength
                # FIXME: should be moved server side
                messages = _.filter messages, RouterStore.filterFlags

                # Update Realtime
                lastMessage = _.last messages
                mailboxID = lastMessage?.mailboxID
                before = lastMessage?.date or timestamp
                Notification.setServerScope {mailboxID, before}

                # Update _conversationLength value
                # that is only displayed by the server
                # with method fetchMessagesByFolder
                # FIXME: should be sent by server
                conversationLength = {}
                conversationLength[conversationID] = messages.length

                result = {messages, conversationLength}
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {result, conversationID, timestamp}


    markAsRead: (target) ->
        {messageID, accountID} = target

        # Do not mark a message that is ever flagged
        message = MessageStore.getByID messageID
        if message and MessageStore.isUnread {message}
            @mark {messageID, accountID}, FlagsConstants.SEEN


    mark: (target, flags) ->
        timestamp = Date.now()

        # Do not mark a removed message
        {messageID} = target
        if messageID and not (message = MessageStore.getByID messageID)
            return

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, flags, timestamp}

        XHRUtils.batchFlag {target, action: flags}, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, error, flags, timestamp}
            else
                # Update _conversationLength value
                # that is only displayed by the server
                # with method fetchMessagesByFolder
                # FIXME: should be sent by server

                # FIXME: clent shouldnt add this information
                # it shoul be done server side
                updated = {messages}
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, updated, flags, timestamp}


    # Delete message(s)
    # target:
    # - messageID or
    # - messageIDs or
    # - conversationIDs or
    # - conversationIDs
    deleteMessage: (target={}) ->
        timestamp = Date.now()
        {messageID, accountID} = target
        messageID ?= RouterStore.getMessageID()
        accountID ?= RouterStore.getAccountID()
        target = {messageID, accountID}

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


_getPage = ->
    key = RouterStore.getURI()
    _pages[key] ?= -1
    _pages[key]


_addPage = ->
    key = RouterStore.getURI()
    _pages[key] ?= -1
    ++_pages[key]


_getNextURI = ->
    key = RouterStore.getURI()
    page = _getPage()
    "#{key}-#{page}"


_getNextURL = ->
    key = _getNextURI()
    if (_nextURL[key] isnt _currentRequest)
        return _nextURL[key]


_getPreviousURI = ->
    if (page = _getPage()) > 0
        key = RouterStore.getURI()
        "#{key}-#{--page}"


_getPreviousURL = ->
    if (key = _getPreviousURI())?
        return _nextURL[key]


# Get URL from last fetch result
# not from the list that is not reliable
_setNextURL = ({pageAfter}) ->
    _addPage()
    key = _getNextURI()

    # Do not overwrite result
    # that has no reasons to changes
    if _getNextURL() is undefined
        action = MessageActions.SHOW_ALL
        filter = {pageAfter}

        currentURL = RouterStore.getCurrentURL {filter, action}
        if _getPreviousURL() isnt currentURL
            _nextURL[key] = currentURL

module.exports = RouterActionCreator
