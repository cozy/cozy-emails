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
            pattern: 'account/:id/mailbox/:mailbox'
            fluxAction: 'showMessageList'
        'account.messages':
            pattern: 'account/:id'
            fluxAction: 'showMessageList'

        'message':
            pattern: 'message/:id'
            fluxAction: 'showConversation'
        'compose':
            pattern: 'compose'
            fluxAction: 'showComposeNewMessage'

    # default route
    routes: '': 'account.messages'

    # Determines and gets the default parameters regarding a specific action
    _getDefaultParameters: (action) ->
        switch action
            when 'account.messages', 'account.config'
                defaultAccount = AccountStore.getDefault()?.id
                defaultParameters = [defaultAccount]
            when 'account.imap.messages'
                defaultAccount = AccountStore.getDefault()?.id
                defaultMailbox = 'lala'
                defaultParameters = [defaultAccount, defaultMailbox]
            else
                defaultParameters = null

        return defaultParameters