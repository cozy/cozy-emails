_ = require 'lodash'

AccountGetter  = require '../puregetters/account'
RouterGetter   = require '../puregetters/router'

reduxStore = require '../reducers/_store'

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
                if RouterGetter.hasNextPage() and
                not RouterGetter.isPageComplete()
                    @getCurrentPage dispatch

    gotoCompose: (dispatch, params={}) ->
        {messageID, mailboxID} = params

        action = MessageActions.NEW
        mailboxID ?= RouterGetter.getMailboxID messageID

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
        messages = RouterGetter.getConversation conversationID
        message = messages.find((message) -> message.isUnread()) or
        messages.first()
        messageID = message?.get 'id'
        @gotoMessage dispatch, {conversationID, messageID}


    gotoMessage: (dispatch, message={}) ->
        {conversationID, messageID, mailboxID, filter} = message

        messageID ?= RouterGetter.getMessageID()
        mailboxID ?= RouterGetter.getMailboxID messageID
        filter = filter or RouterGetter.getFilter()

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
        mailboxID ?= RouterGetter.getMailboxID()
        action = MessageActions.SHOW_ALL
        filter = RouterGetter.getFilter()
        dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: {mailboxID, action, filter}


    closeModal: (dispatch, mailboxID = RouterGetter.getMailboxID()) ->
        return unless mailboxID

        account = AccountGetter.getByMailbox reduxStore.getState(), mailboxID

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
        conversationID ?= RouterGetter.getConversationID()
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
                dispatch
                    type: ActionTypes.CONVERSATION_FETCH_SUCCESS
                    value: {result, conversationID, timestamp}

    markMessage:  ->
        throw new Error('NOT IMPLEMENTED YET')

module.exports = RouterActionCreator
