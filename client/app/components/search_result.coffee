React = require 'react'

{div} = React.DOM

MessageList = React.createFactory require './message-list'

MessageActionCreator = require '../actions/message_action_creator'

MessageStore  = require '../stores/message_store'
AccountStore  = require '../stores/account_store'
SearchStore   = require '../stores/search_store'
SettingsStore = require '../stores/settings_store'


module.exports = React.createClass
    displayName: 'searchResults'

    # FIXME : use getters instead
    # such as : searchResults.getState()
    getInitialState: ->
        @getStateFromStores()

    # FIXME : use getters instead
    # such as : searchResults.getState()
    componentWillReceiveProps: (nextProps={}) ->
        @setState @getStateFromStores()
        nextProps

    getStateFromStores: ->
        accountID = SearchStore.getCurrentSearchAccountID()
        accountID = null if accountID is 'all'
        return state =
            accountID  : accountID
            search     : SearchStore.getCurrentSearch()

    render: ->
        MessageList
            key                  : 'messageList-' + SearchStore.getCurrentSearchKey()
            messages             : SearchStore.getCurrentSearchResults()
            accountID            : @state.accountID
            hasNextPage          : SearchStore.hasMoreSearch()
            queryParams          : null
            filters              : {}
            emptyListMessage     : t 'search deactivated', query: @state.search
