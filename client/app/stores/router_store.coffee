_         = require 'lodash'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'

{AccountActions
ActionTypes
MessageActions
MessageFilter
MessageFlags
SearchActions} = require '../constants/app_constants'

{MSGBYPAGE} = require '../../../server/utils/constants'


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
        pageAfter: null


    _accountID = null
    _mailboxID = null
    _tab = null

    _refreshMailbox = false

    _conversationID = null
    _messageID = null
    _messagesLength = 0

    _timerRouteChange = null


    getRouter: ->
        return _router


    getAction: ->
        return _action


    getFilter: ->
        _currentFilter


    getModalParams: ->
        _modal


    isRefresh: ->
        _refreshMailbox


    getURL: (params={}) ->
        action = _getRouteAction params
        filter = _getURIQueryParams params

        isMessage = !!params.messageID or _.includes action, 'message'
        if isMessage and not params.mailboxID
            params.mailboxID = @getMailboxID()

        isMailbox = _.includes action, 'mailbox'
        if isMailbox and not params.mailboxID
            params.mailboxID = @getMailboxID()

        isAccount = _.includes action, 'account'
        if isAccount and not params.accountID
            params.accountID = @getAccountID()
        if isAccount and not params.tab
            params.tab = 'account'

        if (route = _getRoute action)
            isValid = true
            prefix = unless params.isServer then '#' else ''
            filter = '/' + filter if params.isServer
            url = route.replace /\:\w*/gi, (match) =>
                # Get Route pattern of action
                # Replace param name by its value
                param = match.substring 1, match.length
                params[param] or match
            return prefix + url.replace(/\(\?:query\)$/, filter)


    getCurrentURL: (options={}) ->
        params = _.extend {isServer: true}, options
        params.action ?= @getAction()
        params.mailboxID ?= @getMailboxID()
        params.messageID ?= @getMessageID()
        params.conversationID ?= @getConversationID()

        return @getURL params


    _getRouteAction = (params) ->
        unless (action = params.action)
            return MessageActions.SHOW if params.messageID
            return MessageActions.SHOW_ALL
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

                return key + '=' + encodeURIComponent(value)

        if query.length then "?#{query.join '&'}" else ""


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


    # Useless for MessageStore
    # to clean messages
    isResetFilter: (filter) ->
        filter = @getFilter() unless filter
        filter.type in ['from', 'dest']


    _setCurrentAccount = (accountID, mailboxID, tab="account") ->
        _accountID = accountID
        _mailboxID = mailboxID
        _tab = tab


    _getFlags = (message) ->
        flags = if message?
        then message?.get 'flags'
        else _currentFilter?.flags
        flags = [flags] if _.isString flags
        flags or []


    getAccount: (accountID) ->
        accountID ?= _accountID
        AccountStore.getByID accountID


    getAccountID: ->
        unless _accountID
            return AccountStore.getDefault()?.get 'id'
        else
            return _accountID


    getMailboxID: ->
        unless _mailboxID
            return AccountStore.getDefault()?.get 'inboxMailbox'
        else
            return _mailboxID


    getMailbox: (accountID, mailboxID) ->
        accountID ?= @getAccountID()
        mailboxID ?= @getMailboxID()
        AccountStore.getMailbox accountID, mailboxID


    getAllMailboxes: (accountID) ->
        accountID ?= @getAccountID()
        AccountStore.getAllMailboxes accountID


    getSelectedTab: ->
        _tab


    _setCurrentMessage = (conversationID, messageID) ->
        _conversationID = conversationID
        _messageID = messageID
        _messagesLength = 0


    getConversationID: (messageID) ->
        _conversationID


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
        if message?
            return MessageFlags.SEEN not in flags
        else
            return MessageFilter.UNSEEN in flags


    isFlagged: (message) ->
        flags = _getFlags message
        if message?
            MessageFlags.FLAGGED in flags
        else
            MessageFilter.FLAGGED in flags


    isAttached: (message) ->
        flags = _getFlags message
        if message?
            MessageFlags.ATTACH in flags
        else
            MessageFilter.ATTACH in flags


    isDeleted: (message) ->
        # Message is in trashbox
        trashID = @getAccount()?.get 'trashMailbox'
        mailboxIDs = _.keys message?.get 'mailboxIDs'
        if (trashID in mailboxIDs)
            return true

        # Message is not totally removed
        deletedLabel = 'Deleted Messages'.toLowerCase()
        label = @getMailbox()?.get('label')?.toLowerCase()
        label is deletedLabel


    isDraft: (message) ->
        draftID = @getAccount()?.get 'draftMailbox'
        mailboxIDs = _.keys message?.get 'mailboxIDs'
        draftID in mailboxIDs


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
        if (messageID = @getMessageID())
            unless (message = MessageStore.getByID(messageID))?.size
                return false
        (_messagesLength + 1) >= MSGBYPAGE


    getMessagesList: (mailboxID) ->
        mailboxID ?= @getMailboxID()

        # We dont filter for type from and dest because it is
        # complicated by collation and name vs address.
        _filterFlags = (message) =>
            if @isFlagged()
                return @isFlagged message
            if @isAttached()
                return @isAttached message
            if @isUnread()
                return @isUnread message
            return true

        uniq = {}
        {sort} = @getFilter()
        sortOrder = parseInt "#{sort.charAt(0)}1", 10
        messages = MessageStore.getAll()?.filter (message) =>
            # Display only last Message of conversation
            conversationID = message.get 'conversationID'
            unless (exist = uniq[conversationID])
                uniq[conversationID] = true

            # Should have the same flags
            hasSameFlag = _filterFlags message

            # Message should be in mailbox
            inMailbox = mailboxID of message.get 'mailboxIDs'

            return inMailbox and not exist and hasSameFlag
        .sort _sortByDate sortOrder
        .toOrderedMap()

        _messagesLength = messages.size

        return messages


    getConversation: (conversationID) ->
        conversationID ?= @getConversationID()
        MessageStore.getConversation conversationID


    getNextConversation: ->
        messages = @getMessagesList()
        keys = _.keys messages?.toObject()
        values = messages?.toArray()

        index = keys.indexOf @getMessageID()
        values[--index]


    getPreviousConversation: ->
        messages = @getMessagesList()
        keys = _.keys messages?.toObject()
        values = messages?.toArray()

        index = keys.indexOf @getMessageID()
        values[++index]


    getConversationLength: ({messageID, conversationID}) ->
        unless conversationID
            messageID ?= @getMessageID()
            if (message = MessageStore.getByID messageID)
                conversationID = message.get 'conversationID'

        MessageStore.getConversationLength conversationID


    gotoNextMessage: ->
        messages = MessageStore.getAll()
        keys = _.keys messages?.toObject()
        values = messages?.toArray()

        index = keys.indexOf @getMessageID()
        values[--index]


    gotoPreviousMessage: ->
        messages = MessageStore.getAll()
        keys = _.keys messages?.toObject()
        values = messages?.toArray()

        index = keys.indexOf @getMessageID()
        values[++index]


    getURI: ->
        _URI


    _updateURL = ->
        currentURL = _self.getCurrentURL isServer: false
        if location.hash isnt currentURL
            _router.navigate currentURL


    _setURI = ->
        # Special Case ie. OVH mails
        # sometime there are several INBOX with different id
        # but only one is references as real INBOX
        # Get reference INBOX_ID to keep _nextURL works
        # sith this onther INBOX
        if AccountStore.isInbox _accountID, _mailboxID
            mailboxID = AccountStore.getInbox(_accountID).get 'id'
        else
            mailboxID = _mailboxID

        # Get queryString of URI params
        query = _getURIQueryParams {filter: _currentFilter}

        _URI = "#{mailboxID}#{query}"


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ROUTE_CHANGE, (payload={}) ->
            clearTimeout _timerRouteChange

            {accountID, mailboxID, tab} = payload
            {action, conversationID, messageID, query} = payload

            # We cant display any informations
            # without accounts
            if AccountStore.getAll()?.size
                _action = action
            else
                _action = AccountActions.CREATE

            # From AccountStore
            accountID ?= AccountStore.getDefault(mailboxID)?.get 'id'
            _setCurrentAccount accountID, mailboxID, tab

            # From MessageStore
            # Update currentMessageID
            _setCurrentMessage conversationID, messageID

            # Handle all Selection
            # _resetSelection()

            # Save current filters
            _setFilter query

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
            @emit 'change'


        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, ->
            _action = AccountActions.CREATE
            _setCurrentAccount()
            @emit 'change'


        # handle ActionTypes.ADD_ACCOUNT_REQUEST, ({value}) ->
        #     _newAccountWaiting = true
        #     @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ({account}) ->
            _timerRouteChange = setTimeout =>
                # _newAccountWaiting = false
                _action            = MessageActions.SHOW_ALL

                _setCurrentAccount account.id, account.inboxMailbox
                _updateURL()

                @emit 'change'
            , 5000


        handle ActionTypes.MESSAGE_FETCH_REQUEST, ->
            _refreshMailbox = true
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, (payload) ->
            {lastPage} = payload

            # Save last message references
            _lastPage[_URI] = lastPage if lastPage?

            _refreshMailbox = false

            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_FAILURE, ->
            _refreshMailbox = false
            @emit 'change'


        handle ActionTypes.DISPLAY_MODAL, (params) ->
            _modal = params
            @emit 'change'

        handle ActionTypes.HIDE_MODAL, (value) ->
            _modal = null
            @emit 'change'


        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, updated, ref}) ->
            # Update messageID
            message = @getNextConversation()
            conversationID = message?.get 'conversationID'
            messageID = message?.get 'id'
            _setCurrentMessage conversationID, messageID

            # Update URL if it didnt
            _updateURL()
            @emit 'change'


        handle ActionTypes.REFRESH_REQUEST, ->
            _refreshMailbox = true
            @emit 'change'


        handle ActionTypes.REFRESH_SUCCESS, ->
            _refreshMailbox = false
            @emit 'change'


        handle ActionTypes.REFRESH_FAILURE, ->
            _refreshMailbox = false
            @emit 'change'


        handle ActionTypes.SETTINGS_UPDATE_RESQUEST, ->
            @emit 'change'



_toCamelCase = (value) ->
    return value.replace /\.(\w)*/gi, (match) ->
        part1 = match.substring 1, 2
        part2 = match.substring 2, match.length
        return part1.toUpperCase() + part2


module.exports = (_self = new RouterStore())
