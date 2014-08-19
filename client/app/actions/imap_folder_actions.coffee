module.exports =

    receiveRawImapFolders: (folders) ->
        @dispatch 'RECEIVE_RAW_IMAP_FOLDERS', folders