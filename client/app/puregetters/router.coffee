Routes       = require '../routes'
{MessageFilter} = require '../constants/app_constants'
Immutable = require 'immutable'

Routes = require '../routes'
{MessageActions, AccountActions} = require '../constants/app_constants'
MessageGetter = require './messages'
AccountGetter = require './account'
MessageFetchGetter = require './messagefetch'
MessageGetter = require './messages'
RequestsGetter = require './requests'

Message = require '../models/message'

module.exports =

    getRouteObject:    (state) -> state.get('route')
    getDefaultAccount: (state) ->
        AccountGetter.getAllAccounts(state).first()
    getAction:         (state) -> @getRouteObject(state).get('action')
    getAccountID:      (state) -> @getRouteObject(state).get('accountID')
    getMailboxID:      (state) -> @getRouteObject(state).get('mailboxID')
    getMessageID:      (state) -> @getRouteObject(state).get('messageID')
    getConversationID: (state) -> @getRouteObject(state).get('conversationID')
    getSelectedTab:    (state) -> @getRouteObject(state).get('tab')
    getFilter:         (state) -> @getRouteObject(state).get('messagesFilter')
    getModal:          (state) -> state.get('modal')

    getAccounts: (state) -> AccountGetter.getAllAccounts(state)
    getAllAccounts: (state) -> AccountGetter.getAllAccounts(state)

    getAccount:        (state) ->
        accountID = @getAccountID(state)
        AccountGetter.getAccount(state, accountID) or @getDefaultAccount(state)

    getMailbox:        (state, mailboxID) ->
        mailboxID ?= @getMailboxID(state)
        return AccountGetter.getMailbox(state, mailboxID)

    getAllMailboxes: (state, accountID) ->
        accountID ?= @getAccountID(state)
        AccountGetter.getAllMailboxes(state, accountID)

    getMessagesPerPage: (state) ->
        if @getAction(state) in [MessageActions.SHOW, MessageActions.SHOW_ALL]
            MessageFetchGetter.getMessagesPerPage(state)

    getAccountByMailbox: (state, mailboxID) ->
        AccountGetter.getAccountByMailbox(state, mailboxID)

    getFlags: (state) ->
        [].concat @getFilter(state).get('flags') or []

    isUnread: (state) ->
        MessageFilter.UNSEEN in @getFlags(state)  or
        @getMailboxID(state) is @getAccount(state)?.get('unreadMailbox')

    isFlagged: (state) ->
        MessageFilter.FLAGGED in @getFlags(state) or
        @getMailboxID(state) is @getAccount(state)?.get('flaggedMailbox')

    isAttached: (state) ->
        MessageFilter.ATTACH in @getFlags(state)

    isDeleted: (state) ->
        @getMailboxID(state) is @getAccount(state)?.get('trashMailbox')

    isDraft: (state) ->
        @getMailboxID(state) is @getAccount(state)?.get 'draftMailbox'

    isDeletedMessage: (state, message) ->
        message.inMailbox(@getAccount(state)?.get('trashMailbox'))

    getMailboxTotal: (state) ->
        prop = if @isUnread(state) then 'nbUnread'
        else if @isFlagged(state) then 'nbFlagged'
        else 'nbTotal'
        return @getMailbox(state)?.get(prop) or 0


    getURI: (state) ->
        @getRouteObject(state).get('URIKey')

    getCurrentURL: (state) ->
        @getURL(state, @getRouteObject(state).toJS())

    getURL: (state, params) ->
        unless params.action
            throw new Error('getURL called without action')

        action = params.action

        if action is MessageActions.CREATE and not params.mailboxID
            params.mailboxID = @getAccount(state).get('draftMailbox')

        if action and not params.tab
            params.tab = 'account'

        forServer = params.isServer
        delete params.isServer

        return Routes.makeURL(action, params, forServer)

    getMessagesList: (state) ->
        mailboxID = @getMailboxID(state)

        sort = @getFilter(state).get('sort')
        sortOrder = parseInt "#{sort.charAt(0)}1", 10

        filterFunction = @getFilterFunction(state)

        existingConversations = Immutable.Set()
        messages = MessageGetter.getAll(state)
        messages = messages.filter (message) ->

            # Display only last Message of conversation
            path = message.get('mailboxID') + '/' +
                    message.get('conversationID')
            convExists = existingConversations.has path
            existingConversations = existingConversations.add path

            # Should have the same flags
            hasGoodFlag = filterFunction(message)

            # Message should be in mailbox
            inMailbox = mailboxID of message.get 'mailboxIDs'

            return inMailbox and not convExists and hasGoodFlag

        .toOrderedMap()
        .sortBy (message) -> message.get('date')
        messages = messages.reverse() if sortOrder is -1

        return messages

    getMessagesListWithIsDeleted: (state) ->
        @getMessagesList(state).map (message) =>
            message.set 'isDeleted', @isDeletedMessage(state, message)

    # getNextMessage: ->
    # getPreviousMessage: ->

    getNextConversation: (state) ->
        messages = @getMessagesList(state)
        ids = messages.keySeq().toArray()
        index = ids.indexOf @getRouteObject(state).get('messageID')
        return messages.get(ids[index - 1])

    getPreviousConversation: (state) ->
        messages = @getMessagesList(state)
        ids = messages.keySeq().toArray()
        index = ids.indexOf @getRouteObject(state).get('messageID')
        return messages.get(ids[index  + 1])

    # Get next message from conversation:
    # - from the same mailbox
    # - with the same filters
    # - otherwise get previous message
    # If conversation is empty:
    # - go to next conversation
    # - otherwise go to previous conversation
    getNearestMessage: (state) ->
        message = @getNextConversation state
        message ?= @getPreviousConversation state
        return message

    getFilterFunction: (state) ->
        return (message) =>
            unless message instanceof Message
                throw new Error('message should be a Message')
            if @isFlagged(state) then return message.isFlagged()
            if @isAttached(state) then return message.isAttached()
            if @isUnread(state) then return message.isUnread()
            return true

    getConversation: (state, conversationID, mailboxID) ->
        mailboxID ?= @getMailboxID(state)
        conversationID ?= @getConversationID(state)

        unless conversationID
            return []

        # Filter messages
        return MessageGetter.getConversation state, conversationID, mailboxID
                            .filter @getFilterFunction(state)

    # do we have enough messages of the current request to fill a screen
    isPageComplete: (state)->
        messagesPerPage = @getMessagesPerPage(state)
        messagesLength = @getMessagesList(state).size
        return messagesLength > messagesPerPage

    # is there more messages on the server for the current request
    hasNextPage: (state) ->
        URIKey = @getURI(state)
        not MessageFetchGetter.getRequestStatus(state, URIKey).get('isComplete')

    # are we currently loading more messages for the current request
    isLoading: (state) ->
        URIKey = @getURI(state)
        status = MessageFetchGetter.getRequestStatus(state, URIKey)
        return status.get('isLoading') or false

    # fetch messages after the ones we already have
    getFetchURL: (state) ->
        URIKey = @getURI(state)
        return null unless @hasNextPage(state)
        filter = @getFilter(state)

        status = MessageFetchGetter.getRequestStatus(state, URIKey)
        pageAfter = status.get('lastFetchOldest')

        if pageAfter
            filter = filter.set('pageAfter', pageAfter)

        # console.log('THERE', pageAfter, filter)

        return Routes.makeURL MessageActions.SHOW_ALL,
            mailboxID: @getMailboxID(state)
            filter: filter.toSimpleJS()
        , true

    getMessage: (state) ->
        MessageGetter.getByID(state, @getMessageID(state))

    getSubject: (state) ->
        @getMessage(state)?.get 'subject'

    getLastSync: (state) ->
        accountID = @getAccountID(state)
        mailboxID = @getMailboxID(state)

        return null unless accountID and mailboxID

        # If current mailboxID is inbox
        # test Inbox instead of 1rst mailbox
        if (AccountGetter.isInbox state, accountID, mailboxID)
            # Gmail issue
            # Test \All tag insteadof \INBOX
            mailbox = AccountGetter.getAllMailbox state, accountID
            mailbox ?= AccountGetter.getInbox state, accountID

        mailbox ?= @getMailbox(state)
        mailbox?.get('lastSync')

    getTrashBoxID: (state) ->
        @getAccount(state)?.get('trashMailbox')

    isTrashbox: (state, mailboxID) ->
        accountID = @getAccountID(state)
        mailboxID ?= @getMailboxID(state)
        AccountGetter.isTrashbox state, accountID, mailboxID

    isMailboxIndexing: (state) ->
        accountID = @getAccountID state
        RequestsGetter.isIndexing state, accountID

    getEmptyMessage: (state) ->
        if @isUnread(state)        then t 'no unseen message'
        else if @isFlagged(state)  then t 'no flagged message'
        else if @isAttached(state) then t 'no filter message'
        else  t 'list empty'

    getComposeURL: (state) ->
        @getURL state, {action: MessageActions.CREATE}

    getCreateAccountURL: (state) ->
        @getURL state, {action: AccountActions.CREATE}

    getUnreadLength: (state, accountID) ->
        accountID ?= @getAccountID(state)
        AccountGetter.getInbox(state, accountID)?.get 'nbUnread'

    getFlaggedLength: (state, accountID) ->
        accountID ?= @getAccountID(state)
        AccountGetter.getInbox(state, accountID)?.get 'nbFlagged'

    getToasts: (state) ->
        state.get('notifications')

    hasSettingsChanged: (state) ->
        messageID = @getMessageID(state)
        MessageGetter.isImagesDisplayed state, messageID

    getConversationLength: (state, conversationID) ->
        conversationID ?= @getConversationID(state)
        MessageGetter.getConversationLength(state, conversationID) or 0

    getLogin: (state) ->
        @getAccount(state)?.get('login')

    # not used
    getReplyMessage: (state, messageID) ->
        isReply = @getAction(state) is MessageActions.EDIT
        MessageGetter.getByID state, messageID unless isReply
