Immutable = require 'immutable'

{ActionTypes} = require '../constants/app_constants'

DEFAULTSTATE =
    settings: Immutable.Map()

module.exports = (state = DEFAULTSTATE, action) ->

    switch action.type
        when ActionTypes.SETTINGS_UPDATE_SUCCESS
            nextState =
                settings: state.settings.merge action.value

    return nextState or state
