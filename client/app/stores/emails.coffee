request = superagent

module.exports = EmailStore = Fluxxor.createStore

    actions:
        'RECEIVE_RAW_EMAILS': '_receiveRawEmails'
        'RECEIVE_RAW_EMAIL': '_receiveRawEmail'

        'REMOVE_MAILBOX': '_removeMailbox'

    initialize: ->
        @emails = []

    getAll: -> return @emails

    getByID: (emailID) -> _.findWhere @emails, id: emailID

    getEmailsByMailbox: (mailboxID) -> _.where @emails, mailbox: mailboxID

    getEmailsByThread: (emailID) ->
        idsToLook = [emailID]
        thread = []
        while idToLook = idsToLook.pop()
            thread.push @getByID idToLook
            temp = _.where @emails, inReplyTo: idToLook
            idsToLook = idsToLook.concat _.pluck temp, 'id'

        return thread



    _receiveRawEmails: (emails) ->
        @_receiveRawEmail email, true for email in emails
        @emit 'change'

    _receiveRawEmail: (email, silent = false) ->
        existingEmail = @getByID email.id
        if existingEmail?
            existingEmail = email
        else
            @emails.push email

        # strict equality check because silent is equal to action's name
        # when not specified
        @emit 'change' if silent isnt true

    _removeMailbox: (mailboxID) ->
        emails = @getEmailsByMailbox mailboxID
        for email, index in emails
            email = @emails[index]
            @emails.splice index, 1
            email = null
        @emit 'change'

