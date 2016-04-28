AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
LayoutStore = require '../stores/layout_store'
SearchStore = require '../stores/search_store'
RefreshesStore = require '../stores/refreshes_store'
RouterStore = require '../stores/router_store'

Immutable = require 'immutable'
{MessageActions, MailboxFlags} = require '../constants/app_constants'

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


    getMessagesList: (mailboxID) ->
        mailboxID ?= @getMailboxID()
        RouterStore.getMessagesList mailboxID


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
        if RouterStore.isFlags 'UNSEEN'
            return  t 'no unseen message'
        if RouterStore.isFlags 'FLAGGED'
            return  t 'no flagged message'
        if RouterStore.isFlags 'ATTACH'
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
