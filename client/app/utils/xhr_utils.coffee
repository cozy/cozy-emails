request = superagent

AccountTranslator = require './translators/account_translator'

SettingsStore = require '../stores/settings_store'


handleResponse = (res, callback, details...) ->
    if res.ok then callback null, res.body
    else
        if res.body?.error is true
            err = res.body
        else if res.body?.error
            err = res.body.error
        else if res.body
            err = res.body
        else
            err = new Error("error in #{details[0]}")
        console.log "Error in", details..., err
        callback err

module.exports =
    changeSettings: (settings, callback) ->
        request.put "settings"
        .set 'Accept', 'application/json'
        .send settings
        .end (res) ->
            handleResponse res, callback, 'changeSettings', settings

    fetchMessage: (emailID, callback) ->
        request.get "message/#{emailID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, 'fetchMessage', emailID

    fetchConversation: (conversationID, callback) ->
        request.get "messages/batchFetch?conversationID=#{conversationID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                res.body.conversationLengths = {}
                res.body.conversationLengths[conversationID] = res.body.length

            handleResponse res, callback, "fetchConversation", conversationID

    fetchMessagesByFolder: (url, callback) ->
        request.get url
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "fetchMessagesByFolder", url

    mailboxCreate: (mailbox, callback) ->
        request.post "mailbox"
        .send mailbox
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "mailboxCreate", mailbox

    mailboxUpdate: (data, callback) ->
        request.put "mailbox/#{data.mailboxID}"
        .send data
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "mailboxUpdate", data

    mailboxDelete: (data, callback) ->
        request.del "mailbox/#{data.mailboxID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "mailboxDelete", data

    mailboxExpunge: (data, callback) ->
        request.del "mailbox/#{data.mailboxID}/expunge"
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "mailboxExpunge", data

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
            handleResponse res, callback, "messageSend", message


    batchFetch: (target, callback) ->
        body = _.extend {}, target
        request.put "messages/batchFetch"
        .send target
        .end (res) ->
            handleResponse res, callback, "batchFetch"

    batchAddFlag: (target, flag, callback) ->
        body = _.extend {flag}, target
        request.put "messages/batchAddFlag"
        .send body
        .end (res) ->
            handleResponse res, callback, "batchAddFlag"

    batchRemoveFlag: (target, flag, callback) ->
        body = _.extend {flag}, target
        request.put "messages/batchRemoveFlag"
        .send body
        .end (res) ->
            handleResponse res, callback, "batchRemoveFlag"

    batchDelete: (target, callback) ->
        body = _.extend {}, target
        request.put "messages/batchTrash"
        .send target
        .end (res) ->
            handleResponse res, callback, "batchDelete"

    batchMove: (target, from, to, callback) ->
        body = _.extend {from, to}, target
        request.put "messages/batchMove"
        .send body
        .end (res) ->
            handleResponse res, callback, "batchMove"

    createAccount: (account, callback) ->
        # TODO: validation & sanitization
        request.post 'account'
        .send account
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "createAccount", account

    editAccount: (account, callback) ->

        # TODO: validation & sanitization
        rawAccount = account.toJS()

        request.put "account/#{rawAccount.id}"
        .send rawAccount
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "editAccount", account

    checkAccount: (account, callback) ->

        request.put "accountUtil/check"
        .send account
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "checkAccount"

    removeAccount: (accountID, callback) ->

        request.del "account/#{accountID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "removeAccount"

    accountDiscover: (domain, callback) ->

        request.get "provider/#{domain}"
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "accountDiscover"

    search: (url, callback) ->
        request.get url
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "search"

    refresh: (hard, callback) ->
        url = if hard then "refresh?all=true"
        else "refresh"

        request.get url
        .end (res) ->
            handleResponse res, callback, "refresh"

    refreshMailbox: (mailboxID, opts, callback) ->
        request.get "refresh/#{mailboxID}"
        .query opts
        .end (res) ->
            handleResponse res, callback, "refreshMailbox"


    activityCreate: (options, callback) ->
        request.post "activity"
        .send options
        .set 'Accept', 'application/json'
        .end (res) ->
            handleResponse res, callback, "activityCreate", options
