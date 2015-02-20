PanelRouter = require './libs/panel_router'

AccountStore = require './stores/account_store'
MessageStore = require './stores/message_store'

module.exports = class Router extends PanelRouter

    patterns:
        'account.config':
            pattern: 'account/:accountID/config/:tab'
            fluxAction: 'showConfigAccount'
        'account.new':
            pattern: 'account/new'
            fluxAction: 'showCreateAccount'
        'account.mailbox.messages.full':
            pattern: 'account/:accountID/box/:mailboxID/sort/:sort/' +
                        'flag/:flag/before/:before/after/:after/' +
                        'page/:pageAfter'
            fluxAction: 'showMessageList'
        'account.mailbox.messages':
            pattern: 'account/:accountID/mailbox/:mailboxID'
            fluxAction: 'showMessageList'

        'search':
            pattern: 'search/:query/page/:page'
            fluxAction: 'showSearch'

        'message':
            pattern: 'message/:messageID'
            fluxAction: 'showMessage'
        'conversation':
            pattern: 'conversation/:conversationID/:messageID/'
            fluxAction: 'showConversation'
        'compose':
            pattern: 'compose'
            fluxAction: 'showComposeNewMessage'
        'edit':
            pattern: 'edit/:messageID'
            fluxAction: 'showComposeMessage'

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
            ,    'account.mailbox.messages.full'
                defaultAccountID = AccountStore.getDefault()?.get 'id'
                defaultMailboxID = AccountStore.getDefaultMailbox(defaultAccountID)?.get 'id'
                defaultParameters = _.clone(MessageStore.getParams())
                defaultParameters.accountID = defaultAccountID
                defaultParameters.mailboxID = defaultMailboxID
                defaultParameters.sort = '-'
                defaultParameters.pageAfter = '-'
            when 'account.config'
                defaultAccount = AccountStore.getDefault()?.get 'id'
                defaultParameters =
                    accountID: defaultAccount
                    tab: 'account'
            when 'search'
                defaultParameters =
                    query: ""
                    page: 1
            else
                defaultParameters = null
        return defaultParameters
