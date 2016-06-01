'use strict';
const assert = require('chai').assert;
const _ = require('lodash');

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;

const fixtures = {
  account1: {
    id: '123',
    label: 'personal',
    mailboxes: [
      { id: 'a1', label: 'inbox', attribs: '', tree: [''], accountID: '123' },
      { id: 'a2', label: 'sent', attribs: '', tree: [''], accountID: '123' },
    ],
  },
  account2: {
    id: '124',
    label: 'pro',
    mailboxes: [
      {
        id: 'b1', label: 'mailbox', attribs: '', tree: [''], accountID: '124',
      },
      {
        id: 'b2', label: 'folder1', attribs: '', tree: [''], accountID: '124',
      },
    ],
  },
  account3: {
    id: '125',
  },
  emptyAccount: {
    label: '',
    login: '',
    password: '',
    imapServer: '',
    imapLogin: '',
    smtpServer: '',
    id: null,
    smtpPort: 465,
    smtpSSL: true,
    smtpTLS: false,
    smtpMethod: 'PLAIN',
    imapPort: 993,
    imapSSL: true,
    imapTLS: false,
    accountType: 'IMAP',
    favoriteMailboxes: null,
  },
};


describe('Account Store', () => {
  let accountStore;
  let dispatcher;
  let account1;
  let account2;

  function addAccount(account) {
    dispatcher.dispatch({
      type: ActionTypes.ADD_ACCOUNT_SUCCESS,
      value: { account },
    });
  }

  before(() => {
    dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(dispatcher);
    mockeryUtils.initForStores(['../app/stores/account_store']);
    accountStore = require('../app/stores/account_store');
  });

  before(() => {
    account1 = _.extend(_.clone(fixtures.emptyAccount), fixtures.account1);
    account2 = _.extend(_.clone(fixtures.emptyAccount), fixtures.account2);
    addAccount(account1);
    addAccount(account2);
  });


  /*
   * Problem noticed in the store file:
   *
   * FIXME Remove mailbox event doesn't do anything.
   * FIXME getDefault method can be used as getByMailbox.
   */
  describe('Actions', () => {
    const id = fixtures.account3.id;
    const id2 = fixtures.account2.id;
    const login = 'cozy';
    const password = 'pass';
    const label = 'mailbox-edited';
    const mailboxId = fixtures.account2.mailboxes[0].id;

    it('ADD_ACCOUNT_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_SUCCESS,
        value: { account: { id } },
      });
      const accounts = accountStore.getAll();
      assert.equal(accounts.get(id).get('id'), id);
      assert.deepEqual(accounts.get(id).get('mailboxes').toObject(), {});
    });
    it('EDIT_ACCOUNT_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.EDIT_ACCOUNT_SUCCESS,
        value: { rawAccount: { id, login } },
      });
      const accounts = accountStore.getAll();
      assert.equal(accounts.get(id).get('login'), login);
    });
    it('MAILBOX_CREATE_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.MAILBOX_CREATE_SUCCESS,
        value: { id, login, initialized: true },
      });
      const accounts = accountStore.getAll();
      assert.equal(accounts.get(id).get('initialized'), true);
    });
    it('MAILBOX_UPDATE_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.MAILBOX_UPDATE_SUCCESS,
        value: {
          id, login, password, initialized: true,
        },
      });
      const accounts = accountStore.getAll();
      assert.equal(accounts.get(id).get('password'), password);
    });
    it.skip('REMOVE_ACCOUNT_SUCCESS', () => {
      // FIXME Nothing is done here in the store code.
    });
    it('MAILBOX_DELETE_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.MAILBOX_DELETE_SUCCESS,
        value: { id },
      });
      const accounts = accountStore.getAll();
      assert.isUndefined(accounts.get(id).get('password'));
    });
    it('RECEIVE_MAILBOX_UPDATE', () => {
      dispatcher.dispatch({
        type: ActionTypes.RECEIVE_MAILBOX_UPDATE,
        value: { id: mailboxId, label },
      });
      const accounts = accountStore.getAll();
      const mailbox = accounts.get(id2).get('mailboxes').get(mailboxId);
      assert.equal(mailbox.get('label'), label);
    });
  });

  describe('Methods', () => {
    const id1 = fixtures.account1.id;
    const id2 = fixtures.account2.id;
    const label = 'mailbox-edited';
    const mailboxLabel = fixtures.account2.mailboxes[1].label;
    const mailboxId1 = fixtures.account2.mailboxes[0].id;
    const mailboxId2 = fixtures.account2.mailboxes[1].id;
    it('getByID', () => {
      const account = accountStore.getByID(id2);
      assert.equal(account.get('id'), id2);
    });
    it('getByMailbox', () => {
      const account = accountStore.getByMailbox(mailboxId1);
      assert.equal(account.get('id'), id2);
    });
    it('getDefault', () => {
      const account = accountStore.getDefault();
      assert.equal(account.get('id'), id1);
    });
    it('getByLabel', () => {
      const account = accountStore.getByLabel('pro');
      assert.equal(account.get('id'), id2);
    });
    it('getAllMailboxes', () => {
      let mailboxes = accountStore.getAllMailboxes(id2);
      assert.deepEqual(mailboxes.get(mailboxId1).toObject(), {
        id: mailboxId1, label,
        attribs: '', tree: [''], accountID: id2,
      });
      assert.deepEqual(mailboxes.get(mailboxId2).toObject(), {
        id: mailboxId2,
        label: mailboxLabel,
        attribs: '',
        tree: [''],
        accountID: id2,
      });
      mailboxes = accountStore.getAllMailboxes();
      assert.isUndefined(mailboxes);
    });
    it('makeEmptyAccount', () => {
      const account = accountStore.makeEmptyAccount();
      assert.deepEqual(account.toObject(), fixtures.emptyAccount);
    });
  });

  after(() => {
    mockeryUtils.clean();
  });
});
