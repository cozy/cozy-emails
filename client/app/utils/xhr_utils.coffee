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
                console.log "Error in changeSettings", settings, res.body?.error
                callback t('app error')

    fetchMessage: (emailID, callback) ->
        request.get "message/#{emailID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in fetchMessage", emailID, res.body?.error
                callback t('app error')

    fetchConversation: (emailID, callback) ->
        request.get "conversation/#{emailID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in fetchConversation", emailID,
                    res.body?.error
                callback t('app error')


    fetchMessagesByFolder: (mailboxID, query, callback) ->
        for own key, val of query
            if val is '-' or val is 'all'
                delete query[key]
        request.get "mailbox/#{mailboxID}"
        .set 'Accept', 'application/json'
        .query query
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in fetchMessagesByFolder", res.body?.error
                callback t('app error')

    mailboxCreate: (mailbox, callback) ->
        request.post "mailbox"
        .send mailbox
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in mailboxCreate", mailbox, res.body?.error
                callback t('app error')

    mailboxUpdate: (data, callback) ->
        request.put "mailbox/#{data.mailboxID}"
        .send data
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in mailboxUpdate", data, res.body?.error
                callback t('app error')

    mailboxDelete: (data, callback) ->
        request.del "mailbox/#{data.mailboxID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in mailboxDelete", data, res.body?.error
                callback t('app error')

    mailboxExpunge: (data, callback) ->
        request.del "mailbox/#{data.mailboxID}/expunge"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in mailboxExpunge", data, res.body?.error
                callback t('app error')

    messageSend: (message, callback) ->
        req = request.post "message"
        .set 'Accept', 'application/json'

        files = {}
        message.attachments = message.attachments.map (file) ->
            files[file.get('generatedFileName')] = file.get 'rawFileObject'
            return file.remove 'rawFileObject'
        .toJS()

        req.field 'body', JSON.stringify message
        for name, blob of files
            if blob?
                req.attach name, blob

        req.end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in messageSend", message, res.body?.error
                callback res.body?.error?.message

    messagePatch: (messageID, patch, callback) ->
        request.patch "message/#{messageID}", patch
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in messagePatch", messageID, res.body?.error
                callback t('app error')

    conversationDelete: (conversationID, callback) ->
        request.del "conversation/#{conversationID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in conversationDelete", conversationID,
                    res.body?.error
                callback t('app error')

    conversationPatch: (conversationID, patch, callback) ->
        request.patch "conversation/#{conversationID}", patch
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in conversationPatch", conversationID,
                    res.body?.error
                callback t('app error')

    createAccount: (account, callback) ->

        # TODO: validation & sanitization

        request.post 'account'
        .send account
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in createAccount", account, res.body?.error
                callback res.body, null

    editAccount: (account, callback) ->

        # TODO: validation & sanitization
        rawAccount = account.toJS()

        request.put "account/#{rawAccount.id}"
        .send rawAccount
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in editAccount", account, res.body?.error
                callback res.body, null

    checkAccount: (account, callback) ->

        rawAccount = account.toJS()

        request.put "account/#{rawAccount.id}/check"
        .send rawAccount
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in checkAccount", res.body
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
                console.log "Error in search", res.body?.error
                callback res.body, null

    refresh: (hard, callback) ->
        url = if hard then "refresh?all=true"
        else "refresh"

        request.get url
        .end (res) ->
            if res.ok
                callback null, res.text
            else
                callback res.body

    activityCreate: (options, callback) ->
        request.post "activity"
        .send options
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                console.log "Error in activityCreate", options, res.body?.error
                callback res.body, null
