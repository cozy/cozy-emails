MessageUtils  = require './message_utils'
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
        return message?.toJS()

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
        if typeof key is 'object'
            for own k, v of key
                settings[k] = v
        else
            settings[key] = value
        AppDispatcher.handleViewAction
            type: ActionTypes.SETTINGS_UPDATED
            value: settings

    messageNavigate: (direction, inConv) ->
        if not onMessageList()
            return
        conv = inConv and SettingsStore.get('displayConversation') and
            SettingsStore.get('displayPreview')
        if direction is 'prev'
            next = MessageStore.getPreviousMessage conv
        else
            next = MessageStore.getNextMessage conv
        if not next?
            return

        MessageActionCreator = require '../actions/message_action_creator'

        MessageActionCreator.setCurrent next.get('id'), true

        if SettingsStore.get('displayPreview')
            @messageDisplay next

    messageDisplay: (message) ->
        if not message?
            message = MessageStore.getById(MessageStore.getCurrentID())
        if not message?
            return
        if SettingsStore.get('displayConversation')
            action = 'conversation'
            params =
                messageID: message.get 'id'
                conversationID: message.get 'conversationID'
        else
            action = 'message'
            params =
                messageID: message.get 'id'

        urlOptions =
            direction: 'second'
            action: action
            parameters: params
        url = window.router.buildUrl urlOptions
        window.router.navigate url, {trigger: true}

    messageClose: ->
        closeUrl = window.router.buildUrl
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters:
                accountID: AccountStore.getSelected().get 'id'
                mailboxID: AccountStore.getSelectedMailbox().get 'id'
            fullWidth: true
        window.router.navigate closeUrl, {trigger: true}

    messageDeleteCurrent: ->
        if not onMessageList()
            return
        messageID = MessageStore.getCurrentID()
        if not messageID?
            return
        settings = SettingsStore.get()
        MessageUtils.delete messageID, settings.get 'displayConversation',
            settings.get 'messageConfirmDelete'

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
                "accountID": AccountStore.getDefault()?.get('id'),
                "id": AccountStore.getDefaultMailbox()?.get('id'),
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
            # If no option given, use title as notification body
            if not options?
                options =
                    body: title
            # prevent dispatching when already dispatching
            window.setTimeout ->
                LayoutActionCreator.notify "#{title} - #{options.body}"
            , 0

    # Send errors to serveur
    # Usage: window.cozyMails.log(new Error('message'))
    log: (error) ->
        url = error.stack.split('\n')[0].split('@')[1]
            .split(/:\d/)[0].split('/').slice(0, -2).join('/')
        window.onerror error.name, url, error.lineNumber, error.colNumber, error

    # Debug: allow to dump component tree
    dump: ->
        _dump = (root) ->
            res =
                children: {}
                state: {}
                props: {}
            for key, value of root.state
                if (typeof root.state[key] is 'object')
                    res.state[key] = '{object}'
                else
                    res.state[key] = value
            for key, value of root.props
                if (typeof root.props[key] is 'object')
                    res.props[key] = '{object}'
                else
                    res.props[key] = value
            for key, value of root.refs
                res.children[key] = _dump root.refs[key]

            return res

        _dump window.rootComponent

