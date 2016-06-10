_         = require 'underscore'
Immutable = require 'immutable'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

Store = require '../libs/flux/store/store'


# {MessageActions, AccountActions, MessageFlags} = require '../constants/app_constants'
{ActionTypes, MessageFlags, MessageFilter} = require '../constants/app_constants'

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _messages = Immutable.OrderedMap()
    _conversationLength = Immutable.Map()


    _updateMessages = (result={}, timestamp) ->
        {messages, conversationLength} = result

        # This prevent to override local updates
        # with older ones from server
        messages?.forEach (msg) -> _saveMessage msg, timestamp if msg

        # Shortcut to know conversationLength
        # withount loading all massages of the conversation
        if conversationLength?
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

            attachments = message.attachments or Immutable.List []

            message.date          ?= new Date().toISOString()
            message.createdAt     ?= message.date
            message.flags         ?= []
            message.hasAttachments = attachments.size > 0
            message.attachments    = Immutable.List attachments.map (file) ->
                Immutable.Map file

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


    _deleteMessage = (messageID) ->
        _messages = _messages.remove messageID



    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.MESSAGE_FETCH_SUCCESS, ({result, timestamp}) ->
            _updateMessages result, timestamp
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


        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target}) ->
            {messageID} = target
            _deleteMessage messageID
            @emit 'change'


        handle ActionTypes.MESSAGE_FLAGS_SUCCESS, ({updated}) ->
            _saveMessage message for message in updated
            @emit 'change'


        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({updated}) ->
            _saveMessage message for message in updated
            @emit 'change'


        handle ActionTypes.MESSAGE_SEND_SUCCESS, ({message}) ->
            _saveMessage message
            @emit 'change'


        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (id) ->
            _deleteMessage id
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


        handle ActionTypes.SETTINGS_UPDATE_REQUEST, ({messageID, displayImages}) ->
            # Update settings into component,
            # but not definitly into settingsStore
            if (message = _messages.get messageID)
                message.__displayImages = displayImages
                _messages = _messages.set messageID, message
            @emit 'change'





    ###
        Public API
    ###
    getAll: ->
        _messages


    getByID: (messageID) ->
        _messages.get(messageID)


    getConversation: (conversationID, mailboxID) ->
        _messages.filter (message) ->
            if mailboxID of message.get 'mailboxIDs'
                return conversationID is message.get 'conversationID'
        .sort (msg1, msg2) ->
            msg1.get('date') < msg2.get('date')
        .toArray()


    getConversationLength: (conversationID, mailboxID) ->
        _conversationLength?.get conversationID



module.exports = new MessageStore()
