require = patchRequire global.require
init = require("../common").init
nbContacts = 0

casper.test.begin 'Test Activities', (test) ->
    init casper
    casper.start casper.cozy.startUrl + "test", ->
        casper.evaluate ->
            Activity = require '../utils/activity_utils'
            options =
                name: 'search'
                data:
                    type: 'contact'
            activity = new Activity options
            activity.onsuccess = ->
                window.test1 = this
            activity.onerror = ->
                window.test1 = this
        casper.waitFor ->
            return casper.getGlobal 'test1'
        , ->
            res = casper.getGlobal 'test1'
            test.assert res.result?, "Got contacts"
            test.assert (not res.error?), "No error"
            test.assert Array.isArray(res.result), "Got contacts"
            test.assert res.result[0].name?, "Contact name"
            test.assert res.result[0].address?, "Contact name"
            nbContacts = res.result.length

    casper.then ->
        casper.evaluate ->
            Activity = require '../utils/activity_utils'
            options =
                name: 'cozy'
                data:
                    type: 'contact'
            activity = new Activity options
            activity.onsuccess = ->
                window.test2 = this
            activity.onerror = ->
                window.test2 = this
        casper.waitFor ->
            return casper.getGlobal 'test2'
        , ->
            res = casper.getGlobal 'test2'
            test.assert res.error?, "Error on wrong activity name"

    casper.then ->
        casper.evaluate ->
            Activity = require '../utils/activity_utils'
            options =
                name: 'search'
                data:
                    type: 'badtype'
            activity = new Activity options
            activity.onsuccess = ->
                window.test3 = this
            activity.onerror = ->
                window.test3 = this
        casper.waitFor ->
            return casper.getGlobal 'test3'
        , ->
            res = casper.getGlobal 'test3'
            test.assert res.error?, "Error on wrong activity type"

    casper.then ->
        casper.evaluate ->
            Activity = require '../utils/activity_utils'
            options =
                name: 'create'
                data:
                    type: 'contact'
                    contact: {name: "Test", address: "test@test.org"}
            activity = new Activity options
            activity.onsuccess = ->
                window.test4 = this
            activity.onerror = ->
                window.test4 = this
        casper.waitFor ->
            return casper.getGlobal 'test4'
        , ->
            res = casper.getGlobal 'test4'
            test.assert (not res.error?), "No error"

    casper.then ->
        casper.evaluate ->
            Activity = require '../utils/activity_utils'
            options =
                name: 'search'
                data:
                    type: 'contact'
            activity = new Activity options
            activity.onsuccess = ->
                window.test5 = this
            activity.onerror = ->
                window.test5 = this
        casper.waitFor ->
            return casper.getGlobal 'test5'
        , ->
            res = casper.getGlobal 'test5'
            test.assert (not res.error?), "No error"
            test.assert Array.isArray(res.result), "Got contacts"
            test.assert res.result.length is (nbContacts + 1), "Contact added"
    casper.run ->
        test.done()

