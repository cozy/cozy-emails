AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
LayoutStore = require '../stores/layout_store'
SearchStore = require '../stores/search_store'
RefreshesStore = require '../stores/refreshes_store'
RouterStore = require '../stores/router_store'

Immutable = require 'immutable'
{sortByDate} = require '../utils/misc'
{MessageFilter, MessageActions, MessageFlags, MailboxFlags} = require '../constants/app_constants'

_ = require 'lodash'

class RouteGetter

    hasNextPage: ->
        not MessageStore.isAllLoaded()

    isCurrentURL: (url) ->
        isServer = false
        currentURL = RouterStore.getCurrentURL {isServer}
        currentURL is url

    getURL: (params) ->
        RouterStore.getURL params

    getAction: ->
        RouterStore.getAction()

    getReplyMessage: (messageID) ->
        if (isReply = @getAction() isnt 'message.edit')
            return MessageStore.getByID messageID

    isEditable: ->
        action = @getAction()
        editables = [
            MessageActions.CREATE,
            MessageActions.EDIT,
            MessageActions.REPLY,
            MessageActions.REPLY_ALL,
            MessageActions.FORWARD
            ]
        action in editables

    getQueryParams: ->
        RouterStore.getQueryParams()

    getFilter: ->
        RouterStore.getFilter()

    getSearch: ->
        SearchStore.getCurrentSearch()

    getLayoutSettings: ->
        {
            disposition: LayoutStore.getDisposition()
            isCompact: LayoutStore.getListModeCompact()
            previewSize: LayoutStore.getPreviewSize()
        }

    getProgress: (accountID) ->
        RefreshesStore.getRefreshing().get accountID

    getSelectedTab: ->
        AccountStore.getSelectedTab()

    getModal: ->
        LayoutStore.getModal()

    isFlags: (name) ->
        flags = @getFilter()?.flags or []
        MessageFilter[name] is flags or MessageFilter[name] in flags

    getMessagesList: (mailboxID) ->
        mailboxID ?= @getMailboxID()
        messages = MessageStore.getMessagesList mailboxID

        # We dont filter for type from and dest because it is
        # complicated by collation and name vs address.
        unless _.isEmpty (filter = @getFilter()).flags
            messages = messages.filter (message, index) =>
                if @isFlags 'FLAGGED'
                    return MessageFlags.FLAGGED in message.get 'flags'
                if @isFlags 'ATTACH'
                    return message.get('attachments')?.size > 0
                if @isFlags 'UNSEEN'
                    return MessageFlags.SEEN not in message.get 'flags'
                return true

        # FIXME : use params ASC et DESC into URL
        messages.sort sortByDate filter.order

    getMessage: (messageID) ->
        MessageStore.getByID messageID

    getConversationLength: ({messageID, conversationID}) ->
        MessageStore.getConversationLength {messageID, conversationID}

    getConversation: (messageID) ->
        conversation = MessageStore.getConversation messageID
        conversation?.toArray()

    getCurrentMessageID: ->
        MessageStore.getCurrentID()

    getCurrentMessage: ->
        MessageStore.getByID MessageStore.getCurrentID()

    isCurrentConversation: (conversationID) ->
        conversationID is @getCurrentMessage()?.get 'conversationID'

    getCurrentMailbox: (mailboxID) ->
        AccountStore.getMailbox mailboxID

    getInbox: ->
        AccountStore.getAllMailboxes()?.find (mailbox) ->
            'INBOX' is mailbox.get 'label'

    getAccounts: ->
        accountID = @getAccountID()
        AccountStore.getAll().sort (account1, account2) ->
            if accountID is account1.get('id')
                return -1
            if accountID is account2.get('id')
                return 1
            return 0

    getAccountSignature: ->
        AccountStore.getSelected()?.get 'signature'

    getAccountID: ->
        AccountStore.getAccountID()

    getMailboxID: ->
        AccountStore.getMailboxID()

    getLogin: ->
        @getCurrentMailbox()?.get 'login'

    getMailboxes: ->
        AccountStore.getAllMailboxes()

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
