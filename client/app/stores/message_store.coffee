_         = require 'underscore'
Immutable = require 'immutable'
XHRUtils = require '../utils/xhr_utils'

AppDispatcher = require '../app_dispatcher'

Store = require '../libs/flux/store/store'
AccountStore = require './account_store'
RouterStore = require './router_store'

RouterGetter = require '../getters/router'

{changeRealtimeScope} = require '../utils/realtime_utils'
{sortByDate} = require '../utils/misc'

{ActionTypes, MessageFlags, MessageActions} = require '../constants/app_constants'

EPOCH = (new Date(0)).toISOString()

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _messages = Immutable.OrderedMap()
    _conversationLength = Immutable.Map()

    _currentMessages = Immutable.OrderedMap()

    _currentID = null

    _inFlightByRef = {}
    _inFlightByMessageID = {}
    _undoable = {}


    _setCurrentID = (messageID) ->
        _currentID = messageID

    _addInFlight = (request) ->
        _inFlightByRef[request.ref] = request
        request.messages.forEach (message) ->
            id = message.get('id')
            requests = (_inFlightByMessageID[id] ?= [])
            requests.push request

    _removeInFlight = (ref) ->
        request = _inFlightByRef[ref]
        delete _inFlightByRef[ref]
        request?.messages.forEach (message) ->
            id = message.get('id')
            requests = _inFlightByMessageID[id]
            _inFlightByMessageID[id] = _.without requests, request
        return request

    # Retrieve a batch of message with various criteria
    # target - is an {Object} with a property messageID or messageIDs or
    #          conversationID or messageIDs
    # target.accountID is needed to success Delete
    #
    # Returns an {Array} of {Immutable.Map} messages
    _getMixed = (target) ->
        if target.messageID
            return [_messages.get(target.messageID)]
        else if target.messageIDs
            return target.messageIDs.map (id) ->
                 _messages.get id
            .filter (message) -> message?
        else if target.conversationID
            return _messages.filter (message) ->
                message?.get('conversationID') is target?.conversationID
            .toArray()
        else throw new Error 'Wrong Usage : unrecognized target AS.getMixed'

    isAllLoaded: ->
        total = AccountStore.getMailbox()?.get('nbTotal')
        total is _currentMessages?.size


    # Refresh Emails from Server
    # This is a read data pattern
    # ActionCreator is a write data pattern
    _refreshMailbox = (params={}) ->
        {mailboxID} = params
        mailboxID ?= AccountStore.getMailboxID()
        deep = true

        XHRUtils.refreshMailbox mailboxID, {deep}, (error, updated) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.REFRESH_FAILURE
                    value: {mailboxID, error}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.REFRESH_SUCCESS
                    value: {mailboxID, updated}


    # Get Emails from Server
    # This is a read data pattern
    # ActionCreator is a write data pattern
    _fetchMessages = (params={}) ->
        {messageID, conversationID, action} = params
        mailboxID = AccountStore.getMailboxID()
        action ?= MessageActions.SHOW_ALL
        timestamp = Date.now()

        _fetching++

        callback = (error, result) ->
            _fetching--
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, mailboxID}
            else
                # This prevent to override local updates
                # with older ones from server
                messages = if _.isArray(result) then result else result.messages
                messages?.forEach (message) -> _saveMessage message, timestamp

                # Shortcut to know conversationLength
                # without loading all massages of the conversation
                if (conversationLength = result?.conversationLength)
                    for conversationID, length of conversationLength
                        _saveConversationLength conversationID, length

                # Message should belong to the result
                # If not : go fetch next messages
                if not _self.isAllLoaded() and messageID and
                        not _messages?.get messageID
                    action = MessageActions.PAGE_NEXT

                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {action, nextURL, messageID}

                # Message is not in the result
                # get next page
                if messageID and not _messages.toJS()[messageID]
                    AppDispatcher.dispatch
                        type: ActionTypes.MESSAGE_FETCH_REQUEST
                        value: {action, messageID, mailboxID}
                else
                    AppDispatcher.dispatch
                        type: ActionTypes.MESSAGE_FETCH_SUCCESS
                        value: {action, messages, messageID, mailboxID}

        if action is MessageActions.PAGE_NEXT
            action = MessageActions.SHOW_ALL
            messages = _messages
            url = RouterStore.getNextURL {action, messages, messageID}
            XHRUtils.fetchMessagesByFolder url, callback

        else if action is MessageActions.SHOW_ALL
            mailboxID = AccountStore.getMailboxID()
            url = RouterStore.getCurrentURL {action, mailboxID}
            XHRUtils.fetchMessagesByFolder url, callback

        else
            XHRUtils.fetchConversation conversationID, callback

<<<<<<< HEAD
=======
        out[accountID] = nbUnread: deltaUnread

        stayed.forEach (boxid) ->
            out[boxid] = nbTotal: 0, nbUnread: deltaUnread

        if changed
            return out
        else
            return false

>>>>>>> e341e87... Get conversationLength from server not client
    _saveMessage = (message, timestamp) ->
        oldmsg = _messages.get message.id
        updated = oldmsg?.get 'updated'

        # only update message if new version is newer than
        # the one currently stored
        message.updated = timestamp if timestamp
<<<<<<< HEAD

=======
>>>>>>> e341e87... Get conversationLength from server not client
        if not (timestamp? and updated? and updated > timestamp) and
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

