fs = require 'fs'
loremIpsum = require 'lorem-ipsum'
moment = require 'moment'

names = ['alice', 'bob', 'natacha', 'mark', 'zoey', 'john', 'felicia' ,'max']
mailboxes = ['gmail-ID', 'orange-ID']
imapFolders =
    'gmail-ID': 6
    'orange-ID': 2

numberOfEmails = process.argv[2] or 100

getRandom = (max) -> Math.floor (Math.random() * max)

objects = []
for i in [1..numberOfEmails] by 1

    # sender and receiver must not be the same
    from = names[getRandom(8)]
    loop
        to = names[getRandom(8)]
        break if to isnt from

    mailbox = mailboxes[getRandom(2)]
    imapFolder = "#{mailbox}-folder#{getRandom(imapFolders[mailbox]) + 1}"

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

    objects.push
        "_id": "generated_id_#{i}"
        "docType": "Email",
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
        "imapFolder": imapFolder,
        "mailbox": mailbox


targetFile = './tests/fixtures/emails_generated.json'
jsonObject = JSON.stringify objects
fs.writeFile targetFile, jsonObject, flag: 'w', (err) ->
    console.log err if err?