Store = require '../libs/flux/store/Store'
AppDispatcher = require '../AppDispatcher'

MailboxStore = require './MailboxStore'

{ActionTypes} = require '../constants/AppConstants'

# Used in production instead of real data during development early stage
fixtures = [] # @FIXME require '../tests/fixtures/emails.json'
_idGenerator = 0

class EmailStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Loads from fixtures if necessary
    if not window.mailboxes? or window.mailboxes.length is 0
        emails = fixtures
    else
        emails = []

    # Creates an OrderedMap of emails
    _emails = Immutable.Sequence emails

        # patch to use fixtures (some of them don't have an ID)
        .map (email) ->
            email.id = email.id or email._id or 'id_' + _idGenerator++
            return email

        # sets email ID as index
        .mapKeys (_, email) -> email.id

        # makes email object an immutable Map
        .map (email) -> Immutable.Map email
        .toOrderedMap()

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_EMAIL, onReceiveRawEmail = (email, silent = false) ->
            # create or update
            email = Immutable.Map email
            _emails = _emails.set email.get('id'), email

            @emit 'change' unless silent

        handle ActionTypes.RECEIVE_RAW_EMAILS, (emails) ->
            onReceiveRawEmail email, true for email in emails
            @emit 'change'

        handle ActionTypes.REMOVE_MAILBOX, (mailboxID) ->
            AppDispatcher.waitFor [MailboxStore.dispatchToken]
            emails = @getEmailsByMailbox mailboxID
            _emails = _emails.withMutations (map) ->
                emails.forEach (email) ->map.remove email.get 'id'

            @emit 'change'


    ###
        Public API
    ###
    getAll: -> return _emails

    getByID: (emailID) -> _emails.get(emailID) or null

    getEmailsByMailbox: (mailboxID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _emails.filter (email) -> email.get('mailbox') is mailboxID
        .toOrderedMap()

    getEmailsByImapFolder: (imapFolderID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        _emails.filter (email) -> email.get('imapFolder') is imapFolderID
        .toOrderedMap()

    getEmailsByThread: (emailID) ->
        idsToLook = [emailID]
        thread = []
        while idToLook = idsToLook.pop()
            thread.push @getByID idToLook
            temp = _emails.filter (email) -> email.get('inReplyTo') is idToLook
            idsToLook = idsToLook.concat temp.map((item) -> item.get('id')).toArray()

        return thread

module.exports = new EmailStore()
