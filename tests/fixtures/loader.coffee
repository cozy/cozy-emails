MailParser = require("mailparser").MailParser
fs         = require("fs")
out        = []
sourceDir  = __dirname + "/samples/"

fs.readdir sourceDir, (err, files) ->
    if err?
        console.log err
        return
    treated = 0
    files.forEach (file) ->
        fs.readFile sourceDir + file, (err, data) ->
            tmp = []
            messages = data.toString().split(/^From /gm).filter((e) -> return e isnt '')
            messages.forEach (message) ->
                message = 'From ' + message
                mailparser = new MailParser()
                mailparser.write message
                mailparser.end()
                mailparser.on "end", (mail) ->
                    id               = Math.floor(Math.random() * 1000)
                    mail._id         = mail.messageId
                    mail.docType     = "Message"
                    mail.mailboxIDs  = "f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1":id
                    mail.accountID   = "dovecot-ID"
                    mail.normSubject = mail.subject
                    mail.flags       = []
                    mail.messageID   = mail.messageId
                    if Array.isArray mail.references
                        mail.conversationID = mail.references.shift()
                    else
                        mail.conversationID = mail.messageId
                    if mail.attachments?
                        mail.attachments = mail.attachments.map (m) ->
                            delete m.content
                            return m
                    delete mail.messageId
                    tmp.push mail
                    if tmp.length is messages.length
                        console.log "Done with " + file
                        treated++
                        out = out.concat tmp
                    if treated is files.length
                        output = __dirname + "/messages_loaded.json"
                        fs.writeFile output, JSON.stringify(out, null, "  ")
                        console.log out.length
