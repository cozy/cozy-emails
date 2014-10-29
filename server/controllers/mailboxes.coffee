async = require 'async'

Account = require '../models/account'
Mailbox = require '../models/mailbox'
Promise = require 'bluebird'
{BadRequest, NotFound} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'mailbox:controller')

# create a mailbox
module.exports.create = (req, res, next) ->
    log.info "Creating #{req.body.label} under #{req.body.parentID}" +
        " in #{req.body.accountID}"

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

        # @TODO : probably better to get it from IMAP
        mailbox =
            accountID: account.id
            label: req.body.label
            path: path
            tree: tree
            delimiter: parent?.delimiter or '/'
            attribs: []

        account.imap_createBox path
        .then -> Mailbox.createPromised mailbox
        .return account

    .then (account) -> account.toObjectWithMailbox()
    .then (account) -> res.send account
    .catch next


# update a mailbox
module.exports.update = (req, res, next) ->
    log.info "Updating #{req.params.mailboxID} to #{req.body.label}"

    pBox = Mailbox.findPromised req.params.mailboxID
    .throwIfNull -> new NotFound "Mailbox #{req.params.mailboxID}"

    pAccount = pBox.then (box) -> Account.findPromised box.accountID

    Promise.join pBox, pAccount, (box, account) ->

        path = box.path
        parentPath = path.substring 0, path.lastIndexOf(box.label)
        newPath = parentPath + req.body.label

        account.imap_renameBox path, newPath
        .then -> box.renameWithChildren newPath
        .return account

    .then (account) -> account.toObjectWithMailbox()
    .then (account) -> res.send account
    .catch next

# delete a mailbox
module.exports.delete = (req, res, next) ->
    log.info "Deleting #{req.params.mailboxID}"

    pBox = Mailbox.findPromised req.params.mailboxID
    .throwIfNull -> new NotFound "Mailbox #{req.params.mailboxID}"

    pAccount = pBox.then (box) -> Account.findPromised box.accountID

    Promise.join pBox, pAccount, (box, account) ->
        account.imap_deleteBox box.path
        .then -> account.forgetBox box.id
        .then -> box.destroyAndRemoveAllMessages()
        .return account

    .then (account) -> account.toObjectWithMailbox()
    .then (account) -> res.send account
    .catch next
