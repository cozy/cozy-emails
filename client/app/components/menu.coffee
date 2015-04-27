{div, aside, nav, ul, li, span, a, i, button} = React.DOM

classer = React.addons.classSet

RouterMixin     = require '../mixins/router_mixin'
StoreWatchMixin = require '../mixins/store_watch_mixin'

LayoutActionCreator       = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'

AccountStore = require '../stores/account_store'
LayoutStore  = require '../stores/layout_store'

Modal        = require './modal'
ThinProgress = require './thin_progress'
MessageUtils = require '../utils/message_utils'

RefreshIndicator = require './menu_refresh_indicator'

{Dispositions, SpecialBoxIcons} = require '../constants/app_constants'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [
        RouterMixin
        StoreWatchMixin [LayoutStore]
    ]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))

    getInitialState: ->
        displayActiveAccount: true
        modalErrors: null
        onlyFavorites: true

    getStateFromStores: ->
            isDrawerExpanded: LayoutStore.isDrawerExpanded()

    componentWillReceiveProps: (props) ->
        if not Immutable.is(props.selectedAccount, @props.selectedAccount)
            @setState displayActiveAccount: true


    displayErrors: (refreshee) ->
        @setState modalErrors: refreshee.get 'errors'

    hideErrors: ->
        @setState modalErrors: null

    render: ->

        if @props.accounts.length
            selectedAccountUrl = @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: @props.selectedAccount?.get 'id'
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

        # the button toggles the "settings" screen
        if @props.layout.firstPanel.action is 'settings' or
           @props.layout.secondPanel?.action is 'settings'
            settingsClass = 'active'
            settingsUrl = selectedAccountUrl
        else
            settingsClass = ''
            settingsUrl = @buildUrl
                direction: 'first'
                action: 'settings'
                fullWidth: true

        if @state.modalErrors
            title       = t 'modal please contribute'
            subtitle    = t 'modal please report'
            modalErrors = @state.modalErrors
            closeModal  = @hideErrors
            closeLabel  = t 'app alert close'
            content = React.DOM.pre
                style: "max-height": "300px",
                "word-wrap": "normal",
                    @state.modalErrors.join "\n\n"
            modal = Modal {title, subtitle, content, closeModal, closeLabel}
        else
            modal = null
        # classes = classer
        #     'hidden-xs hidden-sm': not @props.isResponsiveMenuShown
        #     'collapsed': @props.disposition.type isnt Dispositions.THREE
        #     'expanded': @props.disposition.type is Dispositions.THREE
        #     'three': @props.disposition.type is Dispositions.THREE

        aside
            role: 'menubar'
            'aria-expanded': @state.isDrawerExpanded,


            modal

            nav className: 'mainmenu',
                if @props.accounts.length
                    @props.accounts.map (account, key) =>
                        @getAccountRender account, key
                    .toJS()

            nav className: 'submenu',
                a
                    href: newMailboxUrl
                    role: 'menuitem'
                    className: "btn new-account-action #{newMailboxClass}",
                        i className: 'fa fa-plus'
                        span className: 'item-label', t 'menu account new'

                button
                    role: 'menuitem'
                    className: classer
                        btn:               true
                        fa:                true
                        'drawer-toggle':   true
                        'fa-toggle-right': not @state.isDrawerExpanded
                        'fa-toggle-left':  @state.isDrawerExpanded
                    onClick: LayoutActionCreator.drawerToggle

    # renders a single account and its submenu
    getAccountRender: (account, key) ->

        isSelected = (not @props.selectedAccount? and key is 0) \
                     or @props.selectedAccount?.get('id') is account.get('id')

        accountID = account.get 'id'
        nbUnread = account.get('totalUnread')
        defaultMailbox = AccountStore.getDefaultMailbox accountID
        refreshes = @props.refreshes

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

        toggleActive = =>
            if not @state.displayActiveAccount
                @setState displayActiveAccount: true

        toggleDisplay = =>
            if isSelected
                @setState displayActiveAccount: not @state.displayActiveAccount
            else
                @setState displayActiveAccount: true

        toggleFavorites = =>
            @setState onlyFavorites: not @state.onlyFavorites


        isActive = (isSelected and @state.displayActiveAccount)
        accountClasses = classer
            active: isActive
        accountIcon = [
            'fa'
            "fa-angle-#{if isActive then 'down' else 'right'}"
        ].join(' ')

        if @state.onlyFavorites
            mailboxes = @props.favorites
            icon = 'fa-ellipsis-h'
            toggleFavoritesLabel = t 'menu favorites off'
        else
            mailboxes = @props.mailboxes
            icon = 'fa-ellipsis-h'
            toggleFavoritesLabel = t 'menu favorites on'

        div
            className: accountClasses, key: key,
            a
                href: url
                role: 'menuitem'
                className: 'account ' + accountClasses,
                onClick: toggleActive
                onDoubleClick: toggleDisplay
                'data-toggle': 'tooltip'
                'data-delay': '10000'
                'data-placement' : 'right',
                    i className: accountIcon
                    span
                        'data-account-id': key,
                        className: 'item-label',
                        account.get 'label'

                if progress = refreshes.get(accountID)
                    if progress.get('errors').length
                        span className: 'refresh-error',
                            i
                                className: 'fa warning',
                                onClick: @displayErrors.bind null,
                                progress
                    if progress.get('firstImport')
                        ThinProgress
                            done: progress.get('done'),
                            total: progress.get('total')

                else if nbUnread > 0
                    span className: 'badge', nbUnread

            if isSelected
                ul
                    role: 'group'
                    className: 'list-unstyled mailbox-list',
                    mailboxes?.map (mailbox, key) =>
                        selectedMailboxID = @props.selectedMailboxID
                        MenuMailboxItem
                            account:           account,
                            mailbox:           mailbox,
                            key:               key,
                            selectedMailboxID: selectedMailboxID,
                            refreshes:         refreshes,
                            displayErrors:     @displayErrors,
                    .toJS()
                    li className: 'toggle-favorites',
                        a
                            role: 'menuitem',
                            tabIndex: 0,
                            onClick: toggleFavorites,
                            key: 'toggle',
                                i className: 'fa ' + icon
                                span
                                    className: 'item-label',
                                    toggleFavoritesLabel

    _initTooltips: ->
        #jQuery('#account-list [data-toggle="tooltip"]').tooltip()

    componentDidMount: ->
        @_initTooltips()

    componentDidUpdate: ->
        @_initTooltips()


