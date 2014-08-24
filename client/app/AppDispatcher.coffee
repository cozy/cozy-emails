Dispatcher = require './libs/flux/dispatcher/Dispatcher'
{PayloadSources} = require './constants/AppConstants'

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