_         = require 'underscore'
Immutable = require 'immutable'
XHRUtils = require '../utils/xhr_utils'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

Store = require '../libs/flux/store/store'


{changeRealtimeScope} = require '../utils/realtime_utils'

{ActionTypes, MessageActions} = require '../constants/app_constants'

EPOCH = (new Date(0)).toISOString()

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


    # Get Emails from Server
    # This is a read data pattern
    # ActionCreator is a write data pattern
    _fetchMessages = (params={}) ->
        {messageID, conversationID, url} = params
        timestamp = Date.now()

        callback = (error, result) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, url}
            else
                # This prevent to override local updates
                # with older ones from server
                messages = if _.isArray(result) then result else result.messages
                messages?.forEach (message) -> _saveMessage message, timestamp

                # Shortcut to know conversationLength
                # withount loading all massages of the conversation
                if (conversationLength = result?.conversationLength)
                    for conversationID, length of conversationLength
                        _saveConversationLength conversationID, length

                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {messages, messageID}

        if url
            XHRUtils.fetchMessagesByFolder url, callback
        else
            XHRUtils.fetchConversation {messageID, conversationID}, callback


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

        handle ActionTypes.MESSAGE_FETCH_REQUEST, (payload) ->
            _fetchMessages payload
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, ({messages, mailboxID}) ->
            lastdate = _messages.last()?.get 'date'
            before = unless messages then EPOCH else lastdate
            changeRealtimeScope {mailboxID, before}

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


    getUndoableRequest: (ref) ->
        _undoable[ref]


module.exports = new MessageStore()