MenuMailboxItem = React.createClass
    displayName: 'MenuMailboxItem'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))

    getInitialState: ->
        return target: false

    render: ->
        mailboxID = @props.mailbox.get 'id'
        mailboxUrl = @buildUrl
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters: [@props.account.get('id'), mailboxID]

        nbTotal  = @props.mailbox.get('nbTotal') or 0
        nbUnread = @props.mailbox.get('nbUnread') or 0
        nbRecent = @props.mailbox.get('nbRecent') or 0
        title    = t "menu mailbox total", nbTotal
        if nbUnread > 0
            title += t "menu mailbox unread", nbUnread
        if nbRecent > 0
            title += t "menu mailbox new", nbRecent

        mailboxIcon = 'fa-folder-o'
        specialMailbox = false
        for attrib, icon of SpecialBoxIcons
            if @props.account.get(attrib) is mailboxID
                mailboxIcon = icon
                specialMailbox = true

        classesParent = classer
            active: mailboxID is @props.selectedMailboxID
            target: @state.target
        classesChild = classer
            target:  @state.target
            special: specialMailbox
            news:    nbRecent > 0


        progress = @props.refreshes.get mailboxID
        displayError = @props.displayErrors.bind null, progress

        li className: classesParent,
            a
                href: mailboxUrl
                onClick: @props.hideMenu
                className: "#{classesChild} lv-#{@props.mailbox.get('depth')}"
                role: 'menuitem'
                'data-mailbox-id': mailboxID
                onDragEnter: @onDragEnter
                onDragLeave: @onDragLeave
                onDragOver: @onDragOver
                onDrop: @onDrop
                title: title
                'data-toggle': 'tooltip'
                'data-placement' : 'right'
                key: @props.key,
                    # Something must be rethought about the icon
                    i className: 'fa ' + mailboxIcon
                    if not progress and nbUnread and nbUnread > 0
                        span className: 'badge', nbUnread
                    span
                        className: 'item-label',
                        "#{@props.mailbox.get 'label'}"

                if progress and progress.get('firstImport')
                    ThinProgress
                        done: progress.get('done')
                        total: progress.get('total')

                if progress?.get('errors').length
                    span className: 'refresh-error', onClick: displayError,
                        i className: 'fa fa-warning', null

    onDragEnter: (e) ->
        if not @state.target
            @setState target: true

    onDragLeave: (e) ->
        if @state.target
            @setState target: false

    onDragOver: (e) ->
        e.preventDefault()

    onDrop: (event) ->
        data = event.dataTransfer.getData 'text'
        {messageID, mailboxID, conversation} = JSON.parse data
        newID = event.currentTarget.dataset.mailboxId
        @setState target: false
        MessageUtils.move messageID, conversation, mailboxID, newID
