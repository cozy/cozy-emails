AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'
Activity      = require '../utils/activity_utils'
LayoutActionCreator = require '../actions/layout_action_creator'

module.exports = ContactActionCreator =

    searchContact: (query) ->
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

    createContact: (contact) ->
        options =
            name: 'create'
            data:
                type: 'contact'
                contact: contact

        activity = new Activity options
        activity.onsuccess = ->
            AppDispatcher.handleViewAction
                type: ActionTypes.RECEIVE_RAW_CONTACT_RESULTS
                value: @result
            LayoutActionCreator.notify t('contact create success', {contact: contact.name or contact.address}), autoclose: true
        activity.onerror = ->
            LayoutActionCreator.notify t('contact create error', {error: @name}), autoclose: true

