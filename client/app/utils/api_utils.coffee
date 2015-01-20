AccountStore  = require '../stores/account_store'
MessageStore  = require '../stores/message_store'
SettingsStore = require '../stores/settings_store'
LayoutActionCreator = require '../actions/layout_action_creator'

onMessageList = ->
    actions = [
        "account.mailbox.messages",
        "account.mailbox.messages.full"
    ]
    return router.current.firstPanel?.action in actions

module.exports =
    getCurrentAccount: ->
        AccountStore.getSelected()?.toJS()

    getCurrentMailbox: ->
        AccountStore.getSelectedMailbox()?.toJS()

    getCurrentMessage: ->
        messageID = MessageStore.getCurrentID()
        message = MessageStore.getByID messageID
        return message.toJS()

    getCurrentActions: ->
        res = []
        Object.keys(router.current).forEach (panel) ->
            if router.current[panel]?
                res.push router.current[panel].action
        return res

    messageNew: ->
        router.navigate('compose/', {trigger: true})

    # update locate (without saving it into settings)
    setLocale: (lang, refresh) ->
        window.moment.locale lang
        locales = {}
        try
            locales = require "../locales/#{lang}"
        catch err
            console.log err
            locales = require "../locales/en"
        polyglot = new Polyglot()
        # we give polyglot the data
        polyglot.extend locales
        # handy shortcut
        window.t = polyglot.t.bind polyglot
        if refresh
            LayoutActionCreator.refresh()

    getAccountByLabel: (label) ->
        return AccountStore.getByLabel label

    getSetting: (key) ->
        return SettingsStore.get().toJS()[key]

    # warning: don't update setting value server side
    setSetting: (key, value) ->
        AppDispatcher = require '../app_dispatcher'
        {ActionTypes} = require '../constants/app_constants'
        settings = SettingsStore.get().toJS()
        settings[key] = value
        AppDispatcher.handleViewAction
            type: ActionTypes.SETTINGS_UPDATED
            value: settings

    messageNavigate: (direction, nextID) ->
        if not onMessageList()
            return
        if not nextID?
            if direction is 'prev'
                nextID = MessageStore.getPreviousMessage()
            else
                nextID = MessageStore.getNextMessage()
        if not nextID?
            return

        MessageActionCreator = require '../actions/message_action_creator'
        MessageActionCreator.setCurrent nextID

        if SettingsStore.get('displayPreview')
            @messageDisplay nextID

    messageDisplay: (messageID) ->
        if not messageID
            messageID = MessageStore.getCurrentID()
        action = 'message'
        if SettingsStore.get('displayConversation')
            message = MessageStore.getByID messageID
            if not message?
                return
            conversationID = message.get 'conversationID'

            if conversationID
                action = 'conversation'

        url = window.router.buildUrl direction: 'second', action: action, parameters: messageID
        window.router.navigate url, {trigger: true}

    messageClose: ->
        closeUrl = window.router.buildUrl
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters: AccountStore.getSelected().get 'id'
            fullWidth: true
        window.router.navigate closeUrl, {trigger: true}

    messageDeleteCurrent: ->
        if not onMessageList()
            return
        MessageActionCreator = require '../actions/message_action_creator'
        alertError   = LayoutActionCreator.alertError
        message = MessageStore.getByID MessageStore.getCurrentID()
        if not message?
            return
        if (not SettingsStore.get('messageConfirmDelete')) or
        window.confirm(t 'mail confirm delete', {subject: message.get('subject')})
            nextID = MessageStore.getNextMessage()
            @messageNavigate(null, nextID)
            MessageActionCreator.delete message, (error) ->
                if error?
                    alertError "#{t("message action delete ko")} #{error}"

    messageUndo: ->
        MessageActionCreator = require '../actions/message_action_creator'
        MessageActionCreator.undelete()

    customEvent: (name, data) ->
        domEvent = new CustomEvent name, detail: data
        window.dispatchEvent domEvent

    simulateUpdate: ->

        AppDispatcher = require '../app_dispatcher'
        window.setInterval ->
            content =
                "accountID": AccountStore.getDefault().get('id'),
                "id": AccountStore.getDefaultMailbox().get('id'),
                "label": "INBOX",
                "path": "INBOX",
                "tree": ["INBOX"],
                "delimiter": ".",
                "uidvalidity": Date.now()
                "attribs":[],
                "docType": "Mailbox",
                "lastSync": new Date().toISOString(),
                "nbTotal": 467,
                "nbUnread": 0,
                "nbRecent": 5,
                "weight": 1000,
                "depth": 0
            AppDispatcher.handleServerAction
                type: 'RECEIVE_MAILBOX_UPDATE'
                value: content
        , 5000

    notify: (title, options) ->
        if window.Notification? and SettingsStore.get 'desktopNotifications'
            new Notification title, options
        else
            # prevent dispatching when already dispatching
            window.setTimeout ->
                LayoutActionCreator.notify "#{title} - #{options.body}"
            , 0

