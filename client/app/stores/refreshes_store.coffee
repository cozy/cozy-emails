Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'

class RefreshesStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _refreshes = Immutable.Sequence window.refreshes
    # sets task ID as index
    .mapKeys (_, task) -> return task.id
    .map (task) ->
        Immutable.fromJS task
    .toOrderedMap()

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_REFRESH_UPDATE, (task) ->
            task = Immutable.Map task
            id = task.get('id')
            _tasks = _tasks.set(id, task).toOrderedMap()
            @emit 'change'

        handle ActionTypes.RECEIVE_REFRESH_DELETE, (taskid) ->
            _tasks = _tasks.remove(taskid).toOrderedMap()
            @emit 'change'

    getRefreshing: ->
        refreshes = {}
        _tasks.forEach (task) ->
            refreshes[task.get('objectID')] = task

        return refreshes

module.exports = new RefreshesStore()
