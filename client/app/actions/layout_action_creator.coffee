AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes} = require '../constants/app_constants'

module.exports = LayoutActionCreator =

    selectAll: (value) ->
        type = ActionTypes.MAILBOX_SELECT_ALL
        AppDispatcher.dispatch {type}


    updateSelection: (value) ->
        type = ActionTypes.MAILBOX_SELECT
        AppDispatcher.dispatch {type, value}


    clearToasts: ->
        AppDispatcher.dispatch
            type: ActionTypes.CLEAR_TOASTS
            value: null

    showSearchResult: (parameters) ->
        {accountID, search} = parameters

        AppDispatcher.dispatch
            type: ActionTypes.SELECT_ACCOUNT
            value: {accountID}

        AppDispatcher.dispatch
            type: ActionTypes.SEARCH_PARAMETER_CHANGED
            value: {accountID, search}

    toastsShow: ->
        AppDispatcher.dispatch
            type: ActionTypes.TOASTS_SHOW

    toastsHide: ->
        AppDispatcher.dispatch
            type: ActionTypes.TOASTS_HIDE


    intentAvailability: (availability) ->
        AppDispatcher.dispatch
            type: ActionTypes.INTENT_AVAILABLE
            value: availability


    displayModal: (params) ->
        params.closeModal ?= -> LayoutActionCreator.hideModal()
        AppDispatcher.dispatch
            type: ActionTypes.DISPLAY_MODAL
            value: params

    hideModal: ->
        AppDispatcher.dispatch
            type: ActionTypes.HIDE_MODAL
