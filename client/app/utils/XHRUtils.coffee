request = require 'superagent'

EmailActionCreator = require '../actions/EmailActionCreator'
ImapFolderActionCreator = require '../actions/ImapFolderActionCreator'

MailboxStore = require '../stores/MailboxStore'

module.exports =

    fetchEmailsByMailbox: (mailboxID) ->
        request.get "mailbox/#{mailboxID}/emails"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                EmailActionCreator.receiveRawEmails res.body
            else
                console.log "Something went wrong -- #{res.body}"

    fetchEmailThread: (emailID, callback) ->
        request.get "email/#{emailID}"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                EmailActionCreator.receiveRawEmail res.body
                callback null, res.body
            else
                callback "Something went wrong -- #{res.body}"

    fetchImapFolderByMailbox: (mailboxID) ->
        request.get "mailbox/#{mailboxID}/folders"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                ImapFolderActionCreator.receiveRawImapFolders res.body
            else
                console.log "Something went wrong -- #{res.body}"

    fetchEmailsByFolder: (imapFolderID) ->
        request.get "folder/#{imapFolderID}/emails"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                EmailActionCreator.receiveRawEmails res.body
            else
                console.log "Something went wrong -- #{res.body}"

    createMailbox: (mailbox, callback) ->

        # TODO: validation & sanitization

        request.post 'mailbox'
               .send mailbox
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback res.body, null

    editMailbox: (mailbox, callback) ->

        # TODO: validation & sanitization

        request.put "mailbox/#{mailbox.id}"
               .send mailbox
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                callback null, res.body
            else
                callback res.body, null

    removeMailbox: (mailboxID) ->

        request.del "mailbox/#{mailboxID}"
               .set 'Accept', 'application/json'
               .end (res) ->
                    # nothing
