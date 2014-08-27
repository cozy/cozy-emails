Store = require '../libs/flux/store/Store'
AppDispatcher = require '../AppDispatcher'

AccountStore = require './AccountStore'

{ActionTypes} = require '../constants/AppConstants'

# Used in production instead of real data during development early stage
#fixtures = require '../../../tests/fixtures/messages.json'
#fixtures = fixtures.concat require '../../../tests/fixtures/messages_generated.json'
fixtures = [] # @FIXME
_idGenerator = 0

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Loads from fixtures if necessary
    if not window.accounts? or window.accounts.length is 0
        messages = fixtures
        # messages are sorted server-side so we manually sort them
        # if we use fixtures
        messages.sort (e1, e2) ->
            if e1.createdAt < e2.createdAt
                return 1
            else if e1.createdAt > e2.createdAt
                return -1
            else
                return 0
    else
        messages = []

    # Creates an OrderedMap of messages
    _message = Immutable.Sequence messages

        # patch to use fixtures (some of them don't have an ID)
        .map (message) ->
            message.id = message.id or message._id or 'id_' + _idGenerator++
            return message

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

        handle ActionTypes.RECEIVE_RAW_MESSAGE, (messages) ->
            onReceiveRawmessage message, true for message in messages
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

    getMessagesByAccount: (accountID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _message.filter (message) -> message.get('mailbox') is accountID
        .toOrderedMap()

    getMessagesByMailbox: (mailboxID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _message.filter (message) -> message.get('imapFolder') is mailboxID
        .toOrderedMap()

    getMessagesByConversation: (messageID) ->
        idsToLook = [messageID]
        conversation = []
        while idToLook = idsToLook.pop()
            conversation.push @getByID idToLook
            temp = _message.filter (message) -> message.get('inReplyTo') is idToLook
            idsToLook = idsToLook.concat temp.map((item) -> item.get('id')).toArray()

        return conversation

module.exports = new MessageStore()
