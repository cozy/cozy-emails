async = require 'async'

Account = require '../models/account'
Mailbox = require '../models/mailbox'
Promise = require 'bluebird'
log = require('../utils/logging')(prefix: 'mailbox:controller')

# create a mailbox
module.exports.create = (req, res, next) ->
    log.info "Creating #{req.body.label} under #{req.body.parentID} in #{req.body.accountID}"

    pAccount = Account.findPromised req.body.accountID
    pParent = if req.body.parentID then Mailbox.findPromised req.body.parentID
    else Promise.resolve null


    Promise.join pAccount, pParent, (account, parent) ->
        if parent
            path = parent.path + parent.delimiter + req.body.label
            tree = parent.tree.concat req.body.label
        else
            path = req.body.label
            tree = [req.body.label]

        mailbox = new Mailbox
            accountID: account.id
            label: req.body.label
            path: path
            tree: tree
            delimiter: '/' #@TODO : this is probably not safe
            attribs: []
            children: []

        account.imap_createBox mailbox.path
        .then -> Mailbox.createPromised mailbox.toObject()
        .return account

    .then (account) -> account.toObjectWithMailbox()
    .then (account) -> res.send account
    .catch (err) ->
        log.error err
        next err


# update a mailbox
module.exports.update = (req, res, next) ->
    log.info "Updating #{req.params.mailboxID} to #{req.body.label}"
    Mailbox.findPromised req.params.mailboxID
    .then (box) ->
        Account.findPromised box.accountID
        .then (account) ->
            parentPath = box.path.substring 0, box.path.lastIndexOf box.label
            newPath = parentPath + req.body.label

            account.imap_renameBox box.path, newPath
            .then ->
                box.label = req.body.label
                box.path = newPath
                box.tree[box.tree.length - 1] = req.body.label
                box.savePromised()
            .return account

    .then (account) -> account.toObjectWithMailbox()
    .then (account) -> res.send account
    .catch next

# delete a mailbox
module.exports.delete = (req, res, next) ->
    log.info "Deleting #{req.params.mailboxID}"
    Mailbox.findPromised req.params.mailboxID
    .then (box) ->
        Account.findPromised box.accountID
        .then (account) ->
            account.imap_deleteBox box.path
            .then -> box.destroyAndRemoveAllMessages()
            .return account

    .then (account) -> account.toObjectWithMailbox()
    .then (account) -> res.send account
    .catch next
