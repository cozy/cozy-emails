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

    account = getRandomElmt(accounts)._id
    mailbox = getRandomElmt(mailboxes[account])._id

    mailboxUID[mailbox] = 0 unless mailboxUID[mailbox]?
    mailboxUID[mailbox] = mailboxUID[mailbox] + 1

    mailboxObject = {}
    mailboxObject[mailbox] = mailboxUID[mailbox]

    subject = loremIpsum count: getRandom(5), units: 'words', random: randomWithSeed
    content = loremIpsum count: getRandom(10), units: 'paragraphs', random: randomWithSeed

    # simulate email thread
    if getRandom(10) > 3 and i > 2
        inReplyTo  = ["generated_id_#{i - 1}"]
        references = ["generated_id_#{i - 2}", "generated_id_#{i - 1}"]
    else
        inReplyTo  = null
        references = null

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
        "text": content,
        "html": "<html><body><div>#{htmlContent}</div></body></html>",
        "priority": priority,
        "reads": false,
        "mailboxIDs": mailboxObject,
        "accountID": account,
        "attachments": []
        "flags": flags
        "conversationID": "conversation_id_#{i}"


targetFile = path.resolve __dirname, 'messages_generated.json'
json = JSON.stringify messages, null, '  '
fs.writeFile targetFile, json, flag: 'w+', (err) ->
    console.log err if err?
console.log "Done generating #{numberOfEmails} messages"
