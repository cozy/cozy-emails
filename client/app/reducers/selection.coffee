Immutable = require 'immutable'

{ActionTypes} = require '../constants/app_constants'

DEFAULTSTATE =
    selected: Immutable.Set()
    allSelected: false

module.exports = (state = DEFAULTSTATE, action) ->
    switch action.type
        when ActionTypes.MAILBOX_SELECT_ALL
            if state.allSelected
                nextState = DEFAULTSTATE
            else
                nextState =
                    allSelected: true,
                    selected: Immutable.Set()

        when ActionTypes.MAILBOX_SELECT
            id = action.value.id
            if(action.value.value and not state.selected.has(id))
                nextState =
                    allSelected: state.allSelected,
                    selected: state.selected.add(id)
            else
                nextState =
                    allSelected: false,
                    selected: state.selected.delete(id)

        when ActionTypes.MESSAGE_TRASH_SUCCESS
            messageIDs = action.value.target.messageIDs
            if action.value.target.messageIDs?
                selected = state.selected.subtract(messageIDs or [])
                nextState =
                    allSelected: state.allSelected,
                    selected: selected

    return nextState or state
