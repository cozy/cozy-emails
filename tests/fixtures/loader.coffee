MailParser = require("mailparser").MailParser
fs         = require("fs")
messages   = []
sourceDir  = __dirname + "/samples/"

fs.readdir sourceDir, (err, files) ->
    if err?
        console.log err
        return
    files.forEach (file) ->
        fs.readFile sourceDir + file, (err, data) ->
            mailparser = new MailParser()
            i = 0
            len = data.length
            while i < len
                mailparser.write new Buffer([data[i]])
                i++
            mailparser.end()
            mailparser.on "end", (mail) ->
                id               = Math.floor(Math.random() * 1000)
                mail._id         = mail.messageId
                mail.docType     = "Message"
                mail.reads       = false
                mail.mailboxIDs  = "dovecot-ID-folder1": id
                mail.accountID   = "dovecot-ID"
                mail.normSubject = mail.subject
                mail.flags       = []
                messages.push mail
                console.log "Done with " + file
                if messages.length is files.length
                    output = __dirname + "/messages_loaded.json"
                    fs.writeFile output, JSON.stringify(messages, null, "  ")
