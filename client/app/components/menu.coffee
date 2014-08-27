{div, ul, li, a, span, i} = React.DOM

classer = React.addons.classSet

RouterMixin = require '../mixins/RouterMixin'

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
            direction: 'left'
            action: 'account.messages'
            parameters: @props.selectedAccount?.get 'id'
            fullWidth: true

        # the button toggles the "compose" screen
        if @props.layout.leftPanel.action is 'compose' or
           @props.layout.rightPanel?.action is 'compose'
            composeUrl = selectedAccountUrl
        else
            composeUrl = @buildUrl
                direction: 'right'
                action: 'compose'
                parameters: null
                fullWidth: false

        # the button toggle the "new mailbox" screen
        if @props.layout.leftPanel.action is 'account.new'
            newMailboxUrl = selectedAccountUrl
        else
            newMailboxUrl = @buildUrl
                direction: 'left'
                action: 'account.new'
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


    # renders a single mailbox and its submenu
    getAccountRender: (account, key) ->

        isSelected = (not @props.selectedAccount? and key is 0) \
                     or @props.selectedAccount?.get('id') is account.get('id')

        accountClasses = classer active: isSelected
        url = @buildUrl
            direction: 'left'
            action: 'account.messages'
            parameters: account.get 'id'
            fullWidth: false

        li className: accountClasses, key: key,
            a href: url, className: 'menu-item ' + accountClasses,
                i className: 'fa fa-inbox'
                span className: 'badge', account.get 'unreadCount'
                span className: 'item-label', account.get 'label'

            ul className: 'list-unstyled submenu mailbox-list',
                @props.favoriteMailboxes.map (mailbox, key) =>
                    @getMailboxRender mailbox, key
                .toJS()

    getMailboxRender: (mailbox, key) ->
        mailboxUrl = @buildUrl
            direction: 'left'
            action: 'account.mailbox.messages'
            parameters: [mailbox.get('mailbox'), mailbox.get('id')]

        a href: mailboxUrl, className: 'menu-item', key: key,
            # Something must be rethought about the icon
            i className: 'fa fa-star'
            span className: 'badge', Math.floor((Math.random() * 10) + 1) # placeholder
            span className: 'item-label', mailbox.get 'name'
