request = require 'superagent'

MessageActionCreator = require '../actions/MessageActionCreator'
MailboxActionCreator = require '../actions/MailboxActionCreator'

module.exports =

    fetchMessagesByAccount: (mailboxID) ->
        request.get "account/#{mailboxID}/messages"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                MessageActionCreator.receiveRawMessages res.body
            else
                console.log "Something went wrong -- #{res.body}"

    fetchConversation: (emailID, callback) ->
        request.get "message/#{emailID}"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                MessageActionCreator.receiveRawMessage res.body
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    fetchMailboxByAccount: (accountID) ->
        request.get "account/#{accountID}/mailboxes"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                MailboxActionCreator.receiveRawMailboxes res.body
            else
                console.log "Something went wrong -- #{res.body}"

    fetchMessagesByFolder: (mailboxID) ->
        request.get "mailbox/#{mailboxID}/messages"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                MessageActionCreator.receiveRawMessage res.body
            else
                console.log "Something went wrong -- #{res.body}"

    createAccount: (account, callback) ->

        # TODO: validation & sanitization

        request.post 'account'
               .send account
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback res.body, null

    editAccount: (account, callback) ->

        # TODO: validation & sanitization

        request.put "account/#{account.id}"
               .send account
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback res.body, null

    removeAccount: (accountID) ->

        request.del "account/#{accountID}"
               .set 'Accept', 'application/json'
               .end (res) -> # nothing
