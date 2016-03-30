AppDispatcher = require '../app_dispatcher'
Constants = require '../constants/app_constants'
{ActionTypes, MessageFlags, FlagsConstants} = Constants
XHRUtils      = require '../utils/xhr_utils'
AccountStore  = require "../stores/account_store"
MessageStore  = require '../stores/message_store'
SearchStore  = require '../stores/search_store'
refCounter = 1

module.exports = MessageActionCreator =


    receiveRawMessages: (messages) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGES
            value: messages


    receiveRawMessage: (message) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGE
            value: message


    send: (action, message, callback) ->
        conversationID = message.conversationID

        # Message should have a html content
        # event if it is a simple text
        unless message.composeInHTML
            message.html = message.text

        XHRUtils.messageSend message, (error, message) =>
            if error? or not message?
                if 'MESSAGE_SEND' is action
                    msgKo = t "message action sent ko"
                else
                    msgKo = t "message action draft ko"
                LayoutActionCreator.alertError "#{msgKo} #{error}"
                return

            if conversationID and action in ['UNMOUNT', 'MESSAGE_SEND']
                @fetchConversation conversationID

            AppDispatcher.handleViewAction
                type: ActionTypes.MESSAGE_SEND
                value: message

            if callback?
                callback error, message


    # set conv to true to update current conversation ID
    setCurrent: (messageID, conv) ->
        if messageID? and typeof messageID isnt 'string'
            messageID = messageID.get 'id'
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_CURRENT
            value:
                messageID: messageID
                conv: conv

    fetchMoreOfCurrentQuery: ->
        url = MessageStore.getNextUrl()
        return unless url
        mailboxID = AccountStore.getSelectedMailbox().get 'id'

        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {mailboxID}

        ts = Date.now()
        XHRUtils.fetchMessagesByFolder url, (err, rawMsg) ->
            if err?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {mailboxID}
            else
                # This prevent to override local updates with older ones
                # from server
                rawMsg.messages.forEach (msg) -> msg.updated = ts
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {mailboxID, fetchResult: rawMsg}


    fetchSearchResults: (accountID, search) ->
        return null if search is '-'
        url = SearchStore.getNextSearchUrl()
        return unless url

        AppDispatcher.handleViewAction
            type: ActionTypes.SEARCH_REQUEST
            value: {search}

        XHRUtils.search url, (error, searchResults) ->
            if error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.SEARCH_FAILURE
                    value: {error}
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.SEARCH_SUCCESS
                    value: {searchResults}

    fetchConversation: (conversationID) ->

        AppDispatcher.handleViewAction
            type: ActionTypes.CONVERSATION_FETCH_REQUEST
            value: {conversationID}

        XHRUtils.fetchConversation conversationID, (error, updated) ->
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.CONVERSATION_FETCH_FAILURE
                    value: {error}
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.CONVERSATION_FETCH_SUCCESS
                    value: {updated}


    # Immediately synchronise some messages with the server
    # Used if one of the action fail
    recover: (target, ref) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_RECOVER_REQUEST
            value: {ref}

        XHRUtils.batchFetch target, (err, messages) ->
            if err
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_RECOVER_FAILURE
                    value: {ref}
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_RECOVER_SUCCESS
                    value: {ref}


    refreshMailbox: (mailboxID) ->
        unless AccountStore.isMailboxRefreshing(mailboxID)
            AppDispatcher.handleViewAction
                type: ActionTypes.REFRESH_REQUEST
                value: {mailboxID}

            account = AccountStore.getSelected()
            options = deep: account.get('draftMailbox') is mailboxID

            XHRUtils.refreshMailbox mailboxID, options, (error, updated) ->
                if error?
                    AppDispatcher.handleViewAction
                        type: ActionTypes.REFRESH_FAILURE
                        value: {mailboxID, error}
                else
                    AppDispatcher.handleViewAction
                        type: ActionTypes.REFRESH_SUCCESS
                        value: {mailboxID, updated}


    # Delete message(s)
    # target:
    #  - messageID or messageIDs or conversationIDs or conversationIDs
    #  - isDraft?
    #  - silent? (don't display confirmation message when deleting
    #    an empty draft)
    delete: (target, callback) ->
        ref = refCounter++
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_TRASH_REQUEST
            value: {target, ref}

        # send request
        ts = Date.now()
        XHRUtils.batchDelete target, (error, updated) =>
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_TRASH_FAILURE
                    value: {target, ref, error}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else if updated?.length
                msg.updated = ts for msg in updated
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_TRASH_SUCCESS
                    value: {target, ref, updated}

            callback? error, updated


    move: (target, from, to, callback) ->
        ref = refCounter++
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_MOVE_REQUEST
            value: {target, ref, from, to}

        ts = Date.now()
        # send request
        XHRUtils.batchMove target, from, to, (error, updated) =>
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_MOVE_FAILURE
                    value: {target, ref, error}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                msg.updated = ts for msg in updated
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_MOVE_SUCCESS
                    value: {target, ref, updated}

            callback? error, updated

    mark: (target, flagAction, callback) ->
        ref = refCounter++

        switch flagAction
            when FlagsConstants.SEEN
                op = 'batchAddFlag'
                flag = FlagsConstants.SEEN
            when FlagsConstants.FLAGGED
                op = 'batchAddFlag'
                flag = FlagsConstants.FLAGGED
            when FlagsConstants.UNSEEN
                op = 'batchRemoveFlag'
                flag = FlagsConstants.SEEN
            when FlagsConstants.NOFLAG
                op = 'batchRemoveFlag'
                flag = FlagsConstants.FLAGGED
            else
                throw new Error "Wrong usage : unrecognized FlagsConstants"

        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, ref, op, flag, flagAction}

        ts = Date.now()

        XHRUtils[op] target, flag, (error, updated) =>
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, ref, error, op, flag, flagAction}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                msg.updated = ts for msg in updated
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, ref, updated, op, flag, flagAction}

            callback? error, updated

    undo: (ref) ->

        request = MessageStore.getUndoableRequest ref
        {messages, type, from, to, target, trashBoxID} = request
        reverseAction = []

        oldto = if type is 'move' then to else trashBoxID
        bydest = {}
        # messages are the old messages
        messages.forEach (message) ->
            dest = (boxid for boxid, uid of message.get('mailboxIDs'))
            destString = dest.sort().join(',')
            bydest[destString] ?= {to: dest, from: oldto, messageIDs: []}
            bydest[destString].messageIDs.push message.get('id')

        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_UNDO_START
            value: {ref}

        _loopSeries bydest, (request, dest, next) ->
            {to, from, messageIDs} = request
            target = {messageIDs, silent: true}
            MessageActionCreator.move target, from, to, next
        , (error) ->
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_UNDO_FAILURE
                    value: {ref}

                # we dont know if some succeeded or not,
                # in doubt, recover the changed to messages to sync with
                # server
                @recover target, ref
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_UNDO_SUCCESS
                    value: {ref}


_loopSeries = (obj, iterator, done) ->
    keys = Object.keys(obj)
    i = 0
    do step = ->
        key = keys[i]
        iterator obj[key], key, (err) ->
            return done err if err
            return done null if ++i is keys.length
            step()
