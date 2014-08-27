AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'

module.exports =

    receiveRawMailboxes: (mailboxes) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_MAILBOXES
            value: mailboxes