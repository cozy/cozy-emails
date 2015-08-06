async = require 'async'

Account = require '../models/account'
Mailbox = require '../models/mailbox'
Message = require '../models/message'
{BadRequest} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'mailbox:controller')
_ = require 'lodash'
async = require 'async'
ramStore = require '../models/store_account_and_boxes'

# refresh a single mailbox if we can do it fast
# We can do it fast if the server support RFC4551
# see {Mailbox::imap_refreshFast}
module.exports.refresh = (req, res, next) ->
    mailbox = ramStore.getMailbox(req.params.mailboxID)
    account = ramStore.getAccount(mailbox.accountID)
    if not account.supportRFC4551
        next new BadRequest('Cant refresh a non RFC4551 box')
    else
        req.mailbox.imap_refresh
            limitByBox: null
            firstImport: false
            supportRFC4551: true
        , (err, shouldNotif) ->
            return next err if err
            Mailbox.getCounts req.mailbox.id, (err, counts) ->
                return next err if err
                mailboxCounts = counts[req.mailbox.id]
                req.mailbox.nbTotal = mailboxCounts?.total or 0
                req.mailbox.nbUnread = mailboxCounts?.unread or 0
                res.send req.mailbox



# create a mailbox
module.exports.create = (req, res, next) ->
    log.info "Creating #{req.body.label} under #{req.body.parentID}" +
        " in #{req.body.accountID}"

    account = ramStore.getAccount(req.body.accountID)
    parent = ramStore.getMailbox(req.body.parentID)
    label = req.body.label

    Mailbox.imapcozy_create account, parent, label, (err) ->
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

