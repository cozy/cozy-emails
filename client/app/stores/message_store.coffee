_         = require 'lodash'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes, MessageFlags, MessageFilter} = require '../constants/app_constants'


# FIXME: server side data
#  - The fact that the conversation length is calculated remotely,
#  is not clear for the developer.
#
#  - Most operations, like getting raw messages,
#  don't update conversation length.

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _messages = Immutable.OrderedMap()
    _conversationLength = Immutable.Map()


    _updateMessages = (result={}) ->
        {messages, conversationLength} = _.cloneDeep result

        # This prevent to override local updates
        # with older ones from server
        messages?.forEach (msg) -> _saveMessage msg if msg

        # Shortcut to know conversationLength
        # withount loading all massages of the conversation
        if conversationLength?
            for conversationID, length of conversationLength
                _updateConversationLength conversationID, length


    _shouldUpdateMessage = (message) ->
        value = (_messages.get message?.id)?.get 'updated'
        (not value?) or (not message.updated?) or (value < message.updated)


    _saveMessage = (message) ->
        message = _.cloneDeep message

        # Save reference mailbox into message informations
        message.mailboxID = _.keys(message.mailboxIDs).shift()

        if _shouldUpdateMessage message
            message.date          ?= new Date().toISOString()
            message.createdAt     ?= message.date
            message.flags         ?= []

            attachments            = message.attachments or []
            message.attachments    = Immutable.List attachments.map (file) ->
                Immutable.Map file


            # message loaded from fixtures for test purpose have a docType
            # that may cause some troubles
            delete message.docType

            message.updated = (new Date()).toISOString()
            messageMap = Immutable.Map message
            messageMap.prettyPrint = ->
                return """
                    #{message.id} "#{message.from[0].name}" "#{message.subject}"
                """
            _messages = _messages.set message.id, messageMap


    _deleteMessage = ({messageID}, timestamp) ->
        conversationID = _messages.get(messageID)?.get 'conversationID'

        _messages = _messages.remove messageID

        # Update length counter
        # _conversationLength is only sent by server
        # on fetch request but not update
        # FIXME: should be return into serverResponse
        length = _conversationLength.get conversationID
        _updateConversationLength conversationID, --length


    _updateConversationLength = (conversationID, length) ->
        # Remove conversation
        # if no messages exist into it
        # FIXME: should be return into serverResponse
        if length < 0
            _conversationLength = _conversationLength.remove conversationID
        else
            _conversationLength = _conversationLength.set conversationID, length


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->


        handle ActionTypes.MESSAGE_RESET_REQUEST, ->
            _messages = Immutable.OrderedMap();
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, ({result}) ->
            _updateMessages result
            @emit 'change'


        handle ActionTypes.RECEIVE_RAW_MESSAGE, (message) ->
            _saveMessage message
            @emit 'change'


        handle ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME, (message) ->
            _saveMessage message
            @emit 'change'


        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->
            _updateMessages {messages}
            @emit 'change'


        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, (accountID) ->
            _messages = _messages.filter (message) ->
                accountID isnt message.get 'accountID'
            .toOrderedMap()
            @emit 'change'


        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target}) ->
            _deleteMessage target
            @emit 'change'


        handle ActionTypes.MESSAGE_FLAGS_SUCCESS, ({updated}) ->
            _updateMessages updated
            @emit 'change'


        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({updated}) ->
            _updateMessages updated
            @emit 'change'


        handle ActionTypes.MESSAGE_SEND_SUCCESS, ({message}) ->
            _saveMessage message
            @emit 'change'


        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (messageID) ->
            _deleteMessage {messageID}
            @emit 'change'


        handle ActionTypes.MAILBOX_EXPUNGE, (mailboxID) ->
            _messages = _messages.filter (message) ->
                not (mailboxID of message.get 'mailboxIDs')
            .toOrderedMap()
            @emit 'change'


        handle ActionTypes.SEARCH_SUCCESS, ({result}) ->
            _updateMessages result
            @emit 'change'


        handle ActionTypes.SETTINGS_UPDATE_REQUEST, ({messageID, displayImages=true}) ->
            # Update settings into component,
            # but not definitly into settingsStore
            message = @getByID(messageID)?.set '_displayImages', displayImages
            _messages = _messages.set messageID, message
            @emit 'change'


    ###
        Public API
    ###
    getAll: ->
        _messages


    getByID: (messageID) ->
        _messages.get(messageID)


    isImagesDisplayed: (messageID) ->
        @getByID(messageID)?.get('_displayImages') or false


    isUnread: ({flags=[], message}) ->
        if message and message not instanceof Immutable.Map
            message = Immutable.Map message
        if message?
            flags = message.get('flags') or []
            MessageFlags.SEEN not in flags
        else
            MessageFilter.UNSEEN in flags


    isFlagged: ({flags=[], message}) ->
        if message and message not instanceof Immutable.Map
            message = Immutable.Map message
        if message?
            flags = message.get('flags') or []
            MessageFlags.FLAGGED in flags
        else
            MessageFilter.FLAGGED in flags


    isAttached: ({flags=[], message}) ->
        if message and message not instanceof Immutable.Map
            message = Immutable.Map message
        if message?
            !!message.get('attachments')?.length
        else
            MessageFilter.ATTACH in flags


    getConversation: (conversationID, mailboxID) ->
        _messages.filter (message) ->
            isSameMailbox = mailboxID of message.get 'mailboxIDs'
            isSameConversationID = conversationID is message.get 'conversationID'
            isSameMailbox and isSameConversationID
        .sort (msg1, msg2) ->
            msg1.get('date') < msg2.get('date')
        .toArray()


    getConversationLength: (conversationID) ->
        _conversationLength?.get(conversationID) or null



module.exports = new MessageStore()
