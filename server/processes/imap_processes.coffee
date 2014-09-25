ImapScheduler = require './imap_scheduler'
ImapReporter = require './imap_reporter'
Promise = require 'bluebird'
Message = require '../models/message'
Mailbox = require '../models/mailbox'
_ = require 'lodash'
module.exports = ImapProcess = {}
log = require('../utils/logging')(prefix: 'imap:processes')

# get the boxes tree
# return a promise for the raw imap boxes tree
ImapProcess.fetchBoxesTree = (account) ->
    # the user is waiting, we do this ASAP
    ImapScheduler.instanceFor(account).doASAP (imap) ->
        log.info "FETCH BOX TREE"
        imap.getBoxes()

# refresh one account
# return a Promise for task completion
ImapProcess.fetchAccount = (account) ->
    Mailbox.getBoxes(account.id).then (boxes) ->
        Promise.serie boxes, (box) ->
            ImapProcess.fetchMailbox account, box
            .catch (err) -> log.error "FAILED TO FETCH BOX", box.path, err.stack

# refresh one mailbox
# return a promise for task completion
ImapProcess.fetchMailbox = (account, box, limitByBox = false) ->
    reporter = ImapReporter.addUserTask
        code: 'diff'
        total: 1
        box: box.path

    ImapScheduler.instanceFor(account).doLater (imap) ->
        imap.openBox box.path
        .tap -> reporter.addProgress 0.1
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
            imap.search([['ALL']]).tap -> reporter.addProgress 0.5
            Message.getUIDs(box.id).tap -> reporter.addProgress 0.3
        ]

    # we got the ids, we fetch them in separate tasks
    .spread (imapIds, cozyIds) ->

        # cozyIds is an array of [cozyID, box UID]

        # diff local & remote
        toFetch = _.difference imapIds, cozyIds.map (ids) -> ids[1]
        toRemove = (ids[0] for ids in cozyIds when ids[1] not in imapIds)

        log.info 'FETCHING', box.path
        log.info '   in imap', imapIds.length
        log.info '   in cozy', cozyIds.length
        log.info '   to fetch', toFetch.length
        log.info '   to del', toRemove.length
        log.info '   limited', limitByBox

        # get higher UIDs (more recent) first
        toFetch.reverse()

        # fetch max limitByBox mails by box
        if limitByBox
            toFetch = toFetch[0..limitByBox]

        toDo = []
        if toFetch.length
            toDo.push ImapProcess.fetchMails account, box, toFetch

        if toRemove.length
            toDo.push ImapProcess.removeMails box, toRemove

        reporter.onDone()
        Promise.all toDo


ImapProcess.fetchMails = (account, box, uids) ->
    reporter = ImapReporter.addUserTask
        code: 'apply-diff-fetch'
        box: box.path
        total: uids.length

    Promise.map uids, (id) ->
        ImapProcess.fetchOneMail account, box, id
        .tap -> reporter.addProgress 1
        .catch (err) -> reporter.onError err

    .tap -> reporter.onDone()


ImapProcess.removeMails = (box, cozyIDs) ->
    reporter = ImapReporter.addUserTask
        code: 'apply-diff-remove'
        box: box.path
        total: cozyIDs.length

    # remove messages from the box
    Promise.serie cozyIDs, (id) ->
        Message.findPromised id
        .then (message) -> message.removeFromMailbox box
        .tap -> reporter.addProgress 1
        .catch (err) -> reporter.onError err

    .tap -> reporter.onDone()

# fetch one mail from imap server
# return a Promise for task completion
ImapProcess.fetchOneMail = (account, box, uid) ->
    scheduler = ImapScheduler.instanceFor account
    scheduler.doLater (imap) ->
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
                .tap -> log.info "MAIL #{box.path}##{uid} ADDED TO BOX"
            else
                Message.createFromImapMessage mail, box, uid
                .tap -> log.info "MAIL #{box.path}##{uid} CREATED"