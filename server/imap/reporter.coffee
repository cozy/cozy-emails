_ = require 'lodash'
uuid = require 'uuid'
ioServer = require 'socket.io'
Logger = require('../utils/logging')
log = Logger('imap:reporter')

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

    @setIOReference = (ioref) ->
        io = ioref

    # when the user click OK on a finished task
    # we remove it from the userTasks
    @acknowledge = (id) ->
        if id and ImapReporter.userTasks[id]?.finished
            delete ImapReporter.userTasks[id]
            io?.emit 'refresh.delete', id

    # INSTANCE
    constructor: (options) ->
        @id = uuid.v4()
        @done = 0
        @finished = false
        @errors = []
        @total = options.total
        @box = options.box
        @account = options.account
        @objectID = options.objectID
        @code = options.code
        @firstImport = options.firstImport

        ImapReporter.userTasks[@id] = this
        io?.emit 'refresh.create', @toObject()

    sendtoclient: (nocooldown) ->
        if @cooldown and not nocooldown
            return true
        else
            io?.emit 'refresh.update', @toObject()
            @cooldown = true
            setTimeout (=> @cooldown = false) , 500

    toObject: =>
        {@id, @finished, @done, @total, @errors,
            @box, @account, @code, @objectID, @firstImport}

    onDone: ->
        @finished = true
        @done = @total
        @sendtoclient(true)
        unless @errors.length
            setTimeout =>
                ImapReporter.acknowledge @id
            , 3000

    onProgress: (done) ->
        @done = done
        @sendtoclient()

    addProgress: (delta) ->
        @done += delta
        @sendtoclient()

    onError: (err) ->
        @errors.push Logger.getLasts() + "\n" + err.stack
        log.error err.stack
        @sendtoclient()


ImapReporter.accountFetch = (account, boxesLength, firstImport) ->
    return new ImapReporter
        total: boxesLength
        account: account.label
        objectID: account.id
        code: 'account-fetch'
        firstImport: firstImport

ImapReporter.boxFetch = (box, total, firstImport) ->
    return new ImapReporter
        total: total
        box: box.label
        objectID: box.id
        code: 'box-fetch'
        firstImport: firstImport

ImapReporter.recoverUIDValidty = (box, total) ->
    return new ImapReporter
        total: total
        box: box.label
        code: 'recover-uidvalidity'
