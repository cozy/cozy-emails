/* eslint-env mocha */

'use strict';
const assert = require('chai').assert;
const _ = require('lodash');

const ActionTypes = require('../app/constants/app_constants').ActionTypes;
const MailboxFlags = require('../app/constants/app_constants').MailboxFlags;

const AccountFixture = require('./fixtures/account');
const makeTestDispatcher = require('./utils/specs_dispatcher');
const AccountGetter = require('../app/getters/account');


describe('AccountStore', () => {
  let AccountStore;
  let Dispatcher;
  const account = AccountFixture.createAccount();
  const accounts = [];

  function testAccountValues(output, input) {
    output = output.toJS();

    // mailboxes is a specific case
    // if not specified it will be test afterwards
    _.each(output, (value, property) =>
      property === 'mailboxes' || assert.equal(value, input[property])
    );

    input.mailboxes.forEach((mailbox) => {
      testMailboxValues(input, mailbox);
    });
  }


  function testMailboxValues(account, mailbox) {
    let output = AccountStore.getMailbox(mailbox.id);
    if (output === undefined) {
      // eslint-disable-next-line no-console
      console.log('DAFUQ situation', mailbox, mailbox.id,
      account, AccountStore.getAll());
    }
    assert.notEqual(output, undefined);
    assert.notEqual(output.size, 0);

    output = output.toJS();

    if (mailbox.order === undefined) {
      delete output.order;
    }

    assert.deepEqual(mailbox, output);
  }


  function testSpecialMailbox(mailbox, flag) {
    // Check Tree
    const mailboxLabel = mailbox.get('label');
    assert.notEqual(mailboxLabel, undefined);
    assert.notEqual(mailbox.get('tree'), undefined);
    assert.equal(mailboxLabel, mailbox.get('tree').join(''));
    assert.equal(mailbox.get('tree').length, 1);

    // Check for children
    const mailboxes = AccountStore.getAllMailboxes(account.id);
    mailboxes.forEach((mailbox) => {
      if (mailbox.attribs === undefined) return;
      const index = mailbox.attribs.indexOf(flag);
      if (index > -1) {
        assert.equal(index, 0);
        assert.notEqual(mailbox.tree, undefined);
        // assert.equal(mailbox.tree.indexOf(mailboxLabel), 0);
      }
    });
  }

  function isSpecialMailbox(/* flag */) {
    // Check for children
    const mailboxes = AccountStore.getAllMailboxes(account.id);
    mailboxes.forEach((mailbox) => {
      if (mailbox.attribs === undefined) {
        assert.equal(AccountStore.isInbox(account.id, mailbox.id), false);
      } else {
     // const index = mailbox.attribs.indexOf(flag);
    // assert.equal(AccountStore.isInbox(account.id, mailbox.id), index > -1);
      }
    });
  }


  before(() => {
    // Add preset accounts value
    // done serverside in real life
    accounts.push(account);
    accounts.push(AccountFixture.createAccount());
    // accounts.push(AccountFixture.createAccount());
    // accounts.push(AccountFixture.createAccount());
    // accounts.push(AccountFixture.createAccount());
    // accounts.push(AccountFixture.createAccount());
    // accounts.push(AccountFixture.createAccount());
    global.window = { accounts };
    global.t = (x) => x;

    const tools = makeTestDispatcher();
    Dispatcher = tools.Dispatcher;
    AccountStore = tools.makeStateFullGetter(AccountGetter);
  });

  after(() => {
    // mockeryUtils.clean();
    delete global.window;
    delete global.t;
  });


  describe('Methods', () => {
    it('getByID', () => {
      testAccountValues(AccountStore.getByID(account.id), account);
    });

    it('getAll', () => {
      accounts.forEach((input) => {
        // console.log(input.id);
        testAccountValues(AccountStore.getByID(input.id), input);
      });
    });

    it('getDefault', () => {
      const input = accounts[0];
      testAccountValues(AccountStore.getDefault(), input);
    });

    it('getAllMailboxes', () => {
      account.mailboxes.forEach((mailbox) => {
        testMailboxValues(account, mailbox);
      });
    });

    it('getInbox', () => {
      const flag = MailboxFlags.INBOX;
      const mailbox = AccountStore.getInbox(account.id);
      const inboxMailbox = account.inboxMailbox;
      const mailbox0 = AccountStore.getMailbox(inboxMailbox);
      const mailbox1 = AccountStore.getAllMailboxes(account.id)
      .find((mailbox) =>
        mailbox.get('attribs') && mailbox.get('attribs').indexOf(flag) >= -1
      );
      assert.notEqual(mailbox, undefined);
      assert.equal(mailbox, mailbox0);
      assert.equal(mailbox, mailbox1);

      testSpecialMailbox(mailbox, flag);
    });

    it('isInbox', () => {
      const mailbox = AccountStore.getInbox(account.id);

      assert.notEqual(mailbox, undefined);
      assert.equal(AccountStore.isInbox(account.id, mailbox.get('id')), true);
      isSpecialMailbox(MailboxFlags.INBOX);
    });

    it('isTrashbox', () => {
      const flag = MailboxFlags.TRASH;
      const mailbox = AccountStore.getMailbox(account.trashMailbox);

      assert.notEqual(mailbox, undefined);
      const isTrashbox = AccountStore.isTrashbox(account.id, mailbox.get('id'));
      assert.equal(isTrashbox, true);
      testSpecialMailbox(mailbox, flag);
      isSpecialMailbox(flag);
    });

    it('getAllMailbox', () => {
      const flag = MailboxFlags.ALL;
      const output = AccountStore.getAllMailboxes(account.id)
      .find((mailbox) =>
        mailbox.get('attribs') && mailbox.get('attribs').indexOf(flag) >= -1
      );

      assert.notEqual(output, undefined);
      testSpecialMailbox(output, MailboxFlags.ALL);
      isSpecialMailbox(MailboxFlags.ALL);
    });

    it('getMailboxOrder', () => {
      const mailboxes = AccountStore.getAllMailboxes(account.id);
      account.mailboxes.forEach((mailbox) => {
        const output = mailboxes.get(mailbox.id);
        const order = AccountStore.getMailboxOrder(account.id, mailbox.id);

        assert.equal(mailbox.order, undefined);
        assert.equal(order, output.get('order'));
      });

      // Should return default value
      assert.equal(AccountStore.getMailboxOrder(), 100);
      assert.equal(AccountStore.getMailboxOrder(account.id, null), 100);
      const order = AccountStore.getMailboxOrder(null, account.inboxMailbox);
      assert.equal(order, 100);
    });

    it('getByMailbox', () => {
      testAccountValues(
        AccountStore.getByMailbox(account.mailboxes[0].id), account);
    });

    it('getDefault', () => {
      const account0 = AccountStore.getDefault();
      testAccountValues(account0, accounts[0]);

      const account1 = AccountStore.getDefault(accounts[1].inboxMailbox);
      testAccountValues(account1, accounts[1]);
    });

    it('getByLabel', () => {
      testAccountValues(AccountStore.getByLabel(account.label), account);
    });
  });


  describe('Actions', () => {
    after(() => {
      Dispatcher.dispatch({
        type: ActionTypes.RESET_ACCOUNT_REQUEST,
      });
    });

    describe('Should ADD account(s)', () => {
      it('REQUIRE', () => {
        // window.accounts should be stored
        assert.equal(AccountStore.getAll().size, accounts.length);
      });

      it('ADD_ACCOUNT_SUCCESS', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ADD_ACCOUNT_SUCCESS,
          value: { account: AccountFixture.createAccount() },
        });

        const output = AccountStore.getAll().get(account.id);

        // should ADD a new account
        assert.equal(AccountStore.getAll().size, accounts.length + 1);
        testAccountValues(output, account);

        // Should ADD mailboxes
        const mailboxes = output.get('mailboxes');
        assert.equal(mailboxes.toArray().length, account.mailboxes.length);

        // Should be sorted in the same order
        // than into MailboxFlags
        // const defaultOrder = AccountStore.getMailboxOrder();
        // const flags = _.toArray(MailboxFlags);
        // _.toArray(mailboxes.toJS()).forEach((mailbox) => {
        //   let order = mailbox.order;
        //   let attribs = mailbox.attribs;
        //
        //   // Get Mailbox.child right order
        //   // - get 1rst decimal if attribs.lenth is 1
        //   // - get 2nd decimal if attribs.lenth is 2
        //   // etc.
        //   if (mailbox.attribs !== undefined) {
        //     const index = mailbox.attribs.length - 1;
        //     if (index > 0) {
        //       order = `${mailbox.order}`.split('.')[index];
        //       attribs = [mailbox.attribs[index]];
        //     }
        //   }
        //
        //   const flag = flags[order];
        //   if (flag !== undefined) {
        //     // Test order for each flagged mailbox
        //     assert.notEqual(attribs.indexOf(flag), -1);
        //   } else {
        //     // Unflagged mailbox always have the same order
        //     // alphanumeric sorted is applied then
        //     assert.equal(order, defaultOrder);
        //
        //     // If this mailbox has flags
        //     // ensure that it is unknown flags
        //     if (attribs !== undefined) {
        //       attribs.forEach((attrib) => {
        //         assert.equal(flags.indexOf(flags), -1);
        //       });
        //     }
        //   }
        // });
      });
    });

    // TODO: add missing tests
    // RECEIVE_ACCOUNT_UPDATE
    describe('Should UPDATE account(s)', () => {
      beforeEach(() => {
        Dispatcher.dispatch({
          type: ActionTypes.ADD_ACCOUNT_SUCCESS,
          value: { account },
        });
      });

      afterEach(() => {
        Dispatcher.dispatch({
          type: ActionTypes.RESET_ACCOUNT_REQUEST,
        });
      });

      it('EDIT_ACCOUNT_SUCCESS', () => {
        Dispatcher.dispatch({
          type: ActionTypes.EDIT_ACCOUNT_SUCCESS,
          value: { rawAccount: account },
        });

        testAccountValues(AccountStore.getAll().get(account.id), account);
      });

      it('RECEIVE_ACCOUNT_UPDATE', () => {
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_ACCOUNT_UPDATE,
          value: account,
        });

        testAccountValues(AccountStore.getAll().get(account.id), account);
      });

      it('MAILBOX_CREATE_SUCCESS', () => {
        const mailbox = AccountFixture.createMailbox();
        mailbox.accountID = account.id;

        Dispatcher.dispatch({
          type: ActionTypes.MAILBOX_CREATE_SUCCESS,
          value: mailbox,
        });

        const mailbox2 = AccountStore.getMailbox(mailbox.id);
        testMailboxValues(account, mailbox2.toJS());
      });

      it('RECEIVE_MAILBOX_CREATE', () => {
        const mailbox = AccountFixture.createMailbox();
        mailbox.accountID = account.id;

        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_MAILBOX_CREATE,
          value: mailbox,
        });

        const mailbox2 = AccountStore.getMailbox(mailbox.id);
        testMailboxValues(account, mailbox2.toJS());
      });

      it('MAILBOX_UPDATE_SUCCESS', () => {
        const mailbox = AccountFixture.createMailbox();
        mailbox.id = AccountStore.getAll().first().mailboxes.first().id;
        mailbox.label = 'toto';

        Dispatcher.dispatch({
          type: ActionTypes.MAILBOX_UPDATE_SUCCESS,
          value: mailbox,
        });

        const mailbox2 = AccountStore.getMailbox(mailbox.id);
        assert.equal(mailbox2.get('label'), 'toto');
        testMailboxValues(account, mailbox2.toJS());
      });

      it('RECEIVE_MAILBOX_UPDATE', () => {
        const mailbox = AccountFixture.createMailbox();
        mailbox.id = AccountStore.getAll().first().mailboxes.first().id;
        mailbox.label = 'tata';


        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_MAILBOX_UPDATE,
          value: mailbox,
        });

        const mailbox2 = AccountStore.getMailbox(mailbox.id);
        assert.equal(mailbox2.get('label'), 'tata');
        testMailboxValues(account, mailbox);
      });

      it.skip('MAILBOX_DELETE_SUCCESS', () => {
        // It should remove mailboxID from
        // - all messages.mailboxIDs
        // - account.mailboxes
      });

      it.skip('MAILBOX_EXPUNGE', () => {
        // # TODO: should update account counter
        // # if a mailbox came empty
        // # - mailbox.nbTotal should be equal to 0
        // # - account.nbTotal shoudl also be updated: missing args to do this
      });
    });


    describe('Should REMOVE account(s)', () => {
      beforeEach(() => {
        Dispatcher.dispatch({
          type: ActionTypes.ADD_ACCOUNT_SUCCESS,
          value: { account },
        });
      });
      it('REMOVE_ACCOUNT_SUCCESS', () => {
        const sizebefore = AccountStore.getAll().size;
        const first = AccountStore.getAll().first();
        const mailbox = first.get('mailboxes').first();

        Dispatcher.dispatch({
          type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
          value: { accountID: first.get('id') },
        });

        assert.equal(AccountStore.getAll().size, sizebefore - 1);
        assert.equal(AccountStore.getAll().find((account) =>
            account.get('id') === first.get('id')), undefined);
        assert.equal(AccountStore.getMailbox(mailbox.get('id')), undefined);
      });
    });
  });
});
