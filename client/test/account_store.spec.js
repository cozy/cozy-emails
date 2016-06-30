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
  let account = AccountFixture.createAccount();

  before(() => {
    Dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(Dispatcher);
    mockeryUtils.initForStores(['../app/stores/account_store']);
    AccountStore = require('../app/stores/account_store');
  });

  after(() => {
    mockeryUtils.clean();
  });

  beforeEach(() => {
    Dispatcher.dispatch({
      type: ActionTypes.ADD_ACCOUNT_SUCCESS,
      value: { account: _.clone(account) },
    });
  });

  afterEach(() => {
    Dispatcher.dispatch({
      type: ActionTypes.RESET_ACCOUNT_REQUEST,
    });
  });


  // TODO: should test window.accounts
  // is these accounts are added?
  // tets AccountStore._initlaize
  describe('_initialize()', () => {

    // TODO: how to fake window value?!
    it('window.accounts should be stored', () => { });
  });

  /*
   * Problem noticed in the store file:
   *
   * FIXME Remove mailbox event doesn't do anything.
   * FIXME getDefault method can be used as getByMailbox.
   */
  describe('Actions', () => {

    describe('ADD_ACCOUNT_SUCCESS', () => {

      describe('Account', () => {
        it('should be equal to its input value', () => {

        });
      });

      describe('Account.mailboxes', () => {
        it('should be equal to its input value', () => {
            // const output = AccountStore.getAll().get(account.id).get('mailboxes');



            // assert.equal(_.toArray(mailboxesStored.toJS()), account.mailboxes);
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
              // alphanumeric sorted is applied
              assert.equal(order, defaultOrder);

              // If this mailbox has flags
              // ensure that its not known flags
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

    // // TODO: add test on account_update;
    // // data should always be formatted/filtered/sorted
    // // such as account_create
    // // - RECEIVE_MAILBOX_CREATE
    // // - RECEIVE_MAILBOX_UPDATE
    // it('EDIT_ACCOUNT_SUCCESS', () => {
    //   console.log(AccountStore.getAll().size)
    //   // Dispatcher.dispatch({
    //   //   type: ActionTypes.EDIT_ACCOUNT_SUCCESS,
    //   //   value: { rawAccount: { id, login } },
    //   // });
    //   // const accounts = AccountStore.getAll();
    //   // assert.equal(accounts.get(id).get('login'), login);
    // });

    // it('MAILBOX_CREATE_SUCCESS', () => {
    //   Dispatcher.dispatch({
    //     type: ActionTypes.MAILBOX_CREATE_SUCCESS,
    //     value: { id, login, initialized: true },
    //   });
    //   const accounts = AccountStore.getAll();
    //   assert.equal(accounts.get(id).get('initialized'), true);
    // });
    // it('MAILBOX_UPDATE_SUCCESS', () => {
    //   Dispatcher.dispatch({
    //     type: ActionTypes.MAILBOX_UPDATE_SUCCESS,
    //     value: {
    //       id, login, password, initialized: true,
    //     },
    //   });
    //   const accounts = AccountStore.getAll();
    //   assert.equal(accounts.get(id).get('password'), password);
    // });
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
    // it('RECEIVE_MAILBOX_UPDATE', () => {
    //   Dispatcher.dispatch({
    //     type: ActionTypes.RECEIVE_MAILBOX_UPDATE,
    //     value: { id: mailboxId, label },
    //   });
    //   const accounts = AccountStore.getAll();
    //   const mailbox = accounts.get(id2).get('mailboxes').get(mailboxId);
    //   assert.equal(mailbox.get('label'), label);
    // });
  });
  //
  // describe('Methods', () => {
  //   // const id1 = fixtures.account1.id;
  //   // const id2 = fixtures.account2.id;
  //   // const label = 'mailbox-edited';
  //   // const mailboxLabel = fixtures.account2.mailboxes[1].label;
  //   // const mailboxId1 = fixtures.account2.mailboxes[0].id;
  //   // const mailboxId2 = fixtures.account2.mailboxes[1].id;
  //
  //
  //   it('getByID', () => {
  //     const account = AccountStore.getByID(id2);
  //     assert.equal(account.get('id'), id2);
  //   });
  //   it('getByMailbox', () => {
  //     const account = AccountStore.getByMailbox(mailboxId1);
  //     assert.equal(account.get('id'), id2);
  //   });
  //   it('getDefault', () => {
  //     const account = AccountStore.getDefault();
  //     assert.equal(account.get('id'), id1);
  //   });
  //   it('getByLabel', () => {
  //     const account = AccountStore.getByLabel('pro');
  //     assert.equal(account.get('id'), id2);
  //   });
  //   // TODO: add test for mailbox mappinf
  //   // no attribs Case
  //   // no tree cases
  //
  //   //  TODO: add test for OVH know issues
  //   //  TODO: add test for GMAIL know issues
  //   it('getAllMailboxes', () => {
  //     let mailboxes = AccountStore.getAllMailboxes(id2);
  //     assert.deepEqual(mailboxes.get(mailboxId1).toObject(), {
  //       id: mailboxId1,
  //       label,
  //       attribs: undefined,
  //       tree: undefined,
  //       accountID: id2,
  //     });
  //     assert.deepEqual(mailboxes.get(mailboxId2).toObject(), {
  //       id: mailboxId2,
  //       label: mailboxLabel,
  //       attribs: undefined,
  //       tree: undefined,
  //       accountID: id2,
  //     });
  //     mailboxes = AccountStore.getAllMailboxes();
  //     assert.isUndefined(mailboxes);
  //   });
  //   it('makeEmptyAccount', () => {
  //     const account = AccountStore.makeEmptyAccount();
  //     assert.deepEqual(account.toObject(), fixtures.emptyAccount);
  //   });
  // });
});
