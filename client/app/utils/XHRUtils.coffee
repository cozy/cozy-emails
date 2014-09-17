request = superagent

AccountTranslator = require './translators/AccountTranslator'

SettingsStore = require '../stores/SettingsStore'

module.exports =

    fetchConversation: (emailID, callback) ->
        request.get "message/#{emailID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"


    fetchMessagesByFolder: (mailboxID, numPage, callback) ->
        numByPage = SettingsStore.get 'messagesPerPage'
        request.get "mailbox/#{mailboxID}/page/#{numPage}/limit/#{numByPage}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    messageSend: (message, callback) ->
        request.post "/message"
        .send message
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    messageDelete: (messageId, callback) ->
        request.del "/message/#{messageId}"
               .set 'Accept', 'application/json'
               .end (res) ->
                   if res.ok
                       callback null, res.body
                   else
                       callback "Something went wrong -- #{res.body}"

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

    search: (query, numPage, callback) ->
        encodedQuery = encodeURIComponent query
        numByPage = SettingsStore.get 'messagesPerPage'
        request.get "search/#{encodedQuery}/page/#{numPage}/limit/#{numByPage}"
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback res.body, null
