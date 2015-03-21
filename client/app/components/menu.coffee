{div, ul, li, a, span, i} = React.DOM

classer = React.addons.classSet

RouterMixin          = require '../mixins/router_mixin'
LayoutActionCreator  = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'
AccountStore         = require '../stores/account_store'
Modal                = require './modal'
ThinProgress         = require './thin_progress'

{Dispositions, SpecialBoxIcons} = require '../constants/app_constants'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))

    getInitialState: ->
        displayActiveAccount: true
        modalErrors: null
        onlyFavorites: true

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

        # the button toggles the "compose" screen
        if @props.layout.firstPanel.action is 'compose' or
           @props.layout.secondPanel?.action is 'compose'
            composeClass = 'active'
            composeUrl = selectedAccountUrl
        else
            composeClass = ''
            composeUrl = @buildUrl
                direction: 'first'
                action: 'compose'
                parameters: null
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
        classes = classer
            'hidden-xs hidden-sm': not @props.isResponsiveMenuShown
            'col-xs-4': true
            'col-md-1': @props.disposition.type isnt Dispositions.THREE
            'col-md-3': @props.disposition.type is Dispositions.THREE
            'three': @props.disposition.type is Dispositions.THREE

        div id: 'menu', className: classes,

            modal

            unless @props.accounts.length is 0
                a
                    href: composeUrl,
                    onClick: @_hideMenu
                    className: 'menu-item compose-action ' + composeClass,
                        i className: 'fa fa-edit'
                        span className: 'item-label', t 'menu compose'

            if @props.accounts.length isnt 0
                ul id: 'account-list', className: 'list-unstyled',
                    @props.accounts.map (account, key) =>
                        @getAccountRender account, key
                    .toJS()

            a
                href: newMailboxUrl,
                onClick: @_hideMenu
                className: 'menu-item new-account-action ' + newMailboxClass,
                    i className: 'fa fa-inbox'
                    span className: 'item-label', t 'menu account new'

            # #201: remove settings panel
            #a
            #    href: settingsUrl,
            #    onClick: @_hideMenu
            #    className: 'menu-item settings-action ' + settingsClass,
            #        i className: 'fa fa-cog'
            #        span className: 'item-label', t 'menu settings'


    # renders a single account and its submenu
    getAccountRender: (account, key) ->

        isSelected = (not @props.selectedAccount? and key is 0) \
                     or @props.selectedAccount?.get('id') is account.get('id')

        accountID = account.get 'id'
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
            @_hideMenu()

        toggleDisplay = =>
            if isSelected
                @setState displayActiveAccount: not @state.displayActiveAccount
            else
                @setState displayActiveAccount: true

        toggleFavorites = =>
            @setState onlyFavorites: not @state.onlyFavorites


        accountClasses = classer
            active: (isSelected and @state.displayActiveAccount)

        if @state.onlyFavorites
            mailboxes = @props.favorites
            icon = 'fa-toggle-down'
            toggleFavoritesLabel = t 'menu favorites off'
        else
            mailboxes = @props.mailboxes
            icon = 'fa-toggle-up'
            toggleFavoritesLabel = t 'menu favorites on'

        li className: accountClasses, key: key,
            a
                href: url,
                className: 'menu-item account ' + accountClasses,
                onClick: toggleActive,
                onDoubleClick: toggleDisplay,
                'data-toggle': 'tooltip',
                'data-delay': '10000',
                'data-placement' : 'right',
                    i className: 'fa fa-inbox'
                    span
                        'data-account-id': key,
                        className: 'item-label',
                        account.get 'label'

                if progress = refreshes.get(accountID)
                    if progress.get('errors').length
                        span className: 'refresh-error',
                            i className: 'fa warning', onClick: @displayErrors.bind null, progress
                    if progress.get('firstImport')
                        ThinProgress done: progress.get('done'), total: progress.get('total')

            if isSelected
                ul className: 'list-unstyled submenu mailbox-list',
                    mailboxes?.map (mailbox, key) =>
                        selectedMailboxID = @props.selectedMailboxID
                        MenuMailboxItem { account, mailbox, key, selectedMailboxID, refreshes, displayErrors: @displayErrors, hideMenu: @_hideMenu}
                    .toJS()
                    li null,
                        a
                            className: 'menu-item',
                            tabIndex: 0,
                            onClick: toggleFavorites,
                            key: 'toggle',
                                i className: 'fa ' + icon
                                span
                                    className: 'item-label',
                                    toggleFavoritesLabel

    _hideMenu: ->
        if @props.isResponsiveMenuShown
            @props.toggleMenu()

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

        classesParent = classer
            active: mailboxID is @props.selectedMailboxID
            target: @state.target
        classesChild = classer
            'menu-item': true
            target: @state.target
            news: nbRecent > 0

        mailboxIcon = 'fa-folder'
        for attrib, icon of SpecialBoxIcons
            if @props.account.get(attrib) is mailboxID
                mailboxIcon = icon

        progress = @props.refreshes.get mailboxID
        displayError = @props.displayErrors.bind null, progress

        pusher = ""
        pusher += "   " for j in [1..@props.mailbox.get('depth')] by 1

        li className: classesParent,
            a
                href: mailboxUrl,
                onClick: @props.hideMenu,
                className: classesChild,
                'data-mailbox-id': mailboxID,
                onDragEnter: @onDragEnter,
                onDragLeave: @onDragLeave,
                onDragOver: @onDragOver,
                onDrop: @onDrop,
                title: title,
                'data-toggle': 'tooltip',
                'data-placement' : 'right',
                key: @props.key,
                    # Something must be rethought about the icon
                    i className: 'fa ' + mailboxIcon
                    if not progress and nbUnread and nbUnread > 0
                        span className: 'badge', nbUnread
                    span
                        className: 'item-label',
                        "#{pusher}#{@props.mailbox.get 'label'}"

                if progress and progress.get('firstImport')
                    ThinProgress done: progress.get('done'), total: progress.get('total')

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
        {messageID, mailboxID, conversation} = JSON.parse(event.dataTransfer.getData 'text')
        newID = event.currentTarget.dataset.mailboxId
        @setState target: false
        if conversation
            ConversationActionCreator.move messageID, mailboxID, newID, (error) ->
                if error?
                    LayoutActionCreator.alertError "#{t("conversation move ko")} #{error}"
                else
                    LayoutActionCreator.notify t("conversation move ok"),
                        autoclose: true
        else
            MessageActionCreator.move messageID, mailboxID, newID, (error) ->
                if error?
                    LayoutActionCreator.alertError "#{t("message action move ko")} #{error}"
                else
                    LayoutActionCreator.notify t("message action move ok"),
                        autoclose: true
