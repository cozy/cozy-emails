async = require 'async'

Account = require '../models/account'
Mailbox = require '../models/mailbox'
Message = require '../models/message'
{BadRequest} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'mailbox:controller')
_ = require 'lodash'
async = require 'async'

# fetch the mailbox and attach it to the request
module.exports.fetch = (req, res, next) ->
    id = req.params.mailboxID
    Mailbox.find req.params.mailboxID, (err, mailbox) ->
        return next err if err
        req.mailbox = mailbox
        next()

# fetch a mailbox by the body.parentID
# attach it to the request as parentMailbox
module.exports.fetchParent = (req, res, next) ->
    return async.nextTick next unless req.body.parentID

    Mailbox.find req.body.parentID, (err, mailbox) ->
        return next err if err
        req.parentMailbox = mailbox
        next()

# refresh a single mailbox if we can do it fast
# We can do it fast if the server support RFC4551
# see {Mailbox::imap_refreshFast}
module.exports.refresh = (req, res, next) ->
    account = req.account
    if account.isRefreshing()
        return res.status(202).send info: 'in progress'
    else if not account.supportRFC4551
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
                {total, recent, unread} = counts[req.mailbox.id]
                req.mailbox.nbTotal = total
                req.mailbox.nbUnread = unread
                res.send req.mailbox



# create a mailbox
module.exports.create = (req, res, next) ->
    log.info "Creating #{req.body.label} under #{req.body.parentID}" +
        " in #{req.body.accountID}"

    account = req.account
    parent = req.parentMailbox
    label = req.body.label

    Mailbox.imapcozy_create account, parent, label, (err) ->
        return next err if err
        res.account = account
        next()


# update a mailbox
module.exports.update = (req, res, next) ->
    log.info "Updating #{req.params.mailboxID} to #{req.body.label}"

    account = req.account
    mailbox = req.mailbox


    if req.body.label

        path = mailbox.path
        parentPath = path.substring 0, path.lastIndexOf(mailbox.label)
        newPath = parentPath + req.body.label

        mailbox.imapcozy_rename req.body.label, newPath, (err, updated) ->
            return next err if err
            res.account = account
            next null


    else if req.body.favorite?

        favorites = _.without account.favorites, mailbox.id
        favorites.push mailbox.id if req.body.favorite

        account.updateAttributes {favorites}, (err, updated) ->
            return next err if err
            res.account = updated
            next null

    else next new BadRequest 'Unsuported request for mailbox update'

# delete a mailbox
module.exports.delete = (req, res, next) ->
    log.info "Deleting #{req.params.mailboxID}"

    account = req.account

    req.mailbox.imapcozy_delete account, (err) ->
        return next err if err
        res.account = account
        next null

# expunge every messages from trash mailbox
module.exports.expunge = (req, res, next) ->
    log.info "Expunging #{req.params.mailboxID}"

    account = req.account
    if account.trashMailbox is req.params.mailboxID
        if account.isTest()
            Message.safeRemoveAllFromBox req.params.mailboxID, (err) ->
                return next err if err
                res.account = account
                next null
        else
            req.mailbox.imap_expungeMails (err) ->
                return next err if err
                res.account = account
                next null
    else
        next new BadRequest 'You can only expunge trash mailbox'

