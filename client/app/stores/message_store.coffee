_         = require 'underscore'
Immutable = require 'immutable'
XHRUtils = require '../utils/xhr_utils'

AppDispatcher = require '../app_dispatcher'

Store = require '../libs/flux/store/store'
AccountStore = require './account_store'
RouterStore = require '../stores/router_store'

SocketUtils = require '../utils/socketio_utils'
{sortByDate} = require '../utils/misc'

{ActionTypes, MessageFlags} = require '../constants/app_constants'

EPOCH = (new Date(0)).toISOString()

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _messages = Immutable.OrderedMap()
    _conversations = Immutable.Map()

    _fetching = 0

    _conversation = null
    _currentID = null

    _inFlightByRef = {}
    _inFlightByMessageID = {}
    _undoable = {}


    _setCurrentID = (messageID) ->
        _currentID = messageID

    _addInFlight = (request) ->
        console.log 'ADD', request.type, request.ref
        # _inFlightByRef[request.ref] = request
        # request.messages.forEach (message) ->
        #     id = message.get('id')
        #     requests = (_inFlightByMessageID[id] ?= [])
        #     requests.push request

    _removeInFlight = (ref) ->
        console.log 'REMOVE', ref
        # request = _inFlightByRef[ref]
        # delete _inFlightByRef[ref]
        # request.messages.forEach (message) ->
        #     id = message.get('id')
        #     requests = _inFlightByMessageID[id]
        #     _inFlightByMessageID[id] = _.without requests, request
        # return request

    _transformMessageWithRequest = (message, request) ->
        switch request.type
            when 'trash'
                {trashBoxID} = request
                if _isDraft(message)
                    message = null
                else
                    newMailboxIds = {}
                    newMailboxIds[trashBoxID] = -1
                    message = message.set 'mailboxIDs', newMailboxIds

            when 'move'
                mailboxIDs = message.get('mailboxIDs')
                {from, to} = request
                newMailboxIds = {}
                newMailboxIds[key] = value for key, value of mailboxIDs
                delete newMailboxIds[from]
                newMailboxIds[to] ?= -1
                message = message.set 'mailboxIDs', newMailboxIds

            when 'flag'
                flags = message.get('flags')
                {flag, op} = request
                if op is 'batchAddFlag' and flag not in flags
                    message = message.set 'flags', flags.concat [flag]

                else if op is 'batchRemoveFlag' and flag in flags
                    message = message.set 'flags', _.without flags, flag

        return message

    _getMixed = (target) ->
        if target.messageID
            return [_messages.get(target.messageID)]
        else if target.messageIDs
            return target.messageIDs.map (id) -> _messages.get id
        else if target.conversationID
            return _messages.filter (message) ->
                message.get('conversationID') is target.conversationID
            .toArray()
        else if target.messageIDs
            return _messages.filter (message) ->
                message.get('conversationID') in target.messageIDs
            .toArray()
        else throw new Error 'Wrong Usage : unrecognized target AS.getMixed'

    _isDraft = (message, draftMailbox) ->
        mailboxIDs = message.get 'mailboxIDs'
        mailboxIDs[draftMailbox] or MessageFlags.DRAFT in message.get('flags')

    _fetchMessage = (params={}) ->
        return if _self.isFetching()

        ts = Date.now()
        mailboxID = AccountStore.getSelectedMailbox()?.get 'id'
        messageID = params.messageID
        _fetching++

        callback = (err, rawMsg) ->
            _fetching--
            if err?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {mailboxID}
            else
                messages = if _.isArray(rawMsg) then rawMsg else rawMsg.messages
                next = rawMsg?.links?.next

                # This prevent to override local updates with older ones
                # from server
                rawMsg.messages?.forEach (msg) -> msg.updated = ts
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {mailboxID, messages}

                AppDispatcher.handleViewAction
                    type: ActionTypes.SAVE_NEXT_URL
                    value: next

        if messageID
            XHRUtils.fetchConversation {messageID}, callback
        else
            XHRUtils.fetchMessagesByFolder params, callback

    _computeMailboxDiff = (oldmsg, newmsg) ->
        return {} unless oldmsg
        changed = false

        wasRead = MessageFlags.SEEN in oldmsg.get 'flags'
        isRead = MessageFlags.SEEN in newmsg.get 'flags'

        accountID = newmsg.get 'accountID'
        oldboxes = Object.keys oldmsg.get 'mailboxIDs'
        newboxes = Object.keys newmsg.get 'mailboxIDs'

        out = {}
        added = _.difference(newboxes, oldboxes)
        added.forEach (boxid) ->
            changed = true
            out[boxid] = nbTotal: +1, nbUnread: if isRead then 0 else +1

        removed = _.difference oldboxes, newboxes
        removed.forEach (boxid) ->
            changed = true
            out[boxid] = nbTotal: -1, nbUnread: if wasRead then -1 else 0

        stayed = _.intersection oldboxes, newboxes
        deltaUnread = if wasRead and not isRead then +1
        else if not wasRead and isRead then -1
        else 0

        if deltaUnread isnt 0
            changed = true

        out[accountID] = nbUnread: deltaUnread

        stayed.forEach (boxid) ->
            out[boxid] = nbTotal: 0, nbUnread: deltaUnread

        if changed
            return out
        else
            return false

    _saveMessage = (message) ->
        oldmsg = _messages.get message.id
        updated = oldmsg?.get 'updated'

        # only update message if new version is newer than
        # the one currently stored
        if not (message.updated? and updated? and updated > message.updated) and
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

            # FIXME : trier ici par conversation
            # et associer la propriété messageIDs
            # pour garder la trace des messages
            # TODO : garder _messages
            # mais faire aussi un _conversations
            _messages = _messages.set message.id, messageMap

            # Save Conversations
            conversationID = message.conversationID
            conversation = _conversations.get(conversationID)
            conversation ?= Immutable.List()
            if -1 is conversation.indexOf(message.id)
                conversation = conversation.push message.id
            _conversations = _conversations.set conversationID, conversation

            if message.accountID? and (diff = _computeMailboxDiff oldmsg, messageMap)
                AccountStore._applyMailboxDiff message.accountID, diff

    # FIXME : mettre à jour ici les conversations
    # supprimer l'occurence de conversationID
    _deleteMessage = (message) ->
        _messages = _messages.remove message.id


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

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

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            _messages = _messages.filter (message) ->
                accountID isnt message.get 'accountID'
            .toOrderedMap()
            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_REQUEST, ({target, ref}) ->
            messages = @getMixed target
            account = AccountStore.getByID messages[0]?.get('accountID')
            trashBoxID = account?.get? 'trashMailbox'
            _addInFlight {type: 'trash', trashBoxID, messages, ref}

            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, updated, ref}) ->
            _undoable[ref] =_removeInFlight ref
            for message in updated
                if message._deleted
                    _deleteMessage message
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
            messages = @getMixed target
            _addInFlight {type: 'move', from, to, messages, ref}
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({target, updated, ref}) ->
            _undoable[ref] =_removeInFlight ref
            _saveMessage message for message in updated
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_FAILURE, ({target, ref}) ->
            _removeInFlight ref
            @emit 'change'

        handle ActionTypes.MESSAGE_UNDO_TIMEOUT, ({ref}) ->
            delete _undoable[ref]

        handle ActionTypes.MESSAGE_FETCH_REQUEST, (param)->
            _fetchMessage param
            @emit 'change'

        handle ActionTypes.MESSAGE_FETCH_FAILURE, ->
            @emit 'change'

        # FIXME : gérer ça dans messageActionCreate
        handle ActionTypes.MESSAGE_FETCH_SUCCESS, (result) ->
            for message in result.messages when message?
                _saveMessage message

            unless result.messages.length
                # either end of list or no messages, we stay open
                SocketUtils.changeRealtimeScope result.mailboxID, EPOCH

            else if lastdate = _messages.last()?.get('date')
                SocketUtils.changeRealtimeScope result.mailboxID, lastdate

            @emit 'change'

        # handle ActionTypes.CONVERSATION_FETCH_SUCCESS, ({updated}) ->
        #     for message in updated
        #         _saveMessage message
        #     @emit 'change'

        handle ActionTypes.MESSAGE_SEND, (message) ->
            _saveMessage message
            @emit 'change'

        handle ActionTypes.QUERY_PARAMETER_CHANGED, ->
            AppDispatcher.waitFor [RouterStore.dispatchToken]
            if RouterStore.isResetFilter()?
                _messages = _messages.clear()
            @emit 'change'


        # FIXME : charger également la conversation
        handle ActionTypes.MESSAGE_CURRENT, (param) ->
            _setCurrentID param.messageID
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, ->
            _setCurrentID null
            @emit 'change'

        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (id) ->
            _deleteMessage {id}
            @emit 'change'

        handle ActionTypes.MAILBOX_EXPUNGE, (mailboxID) ->
            _messages = _messages.filter (message) ->
                not (mailboxID of message.get 'mailboxIDs')
            .toOrderedMap()
            @emit 'change'

        handle ActionTypes.SEARCH_SUCCESS, ({searchResults}) ->
            for message in searchResults.rows when message?
                _saveMessage message
            @emit 'change'


    ###
        Public API
    ###
    getCurrentID: ->
        return _currentID

    getByID: (messageID) ->
        if (message = _messages.get messageID)
            return _addMessageIDs message

    _addMessageIDs = (message) ->
        conversationID = message.get 'conversationID'
        message.set 'messageIDs', _conversations.get conversationID

    getCurrentConversations: (mailboxID) ->
        __conv = {}
        _messages.filter (message) ->
            conversationID = message.get 'conversationID'
            __conv[conversationID] = true unless (exist = __conv[conversationID])
            inMailbox = mailboxID of message.get 'mailboxIDs'
            return inMailbox and not exist
        .map _addMessageIDs
        .toList()

    # Retrieve a batch of message with various criteria
    # target - is an {Object} wi h a property messageID or messageIDs or
    #          conversationID or messageIDs
    # target.accountID is needed to success Delete
    #
    # Returns an {Array} of {Immutable.Map} messages
    getMixed: (target) ->
        messages = _getMixed target
        target.accountID = messages[0].get('accountID')
        messages

    isFetching: ->
        return _fetching > 0

    # FIXME : move this into RouterStore/RouterGetter
    getUndoableRequest: (ref) ->
        _undoable[ref]

_self = new MessageStore()

module.exports = _self
