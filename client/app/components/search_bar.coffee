React = require 'react'

{div, button, i} = React.DOM

SearchInput = React.createFactory require './search_input'
AccountPicker = React.createFactory require './account_picker'

RouterGetter = require '../getters/router'
SearchStore = require '../stores/search_store'

RouterActionCreator = require '../actions/router_action_creator'

module.exports = GlobalSearchBar = React.createClass
    displayName: 'GlobalSearchBar'

    # FIXME : use getters instead
    # such as : SearchBar.getState()
    getInitialState: ->
        @getStateFromStores()

    # FIXME : use getters instead
    # such as : SearchBar.getState()
    componentWillReceiveProps: (nextProps={}) ->
        @setState @getStateFromStores()
        nextProps

    render: ->
        div className: 'search-bar',

            i className: 'fa fa-search'

            AccountPicker
                accounts: @state.accounts
                valueLink:
                    value: @state.accountID or 'all'
                    requestChange: @onAccountChanged

            SearchInput
                value: @state.search or ''
                placeholder: t 'filters search placeholder'
                onSubmit: @onSearchTriggered

    onSearchTriggered: (newvalue) ->
        unless _.isEmpty (query = newvalue)
            RouterActionCreator.searchAll
                value: {query}
        else
            RouterActionCreator.showMessageList()

    onAccountChanged: (accountID) ->
        if (query = @state.search) isnt ''
            RouterActionCreator.searchAll
                value: {query}
        else
            @setState {accountID}

    getStateFromStores: ->
        accounts = RouterGetter.getAccounts()
        .map (account) -> account.get 'label'
        .toOrderedMap()
        .set 'all', t 'search all accounts'

        accountID = RouterGetter.getAccountID() or 'all'
        search = RouterGetter.getSearch()

        return {accounts, search, accountID}
