AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
RouterStore = require '../stores/router_store'

Immutable = require 'immutable'
{sortByDate} = require '../utils/misc'
{MessageFilter, MessageFlags, MailboxFlags} = require '../constants/app_constants'

_ = require 'lodash'

class RouteGetter

    getNextURL: ->
        RouterStore.getNextURL()

    getURL: (params) ->
        RouterStore.getURL params

    getAction: ->
        RouterStore.getAction()

    isReply: ->
        action = @getAction()
        action isnt 'message.edit'

    isEditable: ->
        action = @getAction()
        editables = [
            'message.new',
            'message.edit',
            'message.reply',
            'message.reply.all',
            'message.forward'
            ]
        action in editables

    getQueryParams: ->
        RouterStore.getQueryParams()

    getFilter: ->
        RouterStore.getFilter()

    isLoading: ->
        MessageStore.isFetching()

    getSelectedTab: ->
        AccountStore.getSelectedTab()

    isFlags: (name) ->
        flags = @getFilter()?.flags or []
        MessageFilter[name] is flags or MessageFilter[name] in flags

    getMessagesToDisplay: (mailboxID) ->
        mailboxID ?= @getMailboxID()
        filter = @getFilter()
        MessageStore.getMessagesToDisplay {mailboxID, filter}

    getMessage: (messageID) ->
        MessageStore.getMessage messageID

    getConversationLength: (messageID) ->
        MessageStore.getConversationLength messageID

    getConversationMessages: (messageID) ->
        messageID ?= MessageStore.getCurrentID()
        messageIDs = MessageStore.getByID(messageID)?.get('messageIDs')
        return messageIDs?.map (messageID) ->
            MessageStore.getByID messageID


    getCurrentMessageID: ->
        MessageStore.getCurrentID()

    isCurrentMessage: (messageID) ->
        messageID is @getCurrentMessageID()

    getCurrentMailbox: (id) ->
        AccountStore.getSelectedMailbox id

    getAccounts: ->
        accountID = @getAccountID()
        AccountStore.getAll().sort (account1, account2) ->
            if accountID is account1.get('id')
                return -1
            if accountID is account2.get('id')
                return 1
            return 0

    getAccountSignature: ->
        AccountStore.getSelectedOrDefault()?.get 'signature'

    getAccountID: ->
        AccountStore.getSelectedOrDefault()?.get 'id'

    getMailboxID: ->
        @getCurrentMailbox()?.get 'id'

    getLogin: ->
        @getCurrentMailbox()?.get 'login'

    getMailboxes: ->
        AccountStore.getSelectedMailboxes()

    getTags: (message) ->
        mailboxID = @getMailboxID()
        mailboxesIDs = Object.keys message.get 'mailboxIDs'
        result = mailboxesIDs.map (id) =>
            if (mailbox = @getCurrentMailbox id)
                isGlobal = MailboxFlags.ALL in mailbox.get 'attribs'
                isEqual = mailboxID is id
                unless (isEqual or isGlobal)
                    return mailbox?.get 'label'
        _.uniq _.compact result

    getEmptyMessage: ->
        filter = @getFilter()
        if @isFlags 'UNSEEN', filter.flags
            return  t 'no unseen message'
        if @isFlags 'FLAGGED', filter.flags
            return  t 'no flagged message'
        if @isFlags 'ATTACH', filter.flags
            return t 'no filter message'
        return  t 'list empty'

    # Uniq Key from URL params
    #
    # return a {string}
    getKey: (str = '') ->
        if (filter = RouterStore.getQueryParams())
            keys = _.compact ['before', 'after'].map (key) ->
                filter[key] if filter[key] isnt '-'
            keys.unshift str unless _.isEmpty str
            return keys.join('-')
        return str

module.exports = new RouteGetter()
