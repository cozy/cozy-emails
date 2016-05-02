AppDispatcher = require '../libs/flux/dispatcher/dispatcher'
{ActionTypes} = require '../constants/app_constants'
Activity = require '../utils/activity_utils'

module.exports = ContactActionCreator =

    searchContact: (query) ->
        options =
            name: 'search'
            data:
                type: 'contact'
                query: query

        AppDispatcher.dispatch
            type: ActionTypes.SEARCH_CONTACT_REQUEST
            value: options

        activity = new Activity options

        activity.onsuccess = (error, result) ->
            AppDispatcher.dispatch
                type: ActionTypes.SEARCH_CONTACT_SUCCESS
                value: result

        activity.onerror = (error) ->
            AppDispatcher.dispatch
                type: ActionTypes.SEARCH_CONTACT_FAILURE
                value: error


    searchContactLocal: (query) ->
        AppDispatcher.dispatch
            type: ActionTypes.CONTACT_LOCAL_SEARCH
            value: query


    createContact: (contact) ->
        options =
            name: 'create'
            data:
                type: 'contact'
                contact: contact

        AppDispatcher.dispatch
            type: ActionTypes.CREATE_CONTACT_REQUEST
            value: options

        activity = new Activity options

        activity.onsuccess = ->
            AppDispatcher.dispatch
                type: ActionTypes.CREATE_CONTACT_SUCCESS
                value: contact

        activity.onerror = (error) ->
            AppDispatcher.dispatch
                type: ActionTypes.CREATE_CONTACT_FAILURE
                value: error


    gotoContactList: (contact) ->
        AppDispatcher.dispatch
            type: ActionTypes.CONTACT_DISPLAY
            value: {contact}
