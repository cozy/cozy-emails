Store = require '../libs/flux/store/Store'
AppDispatcher = require '../AppDispatcher'

AccountStore = require './AccountStore'

{ActionTypes} = require '../constants/AppConstants'

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Creates an OrderedMap of messages
    _message = Immutable.Sequence()

        # sets message ID as index
        .mapKeys (_, message) -> message.id

        # makes message object an immutable Map
        .map (message) -> Immutable.Map message
        .toOrderedMap()

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MESSAGE, onReceiveRawMessage = (message, silent = false) ->
            # create or update
            message = Immutable.Map message
            _message = _message.set message.get('id'), message

            @emit 'change' unless silent

        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->
            onReceiveRawMessage message, true for message in messages
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            messages = @getMessagesByAccount accountID
            _message = _message.withMutations (map) ->
                messages.forEach (message) -> map.remove message.get 'id'

            @emit 'change'


    ###
        Public API
    ###
    getAll: -> return _message

    getByID: (messageID) -> _message.get(messageID) or null

    ###*
    * Get messages from account
    *
    * @param {String} accountID
    * @param {Number} first     index of first message
    * @param {Number} last      index of last message
    *
    * @return {Array}
    ###
    getMessagesByAccount: (accountID, first, last) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _message.filter (message) -> message.get('account') is accountID
        .toOrderedMap()
        .slice(first, last)

    getMessagesCountByAccount: (accountID) ->
        _message.filter (message) -> message.get('account') is accountID
        .count()

    ###*
    * Get messages from mailbox
    *
    * @param {String} mailboxID
    * @param {Number} first     index of first message
    * @param {Number} last      index of last message
    *
    * @return {Array}
    ###
    getMessagesByMailbox: (mailboxID, first, last) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _message.filter (message) -> mailboxID in message.get('mailboxIDs')
        .toOrderedMap()
        .slice(first, last)

    getMessagesCountByMailbox: (mailboxID, first, last) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _message.filter (message) -> mailboxID in message.get('mailboxIDs')
        .count()

    getMessagesByConversation: (messageID) ->
        idsToLook = [messageID]
        conversation = []
        while idToLook = idsToLook.pop()
            conversation.push @getByID idToLook
            temp = _message.filter (message) -> message.get('inReplyTo') is idToLook
            idsToLook = idsToLook.concat temp.map((item) -> item.get('id')).toArray()

        return conversation

module.exports = new MessageStore()
