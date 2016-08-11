'use strict';

const assert = require('chai').assert
const Immutable = require('immutable');

const accountMapper = require('../app/libs/mappers/account');
const accountFixture = require('./fixtures/account');


describe('Account Mapper', () => {

  describe('Methods', () => {

    describe('formatAccount', () => {

      it('should map mailboxes', () => {
        // arrange
        let rawAccount = accountFixture.createAccount({
          randomizeAdditionalMailboxes: false
        });

        // act
        let result = accountMapper
          .formatAccount(rawAccount)
          .get('mailboxes');

        // assert
        assert.equal(result.size, 8);
      });

    });

  });

});
