'use strict';
const assert = require('chai').assert;
const _ = require('lodash');

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;
const MailboxFlags = require('../app/constants/app_constants').MailboxFlags;

const AccountFixture = require('./fixtures/account');

const sinon = require('sinon');

describe('AccountStore', () => {
  let AccountStore;
  let Dispatcher;
  const account = AccountFixture.createAccount();
  let accounts = [];

  function testAccountValues(output, input) {
    output = output.toJS();
    if (undefined === input) input = account;

    // mailboxes is a specific case
    // if not specified it will be test afterwards
    delete output.mailboxes;
    _.each(output, (value, property) => {
      assert.equal(value, input[property]);
    });

    input.mailboxes.forEach((mailbox) => {
      testMailboxValues(input, mailbox);
    });
  }


  function testMailboxValues(account, mailbox) {
    let output = AccountStore.getMailbox(account.id, mailbox.id);
    assert.notEqual(output, undefined);
    assert.notEqual(output.size, 0);

    output = output.toJS();

    assert.equal(typeof output.order, 'number');
    delete output.order;

    assert.deepEqual(mailbox, output);
    assert.equal(mailbox.order, undefined);
  }


  function testSpecialMailbox (type, flag) {
    assert.notEqual(account[type], undefined);

    const mailbox = AccountStore.getMailbox(account.id, account[type]);
    assert.equal(account[type], mailbox.get('id'));

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
        assert.equal(mailbox.tree.indexOf(mailboxLabel), 0);
      }
    });
  }

  function isSpecialMailbox (type, flag) {
    const mailbox = AccountStore.getMailbox(account.id, account[type]);
    assert.equal(AccountStore.isInbox(account.id, account[type]), true);

    // Check for children
    const mailboxes = AccountStore.getAllMailboxes(account.id);
    mailboxes.forEach((mailbox) => {
      if (mailbox.attribs === undefined) {
        assert.equal(AccountStore.isInbox(account.id, mailbox.id), false);
      } else {
        const index = mailbox.attribs.indexOf(flag);
        assert.equal(AccountStore.isInbox(account.id, mailbox.id), index > -1);
      }
    });
  }


  before(() => {
    // Add preset accounts value
    // done serverside in real life
    accounts.push(account);
    accounts.push(AccountFixture.createAccount());
    accounts.push(AccountFixture.createAccount());
    accounts.push(AccountFixture.createAccount());
    accounts.push(AccountFixture.createAccount());
    accounts.push(AccountFixture.createAccount());
    accounts.push(AccountFixture.createAccount());
    global.window = { accounts };

    Dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(Dispatcher);
    mockeryUtils.initForStores(['../app/stores/account_store']);
    AccountStore = require('../app/stores/account_store');
  });

  after(() => {
    mockeryUtils.clean();
    delete global.window
  });


  describe('Methods', () => {

    it('getByID', () => {
      testAccountValues(AccountStore.getByID(account.id));
    });

    it('getAll', () => {
      accounts.forEach((input) => {
        testAccountValues(AccountStore.getByID(input.id), input);
      });
    });

    it('getAllMailboxes', () => {
      account.mailboxes.forEach((mailbox) => {
        testMailboxValues(account, mailbox);
      });
    });

    it('getInbox', () => {
      testSpecialMailbox('inboxMailbox', MailboxFlags.INBOX);
    });

    it('isInbox', () => {
      isSpecialMailbox('inboxMailbox', MailboxFlags.INBOX);
    });

    it('isTrashbox', () => {
      testSpecialMailbox('trashMailbox', MailboxFlags.TRASH);
      isSpecialMailbox('inboxMailbox', MailboxFlags.TRASH);
    });

    it('getAllMailbox', () => {

    });

    it('getMailboxOrder', () => {

    });

    it('getByMailbox', () => {
      testAccountValues(AccountStore.getByMailbox(account.mailboxes[0].id));
    });

    it('getDefault', () => {
      // Default mailbox should be inboxMailbox
      testAccountValues(AccountStore.getDefault());
    });

    it('getByLabel', () => {
      testAccountValues(AccountStore.getByLabel(account.label));
    });

  });


  describe('AccountActions', () => {

    // Test default Account values
    describe('_initialize()', () => {
      it('window.accounts should be stored', () => {
        assert.equal(AccountStore.getAll().size, accounts.length);
        Dispatcher.dispatch({
          type: ActionTypes.RESET_ACCOUNT_REQUEST,
        });
      });
    });


    describe('ADD_ACCOUNT_SUCCESS', () => {

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

      describe('Account.value', () => {
        it('should add a new item', () => {
          assert.equal(AccountStore.getAll().size, 1);
        });

        it('should be equal to its input value', () => {
          testAccountValues(AccountStore.getAll().get(account.id))
        });
      });

      describe('Account.mailboxes', () => {
        it('should have the same size than its input', () => {
            const output = AccountStore.getAll().get(account.id).get('mailboxes');
            assert.equal(_.toArray(output.toJS()).length, account.mailboxes.length);
        });

        it('should be sorted as CONST MailboxFlags', () => {
          const output = AccountStore.getByID(account.id).get('mailboxes');
          const defaultOrder = AccountStore.getMailboxOrder();
          const flags = _.toArray(MailboxFlags);

          _.toArray(output.toJS()).forEach((mailbox, index) => {
            let order = mailbox.order;
            let attribs = mailbox.attribs;

            // Get Mailbox.child right order
            // - get 1rst decimal if attribs.lenth is 1
            // - get 2nd decimal if attribs.lenth is 2
            // etc.
            if (mailbox.attribs != undefined) {
              const index = mailbox.attribs.length - 1;
              if (index > 0) {
                order = `${mailbox.order}`.split('.')[index];
                attribs = [mailbox.attribs[index]]
              }
            }

            const flag = flags[order]
            if (flag != undefined) {
              // Test order for each flagged mailbox
              assert.notEqual(attribs.indexOf(flag), -1);

            } else {
              // Unflagged mailbox always have the same order
              // alphanumeric sorted is applied then
              assert.equal(order, defaultOrder);

              // If this mailbox has flags
              // ensure that it is unknown flags
              if (attribs != undefined) {
                attribs.forEach((attrib) => {
                  assert.equal(flags.indexOf(flags), -1);
                });
              }
            }
          });
        });
      });
    });

    describe('EDIT_ACCOUNT_SUCCESS', () => {

      beforeEach(() => {
        Dispatcher.dispatch({
          type: ActionTypes.EDIT_ACCOUNT_SUCCESS,
          value: { rawAccount: account },
        });
      });

      afterEach(() => {
        Dispatcher.dispatch({
          type: ActionTypes.RESET_ACCOUNT_REQUEST,
        });
      });

      it('should add a new item', () => {
        testAccountValues(AccountStore.getAll().get(account.id))
      });
    });
  });


  describe('MailboxActions', () => {

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

    describe('MAILBOX_CREATE_SUCCESS', () => {
      it('should add a new item', () => {
        const mailbox = AccountFixture.createMailbox();

        Dispatcher.dispatch({
          type: ActionTypes.MAILBOX_CREATE_SUCCESS,
          value: mailbox,
        });

        testMailboxValues(account, mailbox);
      });
    });

    describe('RECEIVE_MAILBOX_CREATE', () => {
      it('should add a new item', () => {
        const mailbox = AccountFixture.createMailbox();

        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_MAILBOX_CREATE,
          value: mailbox,
        });

        testMailboxValues(account, mailbox);
      });
    });

    describe('MAILBOX_UPDATE_SUCCESS', () => {
      it('should update item', () => {
        const mailbox = AccountFixture.createMailbox();

        Dispatcher.dispatch({
          type: ActionTypes.MAILBOX_UPDATE_SUCCESS,
          value: mailbox,
        });

        testMailboxValues(account, mailbox);
      });
    });

    describe('RECEIVE_MAILBOX_UPDATE', () => {
      it('should update item', () => {
        const mailbox = AccountFixture.createMailbox();

        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_MAILBOX_UPDATE,
          value: mailbox,
        });

        testMailboxValues(account, mailbox);
      });
    });

    // it.skip('REMOVE_ACCOUNT_SUCCESS', () => {
    //   // FIXME Nothing is done here in the store code.
    // });
    // it('MAILBOX_DELETE_SUCCESS', () => {
    //   Dispatcher.dispatch({
    //     type: ActionTypes.MAILBOX_DELETE_SUCCESS,
    //     value: { id },
    //   });
    //   const accounts = AccountStore.getAll();
    //   assert.isUndefined(accounts.get(id).get('password'));
    // });
  });

});
