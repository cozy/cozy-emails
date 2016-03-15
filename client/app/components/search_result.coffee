React = require 'react'

{div} = React.DOM

MessageList = React.createFactory require './message-list'

MessageActionCreator = require '../actions/message_action_creator'

StoreWatchMixin = require '../mixins/store_watch_mixin'

MessageStore  = require '../stores/message_store'
AccountStore  = require '../stores/account_store'
SearchStore   = require '../stores/search_store'
SettingsStore = require '../stores/settings_store'


module.exports = React.createClass
    displayName: 'searchResults'

    mixins: [
        StoreWatchMixin [AccountStore, SearchStore]
    ]

    getStateFromStores: ->
        search = SearchStore.getCurrentSearch()
        accountID = SearchStore.getCurrentSearchAccountID()
        accountID = null if accountID is 'all'
        return state =
            currentSearchKey      : SearchStore.getCurrentSearchKey()
            currentSearchResults  : SearchStore.getCurrentSearchResults()
            conversationLengths   : MessageStore.getConversationsLength()
            settings              : SettingsStore.get()
            accountID             : accountID
            currentMessageID      : MessageStore.getCurrentID()
            currentConversationID : MessageStore.getCurrentConversationID()
            accounts              : AccountStore.getAll()
            mailboxes             : AccountStore.getAllMailboxes()
            canLoadMore           : SearchStore.hasMoreSearch()
            emptyListMessage      : t 'search deactivated', query: search

    render: ->

        MessageList
            noFilters            : true
            messages             : @state.currentSearchResults
            accountID            : @state.accountID
            messageID            : @state.currentMessageID
            conversationID       : @state.currentConversationID
            accounts             : @state.accounts
            mailboxes            : @state.mailboxes
            settings             : @state.settings
            conversationLengths  : @state.conversationLengths
            emptyListMessage     : @state.emptyListMessage
            queryParams          : null
            canLoadMore          : @state.canLoadMore
            loadMoreMessage      : ->
                MessageActionCreator.fetchSearchResults()
