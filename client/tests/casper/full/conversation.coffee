if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

casper.test.begin 'Test conversation', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        #casper.evaluate ->
        #    window.cozyMails.setSetting 'messageDisplayHTML', true
        #    window.cozyMails.setSetting 'messageDisplayImages', false
        #    window.cozyMails.setSetting 'displayConversation', false

        casper.cozy.selectMessage "DoveCot", "Test Folder", "Test attachments", ->
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
            , ->
                # sometime we need to click twice ???
                casper.click '.imagesWarning button'
                casper.waitWhileSelector ".imagesWarning", ->
                    casper.page.switchToChildFrame frameName
                    displayed = re.test casper.page.frameContent
                    test.assert displayed, "Images displayed"
                    casper.page.switchToParentFrame()

    casper.then ->
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Test attachments", ->
            test.comment "Header"
            casper.click ".conversation .message.active header"
            casper.waitWhileSelector ".conversation iframe.content", ->
                test.pass "Conversation closed"
                casper.click ".conversation article header"
                casper.waitForSelector ".conversation .message.active iframe.content", ->
                    test.pass "Conversation opened"

    casper.then ->
        # skipping test, as this has been removed for now
        test.skip 1
        return
        test.comment "Add contact"
        test.assertExist ".conversation .sender .address-item"
        this.mouse.move ".conversation .sender .address-item"
        casper.waitForSelector ".conversation .sender .tooltip", ->
            test.pass "Tooltip displayed"
            casper.click ".conversation .sender .tooltip .address-add i"
            casper.waitForText "has been added to your contacts", ->
                test.pass "Contact added"

    casper.then ->
        test.comment "Attachements"
        test.assertElementCount ".conversation .message.active footer .attachments li", 9, "Number of attachments"
        test.assertExist ".attachments li .mime.image", "Attachement file type image"
        test.assertExist ".attachments li .mime.pdf", "Attachement file type pdf"
        test.assertExist ".attachments li .mime.spreadsheet", "Attachement file type spreadsheet"
        test.assertExist ".attachments li .mime.text", "Attachement file type text"
        test.assertExist ".attachments li .mime.word", "Attachement file type word"

    casper.then ->
        test.comment "Attached images"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Email fixture attachments gmail", ->
            casper.click '.imagesWarning button'
            casper.waitWhileSelector ".imagesWarning", ->
                attSrc = casper.getElementInfo(".attachments img").attributes.src
                frameName = casper.getElementInfo("iframe.content").attributes.name
                casper.page.switchToChildFrame frameName
                re = /img src="(message[^"]*)"/.exec(casper.page.frameContent)
                if re? and Array.isArray(re)
                    imgSrc = re[1]
                casper.page.switchToParentFrame()
                test.assertEqual attSrc, imgSrc, "Image displayed"

    casper.then ->
        test.comment "Message Thread"
        #messageID = '20141106092130.GF5642@mail.cozy.io'
        casper.cozy.selectMessage 'DoveCot', 'Test Folder', 'troll', (messageID) ->
            test.assertElementCount ".conversation article.message.active", 1, "One active message"
            test.assertElementCount ".conversation article.message", 3, "3 messages displayed"
            test.assertExists '.conversation button.more', 'More button'
            casper.click '.conversation button.more'
            casper.waitWhileSelector '.conversation button.more', ->
                test.assertElementCount ".conversation article.message", 5, "All messages displayed"
                test.assertExists ".conversation article.active header .toolbar", "Toolbar in header"
                test.assertElementCount ".conversation article.active header .toolbar button", 6, "Buttons in header"
                test.assertExists ".conversation article.active footer .toolbar", "Toolbar in footer"
                test.assertElementCount ".conversation article.active footer .toolbar button", 3, "Buttons in footer"

                test.assertDoesntExist '.conversation article:nth-of-type(1).active', 'First message not active'
                casper.click '.conversation article:nth-of-type(1) header'
                casper.waitForSelector '.conversation article:nth-of-type(1).active', ->
                    test.assertElementCount ".conversation article.message", 5, "All messages displayed"
                    test.assertElementCount ".conversation article.message.active", 2, "Two messages actives"
                    casper.click '.conversation article:nth-of-type(1) header'
                    casper.waitWhileSelector '.conversation article:nth-of-type(1).active', ->
                        test.assertElementCount ".conversation article.message.active", 1, "First message closed"

    casper.then ->
        test.comment "Message Detail"
        #messageID = '20141106092130.GF5642@mail.cozy.io'
        casper.cozy.selectMessage 'DoveCot', 'Test Folder', 'troll', (messageID) ->
            test.assertNotVisible '.conversation article:nth-of-type(1) .popup', 'Details hidden'
            casper.click '.conversation article:nth-of-type(1) .details .btn'
            casper.waitUntilVisible '.conversation article:nth-of-type(1) .popup', ->
                test.pass 'Details shown'
                txt = casper.fetchText '.conversation article:nth-of-type(1) .popup'
                txt = txt.replace(/\s/g, '')
                test.assertEquals txt, 'FromMeme@cozytest.ccToYouyou@cozytest.ccDate2014-11-06T09:21:30.000ZSubjecttroll', 'Details value'
                casper.click '.conversation article:nth-of-type(1) .details .btn'
                casper.waitWhileVisible '.conversation article:nth-of-type(1) .popup', ->
                    test.pass 'Details hidden'

    casper.run ->
        test.done()
