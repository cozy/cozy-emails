Store = require '../libs/flux/store/store'
ContactStore  = require './contact_store'
AppDispatcher = require '../app_dispatcher'

AccountStore = require './account_store'
SocketUtils = require '../utils/socketio_utils'

{ActionTypes, MessageFlags, MessageFilter, FlagsConstants} =
        require '../constants/app_constants'

{reverseDateSort, getSortFunction} = require '../utils/misc'

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _messages = Immutable.OrderedMap()

    _sortField   = 'date'
    _sortOrder   = 1
    _filterType   = '-'
    _filterValue   = 'nofilter'
    _filterBefore  = '-'
    _filterAfter  = '-'

    _fetching     = 0

    _queryRef = 0
    _nextUrl = null
    _noMore = false

    _currentMessages = Immutable.Sequence()
    _conversationLengths = Immutable.Map()
    _conversationMemoize = null
    _currentID       = null
    _currentCID      = null

    _inFlightByRef = {}
    _inFlightByMessageID = {}
    _undoable = {}

    _addInFlight = (request) ->
        _inFlightByRef[request.ref] = request
        request.messages.forEach (message) ->
            id = message.get('id')
            requests = (_inFlightByMessageID[id] ?= [])
            requests.push request

    _removeInFlight = (ref) ->
        request = _inFlightByRef[ref]
        delete _inFlightByRef[ref]
        request.messages.forEach (message) ->
            id = message.get('id')
            requests = _inFlightByMessageID[id]
            _inFlightByMessageID[id] = _.without requests, request

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
        _messages.map (message) ->
            id = message.get 'id'
            for request in _inFlightByMessageID[id] or []
                message = _transformMessageWithRequest message, request
            return message
        .filter (msg) -> msg isnt null

    _fixCurrentMessage = (target) ->
        # If target.inReplyTo is set, we are removing a reply, so stay
        # on current message
        if target.inReplyTo?
            return null
        else
            messageIDs = target.messageIDs or [target.messageID]
            currentMessage = self.getCurrentID() or 'not-null'
            conversationIDs = target.conversationIDs or [target.conversationID]
            currentConversation = self.getCurrentConversationID() or 'not-null'

            # open next message if the deleted / moved one was open ###
            if currentMessage in messageIDs or
            currentConversation in conversationIDs
                next = self.getNextOrPrevious true
                if next?
                    setTimeout ->
                        window.cozyMails.messageSetCurrent next
                    , 1

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

    dedupConversation = ->
        conversationIDs = []
        return filter = (message) ->
            conversationID = message.get 'conversationID'
            if conversationID and conversationID in conversationIDs
                return false
            else
                conversationIDs.push conversationID
                return true


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
            message.attachments = Immutable.Vector.from message.attachments

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

            if message.accountID? and
               diff = computeMailboxDiff(oldmsg, messageMap)
                AccountStore._applyMailboxDiff message.accountID, diff

        getMessage = _messages.get message.id

    handleFetchResult = (result) ->

        if result.links?.next?
            _nextUrl = decodeURIComponent(result.links.next)
        else if result.links?
            _noMore = true

        if lengths = result.conversationLengths
            lengths[message.conversationID] ?= 0 for message in result.messages
            _conversationLengths = _conversationLengths.merge lengths

        for message in result.messages when message?
            onReceiveRawMessage message

        lastdate = _messages.last()?.get('date')
        SocketUtils.changeRealtimeScope result.mailboxID, lastdate if lastdate


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MESSAGE, (message) ->
            onReceiveRawMessage message
            @emit 'change'

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
            messages = _getMixed target
            target.subject = messages[0]?.get('subject')
            target.accountID = messages[0].get('accountID')
            account = AccountStore.getByID messages[0]?.get('accountID')
            trashBoxID = account?.get? 'trashMailbox'
            _addInFlight {type: 'trash', trashBoxID, messages, ref}
            _fixCurrentMessage target
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
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAGS_REQUEST, ({target, op, flag, ref}) ->
            messages = _getMixed target
            target.subject = messages[0]?.get('subject')
            target.accountID = messages[0].get('accountID')
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
            messages = _getMixed target
            target.subject = messages[0]?.get('subject')
            target.accountID = messages[0].get('accountID')
            _addInFlight {type: 'move', from, to, messages, ref}
            _fixCurrentMessage target
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
            handleFetchResult fetchResult
            @emit 'change'

        handle ActionTypes.CONVERSATION_FETCH_SUCCESS, ({updated}) ->
            for message in updated
                onReceiveRawMessage message
            @emit 'change'

        handle ActionTypes.MESSAGE_SEND, (message) ->
            onReceiveRawMessage message
            @emit 'change'

        handle ActionTypes.QUERY_PARAMETER_CHANGED, (parameters) ->

            # _messages  = _messages.clear()
            # "sort/-date/flag/unseen/before/-/after/-"

            {type, flag, sort, before, after} = parameters



            if type isnt _filterType or _filterValue isnt flag or
            _filterBefore isnt before or _filterAfter isnt after or
            _sortOrder + _sortField isnt sort

                _queryRef++
                _sortOrder = sort.substr(0, 1)
                _sortField = sort.substr(1)
                _filterType = type
                _filterValue = flag
                _filterBefore = before
                _filterAfter = after
                _noMore = false
                _nextUrl = null

                if _filterType in ['from', 'dest'] or type in ['from', 'dest']
                    # we cant properly filter messages by dest or from in the
                    # client, instead we clear message cache and dont filter
                    # on display
                    _messages = _messages.clear()

            @emit 'change'


        handle ActionTypes.MESSAGE_CURRENT, (value) ->
            @setCurrentID value.messageID, value.conv
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, (value) ->
            @setCurrentID null
            _sortOrder = '+'
            _sortField = 'date'
            _filterType = 'nofilter'
            _filterValue = '-'
            _filterBefore = '-'
            _filterAfter = '-'
            _noMore = false
            _nextUrl = null

        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (id) ->
            _messages = _messages.remove id
            @emit 'change'

        handle ActionTypes.MAILBOX_EXPUNGE, (mailboxID) ->
            _messages = _messages.filter(notInMailbox(mailboxID))
            @emit 'change'

        handle ActionTypes.SEARCH_SUCCESS, ({searchResults}) ->
            for message in searchResults when message?
                onReceiveRawMessage message
            @emit 'change'


    ###
        Public API
    ###
    getByID: (messageID) ->
        _messages.get(messageID) or null


    # Build message hash from message and currently selected mailbox and
    # account.
    getMessageHash: (message) ->

        messageID = message.get 'id'
        accountID = message.get 'accountID'
        mailboxID = AccountStore.getSelectedMailbox().get 'id'
        unless mailboxID?
            mailboxID = AccountStore.getMailbox message, account

        account = AccountStore.getSelected().get 'id'
        conversationID = message.get('conversationID')

        hash = "#account/#{accountID}/"
        hash += "mailbox/#{mailboxID}/"
        hash += "conversation/#{conversationID}/#{messageID}/"

        return hash


    dedupConversation = ->
        conversationIDs = []
        return filter = (message) ->
            conversationID = message.get 'conversationID'
            if conversationID and conversationID in conversationIDs
                false
            else
                conversationIDs.push conversationID
                return true

    _matchFlag = (message) ->
        switch _filterValue
            when MessageFilter.FLAGGED
                MessageFlags.FLAGGED in message.get('flags')
            when MessageFilter.ATTACH
                message.get('attachments').length > 0
            when MessageFilter.UNSEEN
                MessageFlags.SEEN not in message.get('flags')


    _matchRangeDate = (message) ->
        _filterBefore < message.get(_filterType) < _filterAfter

    ###*
    * Get messages from mailbox, with optional pagination
    *
    * @param {String}  mailboxID
    * @param {Boolean} conversation
    *
    * @return {Array}
    ###
    getMessagesToDisplay: (mailboxID, useConversations) ->
        conversationIDs = []

        sequence = _messagesWithInFlights()
        sequence = sequence.filter inMailbox mailboxID

        if _filterType is 'flag'
            sequence = sequence.filter _matchFlag

        if _filterType in ['date']
            sequence = sequence.filter _matchRangeDate

        # We dont filter for _filterType from and dest because it is
        # complicated by collation and name vs address.
        # Instead we clear the message, see QUERY_PARAMETER_CHANGED handler.

        if useConversations
            sequence = sequence.filter dedupConversation()

        sequence = sequence.sort getSortFunction _sortField, _sortOrder
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

    getCurrentConversationID: ->
        return _currentCID

    getPreviousMessage: (isConv) ->
        if isConv? and isConv
            if not _conversationMemoize?
                return null
            # Conversations displayed
            idx = _conversationMemoize.findIndex (message) ->
                return _currentID is message.get 'id'
            if idx < 0
                return null
            else if idx is _conversationMemoize.length - 1
                # We need first message of previous conversation
                keys = Object.keys _currentMessages.toJS()
                idx = keys.indexOf(_conversationMemoize.last().get('id'))
                if idx < 1
                    return null
                else
                    currentMessage = _currentMessages.get(keys[idx - 1])
                    convID = currentMessage?.get('conversationID')
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
            return if idx is -1 then null
            else _currentMessages.get keys[idx - 1]

    getNextMessage: (isConv) ->
        if isConv? and isConv

            if not _conversationMemoize?
                return null
            # Conversations displayed
            idx = _conversationMemoize.findIndex (message) ->
                return _currentID is message.get 'id'
            if idx < 0
                return null
            else if idx is 0
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
            if not _currentID
                return _currentMessages?.first()

            keys = Object.keys _currentMessages.toJS()
            idx = keys.indexOf _currentID
            if idx is -1 or idx is (keys.length - 1)
                return null
            else
                return _currentMessages.get keys[idx + 1]

    getNextOrPrevious: (isConv) ->
        @getNextMessage(isConv) or @getPreviousMessage(isConv)


    getCurrentConversation: ->
        conversationID = @getCurrentConversationID()
        if conversationID
            return @getConversation(conversationID)
        else
            return null

    getConversation: (conversationID, excludeMailbox) ->
        _conversationMemoize = _messagesWithInFlights()
            .filter (message) ->
                mailboxIDs = Object.keys message.get('mailboxIDs')
                isInConversation =
                    message.get('conversationID') is conversationID
                isInMailbox = not excludeMailbox? or \
                              not (excludeMailbox in mailboxIDs)
                return isInConversation and isInMailbox
            .sort reverseDateSort
            .toVector()

        return _conversationMemoize

    # Retrieve a batch of message with various criteria
    # target - is an {Object} with a property messageID or messageIDs or
    #          conversationID or conversationIDs
    #
    # Returns an {Array} of {Immutable.Map} messages
    getMixed: (target) ->
        _getMixed target

    getConversationsLength: ->
        return _conversationLengths

    isFetching: ->
        return _fetching > 0

    isUndoable: (ref) ->
        _undoable[ref]?

    getUndoableRequest: (ref) ->
        _undoable[ref]

    getQueryParams: ->
        sort: "#{_sortOrder}#{_sortField}"
        type: _filterType
        filter: _filterValue
        before: _filterBefore
        after: _filterAfter
        hasNextPage: not _noMore

    getNextUrl: ->
        if _noMore
            return null
        else if _nextUrl
            _nextUrl
        else
            mailboxID = AccountStore.getSelectedMailbox().get 'id'
            sort = if _filterType in ['from', 'dest']
                encodeURIComponent "+#{_filterType}"
            else
                encodeURIComponent "#{_sortOrder}#{_sortField}"

            url = "mailbox/#{mailboxID}/?sort=#{sort}"
            if _filterType is 'flag'
                url += "&flag=#{_filterValue}"

            if _filterBefore isnt '-'
                url += "&before=#{encodeURIComponent _filterBefore}"

            if _filterAfter isnt '-'
                url += "&after=#{encodeURIComponent _filterAfter}"

            return url


module.exports = self = new MessageStore()

