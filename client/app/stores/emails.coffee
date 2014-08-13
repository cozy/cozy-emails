request = superagent

module.exports = EmailStore = Fluxxor.createStore

    actions:
        'RECEIVE_RAW_EMAILS': '_receiveRawEmails'
        'RECEIVE_RAW_EMAIL': '_receiveRawEmail'
        'REMOVE_MAILBOX': '_removeMailbox'

    initialize: ->
        fixtures = [
            {
                id: "f1a1dc66df94e19a0407c633e6003a832"
                createdAt: "2014-07-11T08:38:23.000Z"
                docType: "email"
                from: "natacha@provider.com"
                hasAttachments: false
                html: "Hello, how are you ? bis"
                'imap-folder': "orange-ID-folder1"
                inReplyTo: ""
                mailbox: "orange-ID2"
                reads: false
                references: ""
                subject: "Hey back"
                text: "Hello, how are you ? bis"
                to: "bob@provider.com"
            },
            {
                id: "f1a1dc66df94e19a0407c633e6003b272"
                createdAt: "2014-07-11T08:38:23.000Z"
                docType: "email"
                from: "alice@provider.com"
                hasAttachments: false
                html: "Hello, how are you ? bis"
                'imap-folder': "orange-ID-folder2"
                inReplyTo: ""
                mailbox: "orange-ID2"
                reads: false
                references: ""
                subject: "Another email"
                text: "Hello, how are you ? bis"
                to: "bob@provider.com"
            },
            {
                id: "f1a1dc66df94e19a0407c633e600112a2"
                createdAt: "2014-07-11T08:38:23.000Z"
                docType: "email"
                from: "alice@provider.com"
                hasAttachments: false
                html: "Hello, how are you ?"
                'imap-folder': "gmail-ID-folder1"
                inReplyTo: ""
                mailbox: "gmail-ID2"
                reads: false
                references: ""
                subject: "Hello Cozy Email manager!"
                text: "Hello, how are you ?"
                to: "bob@provider.com"
            },
            {
                id: "email-ID-12"
                createdAt: "2014-07-11T08:38:23.000Z"
                docType: "email"
                from: "alice@provider.com"
                hasAttachments: false
                html: "Hello, how are you ? bis"
                'imap-folder': "gmail-ID-folder1"
                inReplyTo: ""
                mailbox: "gmail-ID2"
                reads: false
                references: ""
                subject: "First email of thread"
                text: "Hello, how are you ? bis"
                to: "bob@provider.com"
            },
            {
                id: "f1a1dc66df94e19a0407c633e60037e52"
                createdAt: "2014-07-11T08:38:23.000Z"
                docType: "email"
                from: "bob@provider.com"
                hasAttachments: false
                html: "Hello, how are you ? bis"
                'imap-folder': "gmail-ID-folder1"
                inReplyTo: "email-ID-12"
                mailbox: "gmail-ID2"
                reads: false
                references: ""
                subject: "Email in reply to"
                text: "Hello, how are you ? bis"
                to: "alice@provider.com"
            }

        ]

        emails = []
        if not window.mailboxes? or window.mailboxes.length is 0
            emails = fixtures

        # Create an OrderedMap with email id as index
        @emails = Immutable.Sequence emails
                    .mapKeys (_, email) -> email.id
                    .toOrderedMap()

    getAll: -> return @emails

    getByID: (emailID) -> @emails.get(emailID) or null

    getEmailsByMailbox: (mailboxID) ->
        # sequences are lazy so we need .toOrderedMap() to actually execute it
        @emails.filter (email) ->
            email.mailbox is mailboxID
        .toOrderedMap()

    getEmailsByThread: (emailID) ->
        idsToLook = [emailID]
        thread = []
        while idToLook = idsToLook.pop()
            thread.push @getByID idToLook
            temp = @emails.filter (email) -> email.inReplyTo is idToLook
            idsToLook = idsToLook.concat temp.map((item) -> item.id).toArray()

        return thread

    _receiveRawEmails: (emails) ->
        @_receiveRawEmail email, true for email in emails
        @emit 'change'

    _receiveRawEmail: (email, silent = false) ->
        # create or update
        @emails = @emails.set email.id, email

        # strict equality check because silent is equal to action's name
        # when not specified
        @emit 'change' if silent isnt true

    _removeMailbox: (mailboxID) ->
        emails = @getEmailsByMailbox mailboxID
        @emails = @emails.withMutations (map) ->
            emails.forEach (email) -> map.remove email.id

        @emit 'change'

