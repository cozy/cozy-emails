var assert = require('chai').assert
var mockery = require('mockery')
var sinon = require('sinon')

var SpecDispatcher = require('./utils/specs_dispatcher')

var Dispositions = require('../app/constants/app_constants').Dispositions
var ActionTypes = require('../app/constants/app_constants').ActionTypes


describe('LayoutStore spec', function() {

    var sandbox, layoutStore, dispatcher

    before(function () {
        dispatcher = new SpecDispatcher()
        sandbox = sinon.sandbox.create()
        mockery.enable({
            warnOnUnregistered: false,
            useCleanCache: true
        })

        mockery.registerMock('../app_dispatcher', dispatcher)
        mockery.registerMock('../../../app_dispatcher', dispatcher)
        mockery.registerMock('./account_store', {})
        mockery.registerAllowables([
            'node-event-emitter',
            '../constants/app_constants',
            '../libs/flux/store/store',
            '../app/stores/layout_store'
        ])

        global.window = { innerWidth: 1600 }
        layoutStore = require('../app/stores/layout_store')
    })

    after(function () {
        mockery.disable()
        sandbox.restore()
    })

    describe('Disposition', function () {

        it('Default: DISPOSITION is COLUMN', function () {
            assert.equal(layoutStore.getDisposition(), Dispositions.COL)
        })

        it('Switch to ROW: DISPOSITION is ROW', function (done) {
            layoutStore.on('change', function () {
                assert.equal(layoutStore.getDisposition(), Dispositions.ROW)
                done()
            })

            dispatcher.dispatch({
                type: ActionTypes.SET_DISPOSITION,
                value: Dispositions.ROW
            })
        })
    })
})
