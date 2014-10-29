request = superagent

AccountTranslator = require './translators/account_translator'

SettingsStore = require '../stores/settings_store'

module.exports =


    changeSettings: (settings, callback) ->
        request.put "settings"
        .set 'Accept', 'application/json'
        .send settings
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"


    fetchConversation: (emailID, callback) ->
        request.get "message/#{emailID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"


    fetchMessagesByFolder: (mailboxID, numPage, callback) ->
        request.get "mailbox/#{mailboxID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    mailboxCreate: (mailbox, callback) ->
        request.post "/mailbox"
        .send mailbox
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    mailboxUpdate: (data, callback) ->
        request.put "/mailbox/#{data.mailboxID}"
        .send data
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    mailboxDelete: (data, callback) ->
        request.del "/mailbox/#{data.mailboxID}"
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

    messagePatch: (messageId, patch, callback) ->
        request.patch "/message/#{messageId}", patch
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    conversationDelete: (conversationId, callback) ->
        request.del "/conversation/#{conversationId}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    conversationPatch: (conversationId, patch, callback) ->
        request.patch "/conversation/#{conversationId}", patch
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

    accountDiscover: (domain, callback) ->

        request.get "provider/#{domain}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback res.body, null

    search: (query, numPage, callback) ->
        encodedQuery = encodeURIComponent query
        numByPage = SettingsStore.get 'messagesPerPage'
        request.get "search/#{encodedQuery}/page/#{numPage}/limit/#{numByPage}"
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback res.body, null

    refresh: (callback) ->
        request.get "refresh"
        .end (res) ->
            callback(res.text)

    activityCreate: (options, callback) ->
        request.post "/activity"
        .send options
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback res.body, null
