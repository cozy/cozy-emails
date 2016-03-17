require('coffee-script/register')

var test = require('tape')
var tapSpec = require('tap-spec')
var mockery = require('mockery')
var sinon = require('sinon');

var SpecDispatcher = require('./utils/specs_dispatcher')

var Dispositions = require('../app/constants/app_constants').Dispositions
var ActionTypes = require('../app/constants/app_constants').ActionTypes


test.createStream()
    .pipe(tapSpec())
    .pipe(process.stdout)

var sandbox = sinon.sandbox.create()

test.onFinish(function() {
    sandbox.restore()
})

test('LayoutStore spec', function(t) {
    global.window = { innerWidth: 1600 }

    var dispatcher = new SpecDispatcher()

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

    var layoutStore = require('../app/stores/layout_store')

    t.test('Disposition', function (t) {
        t.plan(2)

        t.equal(layoutStore.getDisposition(), Dispositions.COL,
            'Default: DISPOSITION is COLUMN')

        layoutStore.on('change', function () {
            t.equal(layoutStore.getDisposition(), Dispositions.ROW,
                'Switch to ROW: DISPOSITION is ROW')
        })

        dispatcher.dispatch({
            type: ActionTypes.SET_DISPOSITION,
            value: Dispositions.ROW
        })
    })
});
