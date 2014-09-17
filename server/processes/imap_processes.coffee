ImapScheduler = require './imap_scheduler'
Promise = require 'bluebird'
Message = require '../models/message'
Mailbox = require '../models/mailbox'
_ = require 'lodash'
module.exports = ImapProcess = {}

# @deadcode check the connection
ImapProcess.checkConnection = (account) ->
    ImapScheduler.instanceFor(account).doASAP (imap) ->
        Promise.resolve 'ok'

# get the boxes tree
# return a promise for the raw imap boxes tree
ImapProcess.fetchBoxesTree = (account) ->
    # the user is waiting, we do this ASAP
    ImapScheduler.instanceFor(account).doASAP (imap) ->
        imap.getBoxes()

# refresh one account
# return a Promise for task completion
ImapProcess.fetchAccount = (account) ->
    Mailbox.getBoxes(account.id).then (boxes) ->
        Promise.serie boxes, (box) ->
            ImapProcess.fetchMailbox account, box

# refresh one mailbox
# return a promise for task completion
ImapProcess.fetchMailbox = (account, box) ->
    ImapScheduler.instanceFor(account).doLater (imap) ->
        imap.openBox box.path
        .then (imapbox) ->
            unless imapbox.persistentUIDs
                throw new Error 'UNPERSISTENT UID NOT SUPPORTED'

            if box.uidvalidity and imapbox.uidvalidity isnt box.uidvalidity
                # uid validity has changed
                # this should be rare
                # @TODO : recover from this
                #    - create a copy of the mailbox, fetch it (deduped)
                #    - and then destroy old version
                throw new Error 'UID VALIDITY HAS CHANGED'

        # fetch UIDS from db & imap in parallel
        .then -> Promise.all [
            imap.search [['ALL']]
            Message.getUIDs box.id
        ]

    # we got the ids, we fetch them in separate tasks
    .spread (imapIds, cozyIds) ->

        # diff local & remote
        toFetch = _.difference imapIds, cozyIds
        toDelete = _.difference cozyIds, imapIds

        console.log 'FETCHING', box.path
        console.log '   in imap', imapIds.length
        console.log '   in cozy', cozyIds.length
        console.log '   to fetch', toFetch.length
        console.log '   to del', toDelete.length

        Promise.map toFetch.reverse(), (id) ->
            ImapProcess.fetchOneMail account, box, id

        # @TODO handle toDelete ?

# fetch one mail from imap server
# return a Promise for task completion
ImapProcess.fetchOneMail = (account, box, uid) ->
    scheduler = ImapScheduler.instanceFor account
    scheduler.doLater (imap) ->
        log = "MAIL #{box.path}##{uid} "
        mail = null

        imap.openBox box.path
        .then -> imap.fetchOneMail uid
        .then (fetched) ->
            mail = fetched
            # check if the message already exists in another mailbox
            Message.byMessageId account.id, mail.headers['message-id']

        .then (existing) ->
            if existing
                existing.addToMailbox box, uid
                .tap -> console.log  log + "already in db"
            else
                Message.createFromImapMessage mail, box, uid
                .tap -> console.log  log + "created"