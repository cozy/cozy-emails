async = require 'async'

Account = require '../models/account'
Mailbox = require '../models/mailbox'
Imap = require '../processes/imap_processes'
_ = require 'lodash'
{WrongConfigError, HttpError} = require '../utils/errors'

# create a mailbox
module.exports.create = (req, res, next) ->
    console.log "Creating #{req.body.label} under #{req.body.parentID} in #{req.body.accountID}"
    Account.findPromised req.body.accountID
        .then (account) ->
            if account?
                req.account = account
                req.account.includeMailboxes()
                    .then -> res.send 200, req.account
                    .catch next
            else throw new HttpError 404, 'Not Found'
        .nodeify next

# update a mailbox
module.exports.update = (req, res, next) ->
    console.log "Updating #{req.params.mailboxID} to #{req.body.label}"
    Mailbox.findPromised req.params.mailboxID
        .then (box) ->
            # @TODO update box label
            Account.findPromised box.accountID
                .then (account) ->
                    if account?
                        req.account = account
                        req.account.includeMailboxes()
                            .then -> res.send 200, req.account
                            .catch next
                    else throw new HttpError 404, 'Not Found'
                .nodeify next

# delete a mailbox
module.exports.delete = (req, res, next) ->
    console.log "Deleting #{req.params.mailboxID}"
    Mailbox.findPromised req.params.mailboxID
        .then (box) ->
            # @TODO delete box
            Account.findPromised box.accountID
                .then (account) ->
                    if account?
                        req.account = account
                        req.account.includeMailboxes()
                            .then -> res.send 200, req.account
                            .catch next
                    else throw new HttpError 404, 'Not Found'
                .nodeify next

