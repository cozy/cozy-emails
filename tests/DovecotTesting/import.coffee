Imap = require 'imap'
{exec} = require 'child_process'
MailParser = require("mailparser").MailParser
DovecotTesting = require './index'
util = require('util')


remoteMailBox =
    user: 'testzoecozy@gmail.com',
    password: process.argv[2],
    host: 'imap.gmail.com',
    port: 993,
    tls: true

localMailBox = 
    user: "testuser"
    password: "applesauce"
    host: DovecotTesting.serverIP()
    port: 993
    tls: true
    tlsOptions: rejectUnauthorized: false

streamMail = (msg, callback) ->
    msg.on 'body', (stream) =>
        buf = ""
        mailparser = new MailParser()
        mailparser.on "end", (mail) =>
            messageID = mail.headers['message-id'] 
            callback messageID, buf

        stream.on 'data', (d) => 
            buf += d.toString('utf8')
            mailparser.write d

        stream.on 'end', () => mailparser.end()


openMailBox = (box, callback) ->
    mailbox = new Imap box    
    mailbox.once 'ready', () =>
        mailbox.openBox 'INBOX', false, (err, inbox) =>
           callback mailbox, inbox

    mailbox.once 'error', (err) -> console.log err
    mailbox.once 'end', () -> console.log 'Connection ended'
    mailbox.connect()

importMailBox = (callback) ->
    console.log "Check local mails ..."
    # Open local mailbox and create list with all messageID
    openMailBox localMailBox, (local, inboxLocal) =>
        local.seq.search [['ALL']], (err, ids) =>
            mails = []
            f = local.fetch ids, bodies: ''
            f.on 'message', (msg, seqno) =>
                streamMail msg, (messageID, buf) ->
                    mails.push messageID

            f.once 'error', (err) -> console.log "ERROR : #{err}"

            f.once 'end', () =>
                console.log "Import remote mails ..."
                # Recover all remote mails
                openMailBox remoteMailBox, (remote, inboxRemote) =>
                    remote.seq.search [['ALL']], (err, ids) =>
                        f = remote.fetch ids, bodies: ''
                        timeout = null
                        count = 0
                        f.on 'message', (msg, seqno) =>
                            count += 1
                            streamMail msg, (messageID, buf) ->
                                if not(messageID in mails)
                                    # Add mail in local dovecot
                                    local.append buf, mailbox:'INBOX', (err) =>
                                        console.log "import #{messageID}"
                                        clearTimeout timeout
                                        timeout = setTimeout () =>
                                            remote.end()
                                            local.end()
                                            callback(null, count)
                                        , 5000
                                else
                                    clearTimeout timeout
                                    timeout = setTimeout () =>
                                        remote.end()
                                        local.end()
                                        callback(null, count)
                                    , 6000

                    f.once 'error', (err) -> console.log "ERROR : #{err}"

                    f.once 'end', () =>
                        console.log "#{count} mails imported"

if not module.parent
    console.log "Start dovecot server ..."
    DovecotTesting.setupEnvironment (err) ->
        if err
            console.log err
        else
            importMailBox (err, count) ->
                console.log "... import finished : #{count} files"
                saveGithub = 'scp -r vagrant@172.31.1.2:/home/testuser/Maildir /home/zoe/Test/'
                exec saveGithub, (err, stdout, stderr) ->
                    if err
                        console.log err, stderr
                    else
                        console.log "success."