_         = require 'underscore'
Immutable = require 'immutable'
XHRUtils = require '../utils/xhr_utils'

AppDispatcher = require '../app_dispatcher'

Store = require '../libs/flux/store/store'
AccountStore = require './account_store'
RouterStore = require '../stores/router_store'

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
        AccountStore.getMailbox().get('nbTotal') is _currentMessages?.size

    _fetchMessage = (params={}) ->

        {messageID, conversationID, action} = params
        mailboxID = AccountStore.getMailboxID()
        action ?= MessageActions.SHOW_ALL
        timestamp = Date.now()

        callback = (error, result) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, mailboxID}
            else
                # This prevent to override local updates
                # with older ones from server
                messages = if _.isArray(result) then result else result.messages
                messages?.forEach (message) -> _saveMessage message, timestamp

                if (conversationLength = result?.conversationLength)
                    for conversationID, length of conversationLength
                        _saveConversationLength conversationID, length

                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {action, result, messageID}

                # Message doesnt belong to the result
                # Go fetch next page
                if not _self.isAllLoaded() and messageID and
                        not _messages?.get messageID
                    action = MessageActions.PAGE_NEXT
                    AppDispatcher.handleViewAction
                        type: ActionTypes.MESSAGE_FETCH_REQUEST
                        value: {action, messageID}

        if action is MessageActions.PAGE_NEXT
            action = MessageActions.SHOW_ALL
            messages = _currentMessages
            url = RouterStore.getNextURL {action, messages, messageID}
            XHRUtils.fetchMessagesByFolder url, callback

        else if action is MessageActions.SHOW_ALL
            mailboxID = AccountStore.getMailboxID()
            url = RouterStore.getCurrentURL {action, mailboxID}
            XHRUtils.fetchMessagesByFolder url, callback

        else
            XHRUtils.fetchConversation conversationID, callback

    _saveMessage = (message, timestamp) ->
        oldmsg = _messages.get message.id
        updated = oldmsg?.get 'updated'

        # only update message if new version is newer than
        # the one currently stored
        message.updated = timestamp if timestamp

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

    _deleteMessage = (message) ->
        _messages = _messages.remove message.id


    _saveConversationLength = (conversationID, length) ->
        _conversationLength = _conversationLength.set conversationID, length

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ROUTE_CHANGE, (value) ->
            if value.action is MessageActions.SHOW_ALL
                _setCurrentID = AccountStore.getSelectedOrDefault()?.get 'id'
                messageID = @getCurrentID()
                _fetchMessage {action: MessageActions.SHOW_ALL, messageID}

            if value.query and RouterStore.isResetFilter()?
                _messages = _messages.clear()

            _setCurrentID messageID if messageID

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

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, updated, ref, next}) ->
            _undoable[ref] = _removeInFlight ref
            for message in updated
                if message._deleted
                    _deleteMessage message
                    _setCurrentID next?.get('id')
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

        handle ActionTypes.MESSAGE_SEND_SUCCESS, ({message, action}) ->
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
        _messages.get messageID

    _getCurrentConversations = (mailboxID) ->
        __conv = {}
        _messages.filter (message) ->
            conversationID = message.get 'conversationID'
            __conv[conversationID] = true unless (exist = __conv[conversationID])
            inMailbox = mailboxID of message.get 'mailboxIDs'
            return inMailbox and not exist
        .toList()

    getMessagesToDisplay: (mailboxID) ->
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
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FETCH_REQUEST
                    value: {messageID, conversationID, action}

            # Return loaded messages
            return conversation

    getConversationLength: ({messageID, conversationID}) ->
        unless conversationID
            messageID ?= @getCurrentID()
            if messageID and (message = @getByID messageID)
                conversationID = message.get 'conversationID'

        if conversationID
            return _conversationLength.get conversationID



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
    getMessage: (param={}) ->
        # FIXME : vérifier les params rentrant
        # ne passer que par messageID si possible
        {messageID, conversationID, messages, conversationIDs} = param

        messages ?= _currentMessages

        # In this case, we just want
        # next/previous message from a selection
        # then remove selected messages from the list
        if conversationIDs?
            conversationID = conversationIDs[0]
            messages = messages
                .filter (message) ->
                    id = message.get 'conversationID'
                    index = conversationIDs.indexOf id
                    return index is -1
                .toList()

        unless conversationID
            messageID ?= @getCurrentID()
            message = @getByID messageID
            conversationID = message?.get 'conversationID'

        # If no specific action is precised
        # return contextual conversations
        unless _.isFunction param.transform
            return @getByID messageID

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

    ###*
    * Get earlier conversation displayed after current
    *
    * @param {Function}  transform
    *
    * @return {List}
    ###
    getNextConversation: (params={}) ->
        transform = (index) -> --index
        @getMessage _.extend params, {transform}

    # FIXME : move this into RouterStore/RouterGetter
    getUndoableRequest: (ref) ->
        _undoable[ref]

_self = new MessageStore()

module.exports = _self
