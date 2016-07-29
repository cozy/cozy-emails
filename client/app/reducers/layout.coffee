Immutable = require 'immutable'

{ActionTypes} = require '../constants/app_constants'

DEFAULT_STATE =
    # Should definetly be in view or settings file.
    previewSize: 60
    hidden: true
    intentAvailable: false

module.exports = (state=DEFAULT_STATE, action) ->

    switch action.type
        # TOASTS_SHOW
        when ActionTypes.TOASTS_SHOW
            nextstate = Object.assign state, hidden: false


        # TOASTS_HIDE
        when ActionTypes.TOASTS_HIDE
            nextState = Object.assign state, hidden: true


        # INTENT_AVAILABLE
        when ActionTypes.INTENT_AVAILABLE
            availability = action.value
            nextstate = Object.assign state, intentAvailable: availability


    return nextstate or state
