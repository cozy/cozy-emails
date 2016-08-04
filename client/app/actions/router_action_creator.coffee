_ = require 'lodash'

AppDispatcher   = require '../libs/flux/dispatcher/dispatcher'

AccountGetter  = require '../getters/account'
RouterGetter   = require '../getters/router'

reduxStore = require '../reducers/_store'

Realtime = require '../libs/realtime'

XHRUtils = require '../libs/xhr'

{ActionTypes, MessageActions} = require '../constants/app_constants'

RouterActionCreator =
    # Refresh Emails from Server
    # This is a read data pattern
    # ActionCreator is a write data pattern
    refreshMailbox: ({mailboxID}) ->
        throw new Error('expected mailboxID') unless mailboxID

        AppDispatcher.dispatch
            type: ActionTypes.REFRESH_REQUEST
            value: {mailboxID, deep: true, silent: true}

        options = deep: true, silent: true
        XHRUtils.refreshMailbox mailboxID, options, (error, updated) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.REFRESH_FAILURE
                    value: {mailboxID, error}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.REFRESH_SUCCESS
                    value: {mailboxID, updated}

    # called by message-list when the user click on the button at bottom
    loadMore: ->
        state = reduxStore.getState()
        url = RouterGetter.getFetchURL(state)

        if url and
        RouterGetter.hasNextPage(state) and
        not RouterGetter.isLoading(state)
            @doFetchMessages url


    # called by the router when the page is shown and above
    getCurrentPage: ->
        state = reduxStore.getState()
        url = RouterGetter.getFetchURL(state)

        if url and
        RouterGetter.hasNextPage(state) and
        not RouterGetter.isPageComplete(state) and
        not RouterGetter.isLoading(state)
            @doFetchMessages url

    doFetchMessages: (url) ->

        # Always load messagesList
        timestamp = (new Date()).valueOf()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {url, timestamp}

        XHRUtils.fetchMessagesByFolder url, (error, result={}) =>
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, url, timestamp}
            else
                # Update Realtime
                lastMessage = _.last result?.messages
                mailboxID = lastMessage?.mailboxID
                before = lastMessage?.date or timestamp
                Realtime.setServerScope {mailboxID, before}

                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {result, url, timestamp}

                # Fetch missing messages
                # otherwhise if message doesnt exist anymore
                # ie. removed from outside (socketEvent)
                # ie. navigate with history
                # - try to select nearestMessage
                # - if not select current MessageList
                # - if no messageList go to default mailbox
                if RouterGetter.hasNextPage() and
                not RouterGetter.isPageComplete()
                    @getCurrentPage()

    gotoCompose: (params={}) ->
        {messageID, mailboxID} = params

        action = MessageActions.NEW
        mailboxID ?= RouterGetter.getMailboxID messageID

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
        # At first get unread Message
        # if not get last message
        messages = RouterGetter.getConversation conversationID
        message = messages.find (message) -> message.isUnread()
        message ?= messages.shift()
        messageID = message?.get 'id'
        @gotoMessage {conversationID, messageID}


    gotoMessage: (message={}) ->
        {conversationID, messageID, mailboxID, filter} = message

        messageID ?= RouterGetter.getMessageID()
        mailboxID ?= RouterGetter.getMailboxID messageID
        filter = filter or RouterGetter.getFilter()

        unless messageID
            action = MessageActions.SHOW_ALL
            AppDispatcher.dispatch
                type: ActionTypes.ROUTE_CHANGE
                value: {mailboxID, action, filter}
        else
            action = MessageActions.SHOW
            AppDispatcher.dispatch
                type: ActionTypes.ROUTE_CHANGE
                value: {conversationID, messageID, mailboxID, action, filter}


    gotoPreviousConversation: ->
        AppDispatcher.dispatch
            type: ActionTypes.GO_TO_PREVIOUS
            value: null

    gotoNextConversation: ->
        AppDispatcher.dispatch
            type: ActionTypes.GO_TO_NEXT
            value: null


    closeConversation: (params={}) ->
        {mailboxID} = params
        mailboxID ?= RouterGetter.getMailboxID()
        action = MessageActions.SHOW_ALL
        filter = RouterGetter.getFilter()
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, action, filter}


    closeModal: (mailboxID = RouterGetter.getMailboxID()) ->
        return unless mailboxID

        account = AccountGetter.getByMailbox mailboxID

        # Load last messages
        @refreshMailbox {mailboxID}

        # Dispatch modal close
        AppDispatcher.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value:
                action:    MessageActions.SHOW_ALL
                accountID: account.get('id')
                mailboxID: mailboxID


    showMessageList: (params={}) ->
        @closeConversation params


    getConversation: (conversationID) ->
        conversationID ?= RouterGetter.getConversationID()
        timestamp = (new Date()).toISOString()

        AppDispatcher.dispatch
            type: ActionTypes.CONVERSATION_FETCH_REQUEST
            value: {conversationID, timestamp}

        XHRUtils.fetchConversation {conversationID}, (error, messages) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.CONVERSATION_FETCH_FAILURE
                    value: {error, conversationID, timestamp}
            else
                # Apply filters to messages
                # to upgrade conversationLength
                # FIXME: should be moved server side
                filterFunction = RouterGetter.getFilterFunction
                messages = _.filter messages, filterFunction

                # Update Realtime
                lastMessage = _.last messages
                mailboxID = lastMessage?.mailboxID
                before = lastMessage?.date or timestamp
                Realtime.setServerScope {mailboxID, before}

                # Update _conversationLength value
                # that is only displayed by the server
                # with method fetchMessagesByFolder
                # FIXME: should be sent by server
                conversationLength = {}
                conversationLength[conversationID] = messages.length

                result = {messages, conversationLength}
                AppDispatcher.dispatch
                    type: ActionTypes.CONVERSATION_FETCH_SUCCESS
                    value: {result, conversationID, timestamp}

module.exports = RouterActionCreator
