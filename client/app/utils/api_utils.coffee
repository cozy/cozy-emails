React    = require 'react'
_        = require 'underscore'
Polyglot = require 'node-polyglot'
moment   = require 'moment'

{sendReport} = require './error_manager'

RouterGetter = require '../getters/router'

# FIXME : remove all this from Stores to  RouterGetter
AccountStore  = require '../stores/account_store'
MessageStore  = require '../stores/message_store'
RouterStore  = require '../stores/router_store'

SettingsStore = require '../stores/settings_store'
LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
RouterActionCreator  = require '../actions/router_action_creator'
NotificationActionsCreator = require '../actions/notification_action_creator'

{MessageActions, AccountActions} = require '../constants/app_constants'


onMessageList = ->
    return RouterStore.getAction() in [MessageActions.SHOW_ALL, MessageActions.SHOW]


module.exports = Utils =


    debugLogs: []


    getCurrentAccount: ->
        AccountStore.getSelected()?.toJS()


    getCurrentMailbox: ->
        AccountStore.getSelectedMailbox()?.toJS()


    getCurrentMessage: ->
        messageID = MessageStore.getCurrentID()
        message = MessageStore.getByID messageID
        return message?.toJS()


    getMessage: (id) ->
        message = MessageStore.getByID id
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
    setLocale: (lang) ->
        moment.locale lang
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
        AppDispatcher.dispatch
            type: ActionTypes.SETTINGS_UPDATE_SUCCESS
            value: settings

    # top/bottom navigation
    # `top` key     -> direction is prev
    # `bottom` key  -> direction is next
    messageNavigate: (direction) ->
        if 'prev' is direction
            messageID = MessageStore.getNextConversation()?.get 'id'
        else
            messageID = MessageStore.getPreviousConversation()?.get 'id'
        RouterActionCreator.navigate {messageID}


    messageSetCurrent: (message) ->
        return unless message?.get('id')

        MessageActionCreator.setCurrent message.get('id'), true

        if SettingsStore.get('displayPreview')
            @messageDisplay message


    ##
    # Display a message
    # @params {Immutable} message the message (current one if null)
    messageDisplay: (message) ->
        messageID = message?.get('id') or MessageStore.getCurrentID()
        RouterActionCreator.navigate {messageID}


    messageClose: ->
        url = window.location.href
        url = url.replace /\/message\/[\w-]+/gi, ''
        url = url.replace /\/conversation\/[\w-]+\/[\w-]+/gi, ''
        url = url.replace /\/edit\/[\w-]+/gi, ''
        RouterActionCreator.navigate {url}

    messageDeleteCurrent: ->
        messageID = MessageStore.getCurrentID()
        if not onMessageList() or not messageID?
            return

        deleteMessage = (isModal) ->
            MessageActionCreator.delete {messageID}
            RouterActionCreator.navigate action: MessageActions.GROUP_NEXT

        settings = SettingsStore.get()

        # Delete Message without modal
        unless (confirm = settings.get 'messageConfirmDelete')
            deleteMessage false
            return

        # Display 'delete' modal
        confirmMessage = t 'list delete conv confirm',
            smart_count: 1
        modal =
            title       : t 'app confirm delete'
            subtitle    : confirmMessage
            closeLabel  : t 'app cancel'
            actionLabel : t 'app confirm'
            action      : deleteMessage
        LayoutActionCreator.displayModal modal


    messageUndo: ->
        MessageActionCreator.undo()


    simulateUpdate: ->

        AppDispatcher = require '../app_dispatcher'
        window.setInterval ->
            content =
                "accountID": AccountStore.getAccountID()
                "id": AccountStore.getMailboxID()
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
            AppDispatcher.dispatch
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
                NotificationActionsCreator.alert "#{title} - #{options.body}"
            , 0


    # Send errors to serveur
    # Usage: window.cozyMails.log(new Error('message'))
    log: (error) ->
        url = error.stack.split('\n')[0].split('@')[1]
            .split(/:\d/)[0].split('/').slice(0, -2).join('/')
        window.onerror error.name, url, error.lineNumber, error.colNumber, error


    # Log message into server logs
    logInfo: (message) ->
        sendReport 'debug', message


    # Log every Flux action (only in development environment)
    # Logs can be displayed using `displayLogs`
    logAction: (action, message) ->
        if window.app_env is "development"
            # remove some data from action value to lighten the logs
            actionCleanup = (action) ->
                act = _.clone action
                # remove message content
                cleanMsg = (val) ->
                    if val?
                        newVal = _.clone val
                        delete newVal.headers
                        delete newVal.html
                        delete newVal.text
                        delete newVal.attachments
                        return newVal
                if Array.isArray act.value
                    act.value = act.value.map cleanMsg
                else
                    act.value = cleanMsg act.value
                    if Array.isArray act.value?.messages
                        act.value.messages = act.value.messages.map cleanMsg
                return act

            # get call stack
            stack = new Error().stack or ''
            stack = stack.split("\n").filter (trace) ->
                return /app.js/.test(trace.split('@'))
            .map (trace) ->
                return trace.split('@')[0]

            # store logs
            _log =
                date: new Date().toISOString()
                stack: stack.splice(2)
            if action?
                _log.action = actionCleanup action
            if message?
                _log.message = message
            window.cozyMails.debugLogs.unshift _log

            # only keep the last 100 lines of logs
            window.cozyMails.debugLogs = window.cozyMails.debugLogs.slice 0, 100


    # display action logs in a modal window
    displayLogs: ->
        modal =
            title       : t 'modal please contribute'
            subtitle    : t 'modal please report'
            allowCopy   : true
            closeLabel  : t 'app alert close'
            content     : React.DOM.pre
                style: "max-height": "300px",
                "word-wrap": "normal",
                    JSON.stringify(window.cozyMails.debugLogs, null, 4)
        LayoutActionCreator.displayModal modal


    # clear action logs
    clearLogs: ->
        window.cozyMails.debugLogs = []
