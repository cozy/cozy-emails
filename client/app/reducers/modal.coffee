{ActionTypes} = require '../constants/app_constants'

DEFAULT_STATE = null

module.exports = (modal = DEFAULT_STATE, action) ->
    switch action.type
        when ActionTypes.HIDE_MODAL
            return DEFAULT_STATE

        when ActionTypes.DISPLAY_MODAL
            return action.value

        else
            return modal
