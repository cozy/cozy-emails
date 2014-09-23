_ = require 'lodash'

module.exports = ImapReporter = {}


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
# reporter.onDone()
ImapReporter.userTasks = []


ImapReporter.addUserTask = (options) ->
    task = _.extend {done: 0}, options
    ImapReporter.userTasks.push task

    return api =
        onDone: ->
            task.finished = true
        onProgress: (done) ->
            task.done = done
        addProgress: (delta) ->
            task.done += delta
        onError: (err) ->
            console.log err
            task.errors ?= []
            task.errors.push err

ImapReporter.summary = ->
    # @TODO format this a bit
    ImapReporter.userTasks