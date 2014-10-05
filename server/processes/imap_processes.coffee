# There is a circular dependency between ImapProcess & Account
# node handles it if we do module.exports before imports

# Public: static class with imap methods
# if i write here
module.exports = class ImapProcess
    constructor: ->

ImapScheduler = require './imap_scheduler'
ImapReporter = require './imap_reporter'
Promise = require 'bluebird'
Message = require '../models/message'
Mailbox = require '../models/mailbox'
Account = require '../models/account'
_ = require 'lodash'
log = require('../utils/logging')(prefix: 'imap:processes')

# Public: get the boxes tree
# 
# account - the {Account} to fetch from
# 
# Returns a {Promise} for the raw imap boxes tree {Object}
ImapProcess.fetchBoxesTree = (account) ->
    # the user is waiting, we do this ASAP
    ImapScheduler.instanceFor(account).doASAP (imap) ->
        log.info "FETCH BOX TREE"
        imap.getBoxes()


# Public: refresh the account
# 
# account - the {Account} to fetch from
# limitByBox - the maximum {Number} of message to fetch at once
# 
# Returns a {Promise} for task completion
ImapProcess.fetchAccount = (account, limitByBox = false) ->
    Mailbox.getBoxes(account.id).then (boxes) ->
        Promise.serie boxes, (box) ->
            ImapProcess.fetchMailbox account, box, limitByBox
            .catch (err) -> log.error "FAILED TO FETCH BOX", box.path, err.stack

# Public: refresh one mailbox
# register a 'diff' task in {ImapReporter}
# 
# account - the {Account} to fetch from
# box - the {Mailbox} to fetch from
# limitByBox - the maximum {Number} of message to fetch at once
# 
# Returns a {Promise} for task completion
ImapProcess.fetchMailbox = (account, box, limitByBox = false) ->
    reporter = ImapReporter.addUserTask
        code: 'diff'
        total: 1
        account: account.label
        box: box.path

    # let the scheduler safely open the box
    ImapScheduler.instanceFor(account).doLaterWithBox box, (imap) ->
        reporter.addProgress 0.1

        Promise.all [
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
            toDo.push ImapProcess.removeMails account, box, toRemove

        reporter.onDone()
        Promise.all toDo

# Private: fetch mails from a box
# register a 'apply-diff-fetch' task in {ImapReporter}
# 
# account - the {Account} to fetch from
# box - the {Mailbox} to fetch from
# uids - an [{Number}], the uids to fetch
# 
# Returns a {Promise} for task completion
ImapProcess.fetchMails = (account, box, uids) ->
    reporter = ImapReporter.addUserTask
        code: 'apply-diff-fetch'
        account: account.label
        box: box.path
        total: uids.length

    Promise.map uids, (id) ->
        ImapProcess.fetchOneMail account, box, id
        .tap -> reporter.addProgress 1
        .catch (err) -> reporter.onError err

    .tap -> reporter.onDone()

# Private: remove mails from a box in the cozy
# register a 'apply-diff-remove' task in {ImapReporter}
# 
# account - the {Account} to fetch from
# box - the {Mailbox} to fetch from
# cozyIDs - an [{String}], the cozy {Message} ids to remove from this box
# 
# Returns a {Promise} for task completion
ImapProcess.removeMails = (account, box, cozyIDs) ->
    reporter = ImapReporter.addUserTask
        code: 'apply-diff-remove'
        account: account.label
        box: box.path
        total: cozyIDs.length

    # remove messages from the box
    Promise.serie cozyIDs, (id) ->
        Message.findPromised id
        .then (message) -> message.removeFromMailbox box
        .tap -> reporter.addProgress 1
        .catch (err) -> reporter.onError err

    .tap -> reporter.onDone()



# Public: fetch one mail from IMAP and create a 
# {Message} in cozy for it. If the message
# already exists in another mailbox, we just add to its mailboxIDs
# 
# account - the {Account} to create mail into
# box - the {Mailbox} to create mail into
# uid - {Number} the UID of message to fetch
# 
# Returns a {Promise} for the created/updated {Message}
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

# Public: apply a flags & boxes patch to message
# 
# msg      - the target {Message}
# flagsOps - {add : [String flag], remove: [String]}
# boxOps   - {addTo : [String boxIds], removeFrom: [String boxIds]}
# 
# Returns a {Promise} for task completion
ImapProcess.applyMessageChanges = (msg, flagsOps, boxOps) ->

    log.info "MESSAGE CHANGE"
    log.info "BASE"
    log.info "CHANGES", flagsOps, boxOps

    boxIndex = {}
    
    # in parallel
    Promise.all [
        # get a scheduler
        Account.findPromised msg.accountID
        .then (account) -> ImapScheduler.instanceFor account

        # populate the boxIndex
        Mailbox.getBoxes msg.accountID
        .then (boxes) ->
            for box in boxes
                uid = msg.mailboxIDs[box.id]
                boxIndex[box.id] = path: box.path, uid: uid
    ]
    .spread (scheduler) -> scheduler.doASAP (imap) ->  

        # ERROR CASES
        for boxid in boxOps.addTo when not boxIndex[boxid]
            throw new Error "the box ID=#{box} doesn't exists"

        # step 1 - get the first box + UID
        boxid = Object.keys(msg.mailboxIDs)[0]
        uid = msg.mailboxIDs[boxid]
        
        # step 2 - apply flags change
        imap.openBox boxIndex[boxid].path
        .then -> 
            if flagsOps.add.length  
                imap.addFlags uid, flagsOps.add
        .then -> 
            if flagsOps.remove.length
                imap.delFlags uid, flagsOps.remove 
        .then ->
            log.info "CHANGED FLAGS #{boxIndex[boxid].path}:#{uid}",
            "ADD" , flagsOps.add, "REMOVE", flagsOps.remove
            msg.flags = _.union msg.flags, flagsOps.add
            msg.flags = _.difference msg.flags, flagsOps.remove
            log.info "   RESULT = ", msg.flags

        # step 3 - copy the message to its destinations
        .then -> Promise.serie boxOps.addTo, (destId) ->
            imap.copy uid, boxIndex[destId].path
            .then (uidInDestination) -> 
                log.info "COPIED #{boxIndex[boxid].path}:#{uid}",
                " TO #{boxIndex[destId].path}:#{uidInDestination}"
                msg.mailboxIDs[destId] = uidInDestination
    
        # step 4 - remove the message from the box it shouldn't be in
        .then -> 
            Promise.serie boxOps.removeFrom, (boxid) ->
                {path, uid} = boxIndex[boxid] 

                imap.openBox path
                .then -> imap.addFlags uid, '\\Deleted'
                .then -> imap.expunge uid
                .then -> delete msg.mailboxIDs[boxid]
                .tap ->
                    log.info "DELETED #{path}:#{uid}"

