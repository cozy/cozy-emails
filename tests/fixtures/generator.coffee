fs = require 'fs'
loremIpsum = require 'lorem-ipsum'
moment = require 'moment'

names = ['alice', 'bob', 'natacha', 'mark', 'zoey', 'john', 'felicia' ,'max']

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

getRandom = (max) -> Math.floor (Math.random() * max)

messages = []
for i in [1..numberOfEmails] by 1

    # sender and receiver must not be the same
    from = names[getRandom(8)]
    loop
        to = names[getRandom(8)]
        break if to isnt from

    account = accounts[getRandom(accounts.length)]._id
    mailbox = mailboxes[account][getRandom mailboxes[account].length]

    subject = loremIpsum count: getRandom(5), units: 'words'
    content = loremIpsum count: getRandom(10), units: 'sentences'

    # simulate email thread
    inReplyTo = if getRandom(10) > 3 then "generated_id_#{i - 1}" else ""

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
        "from": "#{from}@provider.com",
        "to": "#{to}@provider.com",
        "cc": "",
        "bcc": "",
        "inReplyTo": inReplyTo,
        "text": content,
        "html": content,
        "reads": false,
        "mailboxIDs": [mailbox],
        "account": account


targetFile = './tests/fixtures/messages_generated.json'
json = JSON.stringify messages
fs.writeFile targetFile, json, flag: 'w', (err) ->
    console.log err if err?