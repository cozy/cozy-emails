'use strict'

const assert = require('chai').assert

const AccountsLib = require('../app/libs/accounts')


describe("Accounts libs spec", () => {

    describe("Validate and returns a new state", () => {

        it("should returns a simple value in a new state", () => {
            let state = {}
            let nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, state)

            assert.isObject(nextState)
            assert.notEqual(state, nextState)
            assert.property(nextState, 'login')
            assert.propertyVal(nextState, 'login', 'mail@cozy.io')
        })

        it("should override value if value already present in state", () => {
            let state = {login: 'foo@gmail.com'}
            let nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, state)

            assert.propertyVal(nextState, 'login', 'mail@cozy.io')
        })

        it("should ensure that `port` value is always a number", () => {
            let nextState = AccountsLib.validateState({'port': '143'}, {})
            assert.isNumber(nextState.port)

            nextState = AccountsLib.validateState({'port': '993'}, {})
            assert.isNumber(nextState.port)
        })

        it("should update imap / smtp login properties too when they're not custom", () => {
            let nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, {})

            assert.property(nextState, 'imapLogin')
            assert.property(nextState, 'smtpLogin')
            assert.propertyVal(nextState, 'imapLogin', nextState.login)
            assert.propertyVal(nextState, 'smtpLogin', nextState.login)

            nextState = AccountsLib.validateState({'login': 'box@cozy.io'}, nextState)

            assert.propertyVal(nextState, 'imapLogin', nextState.login)
            assert.propertyVal(nextState, 'smtpLogin', nextState.login)
        })

        it("should leave imap / smtp login properties untouched when they differ from login", () => {
            let state = {imapLogin: 'cozy', smtpLogin: 'yzoc'}
            let nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, state)

            assert.notProperty(nextState, 'imapLogin')
            assert.notProperty(nextState, 'smtpLogin')

            state = {imapLogin: 'cozy'}
            nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, state)

            assert.notProperty(nextState, 'imapLogin')
            assert.property(nextState, 'smtpLogin')
            assert.propertyVal(nextState, 'smtpLogin', nextState.login)
        })

        it("should update imap / smtp password properties too when they're not custom", () => {
            let nextState = AccountsLib.validateState({'password': 'cozy'}, {})

            assert.property(nextState, 'imapPassword')
            assert.property(nextState, 'smtpPassword')
            assert.propertyVal(nextState, 'imapPassword', nextState.password)
            assert.propertyVal(nextState, 'smtpPassword', nextState.password)

            nextState = AccountsLib.validateState({'password': 'mail@cozy.io'}, nextState)

            assert.propertyVal(nextState, 'imapPassword', nextState.password)
            assert.propertyVal(nextState, 'smtpPassword', nextState.password)
        })

        it("should restore autodiscover when update login w/ untouched servers", () => {
            let state = {login: 'mail@cozy', isDiscoverable: false}
            let nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, state)

            assert.property(nextState, 'isDiscoverable')
            assert.propertyVal(nextState, 'isDiscoverable', true)

            state.imapServer = 'imap.cozy.io'
            nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, state)

            assert.notProperty(nextState, 'isDiscoverable')
        })

    })


    describe("Parse providers to return part of state", () => {

        let providers, nextState

        beforeEach(() => {
            nextState = AccountsLib.getProviderProps(providers)
        })

        describe("Parse valid provider settings", () => {
            before(() => {
                providers = [{
                    "type": "imap",
                    "hostname": "mail.gandi.net",
                    "port": "993",
                    "socketType": "SSL"
                }, {
                    "type": "imap",
                    "hostname": "mail.gandi.net",
                    "port": "143",
                    "socketType": "STARTTLS"
                }, {
                    "type": "pop3",
                    "hostname": "mail.gandi.net",
                    "port": "995",
                    "socketType": "SSL"
                }, {
                    "type": "pop3",
                    "hostname": "mail.gandi.net",
                    "port": "110",
                    "socketType": "STARTTLS"
                }, {
                    "type": "smtp",
                    "hostname": "mail.gandi.net",
                    "port": "465",
                    "socketType": "SSL"
                }, {
                    "type": "smtp",
                    "hostname": "mail.gandi.net",
                    "port": "587",
                    "socketType": "STARTTLS"
                }]
            })

            it("should return a state containing IMAP and SMTP infos", () => {
                assert.isObject(nextState)
                assert.property(nextState, 'imapServer')
                assert.property(nextState, 'smtpServer')
            })

            it("should extract Provider settings", () => {
                assert.propertyVal(nextState, 'imapServer', providers[1].hostname)
                assert.propertyVal(nextState, 'imapPort', +providers[1].port)
                assert.propertyVal(nextState, 'imapSecurity', providers[1].socketType.toLowerCase())
            })

        })

        describe("Fallback settings", () => {
            before(() => {
                providers = [{
                    "type": "imap",
                    "hostname": "imap.free.fr",
                    "port": "993",
                    "socketType": "SSL"
                }, {
                    "type": "pop3",
                    "hostname": "pop.free.fr",
                    "port": "995",
                    "socketType": "SSL"
                }, {
                    "type": "smtp",
                    "hostname": "smtp.free.fr",
                    "port": "25",
                    "socketType": "plain"
                }]
            })

            it("should disable security if none is available", () => {
                assert.propertyVal(nextState, 'smtpSecurity', 'none')
            })

        })

    })


    describe('Sanitize state to returns a proper server config', () => {

        const expectedKeys = [
            'label',
            'name',
            'login',
            'password',
            'smtpServer',
            'smtpLogin',
            'smtpPassword',
            'smtpPort',
            'smtpSSL',
            'smtpTLS',
            'imapServer',
            'imapLogin',
            'imapPassword',
            'imapPort',
            'imapSSL',
            'imapTLS'
        ]

        const state = {
            "isBusy": false,
            "isDiscoverable": false,
            "alert": null,
            "OAuth": false,
            "imapPort": 993,
            "imapSecurity": "ssl",
            "smtpPort": 587,
            "smtpSecurity": "starttls",
            "enableSubmit": true,
            "imapLogin": "mail@cozy.io",
            "imapPassword": "cozy",
            "smtpLogin": "mail@cozy.io",
            "smtpPassword": "cozy",
            "login": "mail@cozy.io",
            "password": "cozy",
            "imapServer": "imap.cozy.io",
            "smtpServer": "smtp.cozy.io"
        }

        const payload = AccountsLib.sanitizeConfig(state)

        it("should only contains expected keys", () => {
            assert.sameMembers(Object.keys(payload), expectedKeys)
        })

        it("should use email address prefix as name", () => {
            const prefix = state.login.split('@')[0]
            assert.propertyVal(payload, 'name', prefix)
        })

        it("should use email address as label", () => {
            assert.propertyVal(payload, 'label', state.login)
        })

        it("should transcript security booleans", () => {
            assert.propertyVal(payload, 'imapSSL', true)
            assert.propertyVal(payload, 'imapTLS', false)
            assert.propertyVal(payload, 'smtpSSL', false)
            assert.propertyVal(payload, 'smtpTLS', true)
        })

    })

});
