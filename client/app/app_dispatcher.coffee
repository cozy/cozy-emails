Dispatcher = require './libs/flux/dispatcher/dispatcher'
{PayloadSources} = require './constants/app_constants'

###
    Custom dispatcher class to add semantic method.
###
class AppDispatcher extends Dispatcher

    handleViewAction: (action) ->
        window.cozyMails.logAction action
        payload =
            source: PayloadSources.VIEW_ACTION
            action: action

        @dispatch payload

        # create and dispatch a DOM event for plugins
        window.cozyMails.customEvent PayloadSources.VIEW_ACTION, action

    handleServerAction: (action) ->
        window.cozyMails.logAction action
        payload =
            source: PayloadSources.SERVER_ACTION
            action: action

        @dispatch payload

        # create and dispatch a DOM event for plugins
        window.cozyMails.customEvent PayloadSources.SERVER_ACTION, action


module.exports = new AppDispatcher()
