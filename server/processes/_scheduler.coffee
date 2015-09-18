
log = require('../utils/logging')('processes:scheduler')
ramStore = require '../models/store_account_and_boxes'
{EventEmitter} = require('events')
MailboxRefresh = require './mailbox_refresh'
MailboxRefreshList = require '../processes/mailbox_refresh_list'
ApplicationStartup = require './application_startup'
RemoveMessagesFromAccount = require './message_remove_by_account'
OrphanRemoval = require './orphan_removal'
async = require 'async'
running = null
queued = []
lastAllRefresh = 0
lastFavoriteRefresh = 0
MIN = 60*1000
HOUR = 60*MIN


eventEmitter = new EventEmitter()

Scheduler = module.exports

Scheduler.ASAP = {Symbol: 'ASAP'}
Scheduler.LATER = {Symbol: 'LATER'}

Scheduler.schedule = (proc, asap, callback) ->
    [asap, callback] = [Scheduler.ASAP, asap] unless callback

    if proc.finished
        throw new Error 'scheduling of finished process'
    else
        proc.addCallback callback

        if asap is Scheduler.ASAP
            if running?.abortable
                running.abort ->
                    queued.unshift running.clone()
                    queued.unshift proc
                    running = null
                    Scheduler.doNext()

            else if running
                queued.unshift proc
            else
                queued.unshift proc
                Scheduler.doNext()

        else
            queued.push proc
            Scheduler.doNext() unless running

Scheduler.scheduleMultiple = (processes, callback) ->

    waiters = processes.map (proc) ->
        (cb) -> Scheduler.schedule proc, cb

    async.parallel waiters, callback


Scheduler.doNext = ->
    log.debug "Scheduler.doNext already running = ", running?
    unless running
        proc = running = queued.shift()
        if proc
            proc.run (err) ->
                log.debug "process finished #{proc.id} #{err}"
                running = null
                setImmediate Scheduler.doNext
        else
            # nothing to do
            Scheduler.onIdle()

        eventEmitter.emit 'change'

Scheduler.onIdle = ->
    log.debug "Scheduler.onIdle"
    if lastAllRefresh < Date.now() - 1 * HOUR
        Scheduler.startAllRefresh()

    else if lastFavoriteRefresh < Date.now() - 5 * MIN
        Scheduler.startFavoriteRefresh()

    else
        log.debug "nothing to do, waiting 10 MIN"
        setTimeout Scheduler.doNext, 10 * MIN

Scheduler.refreshNow = (mailbox, callback) ->

    isSameBoxRefresh = (processus) ->
        processus instanceof MailboxRefresh and processus.mailbox is mailbox

    if running and isSameBoxRefresh running
        running.addCallback callback

    else
        if alreadyScheduled = queued.filter(isSameBoxRefresh)[0]
            queued = _.without queued, alreadyScheduled

        refresh = new MailboxRefresh {mailbox}
        Scheduler.schedule refresh, Scheduler.ASAP, callback


# called by the Scheduler every hour
Scheduler.startAllRefresh = (done) ->
    log.debug "Scheduler.startAllRefresh"

    refreshLists = ramStore.getAllAccounts()
        .map (account) -> new MailboxRefreshList {account}


    Scheduler.scheduleMultiple refreshLists, (err) ->
        log.error err if err

        refreshMailboxes = ramStore.getAllMailboxes()
            .map (mailbox) -> new MailboxRefresh {mailbox}

        Scheduler.scheduleMultiple refreshMailboxes, (err) ->
            log.error err if err
            lastFavoriteRefresh = Date.now()
            lastAllRefresh = Date.now()
            done? err

# called by the Scheduler every 5Min
Scheduler.startFavoriteRefresh = ->
    log.debug "Scheduler.startFavoriteRefresh"
    processes = ramStore.getFavoriteMailboxes()
        .map (mailbox) -> new MailboxRefresh {mailbox}

    Scheduler.scheduleMultiple processes, (err) ->
        log.error err if err
        lastFavoriteRefresh = Date.now()

Scheduler.on = (event, listener) ->
    eventEmitter.addListener event, listener

Scheduler.clientSummary = ->
    list = queued
    list = [running].concat list if running
    return list.map (proc) -> proc.summary()

Scheduler.applicationStartupRunning = ->
    running and running instanceof ApplicationStartup

# there is a few time when we want to do an orphan removal after
# the main operation complete, if the user perform several such
# operation quickly, we want to do only one OrphanRemoval.
Scheduler.orphanRemovalDebounced = (accountID) ->

    if accountID
        Scheduler.schedule new RemoveMessagesFromAccount {accountID}

    alreadyQueued = queued.some (proc) ->
        proc instanceof OrphanRemoval

    unless alreadyQueued
        Scheduler.schedule new OrphanRemoval()
