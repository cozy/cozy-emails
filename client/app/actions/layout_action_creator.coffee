{ActionTypes} = require '../constants/app_constants'

module.exports = LayoutActionCreator = (dispatch) ->

    selectAll: ->
        type = ActionTypes.MAILBOX_SELECT_ALL
        dispatch {type}


    updateSelection: (value) ->
        type = ActionTypes.MAILBOX_SELECT
        dispatch {type, value}


    clearToasts: ->
        dispatch
            type: ActionTypes.CLEAR_TOASTS
            value: null

    showSearchResult: (parameters) ->
        {accountID, search} = parameters

        dispatch
            type: ActionTypes.SELECT_ACCOUNT
            value: {accountID}

        dispatch
            type: ActionTypes.SEARCH_PARAMETER_CHANGED
            value: {accountID, search}

    toastsShow: ->
        dispatch
            type: ActionTypes.TOASTS_SHOW

    toastsHide: ->
        dispatch
            type: ActionTypes.TOASTS_HIDE


    intentAvailability: (availability) ->
        dispatch
            type: ActionTypes.INTENT_AVAILABLE
            value: availability


    # FIXME: Need to rethink the way modals can be shown / hidden (see account
    # creation wizard use-case)
    displayModal: (params) ->
        params.closeModal ?= -> LayoutActionCreator.hideModal()
        dispatch
            type: ActionTypes.DISPLAY_MODAL
            value: params

    hideModal: ->
        dispatch
            type: ActionTypes.HIDE_MODAL
