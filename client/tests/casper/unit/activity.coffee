require = patchRequire global.require
init = require("../common").init
nbContacts = 0
contacts = [
    {name: "Dr Claude Lambda"   , address: "claude.lambda@cozytest.cc"},
    {name: "Dr Alex Lambda"     , address: "alex.lambda@cozytest.cc"},
    {name: "Dr Dominique Lambda", address: "dominique.lambda@cozytest.cc"},
    {name: "Dr Camille Guique"  , address: "camille@cozytest.cc"},
    {name: "Dr Alix Guique"     , address: "alix@cozytest.cc"},
    {name: "Dr Dany Guique"     , address: "dany@cozytest.cc"},
    {name: "Dr Gwen Guique"     , address: "gwen@cozytest.cc"}
]

doActivity = (options, cb) ->
    if not Array.isArray(options)
        options = [ options ]
    casper.evaluate (options) ->
        Activity = require '../utils/activity_utils'
        window.testActivity = []
        if not Array.isArray(options)
            options = [ options ]
        send = (option) ->
            activity = new Activity option
            activity.onsuccess = ->
                window.testActivity.push {error: @error, result: @result}
            activity.onerror = ->
                window.testActivity.push {error: @error, result: @result}
        send option for option in options
    , options
    casper.waitFor ->
        return casper.getGlobal('testActivity').length is options.length
    , -> cb(casper.getGlobal 'testActivity')

getOptions = (name, key, value) ->
    options =
        name: name
        data:
            type: 'contact'
    options.data[key] = value
    return options

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
                if /@cozytest/.test contact.address
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
        options = contacts.map (e) -> getOptions 'create', 'contact', e
        doActivity options, (res) ->
            test.assert (not res.error?), "No error"

    casper.then ->
        test.comment "Search by name for contacts created"
        options = getOptions 'search', 'query', 'Dr '
        doActivity options, (res) ->
            res = res.shift()
            test.assert (not res.error?), "No error"
            test.assert Array.isArray(res.result), "Got contacts"
            test.assert res.result.length is (nbContacts + contacts.length),
                "Contact added"

            for contact in res.result
                test.assert /^Dr /.test(contact.name), "Name ok"

    casper.then ->
        test.comment "Search by address for contacts created"
        options = getOptions 'search', 'query', 'cozytest'
        doActivity options, (res) ->
            res = res.shift()
            test.assert (not res.error?), "No error"
            test.assert Array.isArray(res.result), "Got contacts"
            test.assert res.result.length is (nbContacts + contacts.length),
                "Contact added"

            toDelete = []
            for contact in res.result
                test.assert /cozytest/.test(contact.address), "Address ok"
                toDelete.push contact.id

            test.comment "Delete #{toDelete.length} contact"
            options = toDelete.map (e) -> getOptions 'delete', 'id', e
            doActivity options, (res) ->
                casper.evaluate ->
                    Activity = require '../utils/activity_utils'
                    options =
                        name: 'search'
                        data:
                            type: 'contact'
                            query: 'cozytest'
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

