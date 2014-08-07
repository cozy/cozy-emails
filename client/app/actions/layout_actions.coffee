XHRUtils = require '../utils/XHRUtils'

module.exports =

    showEmailList: (panelInfo, direction) ->
        @dispatch 'SELECT_MAILBOX', panelInfo.parameter

        flux = require '../fluxxor'
        defaultMailbox = flux.store('MailboxStore').getDefault()
        mailboxID = panelInfo.parameter or defaultMailbox?.id
        if mailboxID?
            XHRUtils.fetchEmailsByMailbox mailboxID

    showEmailThread: (panelInfo, direction) ->
        XHRUtils.fetchEmailThread panelInfo.parameter

    showComposeNewEmail: (panelInfo, direction) ->
        # nothing

    showCreateMailbox: (panelInfo, direction) ->
        @dispatch 'SELECT_MAILBOX', -1

    showConfigMailbox: (panelInfo, direction) ->
        @dispatch 'SELECT_MAILBOX', panelInfo.parameter