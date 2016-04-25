Immutable = require 'immutable'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


class SelectionStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _selected = Immutable.Set()
    _isAllSelected = false

    _resetSelection = ->
        _selected = Immutable.Set()
        _isAllSelected = false

    _selectAll = ->
        _isAllSelected = true

    _update = (selection) ->
        isSelected = -1 < _selected?.toArray().indexOf selection.id
        action = if selection.value and not isSelected then 'add' else 'delete'
        _selected = _selected[action] selection.id


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.MAILBOX_SELECT_ALL, ->
            if _isAllSelected
                _resetSelection()
            else
                _selectAll()
            @emit 'change'

        handle ActionTypes.MAILBOX_SELECT, (params) ->
            _update params
            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target}) ->
            # Remove ID from Selection
            if target.messageIDs?
                _selected = _selected.subtract target.messageIDs
                @emit 'change'
    ###
        Public API
    ###

    getSelected: ->
        _selected

    getAllSelected: ->
        _isAllSelected

module.exports = new SelectionStore()
