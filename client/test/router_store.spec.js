'use strict';
const assert = require('chai').assert;
const Immutable = require('immutable');
const map = Immutable.Map;
const _ = require('lodash');

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const SpecRouter = require('./utils/specs_router');

const UtilConstants = require('../../server/utils/constants');
const Constants = require('../app/constants/app_constants');
const ActionTypes = Constants.ActionTypes;
const AccountActions = Constants.AccountActions;
const MessageActions = Constants.MessageActions;
const MessageFlags = Constants.MessageFlags;
const MessageFilter = Constants.MessageFilter;


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
};


describe('Router Store', () => {
  let routerStore;
  let dispatcher;
  let router;

  // // Ne pas ajouter de message par défaut
  // //  ça retire tte lisibilité aux tests
  // function changeRoute(message, query) {
  //   if (query === undefined) query = {};
  //   // if (message === undefined) message = fixtures.message1;
  //   dispatcher.dispatch({
  //     type: ActionTypes.ROUTE_CHANGE,
  //     value: {
  //       // accountID: fixtures.account.id,
  //       // mailboxID: fixtures.account.inboxMailbox,
  //       // tab: 'selected',
  //       action: MessageActions.SHOW,
  //       conversationID: message.conversationID,
  //       messageID: message.id,
  //       query,
  //     },
  //   });
  // }

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
    router = new SpecRouter();
    mockeryUtils.initDispatcher(dispatcher);
    mockeryUtils.initForStores([
      '../stores/account_store',
      '../stores/message_store',
      '../stores/requests_store',
      '../app/stores/router_store',
      '../../../server/utils/constants',
    ]);
    routerStore = require('../app/stores/router_store');

    dispatcher.dispatch({
      type: ActionTypes.ROUTE_INITIALIZE,
      value: router,
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
          filter: '',
        },
      });

    dispatcher.dispatch({
      type: ActionTypes.ADD_ACCOUNT_SUCCESS,
      value: { account: _.clone(fixtures.account) },
    });

  });

  describe('Get States From Stores:', () => {

    // TODO: tester lorsqu'on ne trouve aucun comptes
    describe('AccountStore', () => {

      it('Select Mailbox', () => {
        const accountID = fixtures.account.id;
        const mailboxID = fixtures.account.inboxMailbox;
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
          }
        });

        assert.equal(routerStore.getAccountID(), accountID);
        assert.equal(routerStore.getAccount().get('id'), accountID);

        assert.equal(routerStore.getMailboxID(), mailboxID);
        assert.equal(routerStore.getMailbox().get('id'), mailboxID);
      });


      it('Select Tab from AccountEdit page', () => {
        const accountID = fixtures.account.id;
        const mailboxID = fixtures.account.inboxMailbox;
        const accountAction = AccountActions.EDIT;
        const messageAction = MessageActions.SHOW;

        // Tab doesnt exist for none account pages
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
          }
        });
        assert.isNull(routerStore.getSelectedTab());

        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
            action: messageAction,
          }
        });
        assert.isNull(routerStore.getSelectedTab());

        // Tab default value is account
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
            action: accountAction,
          }
        });
        assert.equal(routerStore.getSelectedTab(), 'account');

        // Specify a value for Tab
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
            action: accountAction,
            tab: 'selected'
          }
        });
        assert.equal(routerStore.getSelectedTab(), 'selected');
      });
    });

    describe('MessageStore', () => {

      it('Select Mailbox', () => {
        const messageID = fixtures.message1.id;
        const conversationID = fixtures.message1.conversationID;
        const accountID = fixtures.message1.accountID;
        const mailboxID = _.keys(fixtures.message1.mailboxIDs)[0];
        const action = MessageActions.SHOW;

        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID,
            mailboxID,
            messageID,
            conversationID,
            action,
          }
        });
        assert.equal(routerStore.getConversationID(), conversationID);
        assert.equal(routerStore.getMessageID(), messageID);
        assert.equal(routerStore.getAction(), action);

        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID,
            mailboxID,
            messageID,
          }
        });
        assert.isNull(routerStore.getConversationID());
        assert.isNull(routerStore.getMessageID());
        assert.equal(routerStore.getAction(), MessageActions.SHOW_ALL);

        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID,
            mailboxID,
            action,
          }
        });
        assert.equal(routerStore.getConversationID(), undefined);
        assert.equal(routerStore.getMessageID(), undefined);
        assert.equal(routerStore.getAction(), MessageActions.SHOW_ALL);
      });

      it('isUnread', () => {
        // TODO: tester le FLAGS_REQUEST, FLAGS_SUCCESS, FLAGS_FAILURE ici
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
        // TODO: tester ici:
        // MESSAGE_TRASH_REQUEST, MESSAGE_TRASH_SUCCESS, MESSAGE_TRASH_FAILURE
        // et également RECEIVE_MESSAGE_DELETE
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

      it('getInboxTotal', () => {
        const total = fixtures.account.mailboxes[0].nbTotal
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
          }
        });
        assert.equal(routerStore.getMailboxTotal(), total);
      });

      it('getFlagboxTotal', () => {
        const total = fixtures.account.mailboxes[0].nbFlagged
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
            query: {flags: MessageFilter.FLAGGED},
          }
        });
        assert.equal(routerStore.getMailboxTotal(), total);
      });

      it('getUnreadTotal', () => {
        const total = fixtures.account.mailboxes[0].nbUnread
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
            query: {flags: MessageFilter.UNSEEN},
          }
        });
        assert.equal(routerStore.getMailboxTotal(), total);
      });
    });


    describe('RouterStore', () => {

      // TODO: test getURL

      it('Message List Pagination', () => {

        // TODO: add more complex tests
        // when testing RouterActionCreator.gotoNextPage()
        // ie. navigate thew several mailbox (including flagged ones)
        // to chake if hasNextPage is still coherent

        const start1 = Date.parse("1995-12-17T03:24:00");
        const start2 = Date.parse("1995-12-17T00:24:00");
        const start3 = Date.parse("1995-12-16T03:24:00");
        const start4 = Date.parse("1995-12-15");
        const start5 = Date.parse("1998-10-1");

        // Goto MailboxList
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: fixtures.account.id,
            mailboxID: fixtures.account.inboxMailbox,
          },
        });

        // Fetch 1rst page of messages
        let lastPage = { start: start1, isComplete: false };
        dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FETCH_SUCCESS,
          value: { lastPage },
        });
        assert.equal(routerStore.getLastPage(), lastPage);
        assert.equal(routerStore.hasNextPage(), true);
        assert.equal(routerStore.getURI(), fixtures.account.inboxMailbox);

        // Fetch 2nd page of messages
        lastPage = { start: start2, isComplete: true };
        dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FETCH_SUCCESS,
          value: { lastPage },
        });
        assert.equal(routerStore.getLastPage(), lastPage);
        assert.equal(routerStore.hasNextPage(), false);
      });


      it('Navigate from Message to Messages', () => {
          // TODO: here test isPageComplete with getMessagesList
          // it('isPageComplete', () => {
          //   changeRoute({ });
          //   loadMessages([fixtures.message1, fixtures.message2]);
          //   routerStore.getMessagesList();
          //   assert.isFalse(routerStore.isPageComplete());
          //   const msgs = generateMessages();
          //   loadMessages(msgs);
          //   routerStore.getMessagesList();
          //   assert.isTrue(routerStore.isPageComplete());
          // });
          // it('getMessagesList', () => {
          //   const msgs = [];
          //   for (let i = 0; i < UtilConstants.MSGBYPAGE + 3; i++) {
          //     const message = _.clone(fixtures.message1);
          //     message.id = `id${i}`;
          //     message.messageID = `meid${i}`;
          //     message.conversationID = `c${i}`;
          //     msgs.push(message);
          //   }
          //   msgs[12].flags = [];
          //   msgs[14].flags = [MessageFlags.FLAGGED];
          //   msgs[15].flags = [MessageFlags.FLAGGED, MessageFlags.ATTACH];
          //   changeRoute({ });
          //   loadMessages(msgs);
          //   assert.equal(routerStore.getMessagesList().size, msgs.length);
          //   changeRoute({ flags: MessageFilter.UNSEEN });
          //   assert.equal(routerStore.getMessagesList().size, 3);
          //   changeRoute({ flags: MessageFilter.FLAGGED });
          //   assert.equal(routerStore.getMessagesList().size, 2);
          //   changeRoute({ flags: MessageFilter.ATTACH });
          //   assert.equal(routerStore.getMessagesList().size, 1);
          // });
          // it('getConversation', () => {
          //   const msgs = generateMessages();
          //   msgs[16].conversationID = 'c5';
          //   msgs[17].conversationID = 'c5';
          //   msgs[18].conversationID = 'c5';
          //
          //   changeRoute({ });
          //   loadMessages(msgs);
          //   assert.equal(routerStore.getConversation('c5').length, 4);
          // });
          // it('getConversationLength', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ });
          //   loadMessages(msgs, { c5: 6 });
          //   assert.equal(routerStore.getConversationLength({
          //     conversationID: 'c5',
          //   }), 6);
          // });
          // it('getNextConversation', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ });
          //   msgs[7].conversationID = 'c7';
          //   msgs[8].conversationID = 'c7';
          //   msgs[9].conversationID = 'c7';
          //   loadMessages(msgs);
          //   changeRoute({ }, msgs[7]);
          //   assert.equal(routerStore.getNextConversation().get('messageID'),
          //                msgs[6].messageID);
          // });
          // it('getPreviousConversation', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ });
          //   msgs[7].conversationID = 'c7';
          //   msgs[8].conversationID = 'c7';
          //   msgs[9].conversationID = 'c7';
          //   loadMessages(msgs);
          //   changeRoute({ }, msgs[7]);
          //   assert.equal(routerStore.getPreviousConversation().get('messageID'),
          //                msgs[10].messageID);
          // });
          // it('gotoNextMessage', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ }, msgs[0]);
          //   loadMessages(msgs);
          //   assert.equal(routerStore.gotoPreviousMessage().get('me2'));
          //   assert.equal(routerStore.gotoPreviousMessage().get('me3'));
          // });
          // it('gotoPreviousMessage', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ }, msgs[4]);
          //   routerStore.gotoPreviousMessage();
          //   routerStore.gotoPreviousMessage();
          //   routerStore.gotoPreviousMessage();
          //   assert.equal(routerStore.gotoNextMessage().get('me3'));
          // });
      });


    });
  });
  after(() => {
    mockeryUtils.clean();
  });
});
