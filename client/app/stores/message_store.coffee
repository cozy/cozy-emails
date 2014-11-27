Store = require '../libs/flux/store/store'
ContactStore  = require './contact_store'
AppDispatcher = require '../app_dispatcher'

AccountStore = require './account_store'

{ActionTypes, MessageFlags, MessageFilter} =
        require '../constants/app_constants'

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _sortField   = 'date'
    _sortOrder   = 1
    #_quickFilter = ''
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

    # Creates an OrderedMap of messages
    _messages = Immutable.Sequence()

        # sort first
        .sort __sortFunction

        # sets message ID as index
        .mapKeys (_, message) -> message.id

        # makes message object an immutable Map
        .map (message) -> Immutable.fromJS message
        .toOrderedMap()

    _filter       = null
    _params       = null
    _currentMessages = Immutable.Sequence()
    _currentID       = null
    _prevAction      = null


    initFilters = ->
        _filter       = '-'
        _params       =
            sort: '+date'

    initFilters()

    onReceiveRawMessage = (message, silent = false) ->
        # create or update
        if not message.attachments?
            message.attachments = []
        if not message.date?
            message.date = new Date().toISOString()
        if not message.createdAt?
            message.createdAt = message.date
        # Add messageId to every attachment

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
        _messages = _messages.set message.get('id'), message

        @emit 'change' unless silent

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MESSAGE, onReceiveRawMessage

        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->

            if messages.links?
                if messages.links.next?
                    _params = {}
                    next   = decodeURIComponent(messages.links.next)
                    url    = 'http://localhost' + next
                    url.split('?')[1].split('&').forEach (p) ->
                        tmp = p.split '='
                        if tmp[1] isnt ''
                            _params[tmp[0]] = tmp[1]
                        else
                            _params[tmp[0]] = '-'
                    #if _params.flag is ''
                    #    _params.flag = null#'all'

            if messages.count? and messages.mailboxID?
                messages = messages.messages.sort __sortFunction

            onReceiveRawMessage message, true for message in messages
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            messages = @getMessagesByAccount accountID
            _messages = _messages.withMutations (map) ->
                messages.forEach (message) -> map.remove message.get 'id'

            @emit 'change'

        handle ActionTypes.MESSAGE_SEND, (message) ->
            onReceiveRawMessage message, true

        handle ActionTypes.MESSAGE_DELETE, (message) ->
            onReceiveRawMessage message, true

        handle ActionTypes.MESSAGE_BOXES, (message) ->
            onReceiveRawMessage message, true

        handle ActionTypes.MESSAGE_FLAG, (message) ->
            onReceiveRawMessage message, true

        handle ActionTypes.SELECT_ACCOUNT, ->
            initFilters()

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

        handle ActionTypes.LIST_QUICK_FILTER, (filter) ->
            #_quickFilter = filter
            #@emit 'change'

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
            _prevAction = action

        handle ActionTypes.MESSAGE_CURRENT, (messageID) ->
            @setCurrentID messageID
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, (value) ->
            @setCurrentID null

    ###
        Public API
    ###
    getAll: -> return _messages

    getByID: (messageID) -> _messages.get(messageID) or null

    ###*
    * Get messages from account, with optional pagination
    *
    * @param {String} accountID
    * @param {Number} first     index of first message
    * @param {Number} last      index of last message
    *
    * @return {Array}
    ###
    getMessagesByAccount: (accountID) ->
        sequence = _messages.filter (message) ->
            return message.get('accountID') is accountID

        # sequences are lazy so we need .toOrderedMap() to actually execute it
        return sequence.toOrderedMap()


    getMessagesCountByAccount: (accountID) ->
        return @getMessagesByAccount(accountID).count()

    ###*
    * Get messages from mailbox, with optional pagination
    *
    * @param {String} mailboxID
    * @param {Number} first     index of first message
    * @param {Number} last      index of last message
    *
    * @return {Array}
    ###
    getMessagesByMailbox: (mailboxID) ->
        sequence = _messages.filter (message) ->
            return mailboxID in Object.keys message.get 'mailboxIDs'
        .sort(__getSortFunction _sortField, _sortOrder)

        ###
        if _filter isnt MessageFilter.ALL
            if _filter is MessageFilter.FLAGGED
                filterFunction = (message) ->
                    return MessageFlags.FLAGGED in message.get 'flags'
            else if _filter is MessageFilter.UNSEEN
                filterFunction = (message) ->
                    return MessageFlags.SEEN not in message.get 'flags'
        if filterFunction?
            sequence = sequence.filter filterFunction

        if _quickFilter isnt ''
            re = new RegExp _quickFilter, 'i'
            sequence = sequence.filter (message) ->
                return re.test(message.get 'subject')
        ###

        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _currentMessages = sequence.toOrderedMap()
        if not _currentID?
            @setCurrentID _currentMessages.first()?.get 'id'
        return _currentMessages

    getCurrentID: (messageID) ->
        return _currentID

    setCurrentID: (messageID) ->
        _currentID = messageID

    getPreviousMessage: ->
        keys = Object.keys _currentMessages.toJS()
        idx = keys.indexOf _currentID
        return if idx is -1 then null else keys[idx - 1]

    getNextMessage: ->
        keys = Object.keys _currentMessages.toJS()
        idx = keys.indexOf _currentID
        if idx is -1 or idx is (keys.length - 1)
            return null
        else
            return keys[idx + 1]

    getMessagesByConversation: (messageID) ->
        idsToLook = [messageID]
        conversation = []
        while idToLook = idsToLook.pop()
            conversation.push @getByID idToLook
            temp = _messages.filter (message) ->
                inReply = message.get 'inReplyTo'
                return Array.isArray(inReply) and
                        inReply.indexOf(idToLook) isnt -1
            newIdsToLook = temp.map((item) -> item.get('id')).toArray()
            idsToLook = idsToLook.concat newIdsToLook

        return conversation.sort(__getSortFunction 'date', -1)

    getConversation: (conversationID) ->
        conversation = []
        _messages.filter (message) ->
            return message.get('conversationID') is conversationID
        .map (message) -> conversation.push message
        .toJS()
        return conversation.sort(__getSortFunction 'date', -1)

    getParams: -> return _params

    getPrevAction: -> return _prevAction

module.exports = new MessageStore()
