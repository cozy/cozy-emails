should = require 'should'
helpers = require './helpers'

helpers.initGlobals()
AccountStore = dispatch = null
{ActionTypes} = require '../../client/app/constants/app_constants'

describe 'AccountStore initialized without account', ->

    before ->
        helpers.setWindowVariable accounts: []
        {Store: AccountStore, dispatch} = helpers.getCleanStore 'account_store'

    it "Then default account is null", ->
        should.not.exist AccountStore.getDefault()

    it 'When i send a request to create an account', ->
        dispatch ActionTypes.ADD_ACCOUNT_REQUEST, {}

    it 'Then the default account is still null', ->
        should.not.exist AccountStore.getDefault()

    it 'Then AccountStore.isWaiting is true', ->
        AccountStore.isWaiting().should.be.true

    it 'When i receive a successful response (with no mailboxes)', ->
        dispatch ActionTypes.ADD_ACCOUNT_SUCCESS, account:
            id: 'testid'
            label: 'test'
            login: 'tester'
            mailboxes: []

    it 'Then the default account is the one I created', ->
        defaultAccount = AccountStore.getDefault()
        should.exist defaultAccount
        defaultAccount.should.be.instanceOf Immutable.Map
        defaultAccount.get('id').should.equal 'testid'

    it 'Then the created account should be selected', ->
        AccountStore.getSelected().get('id').should.equal 'testid'
        AccountStore.getSelectedOrDefault().get('id').should.equal 'testid'

    it 'Then AccountStore.isWaiting is false', ->
        AccountStore.isWaiting().should.be.false

    it 'Then AccountStore should have a nomailboxes error', ->
        noMailboxErr = AccountStore.getErrors().get('nomailboxes')
        noMailboxErr.message.should.equal 'translated config error nomailboxes'

    it 'When i send a request to create a second account', ->
        dispatch ActionTypes.ADD_ACCOUNT_REQUEST, {}

    it 'Then the default account is the previously created', ->
        AccountStore.getDefault().get('id').should.equal 'testid'

    it 'Then AccountStore.isWaiting is true', ->
        AccountStore.isWaiting().should.be.true

    it 'When i receive an error response', ->
        dispatch ActionTypes.ADD_ACCOUNT_FAILURE, error:
            name: 'AccountConfigError'
            field: 'smtp'
            causeFields: ['smtp', 'smtpLogin', 'smtpPort']

    it 'Then the default account is still the same', ->
        AccountStore.getDefault().get('id').should.equal 'testid'

    it 'Then AccountStore.isWaiting is false', ->
        AccountStore.isWaiting().should.be.false

    it 'Then AccountStore should have some errors', ->
        should.exist AccountStore.getErrors().get('smtp')
        error = AccountStore.getErrors().get('smtp')
        error.message.should.equal 'translated config error smtp'
        error.should.equal AccountStore.getErrors().get('smtpLogin')
        error.should.equal AccountStore.getErrors().get('smtpPort')

TEST_ACCOUNT =
    id: 'testid'
    label: 'test'
    login: 'tester'
    mailboxes: []

describe 'AccountStore initialized with accounts', ->

    before ->
        helpers.setWindowVariable accounts: [TEST_ACCOUNT]
        {Store: AccountStore, dispatch} = helpers.getCleanStore 'account_store'

    it "Then default account is the first", ->
        AccountStore.getDefault().get('id').should.equal 'testid'

    it "Then selected account should be null", ->
        should.not.exist AccountStore.getSelected()

    it 'Then selectedOrDefault should be first', ->
        AccountStore.getSelectedOrDefault().get('id').should.equal 'testid'
