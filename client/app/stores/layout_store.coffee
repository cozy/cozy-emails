Immutable = require 'immutable'

AppDispatcher = require '../app_dispatcher'

Store = require '../libs/flux/store/store'

AccountStore = require './account_store'

{ActionTypes, Dispositions} = require '../constants/app_constants'

MessageActionCreator = null
getMessageActionCreator = ->
    MessageActionCreator ?= require '../actions/message_action_creator'
    return MessageActionCreator


class LayoutStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _disposition = Dispositions.COL

    _route = null

    # TODO: Use a constant for default value?
    _previewSize = 60

    _previewFullscreen = false

    _focus = null

    _shown = true

    _intentAvailable = false

    _listModeCompact = false

    _drawer = window.innerWidth > 1280

    _modal  = null


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SET_ROUTE, (value) ->
            _route = value

        handle ActionTypes.SET_DISPOSITION, (type) ->
            _disposition = type

        handle ActionTypes.TOGGLE_LIST_MODE, ->
            _listModeCompact = not _listModeCompact
            @emit 'change'

        handle ActionTypes.RESIZE_PREVIEW_PANE, (factor) ->
            if factor
                _previewSize += factor
                # set limits
                _previewSize = 20 if _previewSize < 20
                _previewSize = 80 if _previewSize > 80
            else
                _previewSize = 50
            @emit 'change'

        handle ActionTypes.MINIMIZE_PREVIEW_PANE, ->
            _previewFullscreen = false
            @emit 'change'

        handle ActionTypes.MAXIMIZE_PREVIEW_PANE, ->
            _previewFullscreen = true
            @emit 'change'

        handle ActionTypes.DISPLAY_MODAL, (value) ->
            _modal = value
            @emit 'change'

        handle ActionTypes.HIDE_MODAL, (value) ->
            _modal = null
            @emit 'change'

        handle ActionTypes.FOCUS, (path) ->
            _focus = path

        handle ActionTypes.REFRESH, ->
            @emit 'change'

        handle ActionTypes.TOASTS_SHOW, ->
            _shown = true
            @emit 'change'

        handle ActionTypes.TOASTS_HIDE, ->
            _shown = false
            @emit 'change'

        handle ActionTypes.INTENT_AVAILABLE, (avaibility) ->
            _intentAvailable = avaibility
            @emit 'change'

        handle ActionTypes.DRAWER_SHOW, ->
            return if _drawer is true
            _drawer = true
            @emit 'change'

        handle ActionTypes.DRAWER_HIDE, ->
            return if _drawer is false
            _drawer = false
            @emit 'change'

        handle ActionTypes.DRAWER_TOGGLE, ->
            _drawer = not _drawer
            @emit 'change'


    ###
        Public API
    ###

    getDisposition: ->
        return _disposition

    getListModeCompact: ->
        return _listModeCompact


    getPreviewSize: ->
        return _previewSize


    isPreviewFullscreen: ->
        return _previewFullscreen


    getFocus: ->
        return _focus


    getModal: ->
        return _modal


    isShown: ->
        return _shown


    intentAvailable: ->
        return _intentAvailable


    isDrawerExpanded: ->
        return _drawer


module.exports = new LayoutStore()
