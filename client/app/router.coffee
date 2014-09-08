PanelRouter = require './libs/PanelRouter'

AccountStore = require './stores/AccountStore'

module.exports = class Router extends PanelRouter

    patterns:
        'account.config':
            pattern: 'account/:id/config'
            fluxAction: 'showConfigAccount'
        'account.new':
            pattern: 'account/new'
            fluxAction: 'showCreateAccount'
        'account.mailbox.messages':
            pattern: 'account/:id/mailbox/:mailbox/page/:page'
            fluxAction: 'showMessageList'

        'search':
            pattern: 'search/:query/page/:page'
            fluxAction: 'showSearch'

        'message':
            pattern: 'message/:id'
            fluxAction: 'showConversation'
        'compose':
            pattern: 'compose'
            fluxAction: 'showComposeNewMessage'

        'settings':
            pattern: 'settings'
            fluxAction: 'showSettings'

    # default route
    routes: '': 'account.mailbox.messages'

    # Determines and gets the default parameters regarding a specific action
    _getDefaultParameters: (action) ->
        switch action
            when 'account.mailbox.messages'
                defaultAccount = AccountStore.getDefault()
                defaultMailbox = defaultAccount?.get('mailboxes').first()
                defaultParameters = [
                    defaultAccount?.get('id')
                    defaultMailbox?.get('id')
                    1
                ]
            when 'account.config'
                defaultAccount = AccountStore.getDefault()?.get 'id'
                defaultParameters = [defaultAccount]
            when 'search'
                defaultParameters = ["", 1]
            else
                defaultParameters = null
        return defaultParameters
