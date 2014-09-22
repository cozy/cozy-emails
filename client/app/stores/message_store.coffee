Store = require '../libs/flux/store/store'
AppDispatcher = require '../app_dispatcher'

AccountStore = require './account_store'

{ActionTypes}       = require '../constants/app_constants'

LayoutActionCreator = require '../actions/layout_action_creator'

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

        handle ActionTypes.RECEIVE_RAW_MESSAGE, onReceiveRawMessage = \
        (message, silent = false) ->
            # create or update
            message.hasAttachments = Array.isArray(message.attachments) and \
                                     message.attachments.length > 0
            if not message.createdAt?
                message.createdAt = message.date
            message = Immutable.Map message
            message.getReplyToAddress = ->
                reply = this.get 'replyTo'
                from = this.get 'from'
                reply = if not reply? or reply.length is 0 then from else reply
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

        handle ActionTypes.MESSAGE_SEND, (message) ->
            # message should have been copied to Sent mailbox,
            # so it seems reasonable to emit change
            @emit 'change'

        handle ActionTypes.MESSAGE_DELETE, (message) ->
            # message should have been deleted from current mailbox
            # and copied to trash
            # so it seems reasonable to emit change
            @emit 'change'

        handle ActionTypes.MESSAGE_BOXES, (message) ->
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAG, (message) ->
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
        sequence = _messages.filter (message) ->
            return message.get('account') is accountID
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
        sequence = _messages.filter (message) ->
            return mailboxID in Object.keys message.get 'mailboxIDs'

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
            temp = _messages.filter (message) ->
                return message.get('inReplyTo') is idToLook
            newIdsToLook = temp.map((item) -> item.get('id')).toArray()
            idsToLook = idsToLook.concat newIdsToLook

        return conversation

module.exports = new MessageStore()
