React = require 'react'

{div, button, i} = React.DOM

SearchInput = require './search_input'
AccountPicker = require './account_picker'

Router = require '../mixins/router_mixin'
LayoutActionCreator = require '../actions/layout_action_creator'

StoreWatchMixin  = require '../mixins/store_watch_mixin'

AccountStore = require '../stores/account_store'
SearchStore = require '../stores/search_store'

AccountActionCreator = require '../actions/account_action_creator'

AccountStore = require '../stores/account_store'
SearchStore  = require '../stores/search_store'


module.exports = GlobalSearchBar = React.createClass
    displayName: 'GlobalSearchBar'

    mixins: [
        StoreWatchMixin [AccountStore, SearchStore]
    ]

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
        if newvalue isnt ''
            Router.redirect
                action: 'search'
                value: newvalue
        else
            @setState search: ''
            accountID = @state.accountID
            accountID = null if @state.accountID is 'all'

<<<<<<< 0b56443d1321028d80a8d740e3ccfc1afc84be60
            @redirect
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [ accountID ]
=======
            Router.redirect
                action: 'message.list'
                accountID: accountID
>>>>>>> Use Stattic Router.buildURL and remove mixin

    onAccountChanged: (accountID) ->
        currentAccountId = AccountStore.getSelected()?.get('id')

        if @state.search isnt ''
            Router.redirect
                action: 'search'
                value: @state.search

        else if accountID not in ['all', currentAccountId]
<<<<<<< 0b56443d1321028d80a8d740e3ccfc1afc84be60
            @redirect
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [ accountID ]
=======
            Router.redirect
                action: 'message.list'
>>>>>>> Use Stattic Router.buildURL and remove mixin

        else
            @setState {accountID}

    getStateFromStores: ->
        accounts = AccountStore.getAll()
        .map (account) -> account.get 'label'
        .toOrderedMap()
        .set 'all', t 'search all accounts'

        accountID = AccountStore.getSelected()?.get('id') or 'all'
        search = SearchStore.getCurrentSearch()

        return {accounts, search, accountID}
