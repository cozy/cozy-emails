Store         = require '../libs/flux/store/Store'
AppDispatcher = require '../AppDispatcher'
AccountStore  = require './AccountStore'
{ActionTypes} = require '../constants/AppConstants'

class MailboxStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Creates an OrderedMap of mailboxes
    _mailboxes = Immutable.Sequence()

        # sets mailbox ID as index
        .mapKeys (_, mailbox) -> mailbox.id

        # makes mailbox object an immutable Map
        .map (mailbox) -> Immutable.Map mailbox
        .toOrderedMap()

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MAILBOXES, (rawMailboxes) ->
            _mailboxes = _mailboxes.withMutations (map) ->
                # create or update
                for rawMailbox in rawMailboxes
                    mailbox = Immutable.Map rawMailbox
                    map.set mailbox.get('id'), mailbox

            @emit 'change'


    ###
        Public API
    ###
    getByAccount: (accountID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _mailboxes.filter (mailbox) -> mailbox.get('mailbox') is accountID
        .toOrderedMap()

    getSelected: (accountID, mailboxID) ->
        mailboxes = @getByAccount accountID
        if mailboxID?
            return mailboxes.get mailboxID
        else
            return mailboxes.first()

    # Takes the 3 first mailboxes to show as "favorite".
    # Skip the first 1, assumed to be the inbox
    # Should be made configurable.
    getFavorites: (accountID) ->
        _mailboxes.filter (mailbox) -> mailbox.get('mailbox') is accountID
        .skip 1
        .take 3
        .toOrderedMap()

module.exports = new MailboxStore()
