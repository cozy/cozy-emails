_        = require 'underscore'
request  = require 'superagent'
Throttle = require 'superagent-throttle'

{FlagsConstants} = require '../constants/app_constants'


throttle = new Throttle
    rate:       10
    ratePer:    5000
    concurrent: 5



discovery2Fields = (provider) ->
    infos = {}

    # Set values depending on given providers.
    for server in provider

        if server.type is 'imap' and not infos.imapServer?
            infos.imapServer = server.hostname
            infos.imapPort = server.port

            if server.socketType is 'SSL'
                infos.imapSSL = true
                infos.imapTLS = false

            else if server.socketType is 'STARTTLS'
                infos.imapSSL = false
                infos.imapTLS = true

            else if server.socketType is 'plain'
                infos.imapSSL = false
                infos.imapTLS = false

        if server.type is 'smtp' and not infos.smtpServer?
            infos.smtpServer = server.hostname
            infos.smtpPort = server.port

            if server.socketType is 'SSL'
                infos.smtpSSL = true
                infos.smtpTLS = false

            else if server.socketType is 'STARTTLS'
                infos.smtpSSL = false
                infos.smtpTLS = true

            else if server.socketType is 'plain'
                infos.smtpSSL = false
                infos.smtpTLS = false

    # Set default values if providers didn't give required infos.

    unless infos.imapServer?
        infos.imapServer = ''
        infos.imapPort   = '993'

    unless infos.smtpServer?
        infos.smtpServer = ''
        infos.smtpPort   = '465'

    unless infos.imapSSL
        switch infos.imapPort
            when '993'
                infos.imapSSL = true
                infos.imapTLS = false
            else
                infos.imapSSL = false
                infos.imapTLS = false

    unless infos.smtpSSL
        switch infos.smtpPort
            when '465'
                infos.smtpSSL = true
                infos.smtpTLS = false
            when '587'
                infos.smtpSSL = false
                infos.smtpTLS = true
            else
                infos.smtpSSL = false
                infos.smtpTLS = false

    infos.isGmail = infos.imapServer is 'imap.googlemail.com'

    return infos


handleResponse = (callback, details...) ->
    # Prepare the handler to get `err`, `res` from superagent, and next the
    # contextual args (callback, details...)
    _handler = (err, res, callback, details) ->
        if err or not res.ok
            unless err
                if res.body?.error is true
                    err = res.body
                else if res.body?.error
                    err = res.body.error
                else if res.body
                    err = res.body
                else
                    err = new Error "error in #{details[0]}"

            console.error "Error in", details..., err
            callback err

        else
            callback null, res.body

    # Returns a partial ready to be used by superagent `end`, with placeholders
    _.partial _handler, _, _, callback, details


