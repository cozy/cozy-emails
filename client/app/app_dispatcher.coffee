Dispatcher = require './libs/flux/dispatcher/dispatcher'
{PayloadSources} = require './constants/app_constants'

###
    Custom dispatcher class to add semantic method.
###
class AppDispatcher extends Dispatcher

    handleViewAction: (action) ->
        payload =
            source: PayloadSources.VIEW_ACTION
            action: action

        @dispatch payload

        # create and dispatch a DOM event for plugins
        domEvent = new CustomEvent PayloadSources.VIEW_ACTION, detail: action
        window.dispatchEvent domEvent

    handleServerAction: (action) ->
        payload =
            source: PayloadSources.SERVER_ACTION
            action: action

        @dispatch payload

        # create and dispatch a DOM event for plugins
        domEvent = new CustomEvent PayloadSources.SERVER_ACTION, detail: action
        window.dispatchEvent domEvent


module.exports = new AppDispatcher()
