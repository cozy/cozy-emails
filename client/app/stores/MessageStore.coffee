Store = require '../libs/flux/store/Store'
AppDispatcher = require '../AppDispatcher'

AccountStore = require './AccountStore'

{ActionTypes}       = require '../constants/AppConstants'

LayoutActionCreator = require '../actions/LayoutActionCreator'

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Creates an OrderedMap of messages
    _messages = Immutable.Sequence()

        # sets message ID as index
        .mapKeys (_, message) -> message.id

        # makes message object an immutable Map
        .map (message) -> Immutable.fromJS message
        .toOrderedMap()


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MESSAGE, onReceiveRawMessage = (message, silent = false) ->
            # create or update
            message.hasAttachments = message.attachments.length > 0
            message = Immutable.Map message
            message.getReplyToAddress = ->
                reply = this.get 'replyTo'
                reply = if reply.length == 0 then this.get 'from' else reply
                return reply
            _messages = _messages.set message.get('id'), message

            @emit 'change' unless silent

        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->
            onReceiveRawMessage message, true for message in messages
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            messages = @getMessagesByAccount accountID
            _messages = _messages.withMutations (map) ->
                messages.forEach (message) -> map.remove message.get 'id'

            @emit 'change'

        handle ActionTypes.SEND_MESSAGE, (message) ->
            # message should have been copied to Sent mailbox,
            # so it seems reasonable to emit change
            @emit 'change'


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
    getMessagesByAccount: (accountID, first = null, last = null) ->
        sequence = _messages.filter (message) -> message.get('account') is accountID
        if first? and last?
            sequence = sequence.slice first, last

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
    getMessagesByMailbox: (mailboxID, first = null, last = null) ->
        sequence = _messages.filter (message) -> mailboxID in message.get('mailboxIDs')
        if first? and last?
            sequence = sequence.slice first, last

        # sequences are lazy so we need .toOrderedMap() to actually execute it
        return sequence.toOrderedMap()

    getMessagesCountByMailbox: (mailboxID) ->
        return @getMessagesByMailbox(mailboxID).count()

    getMessagesByConversation: (messageID) ->
        idsToLook = [messageID]
        conversation = []
        while idToLook = idsToLook.pop()
            conversation.push @getByID idToLook
            temp = _messages.filter (message) -> message.get('inReplyTo') is idToLook
            idsToLook = idsToLook.concat temp.map((item) -> item.get('id')).toArray()

        return conversation

module.exports = new MessageStore()
