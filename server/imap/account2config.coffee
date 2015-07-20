xoauth2 = require 'xoauth2'
log = require('../utils/logging')(prefix: 'imap:oauth')

xOAuthCache = {}

CLIENT_ID = '260645850650-2oeufakc8ddbrn8p4o58emsl7u0r0c8s' +
            '.apps.googleusercontent.com'

CLIENT_SECRET = '1gNUceDM59TjFAks58ftsniZ'

getXoauth2Generator = (account) ->
    unless xOAuthCache[account.id]
        log.info "XOAUTH GENERATOR FOR #{account.label}"

        timeout = 1000*account.oauthTimeout - Date.now() #timeout in ms
        timeout = Math.floor timeout/1000 # timeout in s
        timeout = Math.max timeout, 0 # min = 0

        generator = xoauth2.createXOAuth2Generator
            user: account.login
            clientSecret: CLIENT_SECRET
            clientId: CLIENT_ID
            refreshToken: account.oauthRefreshToken
            accessToken: account.oauthAccessToken
            timeout: timeout

        generator.on 'token', ({user, accessToken, timeout}) ->
            account.updateAttributes
                oauthAccessToken: accessToken
                oauthTimeout: generator.timeout
            , (err) ->
                log.info "UPDATED ACCOUNT OAUTH #{account.label}"
                log.warn err if err

        xOAuthCache[account.id] = generator

    return xOAuthCache[account.id]

module.exports.forceOauthRefresh = (account, callback) ->
    log.info "FORCE OAUTH REFRESH"
    getXoauth2Generator(account).generateToken callback

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



module.exports.makeIMAPConfig = (account, callback) ->

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

    else
        callback null,
            user       : account.imapLogin or account.login
            password   : account.password
            xoauth2    : token
            host       : account.imapServer
            port       : parseInt account.imapPort
            tls        : not account.imapSSL? or account.imapSSL
            tlsOptions : rejectUnauthorized : false
