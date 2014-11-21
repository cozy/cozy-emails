Store = require '../libs/flux/store/store'

{ActionTypes, NotifyType} = require '../constants/app_constants'

class TasksStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _tasks = Immutable.Sequence window.tasks
    # sets task ID as index
    .mapKeys (_, task) -> return task.id
    .map (task) ->
        if not task.type?
            task.type = NotifyType.SERVER
        Immutable.fromJS task
    .toOrderedMap()

    _shown = true

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_TASK_UPDATE, (task) ->
            task = Immutable.Map task
            _tasks = _tasks.set task.get('id'), task
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

    getTasks: -> _tasks.toOrderedMap()

    isShown: -> _shown

module.exports = new TasksStore()
