request = superagent

MessageActionCreator = require '../actions/MessageActionCreator'
AccountTranslator = require './translators/AccountTranslator'

module.exports =

    fetchConversation: (emailID, callback) ->
        request.get "message/#{emailID}"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                MessageActionCreator.receiveRawMessage res.body
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    fetchMessagesByFolder: (mailboxID) ->
        request.get "mailbox/#{mailboxID}"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                MessageActionCreator.receiveRawMessages res.body
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
        rawAccount = AccountTranslator.toRawObject account

        request.put "account/#{rawAccount.id}"
               .send rawAccount
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
