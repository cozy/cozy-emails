fs = require 'fs'
loremIpsum = require 'lorem-ipsum'
moment = require 'moment'

names = ['alice', 'bob', 'natacha', 'mark', 'zoey', 'john', 'felicia' ,'max']
priorities = ['low', 'normal', 'high']
provider = 'cozycloud.cc'

accounts = require './accounts.json'

getMailboxesRecursively = (mboxes) ->
    result = []
    for mailbox in mboxes
        result.push mailbox.id
        result = result.concat getMailboxesRecursively mailbox.children

    return result

mailboxes = {}
for account in accounts
    mailboxes[account._id] = getMailboxesRecursively account.mailboxes

numberOfEmails = process.argv[2] or 100

getRandom = (max) -> Math.round (Math.random() * max)
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
    mailbox = getRandomElmt mailboxes[account]

    subject = loremIpsum count: getRandom(5), units: 'words'
    content = loremIpsum count: getRandom(10), units: 'paragraphs'

    # simulate email thread
    if getRandom(10) > 3
        inReplyTo  = "generated_id_#{i - 1}"
        references = "generated_id_#{i - 2} generated_id_#{i - 1}"
    else
        inReplyTo  = null
        references = null

    priority  = getRandomElmt priorities

    # random date this year before now
    today = moment()
    month = getRandom today.month()
    day = getRandom today.date()
    hour = getRandom today.hours()
    minute = getRandom today.minutes()
    date = moment().months(month).days(day).hours(hour).minutes(minute)

    messages.push
        "_id": "generated_id_#{i}"
        "docType": "Message",
        "createdAt": date.toISOString(),
        "subject": subject,
        "from": [from]
        "to": to,
        "cc": cc,
        "inReplyTo": inReplyTo,
        "references": references
        "replyTo": replyTo,
        "text": content,
        "html": "<html><body><div>#{content}</div></body></html>",
        "priority": priority,
        "reads": false,
        "mailboxIDs": [mailbox],
        "account": account,
        "attachments": []


targetFile = './tests/fixtures/messages_generated.json'
json = JSON.stringify messages, null, '  '
fs.writeFile targetFile, json, flag: 'w', (err) ->
    console.log err if err?
console.log "Done generating #{numberOfEmails} messages"
