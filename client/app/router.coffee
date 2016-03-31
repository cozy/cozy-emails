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

        'account.mailbox.messages':
            pattern: 'account/:accountID/mailbox/:mailboxID/sort/:sort/' +
                     ':type/:flag/before/:before/after/:after'
            fluxAction: 'showMessageList'

        'search':
            pattern: 'account/:accountID/search/:search'
            fluxAction: 'showSearchResult'

        'message':
            pattern: 'message/:messageID'
            fluxAction: 'showMessage'

        'conversation':
            pattern: 'conversation/:conversationID/:messageID/'
            fluxAction: 'showConversation'

        'default':
            pattern: ''
            fluxAction: ''

    # default route
    routes: '': 'default'

    # Determines and gets the default parameters regarding a specific action
    _getDefaultParameters: (action, parameters) ->
        switch action

            when 'account.mailbox.messages'
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
                defaultParameters.sort = '-date'
                defaultParameters.after = '-'
                defaultParameters.before = '-'
                defaultParameters.type = 'nofilter'
                defaultParameters.flag = '-'

            when 'account.config'
                defaultAccount = AccountStore.getDefault()?.get 'id'
                defaultParameters =
                    accountID: defaultAccount
                    tab: 'account'

            when 'search'
                defaultParameters =
                    accountID: 'all'
                    search: '-'

            else
                defaultParameters = null

        return defaultParameters
