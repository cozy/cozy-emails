request = superagent

module.exports = MailboxStore = Fluxxor.createStore

    actions:
        'ADD_MAILBOX': 'onCreate'
        'REMOVE_MAILBOX': 'onRemove'
        'EDIT_MAILBOX': 'onEdit'
        'SELECT_MAILBOX': 'onSelectMailbox'
        'NEW_MAILBOX_WAITING': 'onNewMailboxWaiting'
        'NEW_MAILBOX_ERROR': 'onNewMailboxError'

    initialize: ->
        fixtures = [
            {
                id: "gmail-ID2"
                email: "randomlogin@randomprovider.tld"
                imapPort: 465
                imapServer: "imap.gmail.com"
                label: "Gmail"
                name: "Random Name"
                password: "randompassword"
                smtpPort: 993
                smtpServer: "smtp.gmail.com"
            },
            {
                id: "orange-ID2"
                email: "randomlogin@randomprovider.tld"
                imapPort: 465
                imapServer: "imap.orange.fr"
                label: "Orange"
                name: "Random Name"
                password: "randompassword"
                smtpPort: 993
                smtpServer: "smtp.orange.fr"
            }
        ]

        mailboxes = window.mailboxes or fixtures
        mailboxes = fixtures if mailboxes.length is 0

        # Create an OrderedMap with mailbox id as index
        @mailboxes = Immutable.Sequence mailboxes
                        .mapKeys (_, mailbox) -> mailbox.id
                        .toOrderedMap()

        @selectedMailbox = null
        @newMailboxWaiting = false
        @newMailboxError = null


    onCreate: (mailbox) ->
        @mailboxes = @mailboxes.set mailbox.id, mailbox
        @emit 'change'

    onSelectMailbox: (mailboxID) ->
        @selectedMailbox = @mailboxes.get(mailboxID) or null
        @emit 'change'

    onNewMailboxWaiting: (payload) ->
        @newMailboxWaiting = payload
        @emit 'change'

    onNewMailboxError: (error) ->
        @newMailboxError = error
        @emit 'change'

    onEdit: (mailbox) ->
        @mailboxes = @mailboxes.set mailbox.id, mailbox
        @selectedMailbox = @mailboxes.get mailbox.id
        @emit 'change'

    onRemove: (mailboxID) ->
        @mailboxes = @mailboxes.delete mailboxID
        @selectedMailbox = @getDefault()
        @emit 'change'

    getAll: ->
        @mailboxes = @mailboxes.sortBy (mailbox) -> mailbox.label
                    .toOrderedMap()

        return @mailboxes
    getDefault: -> return @mailboxes.first() or null
    getSelectedMailbox: -> return @selectedMailbox or @getDefault()
    getError: -> return @newMailboxError
    isWaiting: -> return @newMailboxWaiting


