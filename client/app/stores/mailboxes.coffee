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
                id: 1
                label: 'joseph.silvestre38@gmail.com'
                unreadCount: 1275
            },
            {
                id: 2
                label: 'joseph.silvestre@cozycloud.cc'
                unreadCount: 369
            }
        ]

        @mailboxes = window.mailboxes or fixtures
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
