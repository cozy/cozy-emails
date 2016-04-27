AppDispatcher = require '../libs/flux/dispatcher/dispatcher'
{ActionTypes} = require '../constants/app_constants'
Activity = require '../utils/activity_utils'

NotificationActionsCreator = require '../actions/notification_action_creator'

module.exports = ContactActionCreator =


    searchContact: (query) ->
        options =
            name: 'search'
            data:
                type: 'contact'
                query: query

        activity = new Activity options

        activity.onsuccess = ->
            AppDispatcher.dispatch
                type: ActionTypes.RECEIVE_RAW_CONTACT_RESULTS
                value: @result

        activity.onerror = ->
            console.log "KO", @error, @name


    searchContactLocal: (query) ->
        AppDispatcher.dispatch
            type: ActionTypes.CONTACT_LOCAL_SEARCH
            value: query


    createContact: (contact, callback) ->
        options =
            name: 'create'
            data:
                type: 'contact'
                contact: contact

        activity = new Activity options

        activity.onsuccess = (err, res) ->
            AppDispatcher.dispatch
                type: ActionTypes.RECEIVE_RAW_CONTACT_RESULTS
                value: @result

            msg = t('contact create success',
                {contact: contact.name or contact.address})
            NotificationActionsCreator.alert msg, autoclose: true
            callback?()

        activity.onerror = ->
            console.log @name
            msg = t('contact create error', {error: @name})
            NotificationActionsCreator.alertError msg, autoclose: true
            callback?()
