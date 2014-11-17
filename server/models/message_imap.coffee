Message = require './message'
Mailbox = require './mailbox'
ImapScheduler = require '../processes/imap_scheduler'
Promise = require 'bluebird'
_ = require 'lodash'
log = require('../utils/logging')('models:message_imap')

Message::doASAP = (gen) ->
    ImapScheduler.instanceFor(@accountID)
    .then (scheduler) -> scheduler.doASAP gen


Message::imap_applyChanges = (flagsOps, boxOps) ->
    boxIndex = {}

    Mailbox.getBoxes @accountID
    .map (box) =>
        uid = @mailboxIDs[box.id]
        boxIndex[box.id] = path: box.path, uid: uid

    .then ->
        # ERROR CASES
        for boxid in boxOps.addTo when not boxIndex[boxid]
            throw new Error "the box ID=#{boxid} doesn't exists"

    .then => @doASAP (imap) =>

        # step 1 - get the first box + UID
        boxid = Object.keys(@mailboxIDs)[0]
        uid = @mailboxIDs[boxid]

        # step 2 - apply flags change
        imap.openBox boxIndex[boxid].path
        .then ->
            if flagsOps.add.length
                imap.addFlags uid, flagsOps.add
                log.info "ADDED FLAGS #{boxIndex[boxid].path}:#{uid}",
                    flagsOps.add
        .then ->
            if flagsOps.remove.length
                imap.delFlags uid, flagsOps.remove
                log.info "DELETED FLAGS #{boxIndex[boxid].path}:#{uid}",
                    flagsOps.add
        .then =>
            @flags = _.union @flags, flagsOps.add
            @flags = _.difference @flags, flagsOps.remove

        # step 3 - copy the message to its destinations
        .then =>
            Promise.serie boxOps.addTo, (destId) =>
                imap.copy uid, boxIndex[destId].path
                .then (uidInDestination) =>
                    log.info "  COPIED #{boxIndex[boxid].path}:#{uid}"
                    log.info "  TO #{boxIndex[destId].path}:#{uidInDestination}"
                    @mailboxIDs[destId] = uidInDestination

        # step 4 - remove the message from the box it shouldn't be in
        .then =>
            Promise.serie boxOps.removeFrom, (boxid) =>
                {path, uid} = boxIndex[boxid]

                imap.openBox path
                .then -> imap.addFlags uid, '\\Deleted'
                .then -> imap.expunge uid
                .then => delete @mailboxIDs[boxid]
                .tap -> log.info "  DELETED #{path}:#{uid}"