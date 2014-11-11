AccountStore  = require '../stores/account_store'
LayoutActionCreator = require '../actions/layout_action_creator'

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
        SettingsStore = require '../stores/settings_store'
        AppDispatcher = require '../app_dispatcher'
        {ActionTypes} = require '../constants/app_constants'
        settings = SettingsStore.get().toJS()
        settings[key] = value
        AppDispatcher.handleViewAction
            type: ActionTypes.SETTINGS_UPDATED
            value: settings

    messageNavigate: (direction) ->
        MessageStore  = require '../stores/message_store'
        SettingsStore = require '../stores/settings_store'
        if direction is 'prev'
            nextID = MessageStore.getPreviousMessage()
        else
            nextID = MessageStore.getNextMessage()
        if not nextID?
            return
        message = MessageStore.getByID MessageStore.getCurrentID()
        conversationID = message.get 'conversationID'

        if conversationID and SettingsStore.get('displayConversation')
            action = 'conversation'
        else
            action = 'message'

        url = window.router.buildUrl direction: 'second', action: action, parameters: nextID
        window.router.navigate url, {trigger: true}
