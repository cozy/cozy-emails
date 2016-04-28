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
        not RouterStore.isAllLoaded()

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
        RouterStore.getSelectedTab()

    getModal: ->
        RouterStore.getModalParams()

    isFlags: (name) ->
        flags = @getFilter()?.flags or []
        MessageFilter[name] is flags or MessageFilter[name] in flags

    getMessagesList: (mailboxID) ->
        mailboxID ?= @getMailboxID()
        return null unless mailboxID

        messages = RouterStore.getMessagesList mailboxID

        #TODO : move this into Router_store
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
        messages?.sort sortByDate filter.order

    getMessage: (messageID) ->
        MessageStore.getByID messageID

    getConversationLength: ({messageID, conversationID}) ->
        MessageStore.getConversationLength {messageID, conversationID}

    getConversation: (messageID) ->
        conversation = MessageStore.getConversation messageID
        conversation?.toArray()

    getCurrentMessageID: ->
        RouterStore.getMessageID()

    getCurrentMessage: ->
        MessageStore.getByID RouterStore.getMessageID()

    isCurrentConversation: (conversationID) ->
        conversationID is @getCurrentMessage()?.get 'conversationID'

    getMailbox: (mailboxID) ->
        RouterStore.getMailbox mailboxID

    getCurrentMailbox: ->
        RouterStore.getMailbox()

    getInbox: (accountID) ->
        RouterStore.getAllMailboxes(accountID)?.find (mailbox) ->
            'INBOX' is mailbox.get 'label'

    getAccounts: ->
        AccountStore.getAll()

    getAccountSignature: ->
        RouterStore.getAccount()?.get 'signature'

    getAccountID: ->
        RouterStore.getAccountID()

    getMailboxID: ->
        RouterStore.getMailboxID()

    getLogin: ->
        @getCurrentMailbox()?.get 'login'

    getMailboxes: ->
        RouterStore.getAllMailboxes()

    getTags: (message) ->
        mailboxID = @getMailboxID()
        mailboxesIDs = Object.keys message.get 'mailboxIDs'
        _.uniq _.compact mailboxesIDs.map (id) =>
            if (mailbox = @getMailbox id)
                attribs = mailbox.get('attribs') or []
                isGlobal = MailboxFlags.ALL in attribs
                isEqual = mailboxID is id
                unless (isEqual or isGlobal)
                    return mailbox?.get 'label'


    # TODO : move this into getter
    # this has nothing to do with store
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
