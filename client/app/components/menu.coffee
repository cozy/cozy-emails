{div, aside, nav, ul, li, span, a, i, button} = React.DOM

classer = React.addons.classSet

RouterMixin     = require '../mixins/router_mixin'
StoreWatchMixin = require '../mixins/store_watch_mixin'

AccountActionCreator      = require '../actions/account_action_creator'
LayoutActionCreator       = require '../actions/layout_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'

AccountStore   = require '../stores/account_store'
LayoutStore    = require '../stores/layout_store'
RefreshesStore = require '../stores/refreshes_store'
SearchStore = require '../stores/search_store'

MessageUtils = require '../utils/message_utils'
colorhash    = require '../utils/colorhash'

MenuMailboxItem = require './menu_mailbox_item'

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
        console.log('there', @)
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
            closeModal  : ->
                LayoutActionCreator.hideModal()
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

            if @state.accounts.length
                @renderComposeButton()

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

                if @state.accounts.length
                    @state.accounts
                    .sort @selectedFirstSort.bind @
                    .map @getAccountRender.bind @
                    .toJS()

            nav className: 'submenu',
                @renderNewMailboxButton()

                button
                    role: 'menuitem'
                    className: classer
                        btn:               true
                        fa:                true
                        'drawer-toggle':   true
                        'fa-caret-right': not @state.isDrawerExpanded
                        'fa-caret-left':  @state.isDrawerExpanded
                    onClick: LayoutActionCreator.drawerToggle

    renderComposeButton: () ->
        composeUrl = @buildUrl
            direction: 'first'
            action: 'compose'
            parameters: null
            fullWidth: true

        a
            href: composeUrl
            className: 'compose-action btn btn-cozy',
                i className: 'fa fa-pencil'
                span className: 'item-label', " #{t 'menu compose'}"

    renderNewMailboxButton: () ->
        if @state.accounts.length
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



        accountClasses = classer active: isSelected


        if @state.onlyFavorites
            mailboxes = @state.favorites
            icon = 'fa-ellipsis-h'
            toggleFavoritesLabel = t 'menu favorites off'
        else
            mailboxes = @state.mailboxes
            icon = 'fa-ellipsis-h'
            toggleFavoritesLabel = t 'menu favorites on'

        allBoxesAreFavorite = @state.mailboxes.length is @state.favorites.length

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
                                'background-color': accountColor
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
                        if progress.get('errors').length
                            span className: 'refresh-error',
                                i
                                    className: 'fa warning',
                                    onClick: @displayErrors.bind null,
                                    progress

                if isSelected
                    a
                        href: configMailboxUrl
                        className: 'mailbox-config',
                        i
                            className:
                                'fa fa-cog'
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
                    .toJS()
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
                    .toJS()
                    unless allBoxesAreFavorite
                        li className: 'toggle-favorites',
                            a
                                role: 'menuitem',
                                tabIndex: 0,
                                onClick: @_toggleFavorites.bind(@),
                                key: 'toggle',
                                    i className: 'fa ' + icon
                                    span
                                        className: 'item-label',
                                        toggleFavoritesLabel

