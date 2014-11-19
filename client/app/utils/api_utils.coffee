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
        AccountStore.getSelected()

    getCurrentMailbox: ->
        AccountStore.getSelectedMailboxes true

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

        if SettingsStore.get('displayPreview')
            @messageDisplay nextID
        else
            MessageActionCreator = require '../actions/message_action_creator'
            MessageActionCreator.setCurrent nextID

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
        alertSuccess = LayoutActionCreator.alertSuccess
        message = MessageStore.getByID MessageStore.getCurrentID()
        if not message?
            return
        if (not SettingsStore.get('messageConfirmDelete')) or
        window.confirm(t 'mail confirm delete', {subject: message.get('subject')})
            nextID = MessageStore.getNextMessage()
            MessageActionCreator.delete message, (error) =>
                if error?
                    alertError "#{t("message action delete ko")} #{error}"
                else
                    alertSuccess t "message action delete ok"
                    @messageNavigate(null, nextID)

    messageUndo: ->
        MessageActionCreator = require '../actions/message_action_creator'
        MessageActionCreator.undelete()

