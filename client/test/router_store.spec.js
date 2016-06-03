'use strict';
const assert = require('chai').assert;
const Immutable = require('immutable');
const map = Immutable.Map;
const _ = require('lodash');

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const UtilConstants = require('../../server/utils/constants');
const Constants = require('../app/constants/app_constants');
const ActionTypes = Constants.ActionTypes;
const AccountActions = Constants.AccountActions;
const MessageActions = Constants.MessageActions;
const MessageFlags = Constants.MessageFlags;
const MessageFilter = Constants.MessageFilter;


let currentURL = '';

const fixtures = {
  fullTestError: {
    name: 'AccountConfigError',
    field: 'error-field',
    originalError: 'original-error',
    originalErrorStack: 'original-error-stack',
    causeFields: ['field1', 'field2'],
  },
  testError: 'test-error',
  unknownError: {
    unknown: 'test-error',
  },
  account: {
    label: 'test',
    login: '',
    password: '',
    imapServer: '',
    imapLogin: '',
    smtpServer: '',
    inboxMailbox: 'mb1',
    trashMailbox: 'mb3',
    draftMailbox: 'mb4',
    id: 'a1',
    smtpPort: 465,
    smtpSSL: true,
    smtpTLS: false,
    smtpMethod: 'PLAIN',
    imapPort: 993,
    imapSSL: true,
    imapTLS: false,
    accountType: 'IMAP',
    favoriteMailboxes: null,
    mailboxes: [
      {
        id: 'mb1',
        label: 'inbox',
        attribs: '',
        tree: [''],
        accountID: 'a1',
        nbTotal: 3253,
        nbFlagged: 15,
        nbUnread: 4,
      },
      { id: 'mb2', label: 'sent', attribs: '', tree: [''], accountID: 'a1' },
      { id: 'mb3', label: 'trash', attribs: '', tree: [''], accountID: 'a1' },
      { id: 'mb4', label: 'draft', attribs: '', tree: [''], accountID: 'a1' },
    ],
  },
  lastPage: {
    info: 'last-page',
    isComplete: true,
  },
  modal: {
    display: true,
  },
  message1: {
    id: 'i1',
    accountID: 'a1',
    messageID: 'me1',
    flags: [MessageFlags.SEEN],
    conversationID: 'c1',
    mailboxIDs: { mb1: 1 },
  },
  message2: {
    id: 'i2',
    accountID: 'a1',
    messageID: 'me2',
    flags: [MessageFlags.SEEN],
    conversationID: 'c2',
    mailboxIDs: { mb1: 1 },
  },
  message3: {
    id: 'i3',
    accountID: 'a1',
    messageID: 'me3',
    conversationID: 'c3',
    mailboxIDs: { mb1: 1, mb3: 1 },
    flags: [MessageFlags.FLAGGED, MessageFlags.ATTACH],
  },
  message4: {
    id: 'i4',
    accountID: 'a1',
    messageID: 'me4',
    conversationID: 'c4',
    mailboxIDs: { mb4: 1 },
    flags: [MessageFlags.FLAGGED, MessageFlags.ATTACH],
  },

  router: {
    navigate: (url) => {
      currentURL = url;
    },
    routes: {
      'mailbox/:mailboxID(?:query)': 'messageList',
      'account/new': 'accountNew',
      'account/:accountID/settings/:tab': 'accountEdit',
      'mailbox/:mailboxID/new': 'messageNew',
      'mailbox/:mailboxID/:messageID/edit': 'messageEdit',
      'mailbox/:mailboxID/:messageID/forward': 'messageForward',
      'mailbox/:mailboxID/:messageID/reply': 'messageReply',
      'mailbox/:mailboxID/:messageID/reply-all': 'messageReplyAll',
      'mailbox/:mailboxID/:conversationID/:messageID(?:query)': 'messageShow',
      '': 'defaultView',
    },
  },
};


