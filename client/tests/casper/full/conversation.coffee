require = patchRequire global.require
init    = require("../common").init
utils   = require "utils.js"
x       = require('casper.js').selectXPath

selectMessage = (account, box, subject, cb) ->
    accounts = casper.evaluate ->
        accounts = {}
        Array.prototype.forEach.call document.querySelectorAll("#account-list > li"), (e) ->
            accounts[e.querySelector('.item-label').textContent.trim()] = e.dataset.reactid
        return accounts
    id = accounts[account]
    casper.test.assert (typeof id is 'string'), "Account #{account} found"
    casper.click "[data-reactid='#{id}'] a"
    casper.waitForSelector "[data-reactid='#{id}'].active", ->
        mailboxes = casper.evaluate ->
            mailboxes = {}
            Array.prototype.forEach.call document.querySelectorAll("#account-list > li.active .mailbox-list > li"), (e) ->
                mailboxes[e.querySelector('.item-label').textContent.trim()] = e.dataset.reactid
            return mailboxes
        id = mailboxes[box]
        casper.click "[data-reactid='#{id}'] .item-label"
        casper.waitForSelector "[data-reactid='#{id}'].active", ->
            subjectSel = x "//span[(contains(normalize-space(.), '#{subject}'))]"
            casper.waitForSelector subjectSel, ->
                casper.click subjectSel
                casper.waitForSelector x("//h3[(contains(normalize-space(.), '#{subject}'))]"), ->
                    casper.test.pass "Message #{subject} selected"
                    cb()
                , ->
                    casper.test.fail "Error displaying #{subject}"
            , ->
                casper.test.fail "No message with subject #{subject}"
        , ->
            casper.test.fail "Unable to go to mailbox #{box}"
    , ->
        casper.test.fail "Unable to go to account #{account}"

casper.test.begin 'Test conversation', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.evaluate ->
            window.cozyMails.setSetting 'messagesPerPage', 100
            window.cozyMails.setSetting 'messageDisplayHTML', true
            window.cozyMails.setSetting 'messageDisplayImages', false

        selectMessage "DoveCot", "INBOX", "Test attachments", ->
            test.assertExist '.imagesWarning', "Images warning"
            test.assertExist 'iframe.content', "Message body"
            frameName = casper.getElementInfo("iframe.content").attributes.name
            casper.page.switchToChildFrame frameName
            re = new RegExp ' src=', 'gm'
            displayed = not re.test casper.page.frameContent
            test.assert displayed, "Images not displayed"
            casper.page.switchToParentFrame()
            casper.click '.imagesWarning button'
            casper.waitWhileSelector ".imagesWarning", ->
                casper.page.switchToChildFrame frameName
                displayed = re.test casper.page.frameContent
                test.assert displayed, "Images displayed"
                casper.page.switchToParentFrame()

    casper.then ->
        test.comment "Header"
        test.assertExists ".header.row.compact", "Compact header"
        casper.click ".header.row.compact"
        casper.waitForSelector ".header.row.full", ->
            casper.click ".header.row.full .participants", ->
            casper.waitForSelector ".header.row.compact", ->
                casper.click ".header.row.compact", ->
                casper.waitForSelector ".header.row.full", ->
                    test.pass "Toggle between full and compact headers"

    casper.then ->
        test.comment "Add contact"
        test.assertExist ".conversation .sender .address"
        casper.click ".conversation .sender .address .address-add i"
        casper.waitForText "has been added to your contacts", ->
            test.pass "Contact added"

    casper.then ->
        test.comment "Attachements"
        test.assertElementCount ".header.row ul.files > li", 9, "Number of attachments"
        test.assertExist "li.file-item > .mime.image", "Attachement file type image"
        test.assertExist "li.file-item > .mime.pdf", "Attachement file type pdf"
        test.assertExist "li.file-item > .mime.spreadsheet", "Attachement file type spreadsheet"
        test.assertExist "li.file-item > .mime.text", "Attachement file type text"
        test.assertExist "li.file-item > .mime.word", "Attachement file type word"
        selectMessage "DoveCot", "INBOX", "Email fixture attachments gmail", ->
            casper.click ".header.row.compact"
            casper.waitForSelector ".header.row.full", ->
                test.assertElementCount ".header.row ul.files > li", 1, "Number of attachments"
                test.assertExist "li.file-item > .mime.image", "Attachement file type"

    casper.run ->
        test.done()
