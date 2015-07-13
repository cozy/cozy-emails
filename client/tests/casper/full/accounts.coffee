if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"

deleteTestAccounts = ->
    casper.evaluate ->
        AccountStore  = require 'stores/account_store'
        account = AccountStore.getByLabel 'Test Account'
        if account?
            AccountActionCreator = require 'actions/account_action_creator'
            console.log "Deleting test account #{account.get 'id'}"
            AccountActionCreator.remove(account.get 'id')
        else
            console.log "No test account to delete"

casper.test.begin 'Test accounts', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        accountSel = ".mainmenu .account"
        accounts = casper.getElementsInfo accountSel
        casper.eachThen accounts, (response) ->
            account = response.data
            id = account.attributes['data-reactid']
            if not casper.exists ".active[data-reactid='#{id}']"
                casper.click "[data-reactid='#{id}']"
            casper.waitForSelector ".active[data-reactid='#{id}']", ->
                label = casper.getElementInfo "[data-reactid='#{id}'] .item-label"
                test.pass "Account #{label.text} selected"
                if casper.exists ".messages-list .message"
                    casper.click ".messages-list .message a .subject"
                    casper.waitUntilVisible ".conversation"
            , ->
                test.fail "Unable to select account #{account.text} #{id}"

    casper.run ->
        test.done()

