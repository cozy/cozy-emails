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
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
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

    # Test attachments
    casper.then ->
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Test attachments", ->
            test.comment "Header"
            casper.click ".conversation .message.active header"
            casper.waitWhileSelector ".conversation iframe.content", ->
                test.pass "Conversation closed"
                casper.click ".conversation article header"
                casper.waitForSelector ".conversation .message.active iframe.content", ->
                    test.pass "Conversation opened"

    # Test attachments
    casper.then ->
        test.comment "Attachements"
        test.assertElementCount ".conversation .message.active footer .attachments li", 9, "Number of attachments"
        test.assertExist ".attachments li .mime.image", "Attachement file type image"
        test.assertExist ".attachments li .mime.pdf", "Attachement file type pdf"
        test.assertExist ".attachments li .mime.spreadsheet", "Attachement file type spreadsheet"
        test.assertExist ".attachments li .mime.text", "Attachement file type text"
        test.assertExist ".attachments li .mime.word", "Attachement file type word"

    # Attached images
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

    # Message Detail
    casper.then ->
        test.comment "Message Detail"
        #messageID = '20141106092130.GF5642@mail.cozy.io'
        casper.cozy.selectMessage 'DoveCot', 'Test Folder', 'troll', (messageID) ->
            test.assertNotVisible '.conversation article:nth-of-type(1) .popup', 'Details hidden'
            casper.click '.conversation article.active .details i.fa-caret-down'
            casper.waitUntilVisible '.conversation article.active .popup', ->
                test.pass 'Details shown'
                casper.click '.conversation article.active .details i.fa-caret-down'
                casper.waitWhileVisible '.conversation article.active .popup', ->
                    test.pass 'Details hidden'

    casper.run ->
        test.done()
