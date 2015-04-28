AppDispatcher = require '../app_dispatcher'
Constants = require '../constants/app_constants'
{ActionTypes, MessageFlags, FlagsConstants} = Constants
XHRUtils      = require '../utils/xhr_utils'
AccountStore  = require "../stores/account_store"
MessageStore  = require '../stores/message_store'
LAC = undefined

module.exports = MessageActionCreator =

    receiveRawMessages: (messages) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGES
            value: messages

    receiveRawMessage: (message) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MESSAGE
            value: message

    setFetching: (fetching) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_FETCHING
            value: fetching

    send: (message, callback) ->
        XHRUtils.messageSend message, (error, message) ->
            if not error?
                AppDispatcher.handleViewAction
                    type: ActionTypes.MESSAGE_SEND
                    value: message
            callback? error, message

    # set conv to true to update current conversation ID
    setCurrent: (messageID, conv) ->
        if typeof messageID isnt 'string'
            messageID = messageID.get 'id'
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_CURRENT
            value:
                messageID: messageID
                conv: conv

    fetchConversation: (conversationID) ->
        XHRUtils.fetchConversation conversationID, (err, rawMessages) ->
            if not err?
                MessageActionCreator.receiveRawMessages rawMessages

    # Immediately synchronise some messages with the server
    refresh: (target) ->
        XHRUtils.batchFetch target, (err, messages) ->
            if err
                LAC.alertError err
            else
                MessageActionCreator.receiveRawMessages messages


    delete: (target, callback) ->
        messages = _localDelete target

        # send request
        XHRUtils.batchDelete target, (err, updated) ->

            alertMsg = _getNotification target, messages, 'delete', err
            if err
                # we cant know which succeeded or not,
                # refetch the batch from the server for update
                MessageActionCreator.refresh target
                LAC.alertError alertMsg
            else
                MessageActionCreator.receiveRawMessagesupdated
                LAC.notify alertMsg,
                    autoclose: true,
                    actions: [
                        label: t 'conversation undelete'
                        onClick: -> MessageActionCreator.undelete()
                    ]

            callback? err, updated


    move: (target, from, to, callback) ->
        messages = _localMove target, from, to

        # send request
        XHRUtils.batchMove target, from, to, (err, updated) ->
            alertMsg = _getNotification target, messages, 'move', err
            if err
                # we cant know which succeeded or not,
                # refetch the batch from the server for update
                MessageActionCreator.refresh target
                LAC.alertError alertMsg
            else
                MessageActionCreator.receiveRawMessages updated
                unless target.undeleting
                    LAC.notify alertMsg,
                        autoclose: true,
                        actions: [
                            label: t 'conversation undelete'
                            onClick: -> MessageActionCreator.undelete()
                        ]

            callback? err, updated

    mark: (target, flag, callback) ->
        {op, flag} = _convertFlagToOp flag


        _localMark target, op, flag


        afterUpdate = (err, updated) ->
            if err
                MessageActionCreator.refresh target
                LAC.alertError err
            else
                MessageActionCreator.receiveRawMessages updated

            callback? err, updated

        if op is 'add'
            XHRUtils.batchAddFlag target, flag, afterUpdate
        else if op is 'remove'
            XHRUtils.batchRemoveFlag target, flag, afterUpdate
        else
            throw new Error "Wrong usage : unrecognized FlagsConstants"

    undelete: ->
        lastBatch = MessageStore.getPrevAction()
        if lastBatch
            done = 0
            for action in lastBatch.actions
                options = {messageID: action.id, undeleting: true}
                done++
                @move options, action.to, action.from, (err) ->
                    if err
                        LAC.notify t('message undelete error')
                    else if --done is 0
                        LAC.notify t('message undelete ok'),
                            autoclose: true

# circular, import after
LAC = require './layout_action_creator'


_getNotification = (target, messages, action, err) ->

    first = messages[0]
    subject = first?.get?('subject') or first?.subject

    if target.messageID
        type = 'message'
    else if target.conversationID
        type = 'conversation'
    else if target.conversationIDs
        type = 'conversations'
        smart_count = target.conversationIDs.length
    else if target.messageIDs
        type = 'messages'
        smart_count = target.messageIDs.length
    else throw new Error 'Wrong Usage : unrecognized target MAC.getNotif'

    if err
        ok = 'ko'
        errMsg = ': ' + err.message or err
    else
        ok = 'ok'
        errMsg = ''


    return t "#{type} #{action} #{ok}",
        error: errMsg
        subject: subject
        smart_count: smart_count