<<<<<<< HEAD
=======
            if message.accountID? and (diff = _computeMailboxDiff oldmsg, messageMap)
                AccountStore._applyMailboxDiff message.accountID, diff

>>>>>>> e341e87... Get conversationLength from server not client
    _deleteMessage = (message) ->
        _messages = _messages.remove message.id


    _saveConversationLength = (conversationID, length) ->
        _conversationLength = _conversationLength.set conversationID, length

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ROUTE_CHANGE, (value) ->
            {messageID} = value
            _setCurrentID messageID

            # Get messageList for 1rst panel
            if action in [MessageActions.SHOW_ALL, MessageActions.SHOW]
                _refreshMailbox payload
                _fetchMessages payload

            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_REQUEST, (payload) ->
            _fetchMessages payload
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, ({messages, mailboxID}) ->
            lastdate = _messages.last()?.get 'date'
            before = unless messages then EPOCH else lastdate
            changeRealtimeScope {mailboxID, before}
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_REQUEST, (params) ->
            _fetchMessage params
            @emit 'change'


        handle ActionTypes.RECEIVE_RAW_MESSAGE, (message) ->
            _saveMessage message
            @emit 'change'

        handle ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME, (message) ->
            _saveMessage message
            @emit 'change'

        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->
            for message in messages when message?
                _saveMessage message
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, (accountID) ->
            _messages = _messages.filter (message) ->
                accountID isnt message.get 'accountID'
            .toOrderedMap()
            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_REQUEST, ({target, ref}) ->
            messages = _getMixed target
            target.accountID = messages[0].get 'accountID'
            trashBoxID = AccountStore.getSelected().get 'trashMailbox'
            _addInFlight {type: 'trash', trashBoxID, messages, ref}
            @emit 'change'

<<<<<<< HEAD
        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, updated, ref}) ->
=======
        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, updated, ref, next}) ->
>>>>>>> e341e87... Get conversationLength from server not client
            _undoable[ref] = _removeInFlight ref
            for message in updated
                if message._deleted
                    _deleteMessage message
                    if (nextMessage = @getNextConversation())?.size
                        _setCurrentID nextMessage?.get 'id'
                else
                    _saveMessage message
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAGS_SUCCESS, ({target, updated, ref}) ->
            _removeInFlight ref
            _saveMessage message for message in updated
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAGS_FAILURE, ({target, ref}) ->
            _removeInFlight ref
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_REQUEST, ({target, from, to, ref}) ->
            messages = _getMixed target
            _addInFlight {type: 'move', from, to, messages, ref}
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({target, updated, ref}) ->
            _undoable[ref] = _removeInFlight ref
            _saveMessage message for message in updated
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_FAILURE, ({target, ref}) ->
            _removeInFlight ref
            @emit 'change'

        handle ActionTypes.MESSAGE_UNDO_TIMEOUT, ({ref}) ->
            delete _undoable[ref]

        handle ActionTypes.MESSAGE_FETCH_FAILURE, ->
            @emit 'change'

        handle ActionTypes.MESSAGE_SEND_SUCCESS, ({message}) ->
            _saveMessage message
            @emit 'change'


        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (id) ->
            _deleteMessage {id}
            @emit 'change'

        handle ActionTypes.MAILBOX_EXPUNGE, (mailboxID) ->
            _messages = _messages.filter (message) ->
                not (mailboxID of message.get 'mailboxIDs')
            .toOrderedMap()
            @emit 'change'

        handle ActionTypes.SEARCH_SUCCESS, ({result}) ->
            for message in result.rows when message?
                _saveMessage message
            @emit 'change'


    ###
        Public API
    ###
    getCurrentID: ->
        return _currentID

    getByID: (messageID) ->
        messageID ?= @getCurrentID()
        _messages.get messageID

    _getCurrentConversations = (mailboxID) ->
        __conv = {}
        _messages.filter (message) ->
            conversationID = message.get 'conversationID'
            __conv[conversationID] = true unless (exist = __conv[conversationID])
            inMailbox = mailboxID of message.get 'mailboxIDs'
            return inMailbox and not exist
        .toList()

    getMessagesList: (mailboxID) ->
        _currentMessages = _getCurrentConversations(mailboxID)?.toOrderedMap()
        return _currentMessages


    getConversation: (messageID) ->
        messageID ?= @getCurrentID()

        # Get messages from loaded ones
        # Do not fetch if messages isnt loaded yet
        if (conversationID = @getByID(messageID)?.get 'conversationID')
            conversation = _messages.filter (message) ->
                conversationID is message.get 'conversationID'

            # If missing messages, get them
            if conversation?.size isnt @getConversationLength {conversationID}
                action = MessageActions.SHOW
                _fetchMessages {messageID, conversationID, action}

            # Return loaded messages
            return conversation


    getNextConversation: ->
        index = _currentMessages.keyOf @getByID()
        return _currentMessages.get --index


    getPreviousConversation: ->
        index = _currentMessages.keyOf @getByID()
        return _currentMessages.get ++index


    getConversationLength: ({messageID, conversationID}) ->
        unless conversationID
            messageID ?= @getCurrentID()
            if messageID and (message = @getByID messageID)
                conversationID = message.get 'conversationID'

        if conversationID
            return _conversationLength.get conversationID


    # FIXME : move this into RouterStore/RouterGetter
    getUndoableRequest: (ref) ->
        _undoable[ref]

_self = new MessageStore()

module.exports = _self
