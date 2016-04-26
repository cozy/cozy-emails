_         = require 'underscore'
Immutable = require 'immutable'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

Store = require '../libs/flux/store/store'

{ActionTypes, MessageActions} = require '../constants/app_constants'

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _messages = Immutable.OrderedMap()
    _conversationLength = Immutable.Map()

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


    _updateMessages = (result={}, timestamp) ->
        {messages, conversationLength} = result

        # This prevent to override local updates
        # with older ones from server
        messages?.forEach (message) -> _saveMessage message, timestamp

        # Shortcut to know conversationLength
        # withount loading all massages of the conversation
        if (conversationLength)
            for conversationID, length of conversationLength
                _conversationLength = _conversationLength.set conversationID, length


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


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, ({error, result, timestamp}) ->
            _updateMessages result, timestamp unless error
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

        handle ActionTypes.REFRESH_SUCCESS, ->
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
    getAll: ->
        _messages

    getByID: (messageID) ->
        _messages.get(messageID)


    getConversation: (conversationID) ->
        result = []
        _messages.filter (message) ->
            if (conversationID is message.get 'conversationID')
                result.push message
        result


    getConversationLength: (conversationID) ->
        _conversationLength?.get conversationID


    # FIXME : move this into RouterStore/RouterGetter
    getUndoableRequest: (ref) ->
        _undoable[ref]


module.exports = new MessageStore()
