XHRUtils = require '../utils/XHRUtils'
MailboxStore = require '../stores/MailboxStore'
AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'
MailboxActionCreator = require './MailboxActionCreator'

module.exports = LayoutActionCreator =

    showReponsiveMenu: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SHOW_MENU_RESPONSIVE
            value: null

    hideReponsiveMenu: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.HIDE_MENU_RESPONSIVE
            value: null

    showEmailList: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()

        defaultMailbox = MailboxStore.getDefault()
        mailboxID = panelInfo.parameters[0] or defaultMailbox?.get('id')

        MailboxActionCreator.selectMailbox mailboxID

        if mailboxID?
            XHRUtils.fetchEmailsByMailbox mailboxID
            XHRUtils.fetchImapFolderByMailbox mailboxID

    showEmailThread: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        XHRUtils.fetchEmailThread panelInfo.parameters[0], (err, rawEmail) ->

            # if there isn't a selected mailbox (page loaded directly),
            # select the email's mailbox
            selectedMailbox = MailboxStore.getSelected()
            if  not selectedMailbox? and rawEmail.mailbox
                MailboxActionCreator.selectMailbox rawEmail.mailbox


    showComposeNewEmail: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()

    showCreateMailbox: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        MailboxActionCreator.selectMailbox -1

    showConfigMailbox: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        MailboxActionCreator.selectMailbox panelInfo.parameters[0]
