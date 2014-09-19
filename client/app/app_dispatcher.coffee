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

    handleServerAction: (action) ->
        payload =
            source: PayloadSources.SERVER_ACTION
            action: action

        @dispatch payload


module.exports = new AppDispatcher()