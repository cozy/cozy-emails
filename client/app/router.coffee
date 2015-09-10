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
            pattern: 'account/:accountID/mailbox/:mailboxID/sort/:sort/flag/:flag'
            fluxAction: 'showMessageList'
        'account.mailbox.messages':
            pattern: 'account/:accountID/mailbox/:mailboxID'
            fluxAction: 'showMessageList'
        'account.mailbox.default':
            pattern: 'account/:accountID'
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
        'compose.reply':
            pattern: 'reply/:messageID'
            fluxAction: 'showComposeMessage'
        'compose.reply-all':
            pattern: 'reply-all/:messageID'
            fluxAction: 'showComposeMessage'
        'compose.forward':
            pattern: 'forward/:messageID'
            fluxAction: 'showComposeMessage'
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
    _getDefaultParameters: (action, parameters) ->
        switch action

            when 'account.mailbox.messages'
            ,    'account.mailbox.messages.full'
            ,    'account.mailbox.default'
                defaultAccountID = AccountStore.getDefault()?.get 'id'
                # if parameters contains accountID but no mailboxID,
                # get the default mailbox for this account
                if parameters.accountID?
                    mailbox = AccountStore.getDefaultMailbox parameters.accountID
                else
                    mailbox = AccountStore.getDefaultMailbox defaultAccountID
                defaultMailboxID = mailbox?.get 'id'
                defaultParameters = {}
                defaultParameters.accountID = defaultAccountID
                defaultParameters.mailboxID = defaultMailboxID
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

