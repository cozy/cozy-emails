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


    gotoCurrentPage: (params={}) ->
        {url} = params

        # Always load messagesList
        action = MessageActions.SHOW_ALL
        timestamp = (new Date()).toISOString()
        url ?= RouterStore.getCurrentURL {action}

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
                isMissingMessages = not RouterStore.isPageComplete()
                hasNextPage = RouterStore.hasNextPage()
                if hasNextPage and isMissingMessages
                    @gotoNextPage()
                else if (messageID = RouterStore.getMessageID())?
                    message = MessageStore.getByID messageID
                    if not hasNextPage.isComplete and not message
                        if (nearestMessage = RouterStore.getNearestMessage())
                            @gotoMessage nearestMessage.toJS()
                        else
                            @closeConversation()


    gotoNextPage: ->
        if not RequestsStore.isRefreshing() and (url = _getNextURL())?
            @gotoCurrentPage {url}


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


    gotoNearestMessage: (type) ->
        type ?= 'conversation'

        message = RouterStore.getNearestMessage type

        console.log 'GOTO_NEAREST_MESSAGE', message?.toJS()
        # @gotoMessage message?.toJS()


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

        console.log 'getConversation', conversationID
        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {conversationID, timestamp}

        XHRUtils.fetchConversation {conversationID}, (error, messages) =>
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, conversationID, timestamp}
            else
                # Apply flags and filter
                # to upgrade conversationLength
                # FIXME: XHRUtils.fetchConversation
                # should handle query params
                # not to do this stuff on client side

                # TODO: faire pareil pour requestByFolder
                # Apply filters to messages
                messages = _getFilteredList messages

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
        @mark target, FlagsConstants.SEEN


    mark: (target, flags) ->
        timestamp = Date.now()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, flags}

        XHRUtils.batchFlag {target, action: flags}, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, error, flags}
            else
                # Get all messages from conversation
                message = MessageStore.getByID updated.messageID
                mailboxID = message?.get 'mailboxID'
                conversationID = message?.get 'conversationID'
                messages = RouterStore.getConversation conversationID, mailboxID

                # Update _conversationLength value
                # that is only displayed by the server
                # with method fetchMessagesByFolder
                # FIXME: should be sent by server
                conversationLength = {}
                conversationLength[conversationID] = messages.length
                target.conversationLength = conversationLength

                message.updated = timestamp for message in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, updated, flags}


    # Delete message(s)
    # target:
    # - messageID or
    # - messageIDs or
    # - conversationIDs or
    # - conversationIDs
    deleteMessage: (target={}) ->
        timestamp = Date.now()
        target.messageID ?= RouterStore.getMessageID()
        target.conversationID ?= RouterStore.getConversationID()
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
    _nextURL[key]


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


# FIXME: doubon avec RouterStore.getConversation
# voir pour se passser de cette méthode
_getFilteredList = (messages) ->
    flags = RouterStore.getFilter().flags or []
    flags = [flags] if 'string' is typeof flags
    isMailboxUnread = MessageFilter.UNSEEN in flags
    isMailboxFlagged = MessageFilter.FLAGGED in flags
    _.filter messages, (message) ->
        isUnread = MessageFlags.SEEN not in message.flags
        isFlagged = MessageFlags.FLAGGED in message.flags
        isUnread is isMailboxUnread and isFlagged is isMailboxFlagged

module.exports = RouterActionCreator