casper.test.begin 'Create account', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        values =
            "mailbox-accountType": "IMAP",
            "mailbox-imapPort": "993",
            "mailbox-imapSSL": true,
            "mailbox-imapServer": "toto",
            "mailbox-imapTLS": false,
            "mailbox-label": "Test Account",
            "mailbox-login": "test@cozytest.org",
            "mailbox-name": "Test",
            "mailbox-password": "toto",
            "mailbox-smtpPort": "465",
            "mailbox-smtpSSL": true,
            "mailbox-smtpServer": "toto",
            "mailbox-smtpTLS": false

        deleteTestAccounts()
        account = casper.evaluate ->
            AccountStore  = require 'stores/account_store'
            account = AccountStore.getByLabel 'Test Account'
            return account?
        test.assertFalsy account, "Test account doesnt exists"
        casper.click '.new-account-action'
        casper.waitForSelector '#mailbox-config', ->
            test.assertSelectorHasText "#mailbox-config h3", "New account"
            test.assertDoesntExist "#mailbox-config .nav-tabs", "No tabs"
            test.assertSelectorHasText "#mailbox-config button.action-save", "Add", "Add button"
            test.assertDoesntExist ".toast-error", "No error message"
            casper.click "#mailbox-config button.action-save"
            casper.waitForSelector ".toast-error", ->
                test.pass "Error message displayed"
                test.assertElementCount ".form-group.has-error", 9, "Errors are underlined"
                casper.fillSelectors 'form', '#mailbox-label':  values['mailbox-label']
                casper.click "#mailbox-config button.action-save"
                casper.wait 100, ->
                    test.assertElementCount ".form-group.has-error", 8, "Errors are underlined"
                    casper.fillSelectors 'form',
                        '#mailbox-name': values['mailbox-name']
                        '#mailbox-login': values['mailbox-login']
                        '#mailbox-password': values['mailbox-password']
                        '#mailbox-smtpServer': values['mailbox-smtpServer']
                        '#mailbox-imapServer': values['mailbox-imapServer']
                        '#maibox-accountType': values['account-type']
                    casper.click "#mailbox-config button.action-save"
                    casper.waitForSelector '.form-account.waiting', ->
                        casper.waitWhileSelector '.form-account.waiting', ->
                            test.assertSelectorHasText "#mailbox-config button.action-save", "Add", "Wrong SMTP Server"
                            test.assertEquals casper.getFormValues('form'), values, "Form not changed"
                            test.assertDoesntExist ".has-error #mailbox-label", "No error on label"
                            test.assertExist ".has-error #mailbox-smtpServer", "Error on SMTP"
                            casper.fillSelectors 'form',
                                '#mailbox-accountType': 'TEST'
                                '#mailbox-smtpServer': 'ssl0.ovh.net'
                                '#mailbox-imapServer': values['mailbox-imapServer']
                            casper.wait 500, ->
                                casper.click "#mailbox-config button.action-save"
                                casper.waitForSelector "#mailbox-config .nav-tabs", ->
                                    test.pass 'No more errors ☺'

    casper.then ->
        test.comment "Creating mailbox"
        name = "Box 1"
        test.assertSelectorHasText "#mailbox-config .nav-tabs .active", "Folders", "Folders tab is active"
        test.assertDoesntExist ".form-group.draftMailbox .dropdown", "No draft folder"
        test.assertDoesntExist ".form-group.sentMailbox .dropdown",  "No sent folder"
        test.assertDoesntExist ".form-group.trashMailbox .dropdown", "No trash folder"
        test.assertElementCount "ul.boxes > li.box-item", 0, "No boxes"
        casper.fillSelectors 'form', '#newmailbox': name
        casper.click '.box-action.add i'
        casper.waitForSelector '.box-item', ->
            test.assertSelectorHasText ".box .box-label", name, "Box created"
            test.assertExist ".form-group.draftMailbox .dropdown", "Draft folder", "Draft dropdown"
            test.assertSelectorHasText ".form-group.draftMailbox .dropdown-menu", name, "Box in draft dropdown"
            test.assertExist ".form-group.sentMailbox .dropdown",  "Sent folder", "Sent dropdown"
            test.assertSelectorHasText ".form-group.sentMailbox .dropdown-menu", name, "Box in sent dropdown"
            test.assertExist ".form-group.trashMailbox .dropdown", "Trash folder", "Trash dropdown"
            test.assertSelectorHasText ".form-group.trashMailbox .dropdown-menu", name, "Box in trash dropdown"

    casper.then ->
        test.comment "Rename mailbox"
        name = "Box 2"
        casper.click ".box .box-action.edit i"
        casper.waitForSelector ".box .box-action.save", ->
            casper.fillSelectors 'form', '.box .box-label': name
            casper.click ".box .box-action.save i"
            casper.waitForSelector ".box span.box-label", ->
                test.assertSelectorDoesntHaveText ".box .box-label", "Box 1", "Box renamed"
                test.assertSelectorHasText ".box .box-label", name, "Box renamed"
                test.assertExist ".form-group.draftMailbox .dropdown", "Draft folder", "Draft dropdown"
                test.assertSelectorHasText ".form-group.draftMailbox .dropdown-menu", name, "Box in draft dropdown"
                test.assertExist ".form-group.sentMailbox .dropdown",  "Sent folder", "Sent dropdown"
                test.assertSelectorHasText ".form-group.sentMailbox .dropdown-menu", name, "Box in sent dropdown"
                test.assertExist ".form-group.trashMailbox .dropdown", "Trash folder", "Trash dropdown"
                test.assertSelectorHasText ".form-group.trashMailbox .dropdown-menu", name, "Box in trash dropdown"

    casper.then ->
        test.comment "Delete mailbox"
        casper.click ".box .box-action.delete i"
        casper.waitUntilVisible '.modal-dialog',  ->
            confirm = casper.fetchText('.modal-body').trim()
            test.assertEquals confirm, "Do you really want to delete all messages in this box?", "Confirmation dialog"
            casper.click ".modal-dialog .btn:not(.btn-cozy-non-default)"
            casper.waitWhileSelector "ul.boxes .box span.box-label", ->
                test.assertDoesntExist ".form-group.draftMailbox .dropdown", "No draft folder"
                test.assertDoesntExist ".form-group.sentMailbox .dropdown",  "No sent folder"
                test.assertDoesntExist ".form-group.trashMailbox .dropdown", "No trash folder"
                test.assertElementCount "ul.boxes > li.box-item", 0, "No boxes"


    casper.then ->
        test.pass "ok"

    casper.run ->
        test.done()

casper.test.begin 'Test accounts', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        accountSel = ".mainmenu .account"
        accounts = casper.getElementsInfo accountSel
        id = accounts[0].attributes['data-reactid']
        if not casper.exists ".active[data-reactid='#{id}']"
            casper.click "[data-reactid='#{id}']"
        casper.waitForSelector ".active[data-reactid='#{id}']", ->
            casper.click '.mainmenu .active .mailbox-config'
            casper.waitForSelector '#mailbox-config', ->
                test.assertSelectorHasText "#mailbox-config h3", "Edit account"
                test.assertSelectorHasText "#mailbox-config .nav-tabs .active", "Account", "Account tab is active"
                test.assertSelectorHasText "#mailbox-config .nav-tabs", "Folders", "Folder tab visible"

    casper.run ->
        deleteTestAccounts()
        test.done()
