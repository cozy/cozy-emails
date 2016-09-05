_ = require 'lodash'

AccountGetter  = require '../getters/account'
RouterGetter   = require '../getters/router'

reduxStore = require '../redux_store'

Realtime = require '../libs/realtime'

XHRUtils = require '../libs/xhr'

{ActionTypes, MessageActions} = require '../constants/app_constants'

RouterActionCreator =
    # Refresh Emails from Server
    # This is a read data pattern
    # ActionCreator is a write data pattern
    refreshMailbox: (dispatch, {mailboxID}) ->
        throw new Error('expected mailboxID') unless mailboxID

        dispatch
            type: ActionTypes.REFRESH_REQUEST
            value: {mailboxID, deep: true, silent: true}

        options = deep: true, silent: true
        XHRUtils.refreshMailbox mailboxID, options, (error, updated) ->
            if error?
                dispatch
                    type: ActionTypes.REFRESH_FAILURE
                    value: {mailboxID, error}
            else
                dispatch
                    type: ActionTypes.REFRESH_SUCCESS
                    value: {mailboxID, updated}

    # called by message-list when the user click on the button at bottom
    loadMore: (dispatch) ->
        state = reduxStore.getState()
        url = RouterGetter.getFetchURL(state)
        hasNextPage = RouterGetter.hasNextPage(state)
        isLoading = RouterGetter.isLoading(state)

        if url and hasNextPage and not isLoading
            @doFetchMessages dispatch, url


    # called by the router when the page is shown and above
    getCurrentPage: (dispatch) ->
        state = reduxStore.getState()
        url = RouterGetter.getFetchURL(state)

        if url and
        RouterGetter.hasNextPage(state) and
        not RouterGetter.isPageComplete(state) and
        not RouterGetter.isLoading(state)
            @doFetchMessages dispatch, url

    doFetchMessages: (dispatch, url) ->

        # Always load messagesList
        timestamp = (new Date()).valueOf()

        dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {url, timestamp}

        XHRUtils.fetchMessagesByFolder url, (error, result={}) =>
            if error?
                dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, url, timestamp}
            else
                # Update Realtime
                lastMessage = _.last result?.messages
                mailboxID = lastMessage?.mailboxID
                before = lastMessage?.date or timestamp
                Realtime.setServerScope {mailboxID, before}

                dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {result, url, timestamp}

                # Fetch missing messages
                # otherwhise if message doesnt exist anymore
                # ie. removed from outside (socketEvent)
                # ie. navigate with history
                # - try to select nearestMessage
                # - if not select current MessageList
                # - if no messageList go to default mailbox
                state = reduxStore.getState()
                if RouterGetter.hasNextPage(state) and
                not RouterGetter.isPageComplete(state)
                    @getCurrentPage dispatch

    gotoCompose: (dispatch, params={}) ->
        {messageID, mailboxID} = params

        action = MessageActions.NEW
        state = reduxStore.getState()
        mailboxID ?= RouterGetter.getMailboxID state, messageID

        dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, messageID, action}


    # Get last message unread
    # or get last message if not
    gotoConversation: (dispatch, params={}) ->
        {conversationID} = params

        # 1rst: load all messages from conversation
        @getConversation dispatch, conversationID

        # 2nd: redirect to conversation
        # At first get unread Message
        # if not get last message
        state = reduxStore.getState()
        messages = RouterGetter.getConversation state, conversationID
        message = messages.find((message) -> message.isUnread()) or
        messages.first()
        messageID = message?.get 'id'
        @gotoMessage dispatch, {conversationID, messageID}


    gotoMessage: (dispatch, message={}) ->
        {conversationID, messageID, mailboxID, filter} = message

        state = reduxStore.getState()
        messageID ?= RouterGetter.getMessageID(state)
        mailboxID ?= RouterGetter.getMailboxID state, messageID
        filter = filter or RouterGetter.getFilter(state)

        unless messageID
            action = MessageActions.SHOW_ALL
            dispatch
                type: ActionTypes.ROUTE_CHANGE
                value: {mailboxID, action, filter}
        else
            action = MessageActions.SHOW
            dispatch
                type: ActionTypes.ROUTE_CHANGE
                value: {conversationID, messageID, mailboxID, action, filter}


    gotoPreviousConversation: (dispatch) ->
        dispatch
            type: ActionTypes.GO_TO_PREVIOUS
            value: null

    gotoNextConversation: (dispatch) ->
        dispatch
            type: ActionTypes.GO_TO_NEXT
            value: null


    closeConversation: (dispatch, params={}) ->
        {mailboxID} = params
        state = reduxStore.getState(state)
        mailboxID ?= RouterGetter.getMailboxID(state)
        action = MessageActions.SHOW_ALL
        filter = RouterGetter.getFilter(state)
        dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, action, filter}


    closeModal: (dispatch, mailboxID) ->

        state = reduxStore.getState(state)
        mailboxID ?= RouterGetter.getMailboxID(state)
        return unless mailboxID

        state = reduxStore.getState()
        account = AccountGetter.getByMailbox state, mailboxID

        # Load last messages
        @refreshMailbox dispatch, {mailboxID}

        # Dispatch modal close
        dispatch
            type: ActionTypes.ROUTE_CHANGE
            value:
                action:    MessageActions.SHOW_ALL
                accountID: account.get('id')
                mailboxID: mailboxID


    showMessageList: (dispatch, params={}) ->
        @closeConversation dispatch, params


    getConversation: (dispatch, conversationID) ->
        state = reduxStore.getState()
        conversationID ?= RouterGetter.getConversationID(state)
        timestamp = (new Date()).toISOString()

        dispatch
            type: ActionTypes.CONVERSATION_FETCH_REQUEST
            value: {conversationID, timestamp}

        XHRUtils.fetchConversation {conversationID}, (error, messages) ->
            if error?
                dispatch
                    type: ActionTypes.CONVERSATION_FETCH_FAILURE
                    value: {error, conversationID, timestamp}
            else
                # Update Realtime
                lastMessage = _.last messages
                mailboxID = lastMessage?.mailboxID
                before = lastMessage?.date or timestamp
                Realtime.setServerScope {mailboxID, before}

                result = {messages}
                dispatch
                    type: ActionTypes.CONVERSATION_FETCH_SUCCESS
                    value: {result, conversationID, timestamp}

    markMessage:  ->
        throw new Error('NOT IMPLEMENTED YET')

module.exports = RouterActionCreator
