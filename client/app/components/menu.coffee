_          = require 'underscore'
React      = require 'react'
classNames = require 'classnames'

{div, aside, nav, ul, li, span, a, i, button} = React.DOM

RouterMixin     = require '../mixins/router_mixin'
StoreWatchMixin = require '../mixins/store_watch_mixin'

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

AccountStore   = require '../stores/account_store'
LayoutStore    = require '../stores/layout_store'
RefreshesStore = require '../stores/refreshes_store'
SearchStore    = require '../stores/search_store'

MessageUtils = require '../utils/message_utils'
colorhash    = require '../utils/colorhash'

MenuMailboxItem = React.createFactory require './menu_mailbox_item'

{SpecialBoxIcons, Tooltips} = require '../constants/app_constants'


# This is here for a convenient way to fond special mailboxes names.
# NOTE: should we externalize them in app_constants?
specialMailboxes = [
    'inboxMailbox'
    'draftMailbox'
    'sentMailbox'
    'trashMailbox'
    'junkMailbox'
    'allMailbox'
]

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [
        RouterMixin
        StoreWatchMixin [AccountStore, LayoutStore, RefreshesStore, SearchStore]
    ]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))

    getStateFromStores: ->
        onlyFavorites    : not @state or @state.onlyFavorites is true
        isDrawerExpanded : LayoutStore.isDrawerExpanded()
        refreshes        : RefreshesStore.getRefreshing()
        accounts         : AccountStore.getAll()
        selectedAccount  : AccountStore.getSelectedOrDefault()
        mailboxes        : AccountStore.getSelectedMailboxes true
        favorites        : AccountStore.getSelectedFavorites true
        search           : SearchStore.getCurrentSearch()

    selectedFirstSort: (account1, account2) ->
        if @state.selectedAccount?.get('id') is account1.get('id')
            return -1
        else if @state.selectedAccount?.get('id') is account2.get('id')
            return 1
        else
            return 0

    _toggleFavorites: ->
        @setState onlyFavorites: not @state.onlyFavorites

    displayErrors: (refreshee) ->
        errors = refreshee.get 'errors'
        modal =
            title       : t 'modal please contribute'
            subtitle    : t 'modal please report'
            allowCopy   : true
            closeLabel  : t 'app alert close'
            content     : React.DOM.pre
                style: "max-height": "300px",
                "word-wrap": "normal",
                    errors.join "\n\n"
        LayoutActionCreator.displayModal modal

    render: ->
        # Starts DOM rendering
        aside
            role: 'menubar'
            'aria-expanded': @state.isDrawerExpanded,

            nav className: 'mainmenu',
                if @state.search and not @state.selectedAccount
                    div className: 'active',
                        div className: 'account-title',
                            a
                                role: 'menuitem'
                                className: 'account active',

                                i className: 'fa fa-search'

                                div
                                    className: 'account-details',
                                        span {}, @state.search

                if @state.accounts.size
                    @state.accounts
                        .sort @selectedFirstSort
                        .map @getAccountRender
                        .toArray()

            nav className: 'submenu',
                @renderNewMailboxButton()

                button
                    role: 'menuitem'
                    className: 'btn fa fa-question-circle help'
                    'aria-describedby':       Tooltips.HELP_SHORTCUTS
                    'data-tooltip-direction': 'top'
                    onClick: -> Mousetrap.trigger '?'

                button
                    role: 'menuitem'
                    className: classNames
                        btn:               true
                        fa:                true
                        'drawer-toggle':   true
                        'fa-caret-right': not @state.isDrawerExpanded
                        'fa-caret-left':  @state.isDrawerExpanded
                    onClick: LayoutActionCreator.drawerToggle

    renderNewMailboxButton: () ->
        if @state.accounts.size
            selectedAccountUrl = @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [@state.selectedAccount?.get 'id']
                fullWidth: true
        else
            selectedAccountUrl = @buildUrl
                direction: 'first'
                action: 'account.new'
                fullWidth: true

        # the button toggle the "new account" screen
        if @props.layout.firstPanel.action is 'account.new'
            newMailboxClass = 'active'
            newMailboxUrl = selectedAccountUrl
        else
            newMailboxClass = ''
            newMailboxUrl = @buildUrl
                direction: 'first'
                action: 'account.new'
                fullWidth: true

        a
            href: newMailboxUrl
            role: 'menuitem'
            className: "btn new-account-action #{newMailboxClass}",
                i className: 'fa fa-plus'
                span className: 'item-label', t 'menu account new'

    # renders a single account and its submenu
    getAccountRender: (account, key) ->

        isSelected     = account is @state.selectedAccount
        accountID      = account.get 'id'
        nbUnread       = account.get('totalUnread')
        defaultMailbox = AccountStore.getDefaultMailbox accountID
        refreshes      = @state.refreshes

        if defaultMailbox?
            url = @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [accountID, defaultMailbox?.get 'id']
                fullWidth: true # /!\ Hide second panel when switching account
        else
            # Go to account settings to add mailboxes
            url = @buildUrl
                direction: 'first'
                action: 'account.config'
                parameters: [accountID, 'account']
                fullWidth: true # /!\ Hide second panel when switching account



        accountClasses = classNames active: isSelected


        if @state.onlyFavorites
            mailboxes = @state.favorites
            icon = 'fa-ellipsis-h'
            toggleFavoritesLabel = t 'menu favorites off'
        else
            mailboxes = @state.mailboxes
            icon = 'fa-ellipsis-h'
            toggleFavoritesLabel = t 'menu favorites on'

        allBoxesAreFavorite = @state.mailboxes.size is @state.favorites.size

        configMailboxUrl = @buildUrl
            direction: 'first'
            action: 'account.config'
            parameters: [accountID, 'account']
            fullWidth: true

        specialMboxes = specialMailboxes.map (mbox) -> account.get mbox
        accountColor  = colorhash(account.get 'label')

        div
            className: accountClasses, key: key,
            div className: 'account-title',
                a
                    href: url
                    role: 'menuitem'
                    className: 'account ' + accountClasses,
                    'data-toggle': 'tooltip'
                    'data-delay': '10000'
                    'data-placement' : 'right',
                        i
                            className: 'avatar'
                            style:
                                backgroundColor: accountColor
                            account.get('label')[0]
                        div
                            className: 'account-details',
                                span
                                    'data-account-id': key,
                                    className: 'item-label display-label'
                                    account.get 'label'
                                span
                                    'data-account-id': key,
                                    className: 'item-label display-login'
                                    account.get 'login'

                    if progress = refreshes.get(accountID)
                        if progress.get('errors').size
                            span className: 'refresh-error',
                                i
                                    className: 'fa warning',
                                    onClick: @displayErrors,
                                    progress

                if isSelected
                    a
                        href: configMailboxUrl
                        className: 'mailbox-config menu-subaction',
                        i
                            'className': 'fa fa-cog'
                            'aria-describedby': Tooltips.ACCOUNT_PARAMETERS
                            'data-tooltip-direction': 'right'

                if nbUnread > 0 and not progress
                    span className: 'badge', nbUnread

            if isSelected
                ul
                    role: 'group'
                    className: 'list-unstyled mailbox-list',
                    mailboxes?.filter (mailbox) ->
                            mailbox.get('id') in specialMboxes
                        .map (mailbox, key) =>
                            MenuMailboxItem
                                account:           account,
                                mailbox:           mailbox,
                                key:               key,
                                selectedMailboxID: @state.selectedMailboxID,
                                refreshes:         refreshes,
                                displayErrors:     @displayErrors,
                        .toArray()
                    mailboxes?.filter (mailbox) ->
                            mailbox.get('id') not in specialMboxes
                        .map (mailbox, key) =>
                            MenuMailboxItem
                                account:           account,
                                mailbox:           mailbox,
                                key:               key,
                                selectedMailboxID: @state.selectedMailboxID,
                                refreshes:         refreshes,
                                displayErrors:     @displayErrors,
                        .toArray()
                    unless allBoxesAreFavorite
                        li className: 'toggle-favorites',
                            a
                                role: 'menuitem',
                                tabIndex: 0,
                                onClick: @_toggleFavorites,
                                key: 'toggle',
                                    i className: 'fa ' + icon
                                    span
                                        className: 'item-label',
                                        toggleFavoritesLabel
