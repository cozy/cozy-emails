AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'

module.exports =

    receiveRawEmails: (emails) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_EMAILS
            value: emails

    receiveRawEmail: (email) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_EMAIL
            value: email
