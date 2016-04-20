RouterGetter = require '../getters/router'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes, MessageActions} = require '../constants/app_constants'

module.exports = LayoutActionCreator =

    setDisposition: (type) ->
        AppDispatcher.dispatch
            type: ActionTypes.SET_DISPOSITION
            value: type

    toggleListMode: ->
        AppDispatcher.dispatch
            type: ActionTypes.TOGGLE_LIST_MODE

    selectAll: (value) ->
        type = ActionTypes.MAILBOX_SELECT_ALL
        AppDispatcher.dispatch {type}

    updateSelection: (value) ->
        type = ActionTypes.MAILBOX_SELECT
        AppDispatcher.dispatch {type, value}

    # TODO: use a global method to DRY this 3-ones
    increasePreviewPanel: (factor = 1) ->
        AppDispatcher.dispatch
            type: ActionTypes.RESIZE_PREVIEW_PANE
            value: Math.abs factor

    decreasePreviewPanel: (factor = 1) ->
        AppDispatcher.dispatch
            type: ActionTypes.RESIZE_PREVIEW_PANE
            value: -1 * Math.abs factor

    resetPreviewPanel: ->
        AppDispatcher.dispatch
            type: ActionTypes.RESIZE_PREVIEW_PANE
            value: null

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
