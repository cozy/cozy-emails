smtp = require 'simplesmtp'

module.exports = SMTPTesting = {}

SMTPTesting.mailStore = []
SMTPTesting.lastConnection = {}
queueID = 0

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
        callback null, "ABC" + queueID++

    smtpServer.listen port, done

unless module.parent
    SMTPTesting.init 587, -> console.log arguments