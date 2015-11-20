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

    fetchConversation: (conversationID, callback) ->
        request.get "messages/batchFetch?conversationID=#{conversationID}"
        .set 'Accept', 'application/json'
        .end (res) ->
            if res.ok
                res.body.conversationLengths = {}
                res.body.conversationLengths[conversationID] = res.body.length
                callback null, res.body
            else
                console.log "Error in fetchConversation", conversationID,
                    res.body?.error
                callback t('app error')


    fetchMessagesByFolder: (url, callback) ->
        request.get url
        .set 'Accept', 'application/json'
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
                callback res.body?.error or res.body

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


    batchFetch: (target, callback) ->
        body = _.extend {}, target
        request.put "messages/batchFetch"
        .send target
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                if res.body?.name?
                    res.error = res.body
                callback res.error

    batchAddFlag: (target, flag, callback) ->
        body = _.extend {flag}, target
        request.put "messages/batchAddFlag"
        .send body
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                if res.body?.name?
                    res.error = res.body
                callback res.error

    batchRemoveFlag: (target, flag, callback) ->
        body = _.extend {flag}, target
        request.put "messages/batchRemoveFlag"
        .send body
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                if res.body?.name?
                    res.error = res.body
                callback res.error

    batchDelete: (target, callback) ->
        body = _.extend {}, target
        request.put "messages/batchTrash"
        .send target
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                if res.body?.name?
                    res.error = res.body
                callback res.error

    batchMove: (target, from, to, callback) ->
        body = _.extend {from, to}, target
        request.put "messages/batchMove"
        .send body
        .end (res) ->
            if res.ok
                callback null, res.body
            else
                if res.body?.name?
                    res.error = res.body
                callback res.error

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

        request.put "accountUtil/check"
        .send account
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

    search: (url, callback) ->
        request.get url
        .set 'Accept', 'application/json'
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
                callback null, res.body
            else
                callback res.body

    refreshMailbox: (mailboxID, callback) ->
        request.get "refresh/#{mailboxID}"
        .end (res) ->
            if res.ok
                callback null, res.body
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

