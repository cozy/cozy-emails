Store = require '../libs/flux/store/store'

{ActionTypes, Dispositions} = require '../constants/app_constants'

class LayoutStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _disposition =
        type   : Dispositions.VERTICAL
        height : 5
        width  : 6
    _alert =
        level: null
        message: null

    _tasks = Immutable.OrderedMap()

    _shown = true


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SET_DISPOSITION, (disposition) ->
            _disposition.type = disposition.type
            if _disposition.type is Dispositions.VERTICAL
                _disposition.height = 5
                _disposition.width  = disposition.value or _disposition.width
            else if _disposition.type is Dispositions.HORIZONTAL
                _disposition.height = disposition.value or _disposition.height
                _disposition.width  = 6
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

        handle ActionTypes.RECEIVE_TASK_UPDATE, (task) ->
            task = Immutable.Map task
            id = task.get('id')
            _tasks = _tasks.set(id, task).toOrderedMap()
            @emit 'change'

        handle ActionTypes.RECEIVE_TASK_DELETE, (taskid) ->
            _tasks = _tasks.remove(taskid).toOrderedMap()
            @emit 'change'

        handle ActionTypes.TOASTS_SHOW, ->
            _shown = true
            @emit 'change'

        handle ActionTypes.TOASTS_HIDE, ->
            _shown = false
            @emit 'change'

    ###
        Public API
    ###
    getDisposition: -> return _disposition

    getAlert: -> return _alert

    getTasks: -> return _tasks

    isShown: -> return _shown

module.exports = new LayoutStore()