module.exports =
    changeSettings: (settings, callback) ->
        request
        .put "settings"
        .set 'Accept', 'application/json'
        .send settings
        .end handleResponse callback, 'changeSettings', settings

    fetchConversation: ({messageID, conversationID}, callback) ->
        if conversationID
            url = "messages/batchFetch?conversationID=#{conversationID}"
        else
            url = "messages/batchFetch?messageID=#{messageID}"

        request
        .get url
        .set 'Accept', 'application/json'
        .use throttle.plugin
        .end (err, res) ->
            _cb = handleResponse callback, 'fetchConversation', {messageID, conversationID}
            _cb err, res

    fetchMessagesByFolder: (url, callback) ->
        request
        .get url
        .set 'Accept', 'application/json'
        .use throttle.plugin
        .end handleResponse callback, "fetchMessagesByFolder", url

    mailboxCreate: (mailbox, callback) ->
        request
        .post "mailbox"
        .send mailbox
        .set 'Accept', 'application/json'
        .end handleResponse callback, "mailboxCreate", mailbox

    mailboxUpdate: (data, callback) ->
        request
        .put "mailbox/#{data.mailboxID}"
        .send data
        .set 'Accept', 'application/json'
        .use throttle.plugin
        .end handleResponse callback, "mailboxUpdate", data

    mailboxDelete: (data, callback) ->
        request
        .del "mailbox/#{data.mailboxID}"
        .set 'Accept', 'application/json'
        .end handleResponse callback, "mailboxDelete", data

    mailboxExpunge: (data, callback) ->
        request
        .del "mailbox/#{data.mailboxID}/expunge"
        .set 'Accept', 'application/json'
        .use throttle.plugin
        .end handleResponse callback, "mailboxExpunge", data

    messageSend: (message, callback) ->
        req = request
        .post "message"
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

        req.end handleResponse callback, "messageSend", message


    batchFetch: (target, callback) ->
        body = _.extend {}, target

        request
        .put "messages/batchFetch"
        .send target
        .use throttle.plugin
        .end handleResponse callback, "batchFetch"

    batchFlag: ({target, action}, callback) ->
        switch action
            when FlagsConstants.SEEN
                operation = 'batchAddFlag'
                flag = FlagsConstants.SEEN
            when FlagsConstants.FLAGGED
                operation = 'batchAddFlag'
                flag = FlagsConstants.FLAGGED
            when FlagsConstants.UNSEEN
                operation = 'batchRemoveFlag'
                flag = FlagsConstants.SEEN
            when FlagsConstants.NOFLAG
                operation = 'batchRemoveFlag'
                flag = FlagsConstants.FLAGGED
            else
                throw new Error "Wrong usage : unrecognized FlagsConstants"

        body = _.extend {flag}, target

        request
        .put "messages/#{operation}"
        .send body
        .use throttle.plugin
        .end handleResponse callback, operation

    batchDelete: (target, callback) ->
        body = _.extend {}, target

        request
        .put "messages/batchTrash"
        .send body
        .use throttle.plugin
        .end handleResponse callback, "batchDelete"

    batchMove: (target, from, to, callback) ->
        body = _.extend {from, to}, target

        request
        .put "messages/batchMove"
        .send body
        .use throttle.plugin
        .end handleResponse callback, "batchMove"

    createAccount: (account, callback) ->
        # TODO: validation & sanitization
        request
        .post 'account'
        .send account
        .set 'Accept', 'application/json'
        .end handleResponse callback, "createAccount", account

    editAccount: (account, callback) ->

        # TODO: validation & sanitization
        rawAccount = account.toJS()

        request
        .put "account/#{rawAccount.id}"
        .send rawAccount
        .set 'Accept', 'application/json'
        .end handleResponse callback, "editAccount", account

    checkAccount: (account, callback) ->
        request
        .put "accountUtil/check"
        .send account
        .set 'Accept', 'application/json'
        .end handleResponse callback, "checkAccount"

    removeAccount: (accountID, callback) ->

        request
        .del "account/#{accountID}"
        .set 'Accept', 'application/json'
        .end handleResponse callback, "removeAccount"

    accountDiscover: (domain, callback) ->
        _callback = (error, provider) =>
            unless error
                infos = discovery2Fields(provider)
            callback error, provider, infos

        request
        .get "provider/#{domain}"
        .set 'Accept', 'application/json'
        .use throttle.plugin
        .end handleResponse _callback, "accountDiscover"

    search: (url, callback) ->
        request
        .get url
        .set 'Accept', 'application/json'
        .use throttle.plugin
        .end handleResponse callback, "search"

    refresh: (hard, callback) ->
        url = if hard then "refresh?all=true"
        else "refresh"

        request
        .get url
        .use throttle.plugin
        .end handleResponse callback, "refresh"


    refreshMailbox: (mailboxID, options={}, callback) ->
        request
        .get "refresh/#{mailboxID}"
        # FIXME: getting query server side doesnt work
        # cf refresh method into  controllers/mailboxes/
        .query options
        .use throttle.plugin
        .end handleResponse callback, "refreshMailbox"


    activityCreate: (options, callback) ->
        request
        .post "activity"
        .send options
        .set 'Accept', 'application/json'
        .use throttle.plugin
        .end handleResponse callback, "activityCreate", options
