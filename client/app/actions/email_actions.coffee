module.exports =

    receiveRawEmails: (emails) ->
        @dispatch 'RECEIVE_RAW_EMAILS', emails

    receiveRawEmail: (email) ->
        @dispatch 'RECEIVE_RAW_EMAIL', email
