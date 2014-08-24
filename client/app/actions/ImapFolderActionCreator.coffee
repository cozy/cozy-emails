AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'

module.exports =

    receiveRawImapFolders: (folders) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_IMAP_FOLDERS
            value: folders