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


describe.skip('Router Store', () => {
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
   * * FIXME: Some events require a value while it's never used
   *          (ex: EDIT_ACCOUNT_REQUEST).
   * * FIXME: EDIT_ACCOUNT_SUCCESS clears errors after creating some. Don't
   *          know what to test.
   * * FIXME: Code is shared between client and server.
   * * FIXME: getPreviousConversation and getNextConversation looks confusing.
   * * FIXME: Search and filter didn't look implemented yet. Tests about it
   *          should be added later (via ROUTE_CHANGE event tests).
   */

  before(() => {
    dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(dispatcher);
    mockeryUtils.initForStores([
      '../app/stores/router_store',
      '../stores/account_store',
      '../stores/message_store',
      '../stores/requests_store',
      '../../../server/utils/constants',
    ]);
    routerStore = require('../app/stores/router_store');
  });

  describe('Actions', () => {
    it('ROUTE_INITIALIZE', () => {
      // Fire two events to allow the initialization of the router store:
      // ADD_ACCOUNT_SUCCESS and RECEIVE_RAW_MESSAGES. The first one
      // adds an account and the second one adds messages. That way the router
      // can build URLs and performs its initializaton like if data are arleady
      // present in the application.
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
    it('ROUTE_CHANGE (no accounts)', () => {
      // First we test that the new account action is automatically selected
      // when the ROUTE_CHANGE event is fired while no account is added to the
      // store.
      dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { },
      });
      assert.equal(routerStore.getAction(), AccountActions.CREATE);
    });
    it('ROUTE_CHANGE (accounts)', () => {
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_SUCCESS,
        value: { account: _.clone(fixtures.account) },
      });
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
      assert.equal(routerStore.getAction(), MessageActions.SHOW);
      assert.equal(routerStore.getAccountID(), fixtures.account.id);
      assert.equal(routerStore.getMailboxID(), fixtures.account.inboxMailbox);
      assert.equal(routerStore.getMessageID(), fixtures.message1.id);
      assert.equal(routerStore.getConversationID(),
                   fixtures.message1.conversationID);
      assert.isNull(routerStore.getFilter().value);
      assert.equal(routerStore.getCurrentURL({ isServer: false }),
                   '#mailbox/mb1/c1/i1');

      dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: {
          accountID: fixtures.account.id,
          mailboxID: fixtures.account.inboxMailbox,
          tab: 'selected',
          action: MessageActions.SHOW_ALL,
        },
      });
      assert.equal(routerStore.getAction(), MessageActions.SHOW_ALL);
      assert.equal(routerStore.getAccountID(), fixtures.account.id);
      assert.equal(routerStore.getMailboxID(), fixtures.account.inboxMailbox);
      assert.isNull(routerStore.getFilter().value);
      assert.equal(routerStore.getCurrentURL({ isServer: false }),
                   '#mailbox/mb1');
    });
    it.skip('ADD_ACCOUNT_SUCCESS', (done) => {
      dispatcher.dispatch({
        type: ActionTypes.ADD_ACCOUNT_SUCCESS,
        value: { account: _.clone(fixtures.account) },
      });
      setTimeout(() => {
        assert.equal(routerStore.getAction(), MessageActions.SHOW_ALL);
        assert.equal(routerStore.getAccountID(), fixtures.account.id);
        assert.equal(routerStore.getMailboxID(), fixtures.account.inboxMailbox);
        assert.equal(routerStore.getSelectedTab(), 'account');
        assert.equal(currentURL, `#mailbox/${fixtures.account.inboxMailbox}`);
        assert.equal(routerStore.getCurrentURL({ isServer: false }),
                     `#mailbox/${fixtures.account.inboxMailbox}`);
        done();
      }, 5000);
    }); // .timeout(6000);
    // Uncomment previous line, if you decide to unskip this test.
    it('MESSAGE_FETCH_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.MESSAGE_FETCH_SUCCESS,
        value: {
          lastPage: fixtures.lastPage,
          result: {},
          timestamp: new Date(),
        },
      });
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

      // FIXME: this event require parameters that are never used.
      // We should check if they are required by another store.
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
      const accountID = fixtures.account.id
      const id2 = fixtures.account.mailboxes[1].id;
      assert.deepEqual(routerStore.getMailbox(accountID, id2).toObject(),
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
    it('getNextConversation', () => {
      const msgs = generateMessages();
      changeRoute({ });
      msgs[7].conversationID = 'c7';
      msgs[8].conversationID = 'c7';
      msgs[9].conversationID = 'c7';
      loadMessages(msgs);
      changeRoute({ }, msgs[7]);
      assert.equal(routerStore.getNextConversation().get('messageID'),
                   msgs[6].messageID);
    });
    it('getPreviousConversation', () => {
      const msgs = generateMessages();
      changeRoute({ });
      msgs[7].conversationID = 'c7';
      msgs[8].conversationID = 'c7';
      msgs[9].conversationID = 'c7';
      loadMessages(msgs);
      changeRoute({ }, msgs[7]);
      assert.equal(routerStore.getPreviousConversation().get('messageID'),
                   msgs[10].messageID);
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
