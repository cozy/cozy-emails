fs = require 'fs'
path = require 'path'
loremIpsum = require 'lorem-ipsum'
moment = require 'moment'

mailboxUID = {}

names = ['alice', 'bob', 'natacha', 'mark', 'zoey', 'john', 'felicia' ,'max']
priorities = ['low', 'normal', 'high']
provider = 'cozytest.cc'

accounts = require './accounts.json'
mailboxes = {}
for box in require './mailboxes.json'
    mailboxes[box.accountID] = [] unless mailboxes[box.accountID]?
    # test folder will only be used for loaded messages
    # we don't want messages in trash to make testing message deletion easier
    mailboxes[box.accountID].push box unless box.label is "Test Folder" or box.label is "Trash"

numberOfEmails = process.argv[2] or 100

seed = 0.42
randomWithSeed = ->
    seed = Math.sin(seed) * 10000
    return seed - Math.floor(seed)

getRandom = (max) -> Math.round (randomWithSeed() * max)
getRandomElmt = (array) -> array[getRandom(array.length - 1)]

messages = []
for i in [1..numberOfEmails] by 1

    # sender and receiver must not be the same
    name = getRandomElmt names
    from =
        "address": "#{name}@#{provider}",
        "name": name

    replyTo = []
    if getRandom(2) > 0
        name = getRandomElmt names
        replyTo.push
            "address": "#{name}@#{provider}",
            "name": name

    nbDest = getRandom(1) + 1
    to = []
    for j in [0..nbDest]
        name = getRandomElmt names
        to.push
            "address": "#{name}@#{provider}",
            "name": name
    nbDest = getRandom(1)
    cc = []
    for j in [0..nbDest]
        name = getRandomElmt names
        cc.push
            "address": "#{name}@#{provider}",
            "name": name

    account   = getRandomElmt(accounts)._id
    mailbox   = getRandomElmt(mailboxes[account])
    mailboxID = mailbox._id

    mailboxUID[mailboxID] = 0 unless mailboxUID[mailboxID]?
    mailboxUID[mailboxID] = mailboxUID[mailboxID] + 1

    mailboxObject = {}
    mailboxObject[mailboxID] = mailboxUID[mailboxID]

    subject = loremIpsum count: getRandom(5), units: 'words', random: randomWithSeed
    content = loremIpsum count: getRandom(10), units: 'paragraphs', random: randomWithSeed

    # simulate email thread
    if mailbox.label isnt 'noconv' and getRandom(10) > 3 and i > 2
        inReplyTo  = ["generated_id_#{i - 1}"]
        references = ["generated_id_#{i - 2}", "generated_id_#{i - 1}"]
        conversationID = messages[messages.length - 2].conversationID
        messages[messages.length - 1].conversationID = conversationID
    else
        inReplyTo  = null
        references = null
        conversationID = "conversation_id_#{i}"

    priority  = getRandomElmt priorities

    # random date this year before now
    today = moment("2014-10-29T23:59:59Z")
    month = getRandom today.month()
    day = getRandom today.date()
    hour = getRandom today.hours()
    minute = getRandom today.minutes()
    date = moment().months(month).days(day).hours(hour).minutes(minute)
        .second(0).millisecond(0)

    flags = []
    flags.push '\\Seen' if getRandom(10) > 5
    flags.push '\\Answered' if getRandom(10) > 9
    flags.push '\\Flagged' if getRandom(10) > 9
    htmlContent = content.split('\r\n').join('</div>\r\n<div>')

    messages.push
        "_id": "generated_id_#{i}"
        "docType": "Message",
        "date": date.toISOString(),
        "subject": subject,
        "normSubject": subject,
        "from": [from]
        "to": to,
        "cc": cc,
        "inReplyTo": inReplyTo,
        "references": references
        "replyTo": replyTo,
        "text": loremIpsum count: getRandom(10), units: 'paragraphs', random: randomWithSeed
        "html": "<html><body><div>#{htmlContent}</div></body></html>",
        "priority": priority,
        "mailboxIDs": mailboxObject,
        "accountID": account,
        "attachments": []
        "flags": flags
        "messageID": "generated_id_#{i}"
        "conversationID": conversationID

# Conversations tests
mailbox = 'f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1'
mailboxUID[mailbox] = 0 unless mailboxUID[mailbox]?
date = new Date()
# Ensure messages are sent in the past
date.setSeconds(date.getSeconds() - 3600)
for i in [1..10] by 1
    mailboxUID[mailbox] = mailboxUID[mailbox] + 1
    mailboxObject = {}
    mailboxObject["#{mailbox}"] = mailboxUID[mailbox]
    date.setSeconds(date.getSeconds() + 10 * i)
    message =
        "_id": "conversation_id_#{i}"
        "docType": "Message",
        "date": date.toISOString(),
        "from": [
          {
            "address": "sender#{i}@cozytest.cc",
            "name": "Sender#{i}"
          }
        ],
        "to": [
          {
            "address": "alice@cozytest.cc",
            "name": "alice"
          }
        ],
        "text": content,
        "html": "<html><body><div>#{htmlContent}</div></body></html>",
        "mailboxIDs": mailboxObject,
        "accountID": 'dovecot-ID',
        "attachments": []
        "flags": [],
        "conversationID": "conversation_test"

    message.htmlContent = message.text.split('\r\n').join('</div>\r\n<div>')

    if i is 1
        message.subject = "Conversation"
    else
        message.subject = "Re: Conversation"
        inReplyTo       = "conversation_id_1"
    message.normSubject = message.subject

    messages.push message

targetFile = path.resolve __dirname, 'messages_generated.json'
json = JSON.stringify messages, null, '  '
fs.writeFile targetFile, json, flag: 'w+', (err) ->
    console.log err if err?
console.log "Done generating #{messages.length} messages"
