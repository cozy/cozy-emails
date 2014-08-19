request = require 'superagent'

# The flux instance is required in each method because when this file is loaded
# the flux instance is being created.

module.exports =

    fetchEmailsByMailbox: (mailboxID) ->
        flux = require '../fluxxor'
        request.get "mailbox/#{mailboxID}/emails"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                flux.actions.email.receiveRawEmails res.body
            else
                console.log "Something went wrong -- #{res.body}"


    fetchEmailThread: (emailID) ->
        flux = require '../fluxxor'
        request.get "email/#{emailID}"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                flux.actions.email.receiveRawEmail res.body
            else
                console.log "Something went wrong -- #{res.body}"

    fetchImapFolderByMailbox: (mailboxID) ->
        flux = require '../fluxxor'
        request.get "mailbox/#{mailboxID}/folders"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                flux.actions.imapFolder.receiveRawImapFolders res.body
            else
                console.log "Something went wrong -- #{res.body}"

    fetchEmailsByFolder: (imapFolderID) ->
        flux = require '../fluxxor'
        request.get "folder/#{imapFolderID}/emails"
               .set 'Accept', 'application/json'
               .end (res) ->
            if res.ok
                flux.actions.email.receiveRawEmails res.body
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
