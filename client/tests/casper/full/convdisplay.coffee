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
        casper.cozy.selectAccount 'DoveCot', 'Test Folder',  ->
            casper.evaluate ->
                window.__testSeen = false
                require('actions/message_action_creator').mark {conversationID: 'conversation_test'}, 'Unseen', ->
                    window.__testSeen = true
            casper.waitFor ->
                return casper.getGlobal '__testSeen'

    casper.then ->
        test.comment "Display first unread message"
        casper.cozy.selectMessage 'DoveCot', 'Test Folder', 'Re: Conversation', ->
            test.assertElementCount ".conversation article.message.active", 1, "Only one message active"
            test.assertElementCount ".conversation article.message", 3, "Only three messages displayed"
            test.assertExists ".conversation article.message.active[data-id='conversation_id_1']", "first unseen displayed"
            test.assertExists ".conversation > button.more", "More is displayed"
            casper.click ".conversation > button.more"
            casper.waitWhileSelector ".convrsation > button.more", ->
                test.assertElementCount ".conversation article.message.active", 1, "Only one message active"
                test.assertElementCount ".conversation article.message", 10, "All messages displayed"
                test.assertExists ".conversation article.message.active[data-id='conversation_id_1']", "first unseen displayed"
                test.assertDoesntExist ".conversation > button.more", "No more More button"

    casper.then ->
        test.comment "Display next unread message"
        casper.click ".conversation > header > a.fa-close"
        casper.waitWhileSelector ".conversation", ->
            casper.cozy.selectMessage 'DoveCot', 'Test Folder', 'Re: Conversation', ->
                test.assertElementCount ".conversation article.message.active", 1, "Only one message active"
                test.assertElementCount ".conversation article.message", 4, "Only four messages displayed"
                test.assertExists ".conversation article.message.active[data-id='conversation_id_2']", "first unseen displayed"
                test.assertExists ".conversation > button.more", "More is displayed"
                casper.click ".conversation > button.more"
                casper.waitWhileSelector ".convrsation > button.more"

    casper.then ->
        test.comment "Folding"
        casper.click ".conversation article.message[data-id='conversation_id_3'] header"
        casper.waitForSelector ".conversation article.message.active[data-id='conversation_id_3']", ->
            test.pass "Third message displayed"
            test.assertElementCount ".conversation article.message.active", 2, "Two messages actives"
            test.assertDoesntExist ".conversation article.message.active[data-id='conversation_id_1']", "First message folded"
            test.assertExist ".conversation article.message.active[data-id='conversation_id_2']", "Second message unfolded"
            casper.click ".conversation article.message.active[data-id='conversation_id_3'] header"
            casper.waitWhileSelector ".conversation article.message.active[data-id='conversation_id_3']", ->
                test.pass "Message folded"
                test.assertElementCount ".conversation article.message.active", 1, "Only one message active"
                casper.click ".conversation article.message.active header"
                casper.waitWhileSelector ".conversation article.message.active", ->
                    test.pass "All messages folded"



    casper.run ->
        test.done()

