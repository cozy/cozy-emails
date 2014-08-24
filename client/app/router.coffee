PanelRouter = require './libs/PanelRouter'

module.exports = class Router extends PanelRouter

    patterns:
        'mailbox.config':
            pattern: 'mailbox/:id/config'
            fluxAction: 'showConfigMailbox'
        'mailbox.new':
            pattern: 'mailbox/new'
            fluxAction: 'showCreateMailbox'
        'mailbox.imap.emails':
            pattern: 'mailbox/:id/folder/:folder'
            fluxAction: 'showEmailList'
        'mailbox.emails':
            pattern: 'mailbox/:id'
            fluxAction: 'showEmailList'

        'email':
            pattern: 'email/:id'
            fluxAction: 'showEmailThread'
        'compose':
            pattern: 'compose'
            fluxAction: 'showComposeNewEmail'

    # default route
    routes: '': 'mailbox.emails'