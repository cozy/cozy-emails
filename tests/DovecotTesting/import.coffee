Imap = require 'imap'
{exec} = require 'child_process'
MailParser = require("mailparser").MailParser
DovecotTesting = require './index'
iconv = require('mailparser/node_modules/encoding/node_modules/iconv-lite')
iconv.extendNodeEncodings();


remoteConfig =
    user: 'rmfoucault@gmail.com'
    password: process.argv[2],
    host: 'imap.gmail.com'
    port: 993
    tls: true
    # debug: console.log.bind console, 'remote'

localConfig =
    user: "testuser"
    password: "applesauce"
    host: DovecotTesting.serverIP()
    port: 993
    tls: true
    # debug: console.log.bind console, 'local'
    tlsOptions: rejectUnauthorized: false


toImport = [
    { from: 'INBOX', to: 'INBOX', uids: [409, 408] }
    { from: '[Gmail]/Messages envoyés', to: 'Sent', uids: [31,32] }
]

asyncLoop = (arr, fn, callback) ->
    do nextStep = ->
        item = arr.pop()
        return callback null unless item
        fn item, (err) ->
            return callback err if err
            nextStep()


openConnection = (config, callback) ->
    imap = new Imap config
    imap.once 'error', (err) -> callback err
    imap.once 'ready', -> callback null, imap
    imap.connect()

openMailBox = (config, boxName, callback) ->
    imap.openBox boxName, false, (err, box) ->
        return callback err if err
        callback null, imap, box

getMail = (imap, id, callback) ->
    f = imap.fetch id, bodies: ''
    f.on 'error', (err) -> callback err
    f.on 'message', (msg) ->
        msg.on 'error', (err) -> callback err
        msg.on 'body', (stream) ->
            parts = []
            stream.on 'data', (d) -> parts.push d
            stream.on 'end', -> callback null, Buffer.concat parts

copyOneMail = (local, remote, id, callback) ->
    getMail remote, id, (err, buffer) ->
        console.log "MAIL HAS LENGTH = ", buffer.length
        local.append buffer, {}, callback


copyOneBox = (li, local, ri, remote, ids, callback) ->
    li.openBox local, false, (err) ->
        return console.log err if err

        ri.openBox remote, false, (err) ->
            return console.log err if err

            asyncLoop ids, (id, cb) ->
                copyOneMail li, ri, id, cb
            , callback

DovecotTesting.setupEnvironment (err) ->
    return console.log err if err

    openConnection localConfig, (err, localImap) ->
        return console.log err if err

        openConnection remoteConfig, (err, remoteImap) ->
            return console.log err if err

            # remoteImap.openBox '[Gmail]/Messages envoyés', (err) ->
            #     remoteImap.search [['ALL']], (err, uids) ->
            #         console.log uids

            asyncLoop toImport, (o, cb) ->
                copyOneBox localImap, o.to, remoteImap, o.from, o.uids, cb

            , (err) ->
                return console.log err if err
                localImap.end()
                remoteImap.end()

                DovecotTesting.saveChanges (err) ->
                    return console.log err if err






#                         timeout = null
#                         count = 0
#                         f.on 'message', (msg, seqno) =>
#                             count += 1
#                             streamMail msg, (messageID, buf) ->
#                                 if not(messageID in mails)
#                                     # Add mail in local dovecot
#                                     local.append buf, mailbox:'INBOX', (err) =>
#                                         console.log "import #{messageID}"
#                                         clearTimeout timeout
#                                         timeout = setTimeout () =>
#                                             remote.end()
#                                             local.end()
#                                             callback(null, count)
#                                         , 5000
#                                 else
#                                     clearTimeout timeout
#                                     timeout = setTimeout () =>
#                                         remote.end()
#                                         local.end()
#                                         callback(null, count)
#                                     , 6000

#                     f.once 'error', (err) -> console.log "ERROR : #{err}"

#                     f.once 'end', () =>
#                         console.log "#{count} mails imported"









            getMail

        # # remoteImap.search [['ALL']], (err, ids) =>
        # #     console.log ids[-10..-1]
        # #     remoteImap.end()

        # getMail remoteImap, 409, (err, buffer) ->
        #     return console.log err if err

        #

        #         localImap.append buffer, {}, (err) =>

        #             console.log err.stack if err
        #             localImap.end()
        #             remoteImap.end()

        #







# streamMail = (msg, callback) ->
#     msg.on 'body', (stream) =>
#         buf = ""
#         mailparser = new MailParser()
#         mailparser.on "end", (mail) =>
#             messageID = mail.headers['message-id']
#             callback messageID, buf

#         stream.on 'data', (d) =>
#             buf += d.toString('utf8')
#             mailparser.write d

#         stream.on 'end', () => mailparser.end()


# openMailBox = (box, callback) ->
#     mailbox = new Imap box
#     mailbox.once 'ready', () =>
#         mailbox.openBox 'INBOX', false, (err, inbox) =>
#            callback mailbox, inbox

#     mailbox.once 'error', (err) -> console.log err
#     mailbox.once 'end', () -> console.log 'Connection ended'
#     mailbox.connect()

# importMailBox = (callback) ->
#     console.log "Check local mails ..."
#     # Open local mailbox and create list with all messageID
#     openMailBox localMailBox, (local, inboxLocal) =>
#         local.seq.search [['ALL']], (err, ids) =>
#             mails = []
#             f = local.fetch ids, bodies: ''
#             f.on 'message', (msg, seqno) =>
#                 streamMail msg, (messageID, buf) ->
#                     mails.push messageID

#             f.once 'error', (err) -> console.log "ERROR : #{err}"

#             f.once 'end', () =>
#                 console.log "Import remote mails ..."
#                 # Recover all remote mails
#                 openMailBox remoteMailBox, (remote, inboxRemote) =>
#                     remote.seq.search [['ALL']], (err, ids) =>
#                         f = remote.fetch ids, bodies: ''
#                         timeout = null
#                         count = 0
#                         f.on 'message', (msg, seqno) =>
#                             count += 1
#                             streamMail msg, (messageID, buf) ->
#                                 if not(messageID in mails)
#                                     # Add mail in local dovecot
#                                     local.append buf, mailbox:'INBOX', (err) =>
#                                         console.log "import #{messageID}"
#                                         clearTimeout timeout
#                                         timeout = setTimeout () =>
#                                             remote.end()
#                                             local.end()
#                                             callback(null, count)
#                                         , 5000
#                                 else
#                                     clearTimeout timeout
#                                     timeout = setTimeout () =>
#                                         remote.end()
#                                         local.end()
#                                         callback(null, count)
#                                     , 6000

#                     f.once 'error', (err) -> console.log "ERROR : #{err}"

#                     f.once 'end', () =>
#                         console.log "#{count} mails imported"

# if not module.parent
#     console.log "Start dovecot server ..."
#     DovecotTesting.setupEnvironment (err) ->
#         if err
#             console.log err
#         else
#             importMailBox (err, count) ->
#                 console.log "... import finished : #{count} files"
#                 saveGithub = 'scp -r vagrant@172.31.1.2:/home/testuser/Maildir /home/zoe/Test/'
#                 exec saveGithub, (err, stdout, stderr) ->
#                     if err
#                         console.log err, stderr
#                     else
#                         console.log "success."