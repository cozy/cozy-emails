require = patchRequire global.require
init = require("../common").init
nbContacts = 0

casper.test.begin 'Test Activities', (test) ->
    init casper
    casper.start casper.cozy.startUrl + "test", ->
        test.comment "Search all contacts"
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
            test.assert Array.isArray(res.result), "Got array of contacts"
            test.assert res.result.length > 0, "Got contacts"
            test.assert res.result[0].name?, "Contact has name"
            test.assert res.result[0].address?, "Contact address"
            for contact in res.result
                if contact.address is 'test@test.org'
                    nbContacts++

    casper.then ->
        test.comment "Should return an error on wrong activity name"
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
        test.comment "Should return an error on wrong activity type"
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
        test.comment "Create contact"
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
        test.comment "Search for contact created"
        casper.evaluate ->
            Activity = require '../utils/activity_utils'
            options =
                name: 'search'
                data:
                    type: 'contact'
                    query: 'Test'
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

            toDelete = []
            for contact in res.result
                test.assert contact.name is 'Test', "Name ok"
                test.assert contact.address is 'test@test.org', "Address ok"
                toDelete.push contact.id

            test.comment "Delete #{toDelete.length} contact"
            casper.evaluate (ids) ->
                window.testDelete = []
                del = (id) ->
                    Activity = require '../utils/activity_utils'
                    options =
                        name: 'delete'
                        data:
                            type: 'contact'
                            id: id
                    activity = new Activity options
                    activity.onsuccess = ->
                        window.testDelete.push {error: @error, result: @result}
                    activity.onerror = ->
                        window.testDelete.push {error: @error, result: @result}
                del id for id in ids
            , {toDelete: toDelete}
            casper.waitFor ->
                return casper.getGlobal('testDelete').length is toDelete.length
            , ->
                casper.evaluate ->
                    Activity = require '../utils/activity_utils'
                    options =
                        name: 'search'
                        data:
                            type: 'contact'
                            query: 'Test'
                    activity = new Activity options
                    activity.onsuccess = ->
                        window.test6 = this
                    activity.onerror = ->
                        window.test6 = this
                casper.waitFor ->
                    return casper.getGlobal 'test6'
                , ->
                    res = casper.getGlobal 'test6'
                    test.assert res.result.length is 0, "Contact deleted"

    casper.run ->
        test.done()

