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

        @mailboxes = window.mailboxes or fixtures
        @mailboxes = fixtures if @mailboxes.length is 0

        @selectedMailbox = null
        @newMailboxWaiting = false
        @newMailboxError = null


    onCreate: (mailbox) ->
        @mailboxes.push mailbox
        @emit 'change'

    onSelectMailbox: (mailboxID) ->
        @selectedMailbox = _.findWhere @mailboxes, id: mailboxID
        @emit 'change'

    onNewMailboxWaiting: (payload) ->
        @newMailboxWaiting = payload
        @emit 'change'

    onNewMailboxError: (error) ->
        @newMailboxError = error
        @emit 'change'

    onEdit: (mailbox) ->
        index = _.pluck(@mailboxes, 'id').indexOf mailbox.id
        @mailboxes[index] = mailbox
        @selectedMailbox = @mailboxes[index]
        @emit 'change'

    onRemove: (mailboxID) ->
        index = _.pluck(@mailboxes, 'id').indexOf mailboxID
        mailbox = @mailboxes[index]
        @mailboxes.splice index, 1
        mailbox = null
        @selectedMailbox = @getDefault()
        @emit 'change'

    getAll: ->
        @mailboxes = _.sortBy @mailboxes, (mailbox) ->
            return mailbox.label

        return @mailboxes
    getDefault: -> return @mailboxes[0] or null
    getSelectedMailbox: -> return @selectedMailbox or @getDefault()
    getError: -> return @newMailboxError
    isWaiting: -> return @newMailboxWaiting
