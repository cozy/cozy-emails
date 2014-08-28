Promise = require 'bluebird'
Guid = require 'guid'
_ = require 'lodash'
ImapConnection = require 'imap'
Promise.promisifyAll ImapConnection.prototype
log = -> console.log.apply console, arguments


module.exports = ImapHelpers = {}


IGNORE_ATTRIBUTES = ['\\HasNoChildren', '\\HasChildren']
ImapHelpers.cleanUpBoxTree = cleanUpBoxTree = (children, path = []) ->
    prepChildren = []
    for name, child of children
        subPath = path.concat [name]
        prepChildren.push
            id: Guid.raw()
            label: name
            path: subPath
            attribs: _.difference child.attribs, IGNORE_ATTRIBUTES
            delimiter: child.delimiter
            children: cleanUpBoxTree child.children, subPath

    return prepChildren


ImapHelpers.getConnection = (account) ->
    pConnection = new Promise (resolve, reject) =>
        connection = new ImapConnection
            user: account.login
            password: account.password
            host: account.imapServer
            port: parseInt account.imapPort
            tls: account.imapSecure or true
            tlsOptions: rejectUnauthorized: false

        connection.once 'ready', ->
            resolve connection

        connection.once 'error', (err) =>
            if pConnection.isPending() then reject err
            else connection.end()

        console.log "NEW CONNECT"
        connection.connect()

    return pConnection.disposer (connection) ->
        console.log "DISPOSING"
        connection.end()
        pConnection = null