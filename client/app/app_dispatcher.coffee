Dispatcher = require './libs/flux/dispatcher/dispatcher'
{PayloadSources} = require './constants/app_constants'

###
    Custom dispatcher class to add semantic method.
###
class AppDispatcher extends Dispatcher

    dispatch: (action) ->
        window.cozyMails.logAction action
        super {action}


module.exports = new AppDispatcher()
