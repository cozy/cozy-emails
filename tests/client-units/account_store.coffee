global.Immutable = require 'immutable'
global.EventEmitter = require('events').EventEmitter
global.window = accounts: []
should = require 'should'


AccountStore = require '../../client/app/stores/account_store'

describe 'AccountStore', ->

    it "Default account is null", ->
        defaultAccount = AccountStore.getDefault()
        should.not.exist defaultAccount




