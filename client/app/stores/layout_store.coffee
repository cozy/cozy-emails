Store = require '../libs/flux/store/store'

{ActionTypes, Dispositions} = require '../constants/app_constants'

class LayoutStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _disposition = Dispositions.COL

    # TODO: Use a constant for default value?
    _previewSize = 50

    _alert =
        level: null
        message: null

    _tasks = Immutable.OrderedMap()

    _shown = true

    _intentAvailable = false

    _drawer = false


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SET_DISPOSITION, (disposition) ->
            _disposition = disposition
            @emit 'change'

        handle ActionTypes.RESIZE_PREVIEW_PANE, (factor) ->
            console.debug factor
            if factor
                _previewSize += factor
                # set limits
                _previewSize = 20 if _previewSize < 20
                _previewSize = 80 if _previewSize > 80
            else
                _previewSize = 50
            @emit 'change'

        handle ActionTypes.DISPLAY_ALERT, (value) ->
            _alert.level   = value.level
            _alert.message = value.message
            @emit 'change'

        handle ActionTypes.HIDE_ALERT, (value) ->
            _alert.level   = null
            _alert.message = null
            @emit 'change'

        # Hide alerts on mailbox / account change
        handle ActionTypes.SELECT_ACCOUNT, (value) ->
            _alert.level   = null
            _alert.message = null
            @emit 'change'

        handle ActionTypes.REFRESH, ->
            @emit 'change'

        handle ActionTypes.CLEAR_TOASTS, ->
            _tasks = Immutable.OrderedMap()
            @emit 'change'

        handle ActionTypes.RECEIVE_TASK_UPDATE, (task) =>
            task = Immutable.Map task
            id = task.get 'id'
            _tasks = _tasks.set id, task
            if task.get 'autoclose'
                remove = =>
                    _tasks = _tasks.remove id
                    @emit 'change'
                setTimeout remove, 5000
            @emit 'change'

        handle ActionTypes.RECEIVE_TASK_DELETE, (taskid) ->
            _tasks = _tasks.remove taskid
            @emit 'change'

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


    ###
        Public API
    ###
    getDisposition: -> return _disposition

    getPreviewSize: -> return _previewSize

    getAlert: -> return _alert

    getToasts: -> return _tasks

    isShown: -> return _shown

    intentAvailable: -> return _intentAvailable

    isDrawerExpanded: -> return _drawer

module.exports = new LayoutStore()