_convertFlagToOp = (flag) ->
    if flag in [FlagsConstants.SEEN, FlagsConstants.FLAGGED]
        op = 'add'
    else if flag is FlagsConstants.NOFLAG
        op = 'remove'
        flag = FlagsConstants.FLAGGED
    else if flag is FlagsConstants.UNSEEN
        op = 'remove'
        flag = FlagsConstants.SEEN

    return {op, flag}


_fixCurrentMessage = (target) ->
    # open next message if the deleted / moved one was open ###
    messageIDs = target.messageIDs or [target.messageID]
    currentMessage = MessageStore.getCurrentID() or 'not-null'
    conversationIDs = target.conversationIDs or [target.conversationID]
    currentConversation = MessageStore.getCurrentConversationID() or 'not-null'
    if currentMessage in messageIDs
        next = MessageStore.getNextOrPrevious false
        # MessageActionCreator.setCurrent next.get('id'), true
        window.cozyMails.messageDisplay next, false
    else if currentConversation in conversationIDs
        next = MessageStore.getNextOrPrevious true
        # MessageActionCreator.setCurrent next.get('id'), true
        window.cozyMails.messageDisplay next, false



_localMark = (target, op, flag) ->

    messages = MessageStore.getMixed target
    target.accountID = messages[0].get('accountID')
    updated = []

    for message in messages
        flags = message.get('flags')
        if op is 'add' and flag not in flags
            flags = flags.concat [flag]

        else if op is 'remove' and flag in flags
            flags = _.without flags, flag

        else continue

        updated.push message.set('flags', flags).toJS()


    # immediately apply change to refresh UI
    # Update datastore
    AppDispatcher.handleViewAction
        type: ActionTypes.RECEIVE_RAW_MESSAGES
        value: updated

    return updated

_isDraft = (message, draftMailbox) ->
    mailboxIDs = message.get 'mailboxIDs'
    mailboxIDs[draftMailbox] or MessageFlags.DRAFT in message.get('flags')

_localMove = (target, from, to) ->

    messages = MessageStore.getMixed target
    target.accountID = messages[0].get('accountID')
    actions = []
    updated = []

    for message in messages
        mailboxIDs = message.get('mailboxIDs')
        if mailboxIDs[from]

            actions.push
                id: message.get('id')
                to: to
                from: [from]

            newMailboxIds = {}
            newMailboxIds[key] = value for key, value of mailboxIDs
            delete newMailboxIds[from]
            newMailboxIds[to] = -1

            updated.push message.set('mailboxIDs', newMailboxIds).toJS()

    # immediately apply change to refresh UI
    # Update datastore
    AppDispatcher.handleViewAction
        type: ActionTypes.RECEIVE_RAW_MESSAGES
        value: updated

    # Store action to allow unmove
    AppDispatcher.handleViewAction
        type: ActionTypes.LAST_ACTION
        value: {actions}

    _fixCurrentMessage target

    return updated

_localDelete = (target) ->

    messages = MessageStore.getMixed target

    accountID = messages[0].get('accountID')
    account = AccountStore.getByID(accountID)
    throw new Error 'Wrong State : no account' unless account
    trashMailbox = account.get 'trashMailbox'
    throw new Error 'Wrong State : no trashMailbox' unless trashMailbox
    draftMailbox = account.get 'draftMailbox'
    target.accountID = accountID


    actions = []
    updated = []

    for message in messages
        if accountID isnt message.get('accountID')
            throw new Error """
                Wrong Usage : delete message from various accounts
            """

        mailboxIDs = message.get('mailboxIDs')
        if mailboxIDs[trashMailbox]
            continue # already in trash
        else if _isDraft message, draftMailbox
            AppDispatcher.handleViewAction
                type: ActionTypes.RECEIVE_MESSAGE_DELETE
                value: message.get 'id'

        unless mailboxIDs[trashMailbox]
            actions.push
                id: message.get 'id'
                to: trashMailbox
                from: Object.keys mailboxIDs

            newMailboxIds = {}
            newMailboxIds[trashMailbox] = -1
            updated.push message.set 'mailboxIDs', newMailboxIds

    # immediately apply change to refresh UI
    # Update datastore
    AppDispatcher.handleViewAction
        type: ActionTypes.RECEIVE_RAW_MESSAGES
        value: updated

    # Store action to allow undelete
    AppDispatcher.handleViewAction
        type: ActionTypes.LAST_ACTION
        value: {actions}

    _fixCurrentMessage target

    return updated