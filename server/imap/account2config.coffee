xoauth2 = require 'xoauth2'
log = require('../utils/logging')(prefix: 'imap:oauth')
{PasswordEncryptedError} = require '../utils/errors'
Account = require '../models/account'

xOAuthCache = {}

# This file handle the generation of config for node-imap and nodemailer
# it also handles xoauthgenerators as singletons by account
# to prevent race between imap & smtp in creating access tokens

CLIENT_ID = '260645850650-2oeufakc8ddbrn8p4o58emsl7u0r0c8s' +
            '.apps.googleusercontent.com'

# @TODO : investigate a better way to distribute this
CLIENT_SECRET = '1gNUceDM59TjFAks58ftsniZ'


# get the single instance of xoauthGenerator for this account
getXoauth2Generator = (account) ->
    unless xOAuthCache[account.id]
        log.info "XOAUTH GENERATOR FOR #{account.label}"

        timeout = 1000 * account.oauthTimeout - Date.now() # timeout in ms
        timeout = Math.floor(timeout / 1000) # timeout in s
        timeout = Math.max(timeout, 0) # min = 0

        generator = xoauth2.createXOAuth2Generator
            user: account.login
            clientSecret: CLIENT_SECRET
            clientId: CLIENT_ID
            refreshToken: account.oauthRefreshToken
            accessToken: account.oauthAccessToken
            timeout: timeout

        # when the generator is forced to create a new token, we save it in
        # the DS for later reuse
        generator.on 'token', ({user, accessToken, timeout}) ->
            account.updateAttributes
                oauthAccessToken: accessToken
                oauthTimeout: generator.timeout
            , (err) ->
                log.info "UPDATED ACCOUNT OAUTH #{account.label}"
                log.warn err if err

        xOAuthCache[account.id] = generator

    return xOAuthCache[account.id]


# force the generator to create a new access token
# used when the connection fail in imap
# (smtp calls the generateToken function directly)
module.exports.forceOauthRefresh = (account, callback) ->
    log.info "FORCE OAUTH REFRESH"
    getXoauth2Generator(account).generateToken callback

# This is used when emails is started when the DS doesnt have the keys
# modify account
module.exports.forceAccountFetch = (account, callback) ->
    Account.find account.id, (err, fetched) ->
        return callback err if err

        if fetched._passwordStillEncrypted
            callback new PasswordEncryptedError()

        else
            account.password = fetched.password
            account._passwordStillEncrypted = undefined
            callback null

# create a nodemailer config for this account
module.exports.makeSMTPConfig = (account) ->
    options =
        port: account.smtpPort
        host: account.smtpServer
        secure: account.smtpSSL
        ignoreTLS: not account.smtpTLS
        tls: rejectUnauthorized: false

    if account.smtpMethod? and account.smtpMethod isnt 'NONE'
        options.authMethod = account.smtpMethod

    if account.oauthProvider is 'GMAIL'
        options.service = 'gmail'
        options.auth =
            xoauth2: getXoauth2Generator account
    else
        options.auth =
            user: account.smtpLogin or account.login
            pass: account.smtpPassword or account.password

    return options


# create a node-imap config for this account
module.exports.makeIMAPConfig = makeIMAPConfig = (account, callback) ->

    if account.oauthProvider is "GMAIL"
        generator = getXoauth2Generator account
        generator.getToken (err, token) ->
            return callback err if err
            callback null,
                user       : account.login
                xoauth2    : token
                host       : "imap.gmail.com"
                port       : 993
                tls        : true
                tlsOptions : rejectUnauthorized : false

    else if account._passwordStillEncrypted
        module.exports.forceAccountFetch account, (err) ->
            return callback err if err
            makeIMAPConfig account, callback

    else
        callback null,
            user       : account.imapLogin or account.login
            password   : account.password
            host       : account.imapServer
            port       : parseInt account.imapPort
            tls        : not account.imapSSL? or account.imapSSL
            tlsOptions : rejectUnauthorized : false
            autotls    : 'required' # for servers with STARTTLS and
                                    # LOGINDISABLED
