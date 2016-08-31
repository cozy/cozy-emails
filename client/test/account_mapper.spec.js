'use strict';

const assert = require('chai').assert

const Account = require('../app/models/account');
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
        let result = Account.from(rawAccount)
          .get('mailboxes');

        // assert
        assert.equal(result.size, 8);
      });

    });

  });

});
