PanelRouter = require './libs/PanelRouter'

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