_ = require 'lodash'
uuid = require 'uuid'
ioServer = require 'socket.io'
log = require('../utils/logging')('imap:reporter')

# user visible tasks, those are not the same than the IMAP tasks
# example : the userTask fetch mailbox X
# is actually one IMAP task by new mail in mailbox X
# usage :
# reporter = ImapReporter.addUserTask
#    code: 'some-code'
#    total: 5
# reporter.addProgress 2 # progress is now 2/5
# reporter.addProgress 1 # progress is now 3/5
# reporter.onProgress 4 # progress is now 4/5
# reporter.onError new Error 'shit happened'
# reporter.onError new Error 'another shit happened'
# reporter.onDone()


io = null
module.exports = class ImapReporter

    # STATIC
    @userTasks = {}
    @addUserTask = (options) ->
        new ImapReporter options

    @summary = ->
        # @TODO format this a bit ?
        for id, task of ImapReporter.userTasks
            task.toObject()

    @initSocketIO = (app, server) ->
        app.io = io = ioServer server
        io.on 'connection', (sock) ->
            sock.on 'mark_ack', ImapReporter.acknowledge

    # when the user click OK on a finished task
    # we remove it from the userTasks
    @acknowledge = (id) ->
        if id and ImapReporter.userTasks[id]?.finished
            delete ImapReporter.userTasks[id]
            io?.emit 'task.delete', id

    # INSTANCE
    constructor: (options) ->
        @id = uuid.v4()
        @done = 0
        @finished = false
        @errors = []
        @total = options.total
        @box = options.box
        @account = options.account
        @code = options.code

        ImapReporter.userTasks[@id] = this
        io?.emit 'task.create', @toObject()

    sendtoclient: (nocooldown) ->
        if @cooldown and not nocooldown
            return true
        else
            io?.emit 'task.update', @toObject()
            @cooldown = true
            setTimeout (=> @cooldown = false) , 500

    toObject: =>
        {@id, @finished, @done, @total, @errors, @box, @account, @code}

    onDone: ->
        @finished = true
        @done = @total
        @sendtoclient(true)

    onProgress: (done) ->
        @done = done
        @sendtoclient()

    addProgress: (delta) ->
        @done += delta
        @sendtoclient()

    onError: (err) ->
        log.error err.stack
        @errors.push err.stack
        @sendtoclient()


ImapReporter.accountFetch = (account, boxesLength) ->
    return new ImapReporter
        total: boxesLength
        account: account.label
        code: 'account-fetch'

ImapReporter.boxFetch = (box, total) ->
    return new ImapReporter
        total: total
        box: box.label
        code: 'box-fetch'

ImapReporter.recoverUIDValidty = (box, total) ->
    return new ImapReporter
        total: total
        box: box.label
        code: 'recover-uidvalidity'
