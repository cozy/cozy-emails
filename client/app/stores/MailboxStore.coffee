Store = require '../libs/flux/store/Store'
Immutable = require 'immutable'

{ActionTypes} = require '../constants/AppConstants'

# Used in production instead of real data during development early stage
fixtures = require '../../../tests/fixtures/mailboxes.json'

class MailboxStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Loads data passed by the server or the fixtures
    _mailboxes = window.mailboxes or fixtures
    _mailboxes = fixtures if mailboxes.length is 0

    # Creates an OrderedMap of mailboxes
    _mailboxes = Immutable.Sequence mailboxes

        # sort first
        .sort (mb1, mb2) ->
            if mb1.label > mb2.label then return 1
            else if mb1.label < mb2.label then return -1
            else return 0

        # sets mailbox ID as index
        .mapKeys (_, mailbox) -> mailbox.id

        # makes mailbox object an immutable Map
        .map (mailbox) -> Immutable.Map mailbox
        .toOrderedMap()

    _selectedMailbox = null
    _newMailboxWaiting = false
    _newMailboxError = null

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ADD_MAILBOX, (mailbox) ->
            mailbox = Immutable.Map mailbox
            _mailboxes = _mailboxes.set mailbox.get('id'), mailbox
            @emit 'change'

        handle ActionTypes.SELECT_MAILBOX, (mailboxID) ->
            _selectedMailbox = _mailboxes.get(mailboxID) or null
            @emit 'change'

        handle ActionTypes.NEW_MAILBOX_WAITING, (payload) ->
            _newMailboxWaiting = payload
            @emit 'change'

        handle ActionTypes.NEW_MAILBOX_ERROR, (error) ->
            _newMailboxError = error
            @emit 'change'

        handle ActionTypes.EDIT_MAILBOX, (mailbox) ->
            mailbox = Immutable.Map mailbox
            _mailboxes = _mailboxes.set mailbox.get('id'), mailbox
            _selectedMailbox = _mailboxes.get mailbox.get 'id'
            @emit 'change'

        handle ActionTypes.REMOVE_MAILBOX, (mailboxID) ->
            _mailboxes = _mailboxes.delete mailboxID
            _selectedMailbox = @getDefault()
            @emit 'change'

    ###
        Public API
    ###
    getAll: -> return _mailboxes

    getDefault: -> return _mailboxes.first() or null

    getSelected: -> return _selectedMailbox

    getError: -> return _newMailboxError

    isWaiting: -> return _newMailboxWaiting

module.exports = new MailboxStore()
