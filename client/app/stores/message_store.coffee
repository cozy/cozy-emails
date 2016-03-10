_         = require 'underscore'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
ContactStore  = require './contact_store'
AppDispatcher = require '../app_dispatcher'

AccountStore = require './account_store'

SocketUtils = require '../utils/socketio_utils'

{ActionTypes, MessageFlags, MessageFilter, FlagsConstants} =
        require '../constants/app_constants'

{reverseDateSort, getSortFunction} = require '../utils/misc'

EPOCH = (new Date(0)).toISOString()

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _messages = Immutable.OrderedMap()

    _currentFilter = null

    _fetching     = 0

    _queryRef = 0
    _nextUrl = null
    _currentUrl = null
    _noMore = false

    _currentMessages = Immutable.OrderedMap()
    _conversationLengths = Immutable.Map()
    _conversationMemoize = null
    _conversationMemoizeID = null
    _currentID       = null
    _currentCID      = null

    _inFlightByRef = {}
    _inFlightByMessageID = {}
    _undoable = {}

    _difference = (obj0, obj1) ->
        result = {}
        _.filter obj0, (value, key) ->
            unless value is obj1[key]
                result[key] = value
        result

    _isFilter = (value) ->
        value and value isnt '-'

    _getURISort = (filter) ->
        filter = _getFilter() unless filter
        "#{filter.order}#{filter.field}"

    _getFilter = (getDefault) ->
        return if not _currentFilter or getDefault
            field: 'date'
            order: '+'
            type: '-'
            value: 'nofilter'
            before: '-'
            after: '-'
        return _currentFilter

    _setFilter = (params) ->
        _defaultValue = _getFilter()

        # Update Filter
        _currentFilter =
            field: if params.sort then params.sort.substr(1) else _defaultValue.field
            order: if params.sort then params.sort.substr(0, 1) else _defaultValue.order
            type: params.type or _defaultValue.type
            value: params.flag or _defaultValue.value
            before: params.before or _defaultValue.before
            after: params.after or _defaultValue.after

        # Update context
        _queryRef++
        _noMore = false
        _nextUrl = null

        return _currentFilter

    _resetFilter = ->
        value = _getFilter true
        _setFilter value

    _addInFlight = (request) ->
        _inFlightByRef[request.ref] = request
        request.messages.forEach (message) ->
            id = message.get('id')
            requests = (_inFlightByMessageID[id] ?= [])
            requests.push request
        _conversationMemoize = null

    _removeInFlight = (ref) ->
        request = _inFlightByRef[ref]
        delete _inFlightByRef[ref]
        request.messages.forEach (message) ->
            id = message.get('id')
            requests = _inFlightByMessageID[id]
            _inFlightByMessageID[id] = _.without requests, request

        _conversationMemoize = null

        return request

    _transformMessageWithRequest = (message, request) ->
        switch request.type
            when 'trash'
                {trashBoxID} = request
                if isDraft(message)
                    message = null
                else
                    newMailboxIds = {}
                    newMailboxIds[trashBoxID] = -1
                    message = message.set 'mailboxIDs', newMailboxIds

            when 'move'
                mailboxIDs = message.get('mailboxIDs')
                {from, to} = request
                newMailboxIds = {}
                newMailboxIds[key] = value for key, value of mailboxIDs
                delete newMailboxIds[from]
                newMailboxIds[to] ?= -1
                message = message.set 'mailboxIDs', newMailboxIds

            when 'flag'
                flags = message.get('flags')
                {flag, op} = request
                if op is 'batchAddFlag' and flag not in flags
                    message = message.set 'flags', flags.concat [flag]

                else if op is 'batchRemoveFlag' and flag in flags
                    message = message.set 'flags', _.without flags, flag

        return message

    # @TODO : memoize me
    _messagesWithInFlights = ->
        _messages
        .map (message) ->
            id = message.get 'id'
            for request in _inFlightByMessageID[id] or []
                message = _transformMessageWithRequest message, request
            return message
        .filter (msg) -> msg isnt null
        .toList()

    _getMixed = (target) ->
        if target.messageID
            return [_messages.get(target.messageID)]
        else if target.messageIDs
            return target.messageIDs.map (id) -> _messages.get id
        else if target.conversationID
            return _messages.filter (message) ->
                message.get('conversationID') is target.conversationID
            .toArray()
        else if target.conversationIDs
            return _messages.filter (message) ->
                message.get('conversationID') in target.conversationIDs
            .toArray()
        else throw new Error 'Wrong Usage : unrecognized target AS.getMixed'

    isDraft = (message, draftMailbox) ->
        mailboxIDs = message.get 'mailboxIDs'
        mailboxIDs[draftMailbox] or MessageFlags.DRAFT in message.get('flags')

    inMailbox = (mailboxID) -> (message) ->
        mailboxID of message.get 'mailboxIDs'

    notInMailbox = (mailboxID) -> (message) ->
        not (mailboxID of message.get 'mailboxIDs')

    isntAccount = (accountID) -> (message) ->
        accountID isnt message.get 'accountID'


    computeMailboxDiff = (oldmsg, newmsg) ->
        return {} unless oldmsg
        changed = false

        wasRead = MessageFlags.SEEN in oldmsg.get 'flags'
        isRead = MessageFlags.SEEN in newmsg.get 'flags'

        accountID = newmsg.get 'accountID'
        oldboxes = Object.keys oldmsg.get 'mailboxIDs'
        newboxes = Object.keys newmsg.get 'mailboxIDs'

        out = {}
        added = _.difference(newboxes, oldboxes)
        added.forEach (boxid) ->
            changed = true
            out[boxid] = nbTotal: +1, nbUnread: if isRead then 0 else +1

        removed = _.difference oldboxes, newboxes
        removed.forEach (boxid) ->
            changed = true
            out[boxid] = nbTotal: -1, nbUnread: if wasRead then -1 else 0

        stayed = _.intersection oldboxes, newboxes
        deltaUnread = if wasRead and not isRead then +1
        else if not wasRead and isRead then -1
        else 0

        if deltaUnread isnt 0
            changed = true

        out[accountID] = nbUnread: deltaUnread

        stayed.forEach (boxid) ->
            out[boxid] = nbTotal: 0, nbUnread: deltaUnread

        if changed
            return out
        else
            return false

    onReceiveRawMessage = (message) ->
        oldmsg = _messages.get message.id
        updated = oldmsg?.get 'updated'

        # only update message if new version is newer than
        # the one currently stored
        if not (message.updated? and updated? and updated > message.updated) and
           not message._deleted # deleted draft are empty, don't update them


            message.attachments   ?= []
            message.date          ?= new Date().toISOString()
            message.createdAt     ?= message.date
            message.flags         ?= []
            message.hasAttachments = message.attachments.length > 0
            message.attachments = message.attachments.map (file) ->
                Immutable.Map file
            message.attachments = Immutable.List message.attachments

            # message loaded from fixtures for test purpose have a docType
            # that may cause some troubles
            delete message.docType

            message.updated = Date.now()

            messageMap = Immutable.Map message

            messageMap.prettyPrint = ->
                return """
                    #{message.id} "#{message.from[0].name}" "#{message.subject}"
                """

            _messages = _messages.set message.id, messageMap


            # updat _currentCID when we have the message
            if message.id is _currentID
                _currentCID = message.conversationID


            if message.accountID?
                diff = computeMailboxDiff(oldmsg, messageMap)
                if diff
                    AccountStore._applyMailboxDiff message.accountID, diff

        _conversationMemoize = null

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MESSAGE, (message) ->
            onReceiveRawMessage message
            @emit 'change', message

        handle ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME, (message) ->
            onReceiveRawMessage message
            @emit 'change'

        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->
            for message in messages when message?
                onReceiveRawMessage message
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            _messages = _messages.filter(isntAccount(accountID)).toOrderedMap()
            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_REQUEST, ({target, ref}) ->
            messages = @getMixed target
            account = AccountStore.getByID messages[0]?.get('accountID')
            trashBoxID = account?.get? 'trashMailbox'
            _addInFlight {type: 'trash', trashBoxID, messages, ref}

            for message in messages
                # Update conversation length
                conversationID = message.get('conversationID')
                _conversationLengths = _conversationLengths
                                                 .update(conversationID,
                                                         (value) -> value - 1)

            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, updated, ref}) ->
            _undoable[ref] =_removeInFlight ref
            for message in updated
                if message._deleted
                    _messages = _messages.remove message.id
                else
                    onReceiveRawMessage message

            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_FAILURE, ({target, ref}) ->
            _removeInFlight ref
            messages = @getMixed target
            for message in messages
                # Update conversation length
                conversationID = message.get('conversationID')
                _conversationLengths = _conversationLengths
                                                 .update(conversationID,
                                                         (value) -> value + 1)
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAGS_REQUEST, ({target, op, flag, ref}) ->
            messages = @getMixed target
            _addInFlight {type: 'flag', op, flag, messages, ref}
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAGS_SUCCESS, ({target, updated, ref}) ->
            _removeInFlight ref
            onReceiveRawMessage message for message in updated
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAGS_FAILURE, ({target, ref}) ->
            _removeInFlight ref
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_REQUEST, ({target, from, to, ref}) ->
            messages = @getMixed target
            _addInFlight {type: 'move', from, to, messages, ref}
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({target, updated, ref}) ->
            _undoable[ref] =_removeInFlight ref
            onReceiveRawMessage message for message in updated
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_FAILURE, ({target, ref}) ->
            _removeInFlight ref
            @emit 'change'

        handle ActionTypes.MESSAGE_UNDO_TIMEOUT, ({ref}) ->
            delete _undoable[ref]

        handle ActionTypes.MESSAGE_FETCH_REQUEST, ({mailboxID}) ->
            # There may be more than one concurrent fetching request
            # so we use a counter instead of a boolean
            _fetching++
            @emit 'change'

        handle ActionTypes.MESSAGE_FETCH_FAILURE, ->
            _fetching--
            @emit 'change'

        handle ActionTypes.MESSAGE_FETCH_SUCCESS, ({fetchResult}) ->
            _fetching--
            if fetchResult.links?.next?
                _nextUrl = decodeURIComponent(fetchResult.links.next)
            else if fetchResult.links?
                _noMore = true

            if lengths = fetchResult.conversationLengths
                for message in fetchResult.messages
                    lengths[message.conversationID] ?= 0
                _conversationLengths = _conversationLengths.merge lengths

            for message in fetchResult.messages when message?
                onReceiveRawMessage message

            if fetchResult.messages.length is 0
                # either end of list or no messages, we stay open
                SocketUtils.changeRealtimeScope fetchResult.mailboxID, EPOCH

            else if lastdate = _messages.last()?.get('date')
                SocketUtils.changeRealtimeScope fetchResult.mailboxID, lastdate

            @emit 'change'

        handle ActionTypes.CONVERSATION_FETCH_SUCCESS, ({updated}) ->
            for message in updated
                onReceiveRawMessage message
            @emit 'change'

        handle ActionTypes.MESSAGE_SEND, (message) ->
            onReceiveRawMessage message
            @emit 'change'

        handle ActionTypes.QUERY_PARAMETER_CHANGED, (parameters) ->
            return if _.isEmpty (params = _difference parameters, _getFilter())

            filter = _setFilter params
            if filter.type in ['from', 'dest']
                # we cant properly filter messages by dest or from in the
                # client, instead we clear message cache and dont filter
                # on display
                _messages = _messages.clear()
                _conversationMemoize = null

            @emit 'change'


        handle ActionTypes.MESSAGE_CURRENT, (value) ->
            @setCurrentID value.messageID, value.conv
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, (value) ->
            @setCurrentID null
            _resetFilter()

        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (id) ->
            _messages = _messages.remove id
            _conversationMemoize = null
            @emit 'change'

        handle ActionTypes.MAILBOX_EXPUNGE, (mailboxID) ->
            _messages = _messages.filter(notInMailbox(mailboxID))
            _conversationMemoize = null
            @emit 'change'

        handle ActionTypes.SEARCH_SUCCESS, ({searchResults}) ->
            for message in searchResults.rows when message?
                onReceiveRawMessage message
            @emit 'change'


    ###
        Public API
    ###
    getByID: (messageID) ->
        _messages.get(messageID) or null

    dedupConversation = ->
        conversationIDs = []
        return filter = (message) ->
            unless (conversationID = message.get 'conversationID') in conversationIDs
                conversationIDs.push conversationID
                return true

    _matchFlag = (message) ->
        filter = _getFilter()
        switch filter.value
            when MessageFilter.FLAGGED
                MessageFlags.FLAGGED in message.get('flags')
            when MessageFilter.ATTACH
                message.get('attachments').size > 0
            when MessageFilter.UNSEEN
                MessageFlags.SEEN not in message.get('flags')
            else
                true


    _matchRangeDate = (message) ->
        filter = _getFilter()
        date = message.get filter.type
        moment(date).isBefore(filter.after) and moment(date).isAfter(filter.before)

    ###*
    * Get messages from mailbox, with optional pagination
    *
    * @param {String}  mailboxID
    * @param {Boolean} conversation
    *
    * @return {Array}
    ###
    getMessagesToDisplay: (mailboxID) ->
        return _currentMessages unless mailboxID

        # We dont filter for type from and dest because it is
        # complicated by collation and name vs address.
        # Instead we clear the message, see QUERY_PARAMETER_CHANGED handler.

        # Get Messages from Mailbox
        sequence = _messagesWithInFlights()
        sequence = sequence.filter inMailbox mailboxID

        # Apply List.Filters
        filter = _getFilter()
        if filter.type is 'flag'
            sequence = sequence.filter _matchFlag
        else if filter.type is 'date'
            sequence = sequence.filter _matchRangeDate
        sequence = sequence.sort getSortFunction filter.field, filter.order

        # Get uniq conversations
        sequence = sequence.filter dedupConversation()

        _currentMessages = sequence.toOrderedMap()
        return _currentMessages


    getCurrentID: ->
        return _currentID


    setCurrentID: (messageID, conv) ->
        if conv?
            # this will set current conversation and conversationID
            conversationID = @getByID(messageID)?.get 'conversationID'
        _currentID = messageID
        _currentCID = conversationID
        _conversationMemoize = null


    getCurrentConversationID: ->
        return _currentCID

    ###*
    * Get older conversation displayed before current
    *
    * @param {Function}  transform
    *
    * @return {List}
    ###
    getPreviousConversation: (param={}) ->
        @getConversation _.extend param, transform: (index) -> ++index

    ###*
    * Get earlier conversation displayed after current
    *
    * @param {Function}  transform
    *
    * @return {List}
    ###
    getNextConversation: (param={}) ->
        @getConversation _.extend param, transform: (index) -> --index

    getCurrentConversation: ->
        conversationID = @getCurrentConversationID()
        if conversationID
            return @getConversation(conversationID)
        else
            return null

    setConversation: (conversationID) ->
        _conversationMemoizeID = conversationID
        _conversationMemoize = _messagesWithInFlights()
            .filter (message) ->
                message.get('conversationID') is conversationID
            .sort reverseDateSort

    ###*
    * Get Conversation
    *
    * If none parameters    return current conversation
    * @param.transform      return the list index needed
    * @param.type="message" return the closest message
    *                       instead of conversation
    *
    * @param {String}   type
    * @param {Function} transform
    *
    * @return {List}
    ###
    getConversation: (param={}) ->
        # Update global context
        if param.conversationID?
            @setConversation param.conversationID

        # If no specific action is precized
        # return all contextual conversations
        unless _.isFunction param.transform
            return _conversationMemoize

        messageID = param.messageID or @getCurrentID()
        conversationID = param.conversationID or @getByID(messageID)?.get 'conversationID'
        messages = @getMessagesToDisplay()

        # In this case, we just want
        # next/previous message from a selection
        # then remove selected messages from the list
        if param.conversationIDs
            conversationID = param.conversationIDs[0]
            messages = messages
                .filter (message) ->
                    id = message.get 'conversationID'
                    index = param.conversationIDs.indexOf id
                    return index is -1
                .toList()

        getMessage = =>
            _getMessage = (index) ->
                index0 = param.transform index
                messages?.get(index0)

            # Get next Conversation not next message
            # `messages` is the list of all messages not conversations
            # TODO : regroup message by its conversationID
            # and use messages.find instead with a simple test
            # FIXME : inconsistency between the 2 results, see why?
            index0 = messages.toArray().findIndex (message, index) ->
                isSameMessage = conversationID is message?.get 'conversationID'
                isNextSameConversation = _getMessage(index)?.get('conversationID') isnt conversationID
                return isSameMessage and isNextSameConversation

            _getMessage(index0)

        # Change Conversation
        return Immutable.Map getMessage()


    # Retrieve a batch of message with various criteria
    # target - is an {Object} with a property messageID or messageIDs or
    #          conversationID or conversationIDs
    # target.accountID is needed to success Delete
    #
    # Returns an {Array} of {Immutable.Map} messages
    getMixed: (target) ->
        messages = _getMixed target
        target.accountID = messages[0].get('accountID')
        messages

    getConversationsLength: ->
        return _conversationLengths

    isFetching: ->
        return _fetching > 0

    isUndoable: (ref) ->
        _undoable[ref]?

    getUndoableRequest: (ref) ->
        _undoable[ref]

    getQueryParams: ->
        filter = _getFilter()
        params =
            sort: _getURISort()
            type: filter.type
            filter: filter.value
            before: filter.before
            after: filter.after
            hasNextPage: not _noMore
        return params

    # Uniq Key from URL params
    #
    # return a {string}
    getQueryKey: (str = '') ->
        filter = _getFilter()
        filterize = (key) ->
            filter[key] if _isFilter filter[key]

        keys = _.compact ['before', 'after'].map filterize
        keys.unshift str unless _.isEmpty str
        keys.join('-')

    getCurrentURL: ->
        filter = _getFilter()
        mailboxID = AccountStore.getSelectedMailbox().get 'id'
        sort = if filter.type in ['from', 'dest']
            encodeURIComponent "+#{filter.type}"
        else
            encodeURIComponent _getURISort()

        url = "mailbox/#{mailboxID}/?sort=#{sort}"
        if filter.type is 'flag' and _isFilter filter.value
            url += "&flag=#{filter.value}"

        if _isFilter filter.before
            url += "&before=#{encodeURIComponent filter.before}"

        if _isFilter filter.after
            url += "&after=#{encodeURIComponent filter.after}"
        return url

    getNextUrl: ->
        if _nextUrl
            return _nextUrl
        else if _noMore or _currentUrl is (url = @getCurrentURL())
            return null
        else
            _currentUrl = url
            return url

module.exports = self = new MessageStore()