describe('Router Store', () => {
  let routerStore;
  let dispatcher;


  function changeRoute(query, message) {
    if (message === undefined) message = fixtures.message1;
    dispatcher.dispatch({
      type: ActionTypes.ROUTE_CHANGE,
      value: {
        accountID: fixtures.account.id,
        mailboxID: fixtures.account.inboxMailbox,
        tab: 'selected',
        action: MessageActions.SHOW,
        conversationID: message.conversationID,
        messageID: message.id,
        query,
      },
    });
  }

  function loadMessages(messages, conversationLength) {
    dispatcher.dispatch({
      type: ActionTypes.MESSAGE_FETCH_SUCCESS,
      value: {
        lastPage: fixtures.lastPage,
        result: {
          messages,
          conversationLength,
        },
        timestamp: new Date(),
      },
    });
  }

  function generateMessages() {
    const msgs = [];
    for (let i = 0; i < UtilConstants.MSGBYPAGE + 3; i++) {
      const message = _.clone(fixtures.message1);
      message.id = `id${i}`;
      message.messageID = `meid${i}`;
      message.conversationID = `c${i}`;
      msgs.push(message);
    }
    return msgs;
  }

  /*
   * Problem noticed:
   *
   * * FIXME: Private methods are melted with public ones.
   * * FIXME: Store requests other stores without using getters.
   * * FIXME: Some events require a value while it's never used
   *          (ex: EDIT_ACCOUNT_REQUEST).
   * * FIXME: EDIT_ACCOUNT_SUCCESS clears errors after creating some. Don't
   *          know what to test.
   * * FIXME: Code is shared bewteen client and server.
   * * FIXME: getPreviousConversation and getNextConversation looks confusing.
   */

  before(() => {
    dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(dispatcher);
    mockeryUtils.initForStores([
      '../app/stores/router_store',
      '../stores/account_store',
      '../stores/message_store',
      '../../../server/utils/constants',
    ]);
    routerStore = require('../app/stores/router_store');
  });

  describe('Actions', () => {
    it('ROUTE_INITIALIZE', () => {
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_SUCCESS,
        value: { account: _.clone(fixtures.account) },
      });
      dispatcher.dispatch({
        type: ActionTypes.RECEIVE_RAW_MESSAGES,
        value: [fixtures.message1, fixtures.message2],
      });
      dispatcher.dispatch({
        type: ActionTypes.ROUTES_INITIALIZE,
        value: fixtures.router,
      });
      assert.equal(routerStore.getRouter(), fixtures.router);
    });
    it('ROUTE_CHANGE', () => {
      dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: {
          accountID: fixtures.account.id,
          mailboxID: fixtures.account.inboxMailbox,
          tab: 'selected',
          action: MessageActions.SHOW,
          conversationID: fixtures.message1.conversationID,
          messageID: fixtures.message1.id,
          query: '',
        },
      });
    });
    it('ADD_ACCOUNT_REQUEST', () => {
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_REQUEST,
        value: '',
      });
      assert.isTrue(routerStore.isWaiting());
    });
    it.skip('ADD_ACCOUNT_SUCCESS', (done) => {
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_SUCCESS,
        value: { account: _.clone(fixtures.account) },
      });
      setTimeout(() => {
        assert.isFalse(routerStore.isWaiting());
        assert.equal(routerStore.getAction(), MessageActions.SHOW_ALL);
        assert.equal(routerStore.getAccountID(), fixtures.account.id);
        assert.equal(routerStore.getMailboxID(), fixtures.account.inboxMailbox);
        assert.equal(routerStore.getSelectedTab(), 'account');
        assert.equal(currentURL, `#mailbox/${fixtures.account.inboxMailbox}`);
        done();
      }, 5000);
    }); // .timeout(6000);
    it('ADD_ACCOUNT_FAILURE', () => {
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_FAILURE,
        value: { error: fixtures.testError },
      });
      assert.isFalse(routerStore.isWaiting());
      let errors = routerStore.getErrors().toObject();
      assert.deepEqual(errors, fixtures.unknownError);
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_FAILURE,
        value: { error: fixtures.fullTestError },
      });
      assert.isFalse(routerStore.isWaiting());
      errors = routerStore.getErrors().toObject();
      assert.deepEqual(errors, {
        field1: {
          message: fixtures.fullTestError.field,
          originalError: fixtures.fullTestError.originalError,
          originalErrorStack: fixtures.fullTestError.originalErrorStack,
        },
        field2: {
          message: fixtures.fullTestError.field,
          originalError: fixtures.fullTestError.originalError,
          originalErrorStack: fixtures.fullTestError.originalErrorStack,
        },
      });
    });
    it('CHECK_ACCOUNT_REQUEST', () => {
      dispatcher.dispatch({ type: ActionTypes.CHECK_ACCOUNT_REQUEST });
      assert.isTrue(routerStore.isChecking());
    });
    it('CHECK_ACCOUNT_SUCCESS', () => {
      dispatcher.dispatch({ type: ActionTypes.CHECK_ACCOUNT_SUCCESS });
      assert.isFalse(routerStore.isChecking());
    });
    it('CHECK_ACCOUNT_FAILURE', () => {
      dispatcher.dispatch({
        type: ActionTypes.CHECK_ACCOUNT_FAILURE,
        value: { error: fixtures.testError },
      });
      assert.isFalse(routerStore.isChecking());
      let errors = routerStore.getErrors().toObject();
      assert.deepEqual(errors, fixtures.unknownError);
      dispatcher.dispatch({
        type: ActionTypes.CHECK_ACCOUNT_FAILURE,
        value: { error: fixtures.fullTestError },
      });
      assert.isFalse(routerStore.isChecking());
      errors = routerStore.getErrors().toObject();
      assert.deepEqual(errors, {
        field1: {
          message: fixtures.fullTestError.field,
          originalError: fixtures.fullTestError.originalError,
          originalErrorStack: fixtures.fullTestError.originalErrorStack,
        },
        field2: {
          message: fixtures.fullTestError.field,
          originalError: fixtures.fullTestError.originalError,
          originalErrorStack: fixtures.fullTestError.originalErrorStack,
        },
      });
    });
    it('EDIT_ACCOUNT_REQUEST', () => {
      dispatcher.dispatch({
        type: ActionTypes.EDIT_ACCOUNT_REQUEST,
        value: { rawAccount: _.clone(fixtures.account) },
      });
      assert.isTrue(routerStore.isWaiting());
    });
    it('EDIT_ACCOUNT_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.EDIT_ACCOUNT_SUCCESS,
        value: { rawAccount: _.clone(fixtures.account) },
      });
      assert.isFalse(routerStore.isWaiting());
    });
    it('EDIT_ACCOUNT_FAILURE', () => {
      dispatcher.dispatch({
        type: ActionTypes.EDIT_ACCOUNT_FAILURE,
        value: { error: fixtures.testError },
      });
      assert.isFalse(routerStore.isChecking());
      const errors = routerStore.getErrors().toObject();
      assert.deepEqual(errors, fixtures.unknownError);
      // More advanced errors are tested in CHECK_ACCOUNT_FAILURE_TEST
      //
    });
    it('MESSAGE_FETCH_REQUEST', () => {
      dispatcher.dispatch({ type: ActionTypes.MESSAGE_FETCH_REQUEST });
      assert.isTrue(routerStore.isRefresh());
    });
    it('MESSAGE_FETCH_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.MESSAGE_FETCH_SUCCESS,
        value: {
          lastPage: fixtures.lastPage,
          result: {},
          timestamp: new Date(),
        },
      });
      assert.isFalse(routerStore.isRefresh());
      assert.deepEqual(routerStore.getLastPage(), fixtures.lastPage);
    });
    it('DISPLAY_MODAL', () => {
      dispatcher.dispatch({
        type: ActionTypes.DISPLAY_MODAL,
        value: fixtures.modal,
      });
      const params = routerStore.getModalParams();
      assert.deepEqual(params, fixtures.modal);
    });
    it('HIDE_MODAL', () => {
      dispatcher.dispatch({ type: ActionTypes.HIDE_MODAL });
      const params = routerStore.getModalParams();
      assert.isNull(params);
    });
    it('MESSAGE_TRASH_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: {
          accountID: fixtures.account.id,
          mailboxID: fixtures.inboxMailbox,
          tab: 'selected',
          action: MessageActions.SHOW,
          conversationID: fixtures.message1.conversationID,
          messageID: fixtures.message1.id,
          query: '',
        },
      });

      /* FIXME: event use wrong parameters. */
      dispatcher.dispatch({
        type: ActionTypes.MESSAGE_TRASH_SUCCESS,
        value: {
          target: '',
          updated: false,
          ref: '',
        },
      });
      // Test if it goes to next conversation.
      const mailboxID = fixtures.account.inboxMailbox;
      const conversationID = fixtures.message2.conversationID;
      const messageID = fixtures.message2.id;
      assert.equal(routerStore.getCurrentURL(),
        `mailbox/${mailboxID}/${conversationID}/${messageID}/`);
    });
    it('REFRESH_REQUEST', () => {
      dispatcher.dispatch({ type: ActionTypes.REFRESH_REQUEST });
      assert.isTrue(routerStore.isRefresh());
    });
    it('REFRESH_SUCCESS', () => {
      dispatcher.dispatch({ type: ActionTypes.REFRESH_REQUEST });
      dispatcher.dispatch({ type: ActionTypes.REFRESH_SUCCESS });
      assert.isFalse(routerStore.isRefresh());
    });
    it('REFRESH_FAILURE', () => {
      dispatcher.dispatch({ type: ActionTypes.REFRESH_REQUEST });
      dispatcher.dispatch({ type: ActionTypes.REFRESH_FAILURE });
      assert.isFalse(routerStore.isRefresh());
    });
    it('SETTINGS_UPDATE_REQUEST', () => {
      // FIXME: This action does nothing.
    });
    it('REMOVE_ACCOUNT_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: fixtures.account.id,
      });
      assert.equal(routerStore.getAction(), AccountActions.CREATE);
      // FIXME: these tests should failed, because the account was removed.
      // assert.isUndefined(routerStore.getAccountID());
      // assert.isUndefined(routerStore.getMailboxID());
      assert.equal(routerStore.getSelectedTab(), 'account');
    });
  });

  describe('Method', () => {
    function cleanMailboxes(account) {
      const mailboxes = account.mailboxes.toObject();
      account.mailboxes = Object.keys(mailboxes).map((key) => {
        return mailboxes[key].toObject();
      });
      loadMessages([fixtures.message1, fixtures.message2]);
    }

    before(() => {
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_SUCCESS,
        value: { account: _.clone(fixtures.account) },
      });
    });
    it('getAccount', () => {
      const account = routerStore.getAccount(fixtures.account.id).toObject();
      cleanMailboxes(account);

      assert.deepEqual(
        account,
        fixtures.account
      );
    });
    it('getAccountID', () => {
      assert.equal(routerStore.getAccountID(), fixtures.account.id);
    });
    it('getMailboxID', () => {
      assert.equal(routerStore.getMailboxID(),
                   fixtures.account.mailboxes[0].id);
    });
    it('getMailbox', () => {
      assert.deepEqual(routerStore.getMailbox().toObject(),
                       fixtures.account.mailboxes[0]);
      const id2 = fixtures.account.mailboxes[1].id;
      assert.deepEqual(routerStore.getMailbox(id2).toObject(),
                       fixtures.account.mailboxes[1]);
    });
    it('getAllMailboxes', () => {
      let mailboxes = routerStore.getAllMailboxes().toObject();
      let mbs = Object.keys(mailboxes).map((key) => {
        return mailboxes[key].toObject();
      });
      assert.deepEqual(mbs,
                       fixtures.account.mailboxes);
      mailboxes =
        routerStore.getAllMailboxes(fixtures.account.id).toObject();
      mbs = Object.keys(mailboxes).map((key) => {
        return mailboxes[key].toObject();
      });
      assert.deepEqual(mbs, fixtures.account.mailboxes);
    });
    it('getInbox', () => {
      assert.deepEqual(routerStore.getInbox().toObject(),
                   fixtures.account.mailboxes[0]);
    });
    it('isInbox', () => {
      let id = fixtures.account.mailboxes[0].id;
      assert.isTrue(routerStore.isInbox(id));
      id = fixtures.account.mailboxes[1].id;
      assert.isFalse(routerStore.isInbox(id));
    });
    it('getTrashMailbox', () => {
      assert.deepEqual(routerStore.getTrashMailbox().toObject(),
                   fixtures.account.mailboxes[2]);
    });
    it('getSelectedTab', () => {
      assert.equal(routerStore.getSelectedTab(), 'account');
    });
    it('getConversationID', () => {
      assert.equal(routerStore.getConversationID(),
                   fixtures.message2.conversationID);
    });
    it('getMessageID', () => {
      assert.equal(routerStore.getMessageID(),
                   fixtures.message2.id);
    });
    it('isUnread', () => {
      assert.isFalse(routerStore.isUnread(map(fixtures.message1)));
      assert.isTrue(routerStore.isUnread(map(fixtures.message3)));
    });
    it('isFlagged', () => {
      assert.isFalse(routerStore.isFlagged(map(fixtures.message1)));
      assert.isTrue(routerStore.isFlagged(map(fixtures.message3)));
    });
    it('isAttached', () => {
      assert.isFalse(
        routerStore.isAttached(map(fixtures.message1)));
      assert.isTrue(
        routerStore.isAttached(map(fixtures.message3)));
    });
    it('isDeleted', () => {
      changeRoute({ });
      assert.isFalse(
        routerStore.isDeleted(map(fixtures.message1)));
      assert.isTrue(
        routerStore.isDeleted(map(fixtures.message3)));
    });
    it('isDraft', () => {
      assert.isFalse(
        routerStore.isDraft(map(fixtures.message1)));
      assert.isTrue(
        routerStore.isDraft(map(fixtures.message4)));
    });
    it('getMailboxTotal', () => {
      assert.equal(
        routerStore.getMailboxTotal(),
        fixtures.account.mailboxes[0].nbTotal
      );
      changeRoute({ });
      assert.equal(
        routerStore.getMailboxTotal(),
        fixtures.account.mailboxes[0].nbTotal
      );
      changeRoute({ flags: MessageFilter.UNSEEN });
      assert.equal(
        routerStore.getMailboxTotal(),
        fixtures.account.mailboxes[0].nbUnread
      );
      changeRoute({ flags: MessageFilter.FLAGGED });
      assert.equal(
        routerStore.getMailboxTotal(),
        fixtures.account.mailboxes[0].nbFlagged
      );
    });
    it('hasNextPage', () => {
      dispatcher.dispatch({
        type: ActionTypes.MESSAGE_FETCH_SUCCESS,
        value: {
          lastPage: {
            info: 'last-page',
            isComplete: false,
          },
          result: {},
          timestamp: new Date(),
        },
      });
      assert.isTrue(routerStore.hasNextPage());
      dispatcher.dispatch({
        type: ActionTypes.MESSAGE_FETCH_SUCCESS,
        value: {
          lastPage: {
            info: 'last-page',
            isComplete: true,
          },
          result: {},
          timestamp: new Date(),
        },
      });
      assert.isFalse(routerStore.hasNextPage());
    });
    it('getLastPage', () => {
      loadMessages([fixtures.message1, fixtures.message2]);
      assert.deepEqual(routerStore.getLastPage(), fixtures.lastPage);
    });
    it('isPageComplete', () => {
      changeRoute({ });
      loadMessages([fixtures.message1, fixtures.message2]);
      routerStore.getMessagesList();
      assert.isFalse(routerStore.isPageComplete());
      const msgs = generateMessages();
      loadMessages(msgs);
      routerStore.getMessagesList();
      assert.isTrue(routerStore.isPageComplete());
    });
    it('getMessagesList', () => {
      const msgs = [];
      for (let i = 0; i < UtilConstants.MSGBYPAGE + 3; i++) {
        const message = _.clone(fixtures.message1);
        message.id = `id${i}`;
        message.messageID = `meid${i}`;
        message.conversationID = `c${i}`;
        msgs.push(message);
      }
      msgs[12].flags = [];
      msgs[14].flags = [MessageFlags.FLAGGED];
      msgs[15].flags = [MessageFlags.FLAGGED, MessageFlags.ATTACH];
      changeRoute({ });
      loadMessages(msgs);
      assert.equal(routerStore.getMessagesList().size, msgs.length);
      changeRoute({ flags: MessageFilter.UNSEEN });
      assert.equal(routerStore.getMessagesList().size, 3);
      changeRoute({ flags: MessageFilter.FLAGGED });
      assert.equal(routerStore.getMessagesList().size, 2);
      changeRoute({ flags: MessageFilter.ATTACH });
      assert.equal(routerStore.getMessagesList().size, 1);
    });
    it('getConversation', () => {
      const msgs = generateMessages();
      msgs[16].conversationID = 'c5';
      msgs[17].conversationID = 'c5';
      msgs[18].conversationID = 'c5';

      changeRoute({ });
      loadMessages(msgs);
      assert.equal(routerStore.getConversation('c5').length, 4);
    });
    it('getConversationLength', () => {
      const msgs = generateMessages();
      changeRoute({ });
      loadMessages(msgs, { c5: 6 });
      assert.equal(routerStore.getConversationLength({
        conversationID: 'c5',
      }), 6);
    });
    it.skip('getNextConversation', () => {
      const msgs = generateMessages();
      changeRoute({ });
      msgs[2].conversationID = 'c1';
      msgs[3].conversationID = 'c1';
      assert.equal(routerStore.getNextConversation().get('messageID'),
                   msgs[3].messageID);
    });
    it.skip('getPreviousConversation', () => {
      const msgs = generateMessages();
      changeRoute({ });
      loadMessages(msgs);
      changeRoute({ }, msgs[4]);
      changeRoute({ }, msgs[4]);
      assert.equal(routerStore.getPreivousConversation().get('messageID'),
                   msgs[1].messageID);
    });
    it('gotoNextMessage', () => {
      const msgs = generateMessages();
      changeRoute({ }, msgs[0]);
      loadMessages(msgs);
      assert.equal(routerStore.gotoPreviousMessage().get('me2'));
      assert.equal(routerStore.gotoPreviousMessage().get('me3'));
    });
    it('gotoPreviousMessage', () => {
      const msgs = generateMessages();
      changeRoute({ }, msgs[4]);
      routerStore.gotoPreviousMessage();
      routerStore.gotoPreviousMessage();
      routerStore.gotoPreviousMessage();
      assert.equal(routerStore.gotoNextMessage().get('me3'));
    });
  });
  after(() => {
    mockeryUtils.clean();
  });
});
