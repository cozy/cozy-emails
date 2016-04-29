_         = require 'lodash'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'

{ActionTypes, MessageFilter, MessageFlags, MessageActions,
AccountActions, SearchActions} = require '../constants/app_constants'

{sortByDate} = require '../utils/misc'
{MSGBYPAGE} = require '../../../server/utils/constants'
{changeRealtimeScope} = require '../utils/realtime_utils'

class RouterStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _router = null
    _action = null
    _nextURL = null
    _lastDate = null

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
    _newAccountWaiting = false
    _newAccountChecking = false
    _serverAccountErrorByField = Immutable.Map()

    _messageID = null
    _messagesLength = 0
    _messagePage = 0


    getRouter: ->
        return _router


    getAction: ->
        return _action


    getQuery: ->
        filter = @getFilter()
        _getURIQueryParams {filter}


    getFilter: ->
        _currentFilter


    getModalParams: ->
        _modal


    getErrors: ->
        _serverAccountErrorByField


    getRawErrors: ->
        _serverAccountErrorByField.get 'unknown'


    getAlertErrorMessage: ->
        error = _serverAccountErrorByField.first()
        if error.name is 'AccountConfigError'
            return t "config error #{error.field}"
        else
            return error.message or error.name or error


    isWaiting: ->
        _newAccountWaiting


    isChecking: ->
        _newAccountChecking


    getURL: (params={}) ->
        action = _getRouteAction params
        filter = _getURIQueryParams params

        isMessage = !!params.messageID or _.contains action, 'message'
        if isMessage and not params.mailboxID
            params.mailboxID = @getMailboxID()

        isMailbox = _.contains action, 'mailbox'
        if isMailbox and not params.mailboxID
            params.mailboxID = @getMailboxID()

        isAccount = _.contains action, 'account'
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

    _getURLparams = (query) ->
        # Get data from URL
        if _.isString query
            params = query.match /([\w]+=[-+\w,:.]+)+/gi
            return unless params?.length
            result = {}

            _.each params, (param) ->
                param = param.split '='
                if -1 < (value = param[1]).indexOf ','
                    value = value.split ','
                else
                    result[param[0]] = value

            return result

        # Get data from Views
        switch query.type
            when 'from', 'dest'
                result = {}
                result.before = query.value
                result.after = "#{query.value}\uFFFF"

            when 'flag'
                # Keep previous filters
                flags = _currentFilter.flags or []
                flags = [flags] if _.isString flags

                # Toggle value
                if -1 < flags.indexOf query.value
                    _.pull flags, query.value
                else
                    flags.push query.value
                (result = {}).flags = flags
        return result

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



    _setFilter = (query) ->
        # Update Filter
        _currentFilter = _.clone _defaultFilter
        _.extend _currentFilter, query
        return _currentFilter


    _isSearchAction = ->
        _action is SearchActions.SHOW_ALL


    # Useless for MessageStore
    # to clean messages
    isResetFilter: (filter) ->
        filter = @getFilter() unless filter
        filter.type in ['from', 'dest']


    _setCurrentAccount = (accountID, mailboxID, tab="mailboxes") ->
        _accountID = accountID
        _mailboxID = mailboxID
        _tab = tab


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


    getMailbox: (mailboxID) ->
        mailboxID ?= @getMailboxID()
        @getAllMailboxes()?.get mailboxID


    getAllMailboxes: (accountID) ->
        accountID ?= @getAccountID()
        AccountStore.getAllMailboxes accountID


    getInbox: (accountID) ->
        @getAllMailboxes(accountID)?.find (mailbox) ->
            'inbox' is mailbox.get('label').toLowerCase()


    getTrashMailbox: (accountID) ->
        @getAllMailboxes(accountID)?.find (mailbox) ->
            'trash' is mailbox.get('label').toLowerCase()


    getSelectedTab: ->
        _tab


    _setCurrentMessage = (messageID) ->
        _messageID = messageID
        _messagesLength = 0
        _messagePage = 0


    getMessageID: ->
        _messageID


    isFlags: (name) ->
        flags = @getFilter()?.flags or []
        MessageFilter[name] is flags or MessageFilter[name] in flags


    getMailboxTotal: ->
        if (@isFlags 'UNSEEN')
            props = 'nbUnread'
        else if (@isFlags 'FLAGGED')
            props = 'nbFlagged'
        else
            props = 'nbTotal'
        @getMailbox()?.get(props) or 0


    hasNextPage: ->
        _messagePage < @getPagesLength()


    getPagesLength: (params={}) ->
        Math.ceil  @getMailboxTotal() / MSGBYPAGE


    isMissingMessages: ->
        if (messageID = @getMessageID())
            unless (message = MessageStore.getByID(messageID))?.size
                return true
        (_messagesLength + 1) < MSGBYPAGE and @hasNextPage()



    getMessagesList: (mailboxID) ->
        mailboxID ?= @getMailboxID()
        filter = @getFilter()

        # We dont filter for type from and dest because it is
        # complicated by collation and name vs address.
        _filterFlags = (message) =>
            if filter?.flags
                flags = message.get 'flags'
                if @isFlags 'FLAGGED'
                    return MessageFlags.FLAGGED in flags
                if @isFlags 'ATTACH'
                    return message.get('attachments')?.size > 0
                if @isFlags 'UNSEEN'
                    return MessageFlags.SEEN not in flags
            true

        uniq = {}
        sortOrder = parseInt "#{filter.sort.charAt(0)}1", 10
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
        .sort sortByDate sortOrder
        .toOrderedMap()

        _messagesLength = messages.size

        return messages


    getConversation: (messageID) ->
        messageID ?= @getMessageID()
        conversationID = MessageStore.getByID(messageID)?.get 'conversationID'
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


    _clearError = ->
        _serverAccountErrorByField = Immutable.Map()


    _addError = (field, err) ->
        _serverAccountErrorByField = _serverAccountErrorByField.set field, err


    _checkForNoMailbox = (rawAccount) ->
        unless rawAccount.mailboxes?.length > 0
            _setError
                name: 'AccountConfigError',
                field: 'nomailboxes'
                causeFields: ['nomailboxes']


    _setError = (error) ->
        if error.name is 'AccountConfigError'
            clientError =
                message: t "config error #{error.field}"
                originalError: error.originalError
                originalErrorStack: error.originalErrorStack
            errorsMap = {}
            errorsMap[field] = clientError for field in error.causeFields
            _serverAccountErrorByField = Immutable.Map errorsMap

        else
            _serverAccountErrorByField = Immutable.Map "unknown": error


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ROUTE_CHANGE, (payload={}) ->
            {accountID, mailboxID, messageID} = payload
            {action, query, tab} = payload

            # We cant display any informations
            # without accounts
            if AccountStore.getAll()?.size
                _action = action
            else
                _action = AccountActions.CREATE

            # From AccountStore
            accountID ?= AccountStore.getDefault(mailboxID)?.get('id')
            _setCurrentAccount accountID, mailboxID, tab

            # From MessageStore
            # Update currentMessageID
            _setCurrentMessage messageID

            # Handle all Sleection
            # _resetSelection()

            # Save current filters
            _setFilter query

            # From searchStore
            if _isSearchAction()
                _resetSearch()

            # Update URL if it didnt
            currentURL = @getCurrentURL isServer: false
            if location.hash isnt currentURL
                _router.navigate currentURL

            @emit 'change'

        handle ActionTypes.ROUTES_INITIALIZE, (router) ->
            _router = router
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, ->
            _action = AccountActions.CREATE
            _setCurrentAccount()
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_REQUEST, ({value}) ->
            _newAccountWaiting = true
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ({account, areMailboxesConfigured}) ->
            _newAccountWaiting = false
            _checkForNoMailbox account
            _action = if areMailboxesConfigured
            then MessageActions.SHOW_ALL
            else AccountActions.EDIT
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_FAILURE, ({error}) ->
            _newAccountWaiting = false
            _setError error
            @emit 'change'


        handle ActionTypes.CHECK_ACCOUNT_REQUEST, () ->
            _newAccountChecking = true
            @emit 'change'


        handle ActionTypes.CHECK_ACCOUNT_SUCCESS, () ->
            _newAccountChecking = false
            @emit 'change'


        handle ActionTypes.CHECK_ACCOUNT_FAILURE, ({error}) ->
            _newAccountChecking = false
            _setError error
            @emit 'change'


        handle ActionTypes.EDIT_ACCOUNT_REQUEST, ({value}) ->
            _newAccountWaiting = true
            @emit 'change'


        handle ActionTypes.EDIT_ACCOUNT_SUCCESS, ({rawAccount}) ->
            _newAccountWaiting = false
            _checkForNoMailbox rawAccount
            _clearError()
            @emit 'change'


        handle ActionTypes.EDIT_ACCOUNT_FAILURE, ({error}) ->
            _newAccountWaiting = false
            _setError error
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, (payload) ->
            {result, timestamp, page} = payload

            _messagePage = page

            # Update Realtime
            mailboxID = @getMailboxID()
            before = if result?.messages?.size
            then result?.messages?.last()?.get('date')
            else timestamp
            changeRealtimeScope {mailboxID, before}

            @emit 'change'


        handle ActionTypes.DISPLAY_MODAL, (params) ->
            _modal = params
            @emit 'change'

        handle ActionTypes.HIDE_MODAL, (value) ->
            _modal = null
            @emit 'change'


        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, updated, ref}) ->
            if (nextMessage = @getNextConversation())?.size
                _setCurrentMessage nextMessage?.get 'id'
            @emit 'change'


_toCamelCase = (value) ->
    return value.replace /\.(\w)*/gi, (match) ->
        part1 = match.substring 1, 2
        part2 = match.substring 2, match.length
        return part1.toUpperCase() + part2


module.exports = (_self = new RouterStore())
