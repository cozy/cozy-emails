async = require 'async'

Account = require '../models/account'
Mailbox = require '../models/mailbox'
Message = require '../models/message'
{BadRequest} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'mailbox:controller')
_ = require 'lodash'
async = require 'async'
ramStore = require '../models/store_account_and_boxes'
Scheduler = require '../processes/_scheduler'
MailboxRefreshFast = require '../processes/mailbox_refresh_fast'

# refresh a single mailbox if we can do it fast
# We can do it fast if the server support RFC4551
# see {Mailbox::imap_refreshFast}
module.exports.refresh = (req, res, next) ->
    mailbox = ramStore.getMailbox(req.params.mailboxID)
    account = ramStore.getAccount(mailbox.accountID)
    if not account.supportRFC4551
        next new BadRequest('Cant refresh a non RFC4551 box')
    else
        res.send ramStore.getMailboxClientObject mailbox.id
        # refresh = new MailboxRefreshFast mailbox: mailbox
        # Scheduler.schedule refresh, (err) ->
        #     return next err if err

# create a mailbox
module.exports.create = (req, res, next) ->
    log.info "Creating #{req.body.label} under #{req.body.parentID}" +
        " in #{req.body.accountID}"

    account = ramStore.getAccount(req.body.accountID)
    parent = ramStore.getMailbox(req.body.parentID)
    label = req.body.label

    if parent
        path = parent.path + parent.delimiter + label
        tree = parent.tree.concat label
    else
        path = label
        tree = [label]

    mailbox =
        accountID: account.id
        label: label
        path: path
        tree: tree
        delimiter: parent?.delimiter or '/'
        attribs: []

    async.series [
        (cb) ->
            ramStore.getImapPool(mailbox).doASAP (imap, cbRelease) ->
                imap.addBox2 path, cbRelease
            , cb
        (cb) ->
            Mailbox.create mailbox, (err, created) ->
                mailbox = created
                cb err
    ], (err) ->
        return next err if err
        res.send ramStore.getAccountClientObject account.id


# update a mailbox
module.exports.update = (req, res, next) ->
    log.info "Updating #{req.params.mailboxID} to #{req.body.label}"

    mailbox = ramStore.getMailbox(req.params.mailboxID)
    account = ramStore.getAccount(mailbox.accountID)

    if req.body.label

        path = mailbox.path
        parentPath = path.substring 0, path.lastIndexOf(mailbox.label)
        newPath = parentPath + req.body.label

        mailbox.imapcozy_rename req.body.label, newPath, (err, updated) ->
            return next err if err
            res.send ramStore.getAccountClientObject account.id


    else if req.body.favorite?

        favorites = _.without account.favorites, mailbox.id
        favorites.push mailbox.id if req.body.favorite

        account.updateAttributes {favorites}, (err, updated) ->
            return next err if err
            res.send ramStore.getAccountClientObject account.id

    else next new BadRequest 'Unsuported request for mailbox update'

# delete a mailbox
module.exports.delete = (req, res, next) ->
    log.info "Deleting #{req.params.mailboxID}"

    mailbox = ramStore.getMailbox(req.params.mailboxID)
    account = ramStore.getAccount(mailbox.accountID)
    mailbox.imapcozy_delete (err) ->
        return next err if err
        res.send ramStore.getAccountClientObject account.id

# expunge every messages from trash mailbox
module.exports.expunge = (req, res, next) ->
    log.info "Expunging #{req.params.mailboxID}"

    mailbox = ramStore.getMailbox(req.params.mailboxID)
    account = ramStore.getAccount(mailbox.accountID)
    if account.trashMailbox is req.params.mailboxID
        mailbox.imap_expungeMails (err) ->
            return next err if err
            res.send ramStore.getAccountClientObject account.id
    else
        next new BadRequest 'You can only expunge trash mailbox'

