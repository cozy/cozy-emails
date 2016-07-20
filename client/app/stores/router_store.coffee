_             = require 'lodash'
Immutable     = require 'immutable'
Store         = require '../libs/flux/store/store'
AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

AccountStore  = require '../stores/account_store'
MessageStore  = require '../stores/message_store'
RequestsStore = require '../stores/requests_store'

{AccountActions
ActionTypes
MessageActions
MessageFilter
MessageFlags
SearchActions} = require '../constants/app_constants'

{MSGBYPAGE} = require '../../../server/utils/constants'
TAB = 'account'


class RouterStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _router = null
    _action = null
    _URI = null
    _lastPage = {}

    _modal = null

    _currentFilter = _defaultFilter =
        sort: '-date'
        flags: null
        value: null
        before: null
        after: null

    _accountID = null
    _mailboxID = null
    _tab = null

    _conversationID = null
    _messageID = null
    _messagesLength = 0
    _nearestMessage = null

    _timerRouteChange = null


    getRouter: ->
        _router


    getAction: ->
        _action


    getFilter: ->
        _currentFilter


    getModalParams: ->
        _modal


    getURL: (options={}) ->
        params = _.cloneDeep options
        action = _getRouteAction params

        isMessage = !!params.messageID or _.includes action, 'message'
        isMailbox = _.includes action, 'mailbox'
        if (isMessage or isMailbox) and not params.mailboxID
            unless (params.mailboxID = @getMailboxID())
                account = @getDefaultAccount()
                params.accountID = account?.get 'id'
                params.mailboxID = account?.get 'inboxMailbox'

        isAccount = _.includes action, 'account'
        if isAccount and not params.accountID
            unless (params.accountID = @getAccountID())
                params.accountID = @getDefaultAccount()?.get 'id'

        if isAccount and not params.tab
            params.tab = 'account'

        return unless (route = _getRoute action)

        prefix = unless params.isServer then '#' else ''
        query = _getURIQueryParams params
        query = '/' + query if params.isServer

        prefix + route.replace(/\(\?:filter\)$/, query)
                .replace /\:\w*/gi, (match) =>
                    # Get Route pattern of action
                    # Replace param name by its value
                    param = match.substring 1, match.length
                    params[param] or match



    getCurrentURL: (options={}) ->
        return unless (action = @getAction() or options.action)

        params = _.cloneDeep options
        params.isServer ?= true
        params.action ?= @getAction()
        params.mailboxID ?= @getMailboxID()
        params.messageID ?= @getMessageID()
        params.conversationID ?= @getConversationID()
        return @getURL params


    _getRouteAction = (params) ->
        unless (action = params.action)
            if params.messageID
                action = MessageActions.SHOW
            else if AccountStore.getAll()?.size
                action = MessageActions.SHOW_ALL
            else
                action = AccountActions.CREATE
        action

    _getRoute = (action) ->
        if (routes = _router?.routes)
            name = _toCamelCase action
            index = _.values(routes).indexOf(name)
            _.keys(routes)[index]


    _getURIQueryParams = (params={}) ->
        _filter = _.clone _defaultFilter
        {filter, resetFilter, isServer} = params
        _.extend _filter, _currentFilter, filter unless resetFilter

        query = _.compact _.map _filter, (value, key) ->
            if value? and _defaultFilter[key] isnt value
                # Server Side request:
                # Flags query doesnt exist
                key = 'flag' if isServer and key is 'flags'
                value = value.join '&' if _.isArray value
                return key + '=' + value

        if query.length then '?' + encodeURI query.join '&' else ''


    _setFilter = (query=_defaultFilter) ->
        # Update Filter
        _currentFilter = _.clone _defaultFilter
        _.extend _currentFilter, query
        return _currentFilter


    _sortByDate = (order) ->
        criteria = 'date'
        order = if order is '+' then -1 else 1
        return sortFunction = (message1, message2) ->
            val1 = message1.get criteria
            val2 = message2.get criteria
            if val1 > val2 then return -1 * order
            else if val1 < val2 then return 1 * order
            else return 0


    _isSearchAction = ->
        _action is SearchActions.SHOW_ALL


    _setCurrentAccount = ({accountID=null, mailboxID=null, tab=TAB}) ->
        _accountID = accountID
        _mailboxID = mailboxID
        _tab = if _action is AccountActions.EDIT then tab else null


    _getFlags = (message) ->
        flags = if message?
        then message?.get 'flags'
        else _currentFilter?.flags
        flags = [flags] if _.isString flags
        flags or []


    getAccount: (accountID) ->
        accountID ?= _accountID
        AccountStore.getByID accountID


    getAccountID: (mailboxID) ->
        if mailboxID
            return AccountStore.getByMailbox('mailboxID')?.get 'id'
        else
            return _accountID


    getDefaultAccount: () ->
        AccountStore.getAll().first()


    getMailboxID: (messageID) ->
        if messageID
            # Get mailboxID from message first
            mailboxIDs = MessageStore.getByID(messageID)?.get 'mailboxIDs'
            if _mailboxID in _.keys(mailboxIDs)
                return _mailboxID

        return _mailboxID


    getMailbox: (accountID, mailboxID) ->
        accountID ?= @getAccountID()
        mailboxID ?= @getMailboxID()
        AccountStore.getMailbox accountID, mailboxID


    getAllMailboxes: (accountID) ->
        accountID ?= @getAccountID()
        AccountStore.getAllMailboxes accountID



    getDefaultTab: ->
        TAB


    getSelectedTab: ->
        _tab


    _setCurrentMessage = ({conversationID, messageID}) ->
        # Return to message list
        # if no messages are found
        if not messageID or not conversationID
            conversationID = null
            messageID = null

        _conversationID = conversationID
        _messageID = messageID
        _messagesLength = 0


    _setCurrentAction = (payload={}) ->
        {action, accountID, mailboxID, messageID, conversationID} = payload
        if AccountStore.getAll()?.size
            if mailboxID
                if messageID and conversationID
                    action = MessageActions.SHOW
                else if accountID and action isnt AccountActions.EDIT
                    action = MessageActions.SHOW_ALL
        _action = action or AccountActions.CREATE


    getConversationID: (messageID) ->
        _conversationID

    # Get default message of a conversation
    # if conversationID is in argument
    # otherwhise, return global messageID (from URL)
    getMessageID: (conversationID) ->
        if conversationID?
            messages = @getConversation conversationID

            # At first get unread Message
            # if not get last message
            message = messages.find @isUnread
            message ?= messages.shift()
            message?.get 'id'
        else
            _messageID


    isUnread: (message) ->
        flags = _getFlags message
        # test flags but also mailboxID
        unless (result = MessageStore.isUnread {flags, message})
            result = @getMailboxID() is @getAccount()?.get('unreadMailbox')
        result


    isFlagged: (message) ->
        flags = _getFlags message
        # test flags but also mailboxID
        unless (result = MessageStore.isFlagged {flags, message})
            result = @getMailboxID() is @getAccount()?.get('flaggedMailbox')
        result


    isAttached: (message) ->
        flags = _getFlags message
        MessageStore.isAttached {flags, message}


    isDeleted: (message) ->

        # Message is in trashbox
        if message?
            account = AccountStore.getByID message.get('accountID')
            trashboxID = account?.get 'trashMailbox'
            return message.get('mailboxIDs')[trashboxID]?

        # Mailbox selected is trashbox
        trashboxID = @getAccount()?.get 'trashMailbox'
        trashboxID? and trashboxID is @getMailboxID()


    isDraft: (message) ->
        if message?
            flags = _getFlags message
            MessageStore.isDraft {flags, message}
        else
            draftID = @getAccount()?.get 'draftMailbox'
            draftID? and draftID is @getMailboxID()


    getMailboxTotal: ->
        if @isUnread()
            props = 'nbUnread'
        else if @isFlagged()
            props = 'nbFlagged'
        else
            props = 'nbTotal'
        @getMailbox()?.get(props) or 0


    hasNextPage: ->
        not @getLastPage()?.isComplete


    getLastPage: ->
        _lastPage[_URI]


    isPageComplete: ->
        # Do not infinite fetch
        # when message doesnt exist anymore
        messageID = @getMessageID()
        if messageID and not MessageStore.getByID(messageID)?.size
            return @hasNextPage()
        (_messagesLength + 1) >= MSGBYPAGE


    filterByFlags: (message) =>
        if message and message not instanceof Immutable.Map
            message = Immutable.Map message
        if @isFlagged()
            return MessageStore.isFlagged message
        if @isAttached()
            return MessageStore.isAttached message
        if @isUnread()
            return MessageStore.isUnread message
        return true


    getMessagesList: (accountID, mailboxID) ->
        accountID ?= @getAccountID()
        mailboxID ?= @getMailboxID()

        inbox = AccountStore.getInbox accountID
        inboxID = (inbox = AccountStore.getInbox accountID)?.get 'id'
        inboxTotal = inbox?.get 'nbTotal'
        isInbox = AccountStore.isInbox accountID, mailboxID

        {sort} = @getFilter()
        sortOrder = parseInt "#{sort.charAt(0)}1", 10

        conversations = {}
        messages = MessageStore.getAll()?.filter (message) =>
            # do not have twice INBOX
            # see OVH twice Inbox issue
            # FIXME: should be executed server side
            # add inboxID for its children
            _.keys(message.get 'mailboxIDs').forEach (id) ->
                isInboxChild = AccountStore.isInbox accountID, id, true
                if not isInbox and isInboxChild
                    mailboxIDs = message.get 'mailboxIDs'
                    mailboxIDs[inboxID] = inboxTotal
                    message.set 'mailboxIDs', mailboxIDs
                    return true
            # Display only last Message of conversation
            path = [message.get('mailboxID'), message.get('conversationID')].join '/'
            conversations[path] = true unless (exist = conversations[path])

            # Should have the same flags
            hasSameFlag = @filterByFlags message

            # Message should be in mailbox
            inMailbox = mailboxID of message.get 'mailboxIDs'

            return inMailbox and not exist and hasSameFlag
        .sort _sortByDate sortOrder
        .toOrderedMap()

        _messagesLength = messages.size

        return messages


    # Get next message from conversation:
    # - from the same mailbox
    # - with the same filters
    # - otherwise get previous message
    # If conversation is empty:
    # - go to next conversation
    # - otherwise go to previous conversation
    getNearestMessage: (target={}, type='conversation') ->
        {messageID, conversationID, mailboxID, accountID} = target
        unless messageID
            messageID = _messageID
            conversationID = _conversationID
            mailboxID = _mailboxID
            accountID = _accountID

        if 'conversation' is type
            conversation = _self.getConversation conversationID, mailboxID
            messages = Immutable.OrderedMap conversation
            message = _self.getNextConversation conversation
            message ?= _self.getPreviousConversation conversation
            return message if message?.size

        message = _self.getNextConversation()
        message ?= _self.getPreviousConversation()
        message


    getConversation: (conversationID, mailboxID) ->
        conversationID ?= @getConversationID()
        unless conversationID
            return []

        # Filter messages
        mailboxID ?= @getMailboxID()
        messages = MessageStore.getConversation conversationID, mailboxID
        _.filter messages, @filterByFlags


    _getConversationIndex = (messages) ->
        keys = _.map messages, (message) -> message.get 'id'
        keys.indexOf _messageID


    getNextConversation: (messages) ->
        messages ?= @getMessagesList()?.toArray()
        index = _getConversationIndex messages
        messages[--index]


    getPreviousConversation: (messages) ->
        messages ?= @getMessagesList()?.toArray()
        index = _getConversationIndex messages
        messages[++index]


    getConversationLength: (conversationID) ->
        conversationID ?= @getConversationID()
        MessageStore.getConversationLength conversationID


    getURI: ->
        _URI


    getMessagesPerPage: ->
        MSGBYPAGE


    _updateURL = ->
        currentURL = _self.getCurrentURL isServer: false
        if location?.hash isnt currentURL
            _router.navigate currentURL


    _setURI = ->
        # Special Case ie. OVH mails
        # sometime there are several INBOX with different id
        # but only one is references as real INBOX
        # Get reference INBOX_ID to keep _nextURL works
        # with this 2nd INBOX
        if AccountStore.isInbox _accountID, _mailboxID
            mailboxID = AccountStore.getInbox(_accountID)?.get 'id'
        else
            mailboxID = _mailboxID

        params = {
            action: _action,
        };

        if _action in _.values(MessageActions)
            Object.assign params, {
                accountID: _accountID,
                mailboxID: _mailboxID,
            }

            unless MessageActions.SHOW_ALL is _action
                Object.assign params, {
                    conversationID: _conversationID,
                    messageID: _messageID,
                }

            # Query are only for Messages
            if (query = _getURIQueryParams { filter: _currentFilter })
                Object.assign params, { query }

        else if AccountActions.EDIT is _action
            Object.assign params, {
                accountID: _accountID,
            }

        # Do not add empty query
        params = _.flatten _.transform params, (result, value, key) =>
            return if 'query' is key and _.isEmpty(value)
            result.push key + '=' + value
        , []

        _URI = _.flatten(params).join '&'


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ROUTE_CHANGE, (payload={}) ->
            # Ensure all stores that listen ROUTE_CHANGE have vanished
            AppDispatcher.waitFor [RequestsStore.dispatchToken]

            # Make sure that MessageStore is up to date
            # before gettings data from it
            AppDispatcher.waitFor [MessageStore.dispatchToken]

            clearTimeout _timerRouteChange

            {accountID, mailboxID, conversationID, messageID} = payload
            {action, tab, filter} = payload

            # We cant display any informations
            # without accounts
            _setCurrentAction payload


            # get Account from mailbox
            accountID ?= AccountStore.getByMailbox(mailboxID)?.get 'id' if mailboxID

            # Get default account
            # and set accountID and mailboxID
            if not accountID and not mailboxID
                account = AccountStore.getDefault()
                accountID = account?.get 'id'
                mailboxID = account?.get 'inboxMailbox'

            mailboxID ?= AccountStore.getByID(accountID)?.get 'inboxMailbox'
            _setCurrentAccount {accountID, mailboxID, tab}

            # From MessageStore
            # Update currentMessageID
            _setCurrentMessage payload

            # Handle all Selection
            # _resetSelection()

            # Save current filters
            _setFilter filter

            # From searchStore
            if _isSearchAction()
                _resetSearch()

            # Update URL if it didnt
            _updateURL()

            # Save URI
            # used for paginate
            _setURI()

            @emit 'change'


        handle ActionTypes.ROUTES_INITIALIZE, (router) ->
            _router = router

            _action = null
            _URI = null
            _lastPage = {}

            _modal = null

            _currentFilter = _defaultFilter =
                sort: '-date'
                flags: null
                value: null
                before: null
                after: null

            _accountID = null
            _mailboxID = null
            _tab = null

            _conversationID = null
            _messageID = null
            _messagesLength = 0
            _nearestMessage = null

            clearTimeout _timerRouteChange if _timerRouteChange
            _timerRouteChange = null

            @emit 'change'


        # Do not redirect to default account
        # if silent is true
        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, ({silent})  ->
            account = @getDefaultAccount()
            accountID = account?.get 'id'
            mailboxID = account?.get 'inboxMailbox'
            _setCurrentAccount {accountID, mailboxID}

            unless silent
                action = AccountActions[if account then 'EDIT' else 'CREATE']
                _setCurrentAction {action}

            _updateURL()

            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, ({result, conversationID, lastPage}) ->
            # Save last message references
            _lastPage[_URI] = lastPage if lastPage?

            # If messageID doesnt belong to conversation
            # message must have been deleted
            # then get default message from this conversation
            if conversationID
                inner = _.find result.messages, (msg) -> msg.id is _messageID
                unless inner
                    messageID = @getMessageID conversationID
                    _setCurrentMessage {conversationID, messageID}
                    _updateURL()

            @emit 'change'


        handle ActionTypes.DISPLAY_MODAL, (params) ->
            _modal = params
            @emit 'change'


        handle ActionTypes.HIDE_MODAL, (value) ->
            _modal = null
            @emit 'change'


        handle ActionTypes.MESSAGE_FLAGS_SUCCESS, ->
            @emit 'change'


        # Get nearest message from message to be deleted
        # to make redirection if request is successful
        handle ActionTypes.MESSAGE_TRASH_REQUEST, ({target}) ->
            if target.messageID is _messageID
                _nearestMessage = @getNearestMessage target
            @emit 'change'


        # Select nearest message from deleted message
        # and remove message from mailbox and conversation lists
        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target}) ->
            if target.messageID is _messageID
                messageID = _nearestMessage?.get 'id'
                conversationID = _nearestMessage?.get 'conversationID'

                # Update currentMessage so that:
                # - all counters should be updated
                # - all messagesList should be updated too
                _setCurrentMessage {conversationID, messageID}
                _updateURL()

            @emit 'change'


        # Delete nearestMessage
        # because it's beacame useless
        handle ActionTypes.MESSAGE_TRASH_FAILURE, ({target}) ->
            if target.messageID is _messageID
                _nearestMessage = null
            @emit 'change'


        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (messageID, deleted) ->
            if messageID is _messageID
                _nearestMessage = @getNearestMessage deleted

                messageID = _nearestMessage?.get 'id'
                conversationID = _nearestMessage?.get 'conversationID'

                # Update currentMessage so that:
                # - all counters should be updated
                # - all messagesList should be updated too
                _setCurrentMessage {conversationID, messageID}
                _updateURL()

            @emit 'change'


        handle ActionTypes.SETTINGS_UPDATE_REQUEST, ->
            @emit 'change'



_toCamelCase = (value) ->
    return value.replace /\.(\w)*/gi, (match) ->
        part1 = match.substring 1, 2
        part2 = match.substring 2, match.length
        return part1.toUpperCase() + part2


module.exports = (_self = new RouterStore())
