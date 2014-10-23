{div, ul, li, a, span, i} = React.DOM

classer = React.addons.classSet

RouterMixin = require '../mixins/router_mixin'

AccountStore = require '../stores/account_store'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return nextState isnt @state or
           not Immutable.is(nextProps.accounts, @props.accounts) or
           not Immutable.is(nextProps.selectedAccount,
                @props.selectedAccount) or
           not _.isEqual(nextProps.layout, @props.layout) or
           nextProps.isResponsiveMenuShown isnt @props.isResponsiveMenuShown or
           not Immutable.is(nextProps.favoriteMailboxes,
                @props.favoriteMailboxes) or
           not Immutable.is(nextProps.unreadCounts, @props.unreadCounts)

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

        classes = classer
            'hidden-xs hidden-sm': not @props.isResponsiveMenuShown
            'col-xs-4 col-md-1': true

        div id: 'menu', className: classes,
            unless @props.accounts.length is 0
                a
                    href: composeUrl,
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
                className: 'menu-item new-account-action ' + newMailboxClass,
                    i className: 'fa fa-inbox'
                    span className: 'item-label', t 'menu account new'

            a
                href: settingsUrl,
                className: 'menu-item settings-action ' + settingsClass,
                    i className: 'fa fa-cog'
                    span className: 'item-label', t 'menu settings'


    # renders a single mailbox and its submenu
    getAccountRender: (account, key) ->

        isSelected = (not @props.selectedAccount? and key is 0) \
                     or @props.selectedAccount?.get('id') is account.get('id')

        accountClasses = classer active: isSelected
        accountID = account.get 'id'
        defaultMailbox = AccountStore.getDefaultMailbox accountID
        unread = @props.unreadCounts.get defaultMailbox?.get 'id'

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
                parameters: [accountID]
                fullWidth: true # /!\ Hide second panel when switching account

        li className: accountClasses, key: key,
            a href: url, className: 'menu-item account ' + accountClasses,
                i className: 'fa fa-inbox'
                if unread > 0
                    span className: 'badge', unread
                span
                    'data-account-id': key,
                    className: 'item-label',
                    account.get 'label'

            ul className: 'list-unstyled submenu mailbox-list',
                @props.favoriteMailboxes?.map (mailbox, key) =>
                    @getMailboxRender account, mailbox, key
                .toJS()

    getMailboxRender: (account, mailbox, key) ->
        mailboxUrl = @buildUrl
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters: [account.get('id'), mailbox.get('id')]

        unread = @props.unreadCounts.get mailbox.get('id')
        selectedClass = if mailbox.get('id') is @props.selectedMailboxID
        then 'active'
        else ''
        specialUse = mailbox.get('attribs')?[0]
        icon = switch specialUse
            when '\\All' then 'fa-archive'
            when '\\Drafts' then 'fa-edit'
            when '\\Sent' then 'fa-share-square-o'
            else 'fa-folder'

        li className: selectedClass,
            a href: mailboxUrl, className: 'menu-item', key: key,
                # Something must be rethought about the icon
                i className: 'fa ' + icon
                if unread and unread > 0
                    span className: 'badge', unread
                span className: 'item-label', mailbox.get 'label'
