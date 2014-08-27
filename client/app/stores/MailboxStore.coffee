Store = require '../libs/flux/store/Store'
Immutable = require 'immutable'
AppDispatcher = require '../AppDispatcher'

AccountStore = require './AccountStore'

{ActionTypes} = require '../constants/AppConstants'

# Used in production instead of real data during development early stage
fixtures = require '../../../tests/fixtures/mailboxes.json'


class MailboxStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Loads from fixtures if necessary
    if not window.accounts? or window.accounts.length is 0
        mailboxes = fixtures
    else
        mailboxes = []

    # Creates an OrderedMap of mailboxes
    _mailboxes = Immutable.Sequence mailboxes

        # patch to use fixtures
        .map (mailbox) ->
            mailbox.id = mailbox.id or mailbox._id
            return mailbox

        # sets mailbox ID as index
        .mapKeys (_, mailbox) -> mailbox.id

        # makes mailbox object an immutable Map
        .map (mailbox) -> Immutable.Map mailbox
        .toOrderedMap()


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_MAILBOX, (rawMailboxes) ->
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
