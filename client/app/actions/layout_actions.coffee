XHRUtils = require '../utils/XHRUtils'

module.exports =

    showReponsiveMenu: ->
        @dispatch 'SHOW_MENU_RESPONSIVE'

    hideReponsiveMenu: ->
        @dispatch 'HIDE_MENU_RESPONSIVE'

    showEmailList: (panelInfo, direction) ->
        @dispatch 'HIDE_MENU_RESPONSIVE'
        @dispatch 'SELECT_MAILBOX', panelInfo.parameters[0]

        flux = require '../fluxxor'
        defaultMailbox = flux.store('MailboxStore').getDefault()
        mailboxID = panelInfo.parameters[0] or defaultMailbox?.get('id')
        if mailboxID?
            XHRUtils.fetchEmailsByMailbox mailboxID
            XHRUtils.fetchImapFolderByMailbox mailboxID

    showEmailThread: (panelInfo, direction) ->
        @dispatch 'HIDE_MENU_RESPONSIVE'
        XHRUtils.fetchEmailThread panelInfo.parameters[0]

    showComposeNewEmail: (panelInfo, direction) ->
        @dispatch 'HIDE_MENU_RESPONSIVE'

    showCreateMailbox: (panelInfo, direction) ->
        @dispatch 'HIDE_MENU_RESPONSIVE'
        @dispatch 'SELECT_MAILBOX', -1

    showConfigMailbox: (panelInfo, direction) ->
        @dispatch 'HIDE_MENU_RESPONSIVE'
        @dispatch 'SELECT_MAILBOX', panelInfo.parameters[0]