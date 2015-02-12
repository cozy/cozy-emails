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
        casper.evaluate ->
            #window.cozyMails.setSetting 'messagesPerPage', 100
            window.cozyMails.setSetting 'messageDisplayHTML', true
            window.cozyMails.setSetting 'messageDisplayImages', false
            window.cozyMails.setSetting 'displayConversation', false

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
        test.comment "Header"
        test.assertExists ".header.compact", "Compact header"
        casper.click ".header.compact .toggle-headers"
        casper.waitForSelector ".header.row.full", ->
            casper.click ".header.row.full .toggle-headers", ->
            casper.waitForSelector ".header.compact", ->
                casper.click ".header.compact .toggle-headers", ->
                casper.waitForSelector ".header.row.full", ->
                    test.pass "Toggle between full and compact headers"

    casper.then ->
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
        test.assertElementCount ".header.row ul.files > li", 9, "Number of attachments"
        test.assertExist "li.file-item > .mime.image", "Attachement file type image"
        test.assertExist "li.file-item > .mime.pdf", "Attachement file type pdf"
        test.assertExist "li.file-item > .mime.spreadsheet", "Attachement file type spreadsheet"
        test.assertExist "li.file-item > .mime.text", "Attachement file type text"
        test.assertExist "li.file-item > .mime.word", "Attachement file type word"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Email fixture attachments gmail", ->
            if casper.exists '.header.compact'
                casper.click ".header.compact .toggle-headers"
            casper.waitForSelector ".header.row.full", ->
                test.assertElementCount ".header.row ul.files > li", 1, "Number of attachments"
                test.assertExist "li.file-item > .mime.image", "Attachement file type"

    casper.then ->
        test.comment "Message Thread"
        messageID = '20141106092130.GF5642@mail.cozy.io'
        casper.cozy.selectMessage 'DoveCot', 'Test Folder', 'troll', messageID, ->
            test.assertExists ".message.active[data-message-id='#{messageID}']", "Message active in list"
            test.assertElementCount "ul.thread > li.message", 5, "Whole conversation displayed"
            test.assertElementCount "ul.thread > li.message.active", 1, "Other messages compacted"
            ###
            test.assertExists "ul.thread > li:nth-of-type(1) .messageToolbox", "Toolbox on current"
            test.assertDoesntExist "ul.thread > li:nth-of-type(2) .messageToolbox", "No toolbox on compacted"
            casper.click '.messageNavigation button.prev'
            casper.waitForSelector x("//h3[(contains(normalize-space(.), 'Re: troll'))]"), ->
                test.pass 'Next message selected'
                test.assertElementCount "ul.thread > li.message", 5, "Whole conversation displayed"
                test.assertElementCount "ul.thread > li.message.active", 1, "Other messages compacted"
                test.assertExists "ul.thread > li.message.active .messageToolbox", "Toolbox on current"

                # random failures
                casper.click 'ul.thread > li.message.active .toggle-active'
                casper.waitWhileSelector 'ul.thread > li.message.active', ->
                    test.pass 'Message folded'
                    casper.click 'ul.thread > li:nth-of-type(3) .toggle-active'
                    casper.waitForSelector 'ul.thread > li.message.active', ->
                        test.assertExists "ul.thread > li:nth-of-type(2) .messageToolbox", "Message unfolded"
            ###

    casper.then ->
        test.comment "Display flat"
        casper.evaluate ->
            window.cozyMails.setSetting 'displayConversation', false
        casper.open casper.cozy.startUrl, ->
            messageID = '20141106092130.GF5642@mail.cozy.io'
            casper.cozy.selectMessage 'DoveCot', 'Test Folder', 'troll', messageID, ->
                test.assertExists ".message.active[data-message-id='#{messageID}']", "Message active in list"
                test.assertElementCount "ul.thread > li.message", 1, "Only one message displayed"
                test.assertExists "ul.thread > li:nth-of-type(1) .messageToolbox", "Toolbox on current"
                casper.click '.messageNavigation button.prev'
                casper.waitForSelector x("//h3[(contains(normalize-space(.), 'Re: troll'))]"), ->
                    test.pass 'Next message selected'
                    test.assertElementCount "ul.thread > li.message", 1, "Only one message displayed"

    casper.run ->
        test.done()
