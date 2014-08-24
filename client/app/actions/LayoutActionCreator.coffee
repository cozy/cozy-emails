XHRUtils = require '../utils/XHRUtils'
MailboxStore = require '../stores/MailboxStore'
AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'

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

        LayoutActionCreator._selectMailbox mailboxID

        if mailboxID?
            XHRUtils.fetchEmailsByMailbox mailboxID
            XHRUtils.fetchImapFolderByMailbox mailboxID

    showEmailThread: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        XHRUtils.fetchEmailThread panelInfo.parameters[0]

    showComposeNewEmail: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()

    showCreateMailbox: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        LayoutActionCreator._selectMailbox -1

    showConfigMailbox: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        LayoutActionCreator._selectMailbox panelInfo.parameters[0]

    _selectMailbox: (mailboxID) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SELECT_MAILBOX
            value: mailboxID
