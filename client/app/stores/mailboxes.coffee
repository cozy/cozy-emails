module.exports = MailboxStore = Fluxxor.createStore
    initialize: ->
        @mailboxes = [

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

    getAll: -> return @mailboxes

    getDefault: -> return @mailboxes[0]