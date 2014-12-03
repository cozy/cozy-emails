Store = require '../libs/flux/store/store'

{ActionTypes, Dispositions} = require '../constants/app_constants'

class LayoutStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _responsiveMenuShown = false
    _disposition = Dispositions.VERTICAL
    _alert =
        level: null
        message: null

    _tasks = Immutable.OrderedMap()

    _shown = true


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SHOW_MENU_RESPONSIVE, ->
            _responsiveMenuShown = true
            @emit 'change'

        handle ActionTypes.HIDE_MENU_RESPONSIVE, ->
            _responsiveMenuShown = false
            @emit 'change'

        handle ActionTypes.SET_DISPOSITION, (value) ->
            _disposition = value.type
            @emit 'change'

        handle ActionTypes.DISPLAY_ALERT, (value) ->
            _alert.level   = value.level
            _alert.message = value.message
            @emit 'change'

        handle ActionTypes.HIDE_ALERT, (value) ->
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
    isMenuShown: -> return _responsiveMenuShown

    getDisposition: -> return _disposition

    getAlert: -> return _alert

    getTasks: -> return _tasks

    isShown: -> return _shown

module.exports = new LayoutStore()
