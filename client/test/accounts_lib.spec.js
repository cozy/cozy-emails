'use strict'

const assert = require('chai').assert

const AccountsLib = require('../app/libs/accounts')


describe("Accounts libs spec", () => {

    describe("Validate and returns a new state", () => {

        it("should returns a simple value in a new state", () => {
            let state = {}
            let nextState = AccountsLib.validateState('login', 'mail@cozy.io', state)

            assert.isObject(nextState)
            assert.notEqual(state, nextState)
            assert.property(nextState, 'login')
            assert.propertyVal(nextState, 'login', 'mail@cozy.io')
        })

        it("should override value if value already present in state", () => {
            let state = {login: 'foo@gmail.com'}
            let nextState = AccountsLib.validateState('login', 'mail@cozy.io', state)

            assert.propertyVal(nextState, 'login', 'mail@cozy.io')
        })

        it("should ensure that `port` value is always a number", () => {
            let nextState = AccountsLib.validateState('port', 143, {})
            assert.isNumber(nextState.port)

            nextState = AccountsLib.validateState('port', '993', {})
            assert.isNumber(nextState.port)
        })

        it("should update imap / smtp login properties too when they're not custom", () => {
            let nextState = AccountsLib.validateState('login', 'mail@cozy.io', {})

            assert.property(nextState, 'imapLogin')
            assert.property(nextState, 'smtpLogin')
            assert.propertyVal(nextState, 'imapLogin', nextState.login)
            assert.propertyVal(nextState, 'smtpLogin', nextState.login)

            nextState = AccountsLib.validateState('login', 'box@cozy.io', nextState)

            assert.propertyVal(nextState, 'imapLogin', nextState.login)
            assert.propertyVal(nextState, 'smtpLogin', nextState.login)
        })

        it("should leave imap / smtp login properties untouched when they differ from login", () => {
            let state = {imapLogin: 'cozy', smtpLogin: 'yzoc'}
            let nextState = AccountsLib.validateState('login', 'mail@cozy.io', state)

            assert.notProperty(nextState, 'imapLogin')
            assert.notProperty(nextState, 'smtpLogin')

            state = {imapLogin: 'cozy'}
            nextState = AccountsLib.validateState('login', 'mail@cozy.io', state)

            assert.notProperty(nextState, 'imapLogin')
            assert.property(nextState, 'smtpLogin')
            assert.propertyVal(nextState, 'smtpLogin', nextState.login)
        })

        it("should update imap / smtp password properties too when they're not custom", () => {
            let nextState = AccountsLib.validateState('password', 'cozy', {})

            assert.property(nextState, 'imapPassword')
            assert.property(nextState, 'smtpPassword')
            assert.propertyVal(nextState, 'imapPassword', nextState.password)
            assert.propertyVal(nextState, 'smtpPassword', nextState.password)

            nextState = AccountsLib.validateState('password', 'mail@cozy.io', nextState)

            assert.propertyVal(nextState, 'imapPassword', nextState.password)
            assert.propertyVal(nextState, 'smtpPassword', nextState.password)
        })

        it("should restore autodiscover when update login w/ untouched servers", () => {
            let state = {login: 'mail@cozy', isDiscoverable: false}
            let nextState = AccountsLib.validateState('login', 'mail@cozy.io', state)

            assert.property(nextState, 'isDiscoverable')
            assert.propertyVal(nextState, 'isDiscoverable', true)

            state.imapServer = 'imap.cozy.io'
            nextState = AccountsLib.validateState('login', 'mail@cozy.io', state)

            assert.notProperty(nextState, 'isDiscoverable')
        })

    })

});
