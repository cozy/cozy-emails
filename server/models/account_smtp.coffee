Account = require './account'
Promise = require 'bluebird'
nodemailer = require 'nodemailer'
{AccountConfigError} = require '../utils/errors'
# @TODO : import directly ?
SMTPConnection = require 'nodemailer/node_modules/' +
    'nodemailer-smtp-transport/node_modules/smtp-connection'

# Public: send a message using this account SMTP config
#
# message - a raw message
# callback - a (err, info) callback with the following parameters
#            :err
#            :info the nodemailer's info
#
# Returns void
Account::sendMessage = (message, callback) ->
    transport = nodemailer.createTransport
        port: @smtpPort
        host: @smtpServer
        tls: rejectUnauthorized: false
        auth:
            user: @login
            pass: @password

    transport.sendMail message, callback


# Private: check smtp credentials
# used in createIfValid
# throws AccountConfigError
#
# Returns a {Promise} that reject/resolve if the credentials are corrects
Account::testSMTPConnection = ->

    connection = new SMTPConnection
        port: @smtpPort
        host: @smtpServer
        tls: rejectUnauthorized: false

    auth =
        user: @login
        pass: @password

    return new Promise (resolve, reject) ->
        connection.once 'error', (err) ->
            log.warn "SMTP CONNECTION ERROR", err
            reject new AccountConfigError 'smtpServer'

        # in case of wrong port, the connection takes forever to emit error
        timeout = setTimeout ->
            reject new AccountConfigError 'smtpPort'
            connection.close()
        , 10000

        connection.connect (err) ->
            return reject new AccountConfigError 'smtpServer' if err
            clearTimeout timeout

            connection.login auth, (err) ->
                if err then reject new AccountConfigError 'auth'
                else resolve 'ok'
                connection.close()