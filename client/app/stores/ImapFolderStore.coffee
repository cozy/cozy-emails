Store = require '../libs/flux/store/Store'
Immutable = require 'immutable'
AppDispatcher = require '../AppDispatcher'

MailboxStore = require './MailboxStore'

{ActionTypes} = require '../constants/AppConstants'

# Used in production instead of real data during development early stage
fixtures = require '../../../tests/fixtures/imap_folders.json'


class ImapFolderStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Loads from fixtures if necessary
    if not window.mailboxes? or window.mailboxes.length is 0
        imapFolders = fixtures
    else
        imapFolders = []

    # Creates an OrderedMap of imap folders
    _imapFolders = Immutable.Sequence imapFolders

        # sets mailbox ID as index
        .mapKeys (_, imapFolder) -> imapFolder.id

        # makes mailbox object an immutable Map
        .map (imapFolder) -> Immutable.Map imapFolder
        .toOrderedMap()


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_IMAP_FOLDERS, (rawImapFolders) ->

            _imapFolders = _imapFolders.withMutations (map) ->
                # create or update
                map.set rawImapFolder.id, rawImapFolder for rawImapFolder in rawImapFolders

            @emit 'change'


    ###
        Public API
    ###
    getByMailbox: (mailboxID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _imapFolders.filter (imapFolder) -> imapFolder.mailbox is mailboxID
        .toOrderedMap()

    getSelected: (mailboxID, imapFolderID) ->
        imapFolders = @getByMailbox mailboxID
        if imapFolderID?
            return imapFolders.get imapFolderID
        else
            return imapFolders.first()

module.exports = new ImapFolderStore()
