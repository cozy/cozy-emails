'use strict'

const assert = require('chai').assert

const AccountsLib = require('../app/libs/accounts')


// TODO: add a test to check relation
// between: security and port?

describe("Accountslibs spec", () => {

    describe("validateState", () => {

        it("should be validated", () => {
            const property = 'login'
            let value = 'mail@cozy.io'
            let input = { fields: { [`${property}`]: `${value}`} }
            let output = AccountsLib.validateState(input)

            // Should save input
            assert.isObject(output.fields)
            assert.property(output.fields, property)
            assert.propertyVal(output.fields, property, input.fields.login)

            // Should update value
            value = 'foo@gmail.com'
            input = { fields: { [`${property}`]: `${value}`} }
            output = AccountsLib.validateState(input)
            assert.propertyVal(output.fields, property, input.fields.login)
        })


        it("should always save `port` as a number", () => {
          const property = 'imapPort'
          let value = '993'
          let input = { fields: { [`${property}`]: `${value}`} }
          let output = AccountsLib.validateState(input)

          // Should save input
          assert.propertyVal(output.fields, property, +output.fields[property])

          // Should update value
          value = '143'
          input = { fields: { [`${property}`]: `${value}`} }
          output = AccountsLib.validateState(input)
          assert.propertyVal(output.fields, property, +output.fields[property])
        })

        it("should initialize 'imapLogin' and 'smtpLogin' when saving a login", () => {
            const property = 'login'
            let value = 'mail@cozy.io'
            let input = { fields: { [`${property}`]: `${value}`} }
            let output = AccountsLib.validateState(input)

            assert.equal(output.fields.imapLogin, value)
            assert.equal(output.fields.smtpLogin, value)

            // Should update value
            value = 'box@cozy.io'
            input = { fields: { [`${property}`]: `${value}`} }
            output = AccountsLib.validateState(input, output)

            assert.equal(output.fields.imapLogin, value)
            assert.equal(output.fields.smtpLogin, value)
        })

        it("should leave imap / smtp login properties untouched when they differ from login", () => {
            let previousState = { fields: {imapLogin: 'cozy', smtpLogin: 'yzoc'} }
            let input = { fields: {'login': 'mail@cozy.io'} }
            let output = AccountsLib.validateState(input, previousState)

            assert.notProperty(output.fields, 'imapLogin')
            assert.notProperty(output.fields, 'smtpLogin')

            // Updating login
            // force update of imapLogin and smtpLogin
            previousState = {imapLogin: 'cozy'}
            input = { fields: {'login': 'mail@cozy.io'} }
            output = AccountsLib.validateState(input, previousState)

            assert.equal(output.fields.imapLogin, input.fields.login)
            assert.equal(output.fields.smtpLogin, input.fields.login)
        })

        it("should update imap / smtp password properties too when they're not custom", () => {
            let input = { fields: {'password': 'cozy'} }
            let output = AccountsLib.validateState(input)

            assert.equal(output.fields.password, input.fields.password)
            assert.equal(output.fields.smtpPassword, input.fields.password)
            assert.equal(output.fields.imapPassword, input.fields.password)

            // Should update value
            input = { fields: {'password': 'mail@cozy.io'} }
            output = AccountsLib.validateState(input, output)

            assert.equal(output.fields.smtpPassword, input.fields.password)
            assert.equal(output.fields.imapPassword, input.fields.password)
        })

        // FIXME: discover is not working anymore
        // since Redux Migration
        it.skip("should restore autodiscover when update login w/ untouched servers", () => {
            let state = {login: 'mail@cozy', isDiscoverable: false}
            let nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, state)

            assert.property(nextState, 'isDiscoverable')
            assert.propertyVal(nextState, 'isDiscoverable', true)

            state.imapServer = 'imap.cozy.io'
            nextState = AccountsLib.validateState({'login': 'mail@cozy.io'}, state)

            assert.notProperty(nextState, 'isDiscoverable')
        })

    })

    describe('mergeWithStore', () => {
      it.skip('should add requestStore properties (repart activity)', () => { })
    })

    describe('filterPropsByProvider', () => {
      it.skip('should return properties relalated to provider', () => { })
    })

    describe('getProviderProps', () => {
      it.skip('should return properties from provider', () => { })
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
      let payload;
      let expectedKeys;
      let state;


      before(() => {
        expectedKeys = [
          'login',
          'label',
          'name',
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

        state = {
          'account': null,
          'mailboxID': null,

          'OAuth': false,

          'alert': null,

          'isBusy': false,
          'disable': false,
          'expanded': false,

          'fields': {
            'login': 'mail@cozy.io',
            'password': 'cozy',

            'imapServer': 'imap.cozy.io',
            'imapPort': 993,
            'imapSecurity': 'ssl',
            'imapLogin': 'mail@cozy.io',
            'imapPassword': 'cozy',

            'smtpServer': 'smtp.cozy.io',
            'smtpPort': 587,
            'smtpSecurity': 'starttls',
            'smtpLogin': null,
            'smtpLogin': 'mail@cozy.io',
            'smtpPassword': 'cozy',
          },
        }

        payload = AccountsLib.sanitizeConfig(state)
      })


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
