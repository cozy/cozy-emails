if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

doSelect = (n, cb) ->
    casper.click ".message-list li.message:nth-of-type(#{n})"
    casper.waitForSelector ".message-list li.message:nth-of-type(#{n}).active", ->
        infos = casper.getElementInfo '.message-list li.message.active'
        messageID = infos.attributes['data-message-id']
        casper.test.assertExists "h3.message-title[data-message-id='#{messageID}']", "Message #{n} selected"
        if cb?
            cb()

doKey = (key, next, cb) ->
    #casper.page.sendEvent('keydown', casper.page.event.key.Down)
    #casper.page.sendEvent('keyup', casper.page.event.key.Down)
    #casper.page.sendEvent('keypress', casper.page.event.key.Down)
    casper.evaluate (key) ->
        console.log key
        window.Mousetrap.trigger('j')
    , 'j'
    casper.waitForSelector ".message-list li.message:nth-of-type(#{next}).active", ->
        infos = casper.getElementInfo '.message-list li.message.active'
        messageID = infos.attributes['data-message-id']
        casper.test.assertExists "h3.message-title[data-message-id='#{messageID}']", "Message #{next} selected"
        if cb?
            cb()

doNav = (dir, next, cb) ->
    casper.click ".conversation .fa-long-arrow-#{dir}"
    casper.waitForSelector ".message-list li.message:nth-of-type(#{next}).active", ->
        infos = casper.getElementInfo '.message-list li.message.active'
        messageID = infos.attributes['data-message-id']
        casper.test.assertExists "h3.message-title[data-message-id='#{messageID}']", "Message #{next} selected"
        if cb?
            cb()

doNavConv = (dir, next, messageID, cb) ->
    casper.click ".conversation .fa-long-arrow-#{dir}"
    casper.waitForSelector ".message-list li.message:nth-of-type(#{next}).active", ->
        casper.test.assertExists "h3.message-title[data-message-id='#{messageID}']", "Message #{next} selected"
        if cb?
            cb()

casper.test.begin 'Test Message Selection', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.evaluate ->
            window.cozyMails.setSetting 'displayConversation', false
            window.cozyMails.setSetting 'displayPreview', true

    casper.then ->
        test.comment "Selecting by click"
        casper.cozy.selectAccount "DoveCot", "Test Folder", ->
            test.assertExists '.message-list li.message:nth-of-type(1).active', 'First message selected'
            doSelect 3, ->
                doSelect 5, ->
                    doSelect 2, ->
                        # force folder update
                        casper.cozy.selectAccount "DoveCot", "INBOX"

    casper.then ->
        if require('system').env.NO_TRAVIS
            test.comment "Click navigation"
            casper.evaluate ->
                window.cozyMails.setSetting 'displayConversation', false
            casper.waitFor ->
                casper.evaluate ->
                    return not window.cozyMails.getSetting 'displayConversation'
            , ->
                casper.cozy.selectAccount "DoveCot", "Test Folder", ->
                    firstSel = '.message-list li.message:nth-of-type(1)'
                    casper.click firstSel
                    messageID = casper.getElementInfo(firstSel).attributes['data-message-id']
                    casper.waitForSelector "h3[data-message-id='#{messageID}']", ->
                        doNav 'right', 2, ->
                            doNav 'right', 3, ->
                                doNav 'right', 4, ->
                                    doNav 'left', 3, ->
                                        doNav 'left', 2, ->
                                            # force folder update
                                            casper.cozy.selectAccount "DoveCot", "INBOX"

    casper.then ->
        test.comment "Selecting by click in conversation mode"
        casper.evaluate ->
            window.cozyMails.setSetting 'displayConversation', true
        casper.waitFor ->
            casper.evaluate ->
                window.cozyMails.getSetting 'displayConversation'
        , ->
            casper.cozy.selectAccount "DoveCot", "Test Folder", ->
                test.assertExists '.message-list li.message:nth-of-type(1).active', 'First message selected'
                doSelect 3, ->
                    doSelect 1, ->
                        # force folder update
                        casper.cozy.selectAccount "DoveCot", "INBOX"


    ### Conversation navigation has been reverted
    casper.then ->
        test.comment "Click navigation in conversation mode"
        casper.evaluate ->
            window.cozyMails.setSetting 'displayConversation', true
        casper.cozy.selectAccount "DoveCot", "Test Folder", ->
            casper.click '.message-list li.message:nth-of-type(1)'
            casper.waitForSelector '.conversation', ->
                doNavConv 'right', 1, "20141106093618.GI5642@mail.cozy.io", ->
                    doNavConv 'right', 1, "20141106093513.GH5642@mail.cozy.io", ->
                        doNavConv 'right', 1, "20141106092531.GG5642@mail.cozy.io", ->
                            doNavConv 'right', 1, "20141106092130.GF5642@mail.cozy.io", ->
                                doNavConv 'right', 2, "CA+nLd+uoQZbQ0fUqDdcyZHW+SQo3E71UNT-m8YqOyci+Hskspw@mail.gmail.com", ->
                                    doNavConv 'left', 1, "20141106092130.GF5642@mail.cozy.io", ->
                                        doNavConv 'left', 1, "20141106092531.GG5642@mail.cozy.io"
    ###

    ###
    casper.then ->
        test.comment "Keyboard navigation"
        casper.evaluate ->
            window.cozyMails.setSetting 'displayConversation', false
        casper.cozy.selectAccount "DoveCot", "Test Folder", ->
            test.assertExists '.message-list li.message:nth-of-type(1).active', 'First message selected'
            casper.wait 5000, ->
                doKey 'down', 2, ->
                    doKey 'down', 3, ->
                        doKey 'j', 4, ->
                            doKey 'k', 3, ->
                                doKey 'up', 2
    ###

    casper.then ->
        test.comment "Select mode togle"
        test.assertNotVisible '.message-list input[type=checkbox]', 'No checkbox displayed'
        casper.mouse.move ".message-list li.message:nth-of-type(1) .fa-user"
        test.assertVisible ".message-list li.message:nth-of-type(1) input[type=checkbox]", 'Checkbox visible on mouse over'
        test.assertNotVisible ".message-list li.message:nth-of-type(2) input[type=checkbox]", 'Other checkboxes not visibles'
        casper.click ".message-list li.message:nth-of-type(1) input[type=checkbox]"
        test.assertVisible ".message-list li.message:nth-of-type(1) input[type=checkbox]:checked", 'Checkbox checked'
        test.assertVisible ".message-list li.message:nth-of-type(2) input[type=checkbox]", 'Other checkboxes visibles'
        casper.click ".message-list li.message:nth-of-type(1) input[type=checkbox]"
        test.assertNotVisible '.message-list input[type=checkbox]', 'No checkbox displayed'


    casper.run ->
        test.done()

