smtp = require 'simplesmtp'

module.exports = SMTPTesting = {}

SMTPTesting.mailStore = []
SMTPTesting.lastConnection = {}
queueID = 0

# to be overidden
SMTPTesting.onSecondMessage = (env, callback) ->
    callback null

SMTPTesting.init = (port, done) ->

    smtpServer = smtp.createServer
        debug: false
        disableDNSValidation: true
        authMethods: ['LOGIN']
        requireAuthentication: true

    smtpServer.on 'startData', (env) -> env.body = ''
    smtpServer.on 'data', (env, chunk) -> env.body += chunk
    smtpServer.on 'authorizeUser', (connection, username, password, callback) ->
        SMTPTesting.lastConnection = {username, password}
        callback null, true

    smtpServer.on 'dataReady', (envelope, callback) ->
        SMTPTesting.mailStore.push envelope
        if queueID is 0
            # just say ok
            callback null, "ABC" + queueID++

        else
            SMTPTesting.onSecondMessage envelope, ->
                callback null, "ABC" + queueID++

    smtpServer.listen parseInt(port), done

unless module.parent
    port = process.argv[2] or 587
    SMTPTesting.init port, -> console.log arguments
