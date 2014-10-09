PanelRouter = require './libs/panel_router'

AccountStore = require './stores/account_store'

module.exports = class Router extends PanelRouter

    patterns:
        'account.config':
            pattern: 'account/:accountID/config'
            fluxAction: 'showConfigAccount'
        'account.new':
            pattern: 'account/new'
            fluxAction: 'showCreateAccount'
        'account.mailbox.messages':
            pattern: 'account/:accountID/mailbox/:mailboxID/page/:page'
            fluxAction: 'showMessageList'

        'search':
            pattern: 'search/:query/page/:page'
            fluxAction: 'showSearch'

        'message':
            pattern: 'message/:messageID'
            fluxAction: 'showConversation'
        'compose':
            pattern: 'compose/:messageID'
            fluxAction: 'showComposeNewMessage'

        'settings':
            pattern: 'settings'
            fluxAction: 'showSettings'
        
        'default':
            pattern: ''
            fluxAction: ''

    # default route
    routes: '': 'default'

    # Determines and gets the default parameters regarding a specific action
    _getDefaultParameters: (action) ->
        switch action
            when 'account.mailbox.messages'
                defaultAccount = AccountStore.getDefault()
                defaultMailbox = defaultAccount?.get('mailboxes').first()
                defaultParameters =
                    accountID: defaultAccount?.get 'id'
                    mailboxID: defaultMailbox?.get 'id'
                    page: 1
            when 'account.config'
                defaultAccount = AccountStore.getDefault()?.get 'id'
                defaultParameters = accountID: defaultAccount
            when 'search'
                defaultParameters =
                    query: ""
                    page: 1
            else
                defaultParameters = null
        return defaultParameters
