Store = require '../libs/flux/store/store'
ContactStore  = require './contact_store'
AppDispatcher = require '../app_dispatcher'

AccountStore = require './account_store'
SocketUtils = require '../utils/socketio_utils'

{ActionTypes, MessageFlags, MessageFilter} =
        require '../constants/app_constants'

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _sortField   = 'date'
    _sortOrder   = 1
    __getSortFunction = (criteria, order) ->
        sortFunction = (message1, message2) ->
            if typeof message1.get is 'function'
                val1 = message1.get criteria
                val2 = message2.get criteria
            else
                val1 = message1[criteria]
                val2 = message2[criteria]
            if val1 > val2 then return -1 * order
            else if val1 < val2 then return 1 * order
            else return 0

    __sortFunction = __getSortFunction 'date', 1
    reverseDateSort = __getSortFunction 'date', -1

    # Creates an OrderedMap of messages
    _messages = Immutable.Sequence()

        # sort first
        .sort __sortFunction

        # sets message ID as index
        .mapKeys (_, message) -> message.id

        # makes message object an immutable Map
        .map (message) -> Immutable.fromJS message
        .toOrderedMap()

    _filter       = '-'
    _params       = sort: '-date'
    _fetching     = false
    _currentMessages = Immutable.Sequence()
    _conversationLengths = Immutable.Map()
    _conversationMemoize = null
    _conversationMemoizeID = null
    _currentID       = null
    _prevAction      = null

    computeMailboxDiff = (oldmsg, newmsg) ->
        return {} unless oldmsg
        changed = false

        wasRead = MessageFlags.SEEN in oldmsg.get 'flags'
        isRead = MessageFlags.SEEN in newmsg.get 'flags'

        oldboxes = Object.keys oldmsg.get 'mailboxIDs'
        newboxes = Object.keys newmsg.get 'mailboxIDs'

        out = {}
        added = _.difference(newboxes, oldboxes)
        added.forEach (boxid) ->
            changed = true
            out[boxid] = nbTotal: +1, nbUnread: if isRead then +1 else 0

        removed = _.difference oldboxes, newboxes
        removed.forEach (boxid) ->
            changed = true
            out[boxid] = nbTotal: -1, nbUnread: if wasRead then -1 else 0

        stayed = _.intersection oldboxes, newboxes
        deltaUnread = if wasRead and not isRead then +1
        else if not wasRead and isRead then -1
        else 0
        stayed.forEach (boxid) ->
            changed = true if deltaUnread isnt 0
            out[boxid] = nbTotal: 0, nbUnread: deltaUnread

        if changed
            return out
        else
            return false


    onReceiveRawMessage = (message) ->
        # create or update
        if not message.attachments?
            message.attachments = []
        if not message.date?
            message.date = new Date().toISOString()
        if not message.createdAt?
            message.createdAt = message.date
        # Add messageID to every attachment

        message.hasAttachments = message.attachments.length > 0
        message.attachments = message.attachments.map (file) ->
            Immutable.Map file
        message.attachments = Immutable.Vector.from message.attachments

        if not message.flags?
            message.flags = []

        # message loaded from fixtures for test purpose have a docType
        # that may cause some troubles
        delete message.docType
        message = Immutable.Map message

        oldmsg = _messages.get message.get('id')
        _messages = _messages.set message.get('id'), message
        if diff = computeMailboxDiff(oldmsg, message)
            AccountStore._applyMailboxDiff message.get('accountID'), diff

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MESSAGE, (message) ->
            onReceiveRawMessage message
            @emit 'change'

        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->

            if messages.mailboxID
                SocketUtils.changeRealtimeScope messages.mailboxID

            if messages.links?
                if messages.links.next?
                    # reinit params here for pagination on filtered lists
                    _params = {}
                    next   = decodeURIComponent(messages.links.next)
                    url    = 'http://localhost' + next
                    url.split('?')[1].split('&').forEach (p) ->
                        [key, value] = p.split '='
                        value = '-' if value is ''
                        _params[key] = value

                SocketUtils.changeRealtimeScope messages.mailboxID,
                    _params.pageAfter

            if lengths = messages.conversationLengths
                _conversationLengths = _conversationLengths.merge lengths

            if messages.count? and messages.mailboxID?
                messages = messages.messages.sort __sortFunction



            onReceiveRawMessage message for message in messages
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            _messages = _messages.filter (message) ->
                message.get('accountID') isnt accountID
            .toOrderedMap()

            @emit 'change'

        handle ActionTypes.MESSAGE_SEND, (message) ->
            onReceiveRawMessage message

        handle ActionTypes.MESSAGE_DELETE, (message) ->
            onReceiveRawMessage message

        handle ActionTypes.MESSAGE_BOXES, (message) ->
            onReceiveRawMessage message

        handle ActionTypes.MESSAGE_FLAG, (message) ->
            onReceiveRawMessage message

        handle ActionTypes.LIST_FILTER, (filter) ->
            _messages  = _messages.clear()
            if _filter is filter
                _filter = '-'
            else
                _filter = filter
            _params =
                after: '-'
                flag: _filter
                before: '-'
                pageAfter: '-'
                sort : _params.sort

        handle ActionTypes.LIST_SORT, (sort) ->
            _messages    = _messages.clear()
            _sortField   = sort.field
            currentField = _params.sort.substr(1)
            currentOrder = _params.sort.substr(0, 1)
            if currentField is sort.field
                newOrder   = if currentOrder is '+' then '-' else '+'
                _sortOrder = -1 * _sortOrder
            else
                _sortOrder = -1
                if sort.field is 'date'
                    newOrder   = '-'
                else
                    newOrder   = '+'
            _params =
                after: '-'
                flag: _params.flag
                before: '-'
                pageAfter: '-'
                sort : newOrder + sort.field

        handle ActionTypes.MESSAGE_ACTION, (action) ->
            action.target = 'message'
            _prevAction = action

        handle ActionTypes.CONVERSATION_ACTION, (action) ->
            action.target = 'conversation'
            _prevAction = action

        handle ActionTypes.MESSAGE_CURRENT, (value) ->
            @setCurrentID value.messageID, value.conv
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, (value) ->
            @setCurrentID null
            _params.after     = '-'
            _params.before    = '-'
            _params.pageAfter = '-'

        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (id) ->
            _messages = _messages.remove id
            @emit 'change'

        handle ActionTypes.MAILBOX_EXPUNGE, (mailboxID) ->
            _messages = _messages.filter (message) ->
                mailboxes = Object.keys message.get 'mailboxIDs'
                return mailboxID not in mailboxes
            .toOrderedMap()

            @emit 'change'

        handle ActionTypes.SET_FETCHING, (fetching) ->
            _fetching = fetching
            @emit 'change'

    ###
        Public API
    ###
    getAll: -> return _messages

    getByID: (messageID) -> _messages.get(messageID) or null


    ###*
    * Get messages from mailbox, with optional pagination
    *
    * @param {String}  mailboxID
    * @param {Boolean} conversation
    *
    * @return {Array}
    ###
    getMessagesByMailbox: (mailboxID, useConversations) ->
        conversationIDs = []

        sequence = _messages.filter (message) ->
            mailboxes = Object.keys message.get 'mailboxIDs'
            if mailboxID not in mailboxes
                return false

            if useConversations
                # one message of each conversation
                conversationID = message.get 'conversationID'
                if conversationID in conversationIDs
                    return false
                else
                    conversationIDs.push conversationID
                    return true
            else
                return true
        .sort(__getSortFunction _sortField, _sortOrder)

        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _currentMessages = sequence.toOrderedMap()
        if not _currentID?
            @setCurrentID _currentMessages.first()?.get 'id'
        return _currentMessages

    getCurrentID: ->
        return _currentID

    setCurrentID: (messageID, conv) ->
        if conv?
            _conversationMemoizeID = @getByID(messageID).get 'conversationID'
        _currentID = messageID

    getCurrentConversationID: ->
        return _conversationMemoizeID

    getPreviousMessage: (isConv) ->
        if isConv? and isConv
            if not _conversationMemoize?
                return null
            # Conversations displayed
            idx = _conversationMemoize.findIndex (message) ->
                return _currentID is message.get 'id'
            if idx is _conversationMemoize.length - 1
                # We need first message of previous conversation
                keys = Object.keys _currentMessages.toJS()
                idx = keys.indexOf(_conversationMemoize.last().get('id'))
                if idx < 1
                    return null
                else
                    convID = _currentMessages.get(keys[idx - 1])?.get('conversationID')
                    return null if not convID?
                    prev = _messages.filter (message) ->
                        message.get('conversationID') is convID
                    .sort reverseDateSort
                    .first()
                    return prev
            else
                return _conversationMemoize.get(idx + 1)
        else
            keys = Object.keys _currentMessages.toJS()
            idx = keys.indexOf _currentID
            return if idx is -1 then null else _currentMessages.get keys[idx - 1]

    getNextMessage: (isConv) ->
        if isConv? and isConv
            if not _conversationMemoize?
                return null
            # Conversations displayed
            idx = _conversationMemoize.findIndex (message) ->
                return _currentID is message.get 'id'
            if idx is 0
                # We need first message of next conversation
                keys = Object.keys _currentMessages.toJS()
                idx = keys.indexOf(_conversationMemoize.last().get('id'))
                if idx is -1 or idx is (keys.length - 1)
                    return null
                else
                    return _currentMessages.get keys[idx + 1]
            else
                return _conversationMemoize.get(idx - 1)
        else
            keys = Object.keys _currentMessages.toJS()
            idx = keys.indexOf _currentID
            if idx is -1 or idx is (keys.length - 1)
                return null
            else
                return _currentMessages.get keys[idx + 1]

    getConversation: (conversationID) ->
        _conversationMemoize = _messages
            .filter (message) ->
                message.get('conversationID') is conversationID
            .sort reverseDateSort
            .toVector()
        _conversationMemoizeID = conversationID

        return _conversationMemoize

    getConversationsLength: -> return _conversationLengths

    getParams: -> return _params

    getCurrentFilter: -> return _filter

    getPrevAction: -> return _prevAction

    isFetching: -> return _fetching

module.exports = new MessageStore()
