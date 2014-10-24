AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

module.exports = ContactActionCreator =


    searchContact: (query) ->
        Activity = require '../utils/activity_utils'
        options =
            name: 'search'
            data:
                type: 'contact'
                query: query

        activity = new Activity options
        activity.onsuccess = ->
            AppDispatcher.handleViewAction
                type: ActionTypes.RECEIVE_RAW_CONTACT_RESULTS
                value: @result
        activity.onerror = ->
            console.log "KO", @error, @name

