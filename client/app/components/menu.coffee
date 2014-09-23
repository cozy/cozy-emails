{div, ul, li, a, span, i} = React.DOM

classer = React.addons.classSet

RouterMixin = require '../mixins/router_mixin'

AccountStore = require '../stores/account_store'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not Immutable.is(nextProps.accounts, @props.accounts) or
               not Immutable.is(nextProps.selectedAccount, @props.selectedAccount) or
               not _.isEqual(nextProps.layout, @props.layout) or
               nextProps.isResponsiveMenuShown isnt @props.isResponsiveMenuShown or
               not Immutable.is(nextProps.favoriteMailboxes, @props.favoriteMailboxes)

    render: ->
        selectedAccountUrl = @buildUrl
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters: @props.selectedAccount?.get 'id'
            fullWidth: true

        # the button toggles the "compose" screen
        if @props.layout.firstPanel.action is 'compose' or
           @props.layout.secondPanel?.action is 'compose'
            composeUrl = selectedAccountUrl
        else
            composeUrl = @buildUrl
                direction: 'second'
                action: 'compose'
                parameters: null
                fullWidth: false

        # the button toggle the "new mailbox" screen
        if @props.layout.firstPanel.action is 'account.new'
            newMailboxUrl = selectedAccountUrl
        else
            newMailboxUrl = @buildUrl
                direction: 'first'
                action: 'account.new'
                fullWidth: true

        # the button toggles the "settings" screen
        if @props.layout.firstPanel.action is 'settings' or
           @props.layout.secondPanel?.action is 'settings'
            settingsUrl = selectedAccountUrl
        else
            settingsUrl = @buildUrl
                direction: 'first'
                action: 'settings'
                fullWidth: true

        classes = classer
            'hidden-xs hidden-sm': not @props.isResponsiveMenuShown
            'col-xs-4 col-md-1': true

        div id: 'menu', className: classes,
            a href: composeUrl, className: 'menu-item compose-action',
                i className: 'fa fa-edit'
                span className: 'item-label', t 'menu compose'

            ul id: 'account-list', className: 'list-unstyled',
                @props.accounts.map (account, key) =>
                    @getAccountRender account, key
                .toJS()

            a href: newMailboxUrl, className: 'menu-item new-account-action',
                i className: 'fa fa-inbox'
                span className: 'item-label', t 'menu account new'

            a href: settingsUrl, className: 'menu-item settings-action',
                i className: 'fa fa-cog'
                span className: 'item-label', t 'menu settings'


    # renders a single mailbox and its submenu
    getAccountRender: (account, key) ->

        isSelected = (not @props.selectedAccount? and key is 0) \
                     or @props.selectedAccount?.get('id') is account.get('id')

        accountClasses = classer active: isSelected
        accountID = account.get 'id'
        defaultMailbox = AccountStore.getDefaultMailbox accountID
        url = @buildUrl
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters: [accountID, defaultMailbox?.get 'id']
            fullWidth: false

        li className: accountClasses, key: key,
            a href: url, className: 'menu-item ' + accountClasses,
                i className: 'fa fa-inbox'
                span className: 'badge', account.get 'unreadCount'
                span className: 'item-label', account.get 'label'

            ul className: 'list-unstyled submenu mailbox-list',
                @props.favoriteMailboxes.map (mailbox, key) =>
                    @getMailboxRender account, mailbox, key
                .toJS()

    getMailboxRender: (account, mailbox, key) ->
        mailboxUrl = @buildUrl
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters: [account.get('id'), mailbox.get('id')]

        a href: mailboxUrl, className: 'menu-item', key: key,
            # Something must be rethought about the icon
            i className: 'fa fa-star'
            span className: 'badge', Math.floor((Math.random() * 10) + 1) # placeholder
            span className: 'item-label', mailbox.get 'label'
