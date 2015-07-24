Store = require '../libs/flux/store/store'

{ActionTypes, Dispositions} = require '../constants/app_constants'

MessageActionCreator = null
getMessageActionCreator = ->
    MessageActionCreator ?= require '../actions/message_action_creator'
    return MessageActionCreator


class LayoutStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _disposition = Dispositions.COL

    # TODO: Use a constant for default value?
    _previewSize = 60

    _previewFullscreen = false

    _tasks = Immutable.OrderedMap()

    _shown = true

    _intentAvailable = false

    _drawer = false

    _modal  = null


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SET_DISPOSITION, (disposition) ->
            _disposition = disposition
            @emit 'change'

        handle ActionTypes.RESIZE_PREVIEW_PANE, (factor) ->
            if factor
                _previewSize += factor
                # set limits
                _previewSize = 20 if _previewSize < 20
                _previewSize = 80 if _previewSize > 80
            else
                _previewSize = 50
            @emit 'change'

        handle ActionTypes.MINIMIZE_PREVIEW_PANE, ->
            _previewFullscreen = false
            @emit 'change'

        handle ActionTypes.MAXIMIZE_PREVIEW_PANE, ->
            _previewFullscreen = true
            @emit 'change'

        handle ActionTypes.DISPLAY_MODAL, (value) ->
            _modal = value
            @emit 'change'

        handle ActionTypes.HIDE_MODAL, (value) ->
            _modal = null
            @emit 'change'

        handle ActionTypes.REFRESH, ->
            @emit 'change'

        handle ActionTypes.CLEAR_TOASTS, ->
            _tasks = Immutable.OrderedMap()
            @emit 'change'

        handle ActionTypes.RECEIVE_TASK_UPDATE, (task) =>
            @_showNotification task

        handle ActionTypes.RECEIVE_TASK_DELETE, (taskid) ->
            @_removeNotification taskid

        handle ActionTypes.TOASTS_SHOW, ->
            _shown = true
            @emit 'change'

        handle ActionTypes.TOASTS_HIDE, ->
            _shown = false
            @emit 'change'

        handle ActionTypes.INTENT_AVAILABLE, (avaibility) ->
            _intentAvailable = avaibility
            @emit 'change'

        handle ActionTypes.DRAWER_SHOW, ->
            return if _drawer is true
            _drawer = true
            @emit 'change'

        handle ActionTypes.DRAWER_HIDE, ->
            return if _drawer is false
            _drawer = false
            @emit 'change'

        handle ActionTypes.DRAWER_TOGGLE, ->
            _drawer = not _drawer
            @emit 'change'

        makeErrorMessage = (error) ->
            if error.name is 'AccountConfigError'
                t "config error #{error.field}"
            else
                error.message or error.name or error

        makeMessage = (target, ref, actionAndOK, errMsg)->
            subject = target?.subject

            if target.messageID and target.isDraft
                type = 'draft'
            else if target.messageID
                type = 'message'
            else if target.conversationID
                type = 'conversation'
            else if target.conversationIDs
                type = 'conversations'
                smart_count = target.conversationIDs.length
            else if target.messageIDs
                type = 'messages'
                smart_count = target.messageIDs.length
            else
                throw new Error 'Wrong Usage : unrecognized target'

            return t "#{type} #{actionAndOK}",
                error: errMsg
                subject: subject or ''
                smart_count: smart_count

        makeUndoAction = (ref) ->
            label: t 'action undo'
            onClick: -> getMessageActionCreator().undo ref

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, ref, updated}) ->
            @_showNotification
                message: makeMessage target, ref, 'delete ok'
                actions: [makeUndoAction ref]
                autoclose: true

        handle ActionTypes.MESSAGE_TRASH_FAILURE, ({target, ref, error}) ->
            @_showNotification
                message: makeMessage target, ref, 'delete ko', error
                errors: [error]
                autoclose: true

        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({target, ref, updated}) ->
            unless target.silent
                @_showNotification
                    message: makeMessage target, ref, 'move ok'
                    actions: [makeUndoAction ref]
                    autoclose: true

        handle ActionTypes.MESSAGE_MOVE_FAILURE, ({target, ref, error}) ->
            @_showNotification
                message: makeMessage target, ref, 'move ko', error
                errors: [error]
                autoclose: true

        # dont display a notification for MESSAGE_FLAG_SUCCESS
        handle ActionTypes.MESSAGE_FLAGS_FAILURE, ({target, ref, error}) ->
            @_showNotification
                message: makeMessage target, ref, 'flag ko', error
                errors: [error]
                autoclose: true

        # dont display a notification for MESSAGE_RECOVER_SUCCESS
        handle ActionTypes.MESSAGE_RECOVER_FAILURE, ({target, ref, error}) ->
            @_showNotification
                message: 'lost server connection'
                errors: [error]
                autoclose: true

        handle ActionTypes.MESSAGE_FETCH_FAILURE, ({error}) ->
            @_showNotification
                message: 'message fetch failure'
                errors: [error]
                autoclose: true

        handle ActionTypes.REFRESH_FAILURE, ({error}) ->
            @_showNotification
                message: makeErrorMessage error
                errors: [error]
                autoclose: true


    ###
        Private API
    ###
    _removeNotification: (id) ->
        _tasks = _tasks.remove id
        @emit 'change'

    _showNotification: (options) ->
        id = options.id or +Date.now()
        options.finished ?= true
        _tasks = _tasks.set id, Immutable.Map options
        if options.autoclose
            setTimeout @_removeNotification.bind(@, id), 5000
        @emit 'change'

    ###
        Public API
    ###
    getDisposition: ->
        return _disposition


    getPreviewSize: ->
        return _previewSize


    isPreviewFullscreen: ->
        return _previewFullscreen


    getModal: ->
        return _modal


    getToasts: ->
        return _tasks


    isShown: ->
        return _shown


    intentAvailable: ->
        return _intentAvailable


    isDrawerExpanded: ->
        return _drawer


module.exports = LayoutStoreInstance = new LayoutStore()

