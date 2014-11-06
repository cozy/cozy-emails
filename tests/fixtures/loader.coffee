MailParser = require("mailparser").MailParser
fs         = require("fs")
out        = []
sourceDir  = __dirname + "/samples/"

fs.readdir sourceDir, (err, files) ->
    if err?
        console.log err
        return
    files.forEach (file) ->
        fs.readFile sourceDir + file, (err, data) ->
            messages = data.toString().split(/^From /gm)
            messages.forEach (message) ->
                message = 'From ' + message
                mailparser = new MailParser()
                mailparser.write message
                mailparser.end()
                mailparser.on "end", (mail) ->
                    id               = Math.floor(Math.random() * 1000)
                    mail._id         = mail.messageId
                    mail.docType     = "Message"
                    mail.reads       = false
                    mail.mailboxIDs  = "f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1":id
                    mail.accountID   = "dovecot-ID"
                    mail.normSubject = mail.subject
                    mail.flags       = []
                    if Array.isArray mail.references
                        mail.conversationID = mail.references.shift()
                    else
                        mail.conversationID = mail.messageId
                    if mail.attachments?
                        mail.attachments = mail.attachments.map (m) ->
                            delete m.content
                            return m
                    out.push mail
                    console.log "Done with " + file
                    if out.length is files.length
                        output = __dirname + "/messages_loaded.json"
                        fs.writeFile output, JSON.stringify(out, null, "  ")
