Fluxxor = require 'fluxxor'
Immutable = require 'immutable'

module.exports = Fluxxor.createStore

    actions:
        'RECEIVE_RAW_IMAP_FOLDERS': '_receiveRawImapFolders'

    initialize: ->
        fixtures = []

        imapFolders = []
        if not window.mailboxes? or window.mailboxes.length is 0
            imapFolders = fixtures

        # Create an OrderedMap with imap folder id as index
        @imapFolders = Immutable.Sequence imapFolders
                    .mapKeys (_, imapFolder) -> imapFolder.id
                    .map (imapFolder) -> Immutable.Map imapFolder
                    .toOrderedMap()

    getByMailbox: (mailboxID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        @imapFolders.filter (imapFolder) -> imapFolder.mailbox is mailboxID
        .toOrderedMap()

    getSelected: (mailboxID, imapFolderID) ->
        imapFolders = @getByMailbox mailboxID
        if imapFolderID?
            return imapFolders.get imapFolderID
        else
            return imapFolders.first()

    _receiveRawImapFolders: (imapFolders) ->

        @imapFolders = @imapFolders.withMutations (map) ->
            # create or update
            map.set imapFolder.id, imapFolder for imapFolder in imapFolders

        @emit 'change'
