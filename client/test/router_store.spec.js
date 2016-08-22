/* eslint-env mocha */

'use strict';

const assert = require('chai').assert;
// const Immutable = require('immutable');
// const map = Immutable.Map;
const _ = require('lodash');

const SpecRouter = require('./utils/specs_router');

const UtilConstants = require('../../server/utils/constants');
const Constants = require('../app/constants/app_constants');
const Router = require('../app/router');
const ActionTypes = Constants.ActionTypes;
const AccountActions = Constants.AccountActions;
const MessageActions = Constants.MessageActions;
const MessageFilter = Constants.MessageFilter;
const MessageFlags = Constants.MessageFlags;

const getUID = require('./utils/guid').getUID;
const AccountFixtures = require('./fixtures/account');
const MessageFixtures = require('./fixtures/message');

const AccountGetter = require('../app/puregetters/account');
const MessageGetter = require('../app/puregetters/messages');
const RouterGetter = require('../app/puregetters/router');

const makeTestDispatcher = require('./utils/specs_dispatcher');

const DEFAULT_TAB = 'account';
// const reduxStore = require('../app/reducers/_store');


describe('RouterStore', () => {
  let RouterStore;
  let AccountStore;
  let MessageStore;
  let Dispatcher;
  let account;
  let routes;
  let accounts;
  const router = new SpecRouter();

  /*
   * Problem noticed:
   *
   * * FIXME: Private methods are melted with public ones.
   * * FIXME: Code is shared between client and server.
   */

  before(() => {
    global.t = (x) => x;
    resetStore();
  });


  after(() => {
      delete global.t;
  });

  beforeEach(() => {
    // Dispatcher.dispatch({ type: ActionTypes.RESET_FOR_TESTS });

    // Reverse relation value to simplify tests
    // ie. routes['messageList'] = url
    if (undefined === routes) {
      const reversed = {};
      const routerRoutes = Router.prototype.routes;
      Object.keys(routerRoutes).forEach((key) => {
        reversed[routerRoutes[key]] = key;
      });
      routes = reversed;
    }
  });


  // Skipped after account redux migration
  // TODO: make the acount fixture as Immutable
  describe('Basics', () => {
    beforeEach(() => {
      resetStore();

      // Add messages
      // that belongs to defaultAccount
      const conversationID = `coucou-${getUID()}`;
      const params = { conversationID, account };
      const messages = [];
      messages.push(MessageFixtures.createMessage(params));
      messages.push(MessageFixtures.createMessage(params));
      messages.push(MessageFixtures.createMessage(params));
      Dispatcher.dispatch({
        type: ActionTypes.RECEIVE_RAW_MESSAGES,
        value: messages,
      });
    });

    it.skip('getRouter', () => {
      const result = RouterStore.getRouter();
      assert.equal(result, router);
      assert.equal(typeof result, 'object');
      assert.isTrue(!!result);
    });


    describe('getAccountID', () => {
      let accounts;

      beforeEach(() => {
        accounts = AccountStore.getAll().toArray();
      });

      it('Should return (default) `value`', () => {
        assert.equal(RouterStore.getAccountID(), undefined);
      });

      it.skip('Should save `value`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        const output = RouterStore.getAccountID();
        assert.equal(output, accounts[0].get('id'));
        assert.notEqual(output, undefined);
      });

      it('Should define `mailboxID` from `accountID`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { accountID: accounts[1].get('id') },
        });
        const output = RouterStore.getAccountID();
        assert.equal(output, accounts[1].get('id'));
        assert.notEqual(output, undefined);
      });

      it('Should define `accountID` from `mailboxID`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: accounts[2].get('inboxMailbox') },
        });
        const output = RouterStore.getAccountID();
        assert.equal(output, accounts[2].get('id'));
        assert.notEqual(output, undefined);
      });
    });

    describe('getAccount', () => {
      it.skip('Shouldnt find `(default) Account`', () => {
        assert.equal(RouterStore.getAccount(), undefined);
      });

      it.skip('Should save `Account`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        const input = AccountStore.getDefault();
        const output = RouterStore.getAccount();
        assert.equal(output.get('id'), input.get('id'));
      });

      it('Should save `accountID`', () => {
        const input = AccountStore.getAll().toArray()[1];
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { accountID: input.get('id') },
        });
        const output = RouterStore.getAccount(input.get('id'));
        assert.equal(output.get('id'), input.get('id'));
      });
    });

    // Skipped after account redux migration
    // TODO: make the acount fixture as Immutable
    it('getDefaultAccount', () => {
      const input = AccountStore.getAll().first();
      const output = RouterStore.getDefaultAccount();
      assert.deepEqual(input.toJS(), output.toJS());
    });


    describe('getMailboxID', () => {
      let accounts;

      beforeEach(() => {
        accounts = AccountStore.getAll().toArray();
      });

      // Get default value
      it('Should return null', () => {
        assert.equal(RouterStore.getMailboxID(), undefined);
      });

      it.skip('Should save `mailboxID`', () => {
        // Save direct value
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        const output = RouterStore.getMailboxID();
        assert.equal(output, accounts[0].get('inboxMailbox'));
        assert.notEqual(output, undefined);
      });

      it('Should save `accountID` from `mailboxID`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: accounts[1].get('inboxMailbox') },
        });
        const output = RouterStore.getMailboxID();
        assert.equal(output, accounts[1].get('inboxMailbox'));
        assert.notEqual(output, undefined);
      });

      it('Should save `mailboxID` from `accountID`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { accountID: accounts[2].get('id') },
        });
        const output = RouterStore.getMailboxID();
        assert.equal(output, accounts[2].get('inboxMailbox'));
        assert.notEqual(output, undefined);
      });
    });

    describe('getMailbox', () => {
      it('Shouldnt find `(default) Account.mailbox`', () => {
        assert.equal(RouterStore.getMailbox(), undefined);
      });

      it.skip('Should find `(default) Account.mailbox`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        const input = AccountStore.getAll().toArray()[0];
        const output = RouterStore.getMailbox();
        assert.equal(output.get('id'), input.get('inboxMailbox'));
        assert.equal(output.get('id'), RouterStore.getMailboxID());
      });

      it('Should save `Account.mailbox` from mailboxID', () => {
        // Should save value
        const input = AccountStore.getAll().toArray()[1];
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: input.get('inboxMailbox') },
        });
        const output = RouterStore.getMailbox();
        assert.equal(output.get('id'), input.get('inboxMailbox'));
      });
    });

    describe('getAllMailboxes', () => {
      let accounts;

      beforeEach(() => {
        accounts = AccountStore.getAll().toArray();
      });

      it.skip('Should return `(default) Account`', () => {
        const input = accounts[0].get('mailboxes');
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        const output = RouterStore.
        es();
        assert.deepEqual(input.toJS(), output.toJS());
      });

      it('Should return `Account` from `accountID`', () => {
        const input = accounts[2].get('mailboxes');
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { accountID: accounts[2].get('id') },
        });
        const output = RouterStore.getAllMailboxes(accounts[2].get('id'));
        assert.deepEqual(input.toJS(), output.toJS());
      });
    });


    describe('getMessageID', () => {
      let messages;
      let messageID;
      let conversationID;

      beforeEach(() => {
        messages = MessageStore.getAll().toArray();
        messageID = messages[2].get('id');
        conversationID = messages[2].get('conversationID');
      });

      it('Should return `null`', () => {
        assert.equal(RouterStore.getMessageID(), null);
      });

      it.skip('Shouldnt be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        assert.equal(RouterStore.getMessageID(), null);

        // MessageID always works with conversationID
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { messageID },
        });
        assert.equal(RouterStore.getMessageID(), null);
      });

      it('Should be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { messageID, conversationID },
        });
        assert.equal(RouterStore.getMessageID(), messageID);
      });
    });

    describe('getConversationID', () => {
      let messages;
      let messageID;
      let conversationID;

      beforeEach(() => {
        messages = MessageStore.getAll().toArray();
        messageID = messages[1].get('id');
        conversationID = messages[1].get('conversationID');
      });

      it.skip('Should return `null`', () => {
        assert.equal(RouterStore.getConversationID(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        assert.equal(RouterStore.getConversationID(), null);
      });

      it('Shouldnt be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { conversationID },
        });
        assert.equal(RouterStore.getConversationID(), null);
      });

      it('Should be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { messageID, conversationID },
        });
        assert.equal(RouterStore.getConversationID(), conversationID);
      });
    });


    describe('getAction', () => {
      let accounts;
      let accountIDs;

      beforeEach(() => {
        accounts = AccountStore.getAll();
        accountIDs = _.keys(accounts.toJS());
      });

      it('Should return null', () => {
        assert.equal(RouterStore.getAction(), null);
      });

      it('Should be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.CREATE },
        });
        assert.equal(RouterStore.getAction(), AccountActions.CREATE);
      });
    });


    // TODO: add test for value, sort, before and after
    // when it will be handled by components
    describe('getFilter', () => {
      let defaultValue;

      beforeEach(() => {
        defaultValue = RouterStore.getFilter();
      });

      it('Shouldnt return `undefined`', () => {
        assert.notEqual(defaultValue, undefined);
        assert.equal(defaultValue.sort, '-date');
        assert.isNull(defaultValue.flags);
        assert.isNull(defaultValue.value);
        assert.isNull(defaultValue.before);
        assert.isNull(defaultValue.after);
      });

      it('Should be updated', () => {
        const flags = MessageFilter.UNSEEN;
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags } },
        });

        // Filter.flags should have change
        const filter = RouterStore.getFilter();
        assert.equal(filter.flags, flags);
        assert.equal(filter.sort, defaultValue.sort);
        assert.equal(filter.value, defaultValue.value);
        assert.equal(filter.before, defaultValue.before);
        assert.equal(filter.after, defaultValue.after);
      });

      it('Should be reset', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: null },
        });
        assert.deepEqual(RouterStore.getFilter(), defaultValue);
      });
    });

    describe('isUnread', () => {
      it('Should return `mailbox.unread`', () => {
        assert.isFalse(RouterStore.isUnread());

        // Add Unseen filter into URI
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.UNSEEN } },
        });
        assert.isTrue(RouterStore.isUnread());

        // Add Flagged filter into URI
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.FLAGGED } },
        });
        assert.isFalse(RouterStore.isUnread());
      });

      it('Should return `message.unread`', () => {
        // Add unread message
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: MessageFixtures.createUnread({ account }),
        });

        // Test unread message
        let message = MessageStore.getAll().find((message) =>
          !message.get('flags').length
        );
        assert.notEqual(message, undefined);
        assert.isTrue(message.isUnread());

        // Test on read message
        message = MessageStore.getAll().find((message) =>
          message.get('flags').length
        );
        assert.notEqual(message, undefined);
        assert.isFalse(message.isUnread());
      });
    });


    describe('isFlagged', () => {
      it('Should return `mailbox.flagged`', () => {
        assert.isFalse(RouterStore.isFlagged());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.FLAGGED } },
        });
        assert.isTrue(RouterStore.isFlagged());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.ATTACH } },
        });
        const message = MessageStore.getAll().find((message) => {
          return message.get('flags').length;
        });
        assert.notEqual(message, undefined);
        assert.isFalse(RouterStore.isFlagged());
      });

      it('Should return `message.flagged`', () => {
        // Add flagged message
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: MessageFixtures.createFlagged({ account }),
        });

        // Test flagged message
        let message = MessageStore.getAll().find((message) =>
          message.get('flags').indexOf(MessageFlags.FLAGGED) !== -1
        );
        assert.notEqual(message, undefined);
        assert.isTrue(message.isFlagged());

        // Test on un-flagged message
        message = MessageStore.getAll().find((message) => {
          return -1 === message.get('flags').indexOf(MessageFlags.FLAGGED);
        });
        assert.notEqual(message, undefined);
        assert.isFalse(message.isFlagged());
      });
    });


    describe('isAttached', () => {
      it('Should return `mailbox.attached`', () => {
        assert.isFalse(RouterStore.isAttached());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.ATTACH } },
        });
        assert.isTrue(RouterStore.isAttached());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.UNREAD } },
        });
        assert.isFalse(RouterStore.isAttached());
      });

      it('Should return `mailbox.attached`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: MessageFixtures.createAttached({ account }),
        });
        let message = MessageStore.getAll().find((message) =>
          message.get('attachments').size
        );
        assert.notEqual(message, undefined);
        assert.isTrue(message.isAttached());

        message = MessageStore.getAll().find((message) =>
          message.get('flags').indexOf(MessageFlags.ATTACH) === -1
        );
        assert.notEqual(message, undefined);
        assert.isFalse(message.isAttached());
      });
    });


    describe('isDeleted', () => {
      it('Should return `mailbox.deleted`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.inboxMailbox },
        });
        assert.isFalse(RouterStore.isDeleted());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.trashMailbox },
        });
        assert.isTrue(RouterStore.isDeleted());
      });

      it('Should return `message.deleted`', () => {
        let input = MessageFixtures.createTrash({ account });
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: input,
        });
        let message = MessageStore.getByID(input.id);
        assert.notEqual(message, undefined);
        assert.isTrue(RouterStore.isDeletedMessage(message));

        // Create a message that cant belongs to trashMailbox
        input = MessageFixtures.createMessage({ account });
        delete input.mailboxIDs[account.trashMailbox];
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: input,
        });
        message = MessageStore.getByID(input.id);
        assert.notEqual(message, undefined);
        assert.isFalse(RouterStore.isDeletedMessage(message));
      });
    });

    // Add test for MessageStore.isDraft()
    describe('isDraft', () => {
      it('Should return `false`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.inboxMailbox },
        });
        assert.isFalse(RouterStore.isDraft());
      });

      it('Should return `message.isDraft`', () => {
        // Add Attached message
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: MessageFixtures.createDraft({ account }),
        });

        // Test Draft message
        let message = MessageStore.getAll().find((message) => {
          return -1 < message.get('flags').indexOf(MessageFlags.DRAFT);
        });
        assert.notEqual(message, undefined);
        assert.isTrue(message.isDraft());

        message = MessageStore.getAll().find((message) =>
          message.get('flags').indexOf(MessageFlags.DRAFT) === -1
        );
        assert.notEqual(message, undefined);
        assert.isFalse(message.isDraft());
      });

      it('Should return `mailbox.isDraft`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.draftMailbox },
        });
        assert.isTrue(RouterStore.isDraft());
      });
    });

    describe('getMailboxTotal', () => {

      it('Should return 0', () => {
        assert.equal(RouterStore.getMailboxTotal(), 0);
      });

      it('Should return `inboxMailbox.nbTotal`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.inboxMailbox },
        });

        const mailbox = RouterStore.getMailbox();
        const value = RouterStore.getMailboxTotal();
        assert.equal(value, mailbox.get('nbTotal'));
      });

      it('Should return `flaggedMailbox.nbTotal`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.flaggedMailbox },
        });
        const inbox = getInbox();
        const mailbox = RouterStore.getMailbox();
        const value = RouterStore.getMailboxTotal();
        assert.equal(value, inbox.get('nbFlagged'));
        assert.equal(value, mailbox.get('nbTotal'));
      });

      it('Should return `unreadMailbox.nbTotal`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.unreadMailbox },
        });
        const inbox = getInbox();
        const mailbox = RouterStore.getMailbox();
        const value = RouterStore.getMailboxTotal();
        assert.equal(value, inbox.get('nbUnread'));
        assert.equal(value, mailbox.get('nbTotal'));
      });

      function getInbox() {
        const account = RouterStore.getAccount();
        const mailboxID = account.get('inboxMailbox');
        return AccountStore.getMailbox(mailboxID);
      }
    });


    describe('getSelectedTab', () => {

      it('Should return `null`', () => {
        assert.equal(RouterStore.getSelectedTab(), null);
      });

      it('Shouldnt be stored (err)', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.CREATE },
        });
        assert.equal(RouterStore.getSelectedTab(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.CREATE, tab: 'plip' },
        });
        assert.equal(RouterStore.getSelectedTab(), null);
      });

      it('Should return (default) `value`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.EDIT },
        });
        assert.equal(RouterStore.getSelectedTab(), 'account');
        assert.equal(RouterStore.getSelectedTab(), DEFAULT_TAB);
      });

      it('Should save dispatched `value`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.EDIT, tab: 'plip' },
        });
        assert.equal(RouterStore.getSelectedTab(), 'plip');
      });

      it('Should reset `value` when `action` changes', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.SHOW_ALL },
        });
        assert.equal(RouterStore.getSelectedTab(), null);
      });
    });
  });


  describe('Routing', () => {

    describe('getURL', () => {

      before(() => {
        resetStore();
        Dispatcher.dispatch({ type: 'FORCE STORES TO GET INITIAL STATE' });
      });

      // Skipped after account redux migration
      // TODO: make the acount fixture as Immutable
      describe('defaultView', () => {
        it.skip('Should goto `AccountNew` (no account found)', () => {
          let url = RouterStore.getURL({}).replace('#', '');
          assert.equal(url, routes['accountNew']);
          assert.equal(url, RouterStore.getURL({ isServer: true }));
        });

        it('Should goto `MessageList` (default account)', () => {
          testMessagesList();
        });
      });

      // Skipped after account redux migration
      // TODO: make the acount fixture as Immutable
      describe('messagesList', () => {
        it('Shouldnt handle filters', () => {
          testMessagesList();
        });

        it('Should handle filter', () => {
          const filter = { 'plop': 'one value' };
          testMessagesList({ filter });
        });

        it('Should handle all filters', () => {
          const filter = { 'plop': ['several', 'values', 'with special chars'] };
          testMessagesList({ filter });
        });
      });

      it('accountNew', () => {
        const action = AccountActions.CREATE;
        testAccountURI({ action }, 'accountNew');
      });

      it('accountEdit', () => {
        const action = AccountActions.EDIT;
        testAccountURI({ action }, 'accountEdit');
      });

      it('messageNew', () => {
        const action = MessageActions.CREATE;
        testMessage({ action }, 'messageNew');
      });

      it('messageEdit', () => {
        const action = MessageActions.EDIT;
        testMessage({ action }, 'messageEdit');
      });

      it('messageForward', () => {
        const action = MessageActions.FORWARD;
        testMessage({ action }, 'messageForward');
      });

      it('messageReply', () => {
        const action = MessageActions.REPLY;
        testMessage({ action }, 'messageReply');
      });

      it('messageReplyAll', () => {
        const action = MessageActions.REPLY_ALL;
        testMessage({ action }, 'messageReplyAll');
      });

      it('messageShow', () => {
        const action = MessageActions.SHOW;
        testMessage({ action }, 'messageShow');
      });


      function testAccountURI(data, keyRoute) {
        let route = _.cloneDeep(routes[keyRoute]);
        let params = Object.assign({
          mailboxID: 'mailboxID',
          accountID: 'accountID',
          tab: DEFAULT_TAB,
        }, data);

        let url = RouterStore.getURL(params).replace('#', '');
        _.forEach(params, (value, key) => {
          route = route.replace(`:${key}`, value);
        });
        assert.equal(url, route);

        let paramsServer = Object.assign({}, params, { isServer: true });
        assert.equal(url, RouterStore.getURL(paramsServer));

        // Select specific tab
        params = Object.assign(params, { tab: 'PLOP' });
        url = RouterStore.getURL(params).replace('#', '');
        route = _.cloneDeep(routes[keyRoute]);
        _.forEach(params, (value, key) => {
          route = route.replace(`:${key}`, value);
        });
        assert.equal(url, route);

        paramsServer = Object.assign({}, params, { isServer: true });
        assert.equal(url, RouterStore.getURL(paramsServer));
      }

      function testMessage(data, keyRoute) {
        let route = _.cloneDeep(routes[keyRoute]);
        const params = Object.assign({
          conversationID: 'conversationID',
          messageID: 'messageID',
          mailboxID: 'mailboxID',
          filter: null,
        }, data);

        let url = RouterStore.getURL(params).replace('#', '');

        let query = toQueryParameters(params.filter);
        route = route.replace('(?:filter)', query);
        _.forEach(params, (value, key) => {
          route = route.replace(`:${key}`, value);
        });
        assert.equal(url, route);

        // ServerSide URL need a / between URI and Query
        // Only for mailbox/mailboxID/conversationID/messageID/
        if (MessageActions.SHOW === params.action)
          if (query.length) url = url.replace(query, '/' + query);
          else url += '/';
        const paramsServer = Object.assign({}, params, { isServer: true });
        assert.equal(url, RouterStore.getURL(paramsServer));
      }

      function testMessagesList(data) {

        const params = Object.assign({
          action: MessageActions.SHOW_ALL,
          mailboxID: RouterStore.getDefaultAccount().get('inboxMailbox'),
        }, data);

        let url = RouterStore.getURL(params).replace('#', '');
        let route = routes['messageList'];
        let query = toQueryParameters(params.filter);

        route = route.replace('(?:filter)', query);
        route = route.replace(':mailboxID', params.mailboxID);

        assert.equal(url, route);

        // ServerSide URL need a / between URI and Query
        if (query.length) url = url.replace(query, '/' + query);
        else url += '/';
        const paramsServer = Object.assign({}, params, { isServer: true });
        assert.equal(url, RouterStore.getURL(paramsServer));
      }
    });


    // TODO: tester avec options et params par défaut
    describe.skip('getFetchURL', () => {
      let action = MessageActions.SHOW_ALL;

    });

    describe.skip('getURI', () => {

      it.skip('defaultView', () => {
        assert.isNull(RouterStore.getURI());
      });

      it('messagesList', () => {
        const action = MessageActions.SHOW_ALL;
        testMessageURI(action);
      });

      it.skip('messageNew', () => {
        const action = MessageActions.CREATE;
        testMessageURI(action);
      });

      it.skip('messageEdit', () => {
        const action = MessageActions.EDIT;
        testMessageURI(action);
      });

      it.skip('messageForward', () => {
        const action = MessageActions.FORWARD;
        testMessageURI(action);
      });

      it.skip('messageReply', () => {
        const action = MessageActions.REPLY;
        testMessageURI(action);
      });

      it.skip('messageReplyAll', () => {
        const action = MessageActions.REPLY_ALL;
        testMessageURI(action);
      });

      it.skip('messageShow', () => {
        const action = MessageActions.SHOW;
        testMessageURI(action);
      });

      it.skip('accountNew', () => {
        const action = AccountActions.CREATE;
        testAccountURI(action);
      });

      it.skip('accountEdit', () => {
        const action = AccountActions.EDIT;
        testAccountURI(action);
      });


      function testAccountURI(action) {
        let accountID;
        let result;

        if (AccountActions.CREATE !== action) {
          accountID = 'accountID';
        }

        // Without any params
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action },
        });
        result = `action=${action}`;
        if (undefined !== accountID) result += '&accountID=null';
        assert.equal(RouterStore.getURI(), result);

        // With accountID
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID, mailboxID: 'PLOP' },
        });
        result = `action=${action}`;
        if (undefined !== accountID) result += `&accountID=${accountID}`;
        assert.equal(RouterStore.getURI(), result);

        // With one filter
        let filter = { 'plop': 'one value' };
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, filter },
        });
        result = `action=${action}`;
        if (undefined !== accountID) result += '&accountID=null';
        assert.equal(RouterStore.getURI(), result);
      }

      function testMessageURI(action) {
        const mailboxID = 'mailboxID';
        const accountID = 'accountID';

        let conversationID;
        let messageID;

        if (MessageActions.SHOW_ALL !== action) {
          conversationID = 'conversationID';
          messageID = 'messageID';
        }

        // Without any params
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action },
        });
        let result = `action=${action}&accountID=null&mailboxID=null`;
        if (undefined !== conversationID) result += '&conversationID=null';
        if (undefined !== messageID) result += '&messageID=null';
        assert.equal(RouterStore.getURI(), result);

        // Without mailboxID
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID },
        });
        result = `action=${action}&accountID=${accountID}&mailboxID=null`;
        if (undefined !== conversationID) result += '&conversationID=null';
        if (undefined !== messageID) result += '&messageID=null';
        assert.equal(RouterStore.getURI(), result);

        // With all params
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID, mailboxID, conversationID, messageID },
        });
        result = `action=${action}&accountID=${accountID}&mailboxID=${mailboxID}`;
        if (undefined !== conversationID) result += `&conversationID=${conversationID}`;
        if (undefined !== messageID) result += `&messageID=${messageID}`;
        assert.equal(RouterStore.getURI(), result);

        // With one filter
        let filter = { 'plop': 'one value' };
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID, mailboxID, conversationID, messageID, filter },
        });
        result = `action=${action}&accountID=${accountID}&mailboxID=${mailboxID}`;
        if (undefined !== conversationID) result += `&conversationID=${conversationID}`;
        if (undefined !== messageID) result += `&messageID=${messageID}`;
        result += `&query=${toQueryParameters(filter)}`;
        assert.equal(RouterStore.getURI(), result);

        // With several filters
        filter = { plop: ['several', 'values', 'with special chars'] };
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID, mailboxID, conversationID, messageID, filter },
        });
        result = `action=${action}&accountID=${accountID}&mailboxID=${mailboxID}`;
        if (undefined !== conversationID) result += `&conversationID=${conversationID}`;
        if (undefined !== messageID) result += `&messageID=${messageID}`;
        result += `&query=${toQueryParameters(filter)}`;
        assert.equal(RouterStore.getURI(), result);
      }
    });
  });


  describe('Pagination', () => {
    beforeEach(() => {
      resetStore();
    });
    // Skipped after account redux migration
    // TODO: make the acount fixture as Immutable
    describe('getMessagesPerPage', () => {
      it.skip('Should be `null`', () => {
        assert.equal(RouterStore.getMessagesPerPage(), null);
      });

      // Skipped after account redux migration
      // TODO: make the acount fixture as Immutable
      it('Should be defaultValue', () => {
        // 1rst test
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.SHOW },
        });
        assert.equal(RouterStore.getMessagesPerPage(), UtilConstants.MSGBYPAGE);

        // Reset
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.EDIT },
        });
        assert.equal(RouterStore.getMessagesPerPage(), null);

        // 2nd test
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.SHOW_ALL },
        });
        assert.equal(RouterStore.getMessagesPerPage(), UtilConstants.MSGBYPAGE);
      });

      it('Should be updated', () => {
        let messagesPerPage = 2;
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.SHOW, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), messagesPerPage);

        messagesPerPage = 10;
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.SHOW_ALL, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), messagesPerPage);
      });

      it('Shouldnt be updated', () => {
        const messagesPerPage = 10;
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.CREATE, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.EDIT, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.CREATE, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.EDIT, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.REPLY, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.REPLY_ALL, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.FORWARD, messagesPerPage },
        });
        assert.equal(RouterStore.getMessagesPerPage(), null);
      });
    });


    describe.skip('getMessagesList', () => {

    });

    describe.skip('getFilterFunction', () => {
      /*
        1. ajouter un flag
        2. tester un message de la même mailbox
        3. tester un message d'une autre mailbox
      */
    });


    describe('UseCases', () => {
      it.skip('At first nothing should be stored', () => {
        // TODO: vérifier que messageLength et mis à jour à
        // chaque lancement de cette méthode
      });

      // Skipped after account redux migration
      // TODO: make the acount fixture as Immutable
      describe('Goto last page should set `isComplete` falsy', () => {
        let action;
        let accountID;
        let mailboxID;
        let messages;

        beforeEach(() => {
          Dispatcher.dispatch({
            type: ActionTypes.MESSAGE_RESET_REQUEST,
          });
          action = MessageActions.SHOW_ALL;
          accountID = AccountStore.getDefault().get('id');
          mailboxID = AccountStore.getDefault().get('inboxMailbox');
          messages = [];
        });

        afterEach(() => {
          Dispatcher.dispatch({
            type: ActionTypes.MESSAGE_RESET_REQUEST,
          });
        });

        it.skip('With default MSGBYPAGE', () => {
          Dispatcher.dispatch({
            type: ActionTypes.ROUTE_CHANGE,
            value: { action, mailboxID },
          });

          messages = createMessages(35);

          let request = {
            page: 0,
            isComplete: false,
            hasNextPage: true,
          };

          testMoreMessages(messages.slice(0, 5), request, false);

          request.page = 1;
          testMoreMessages(messages.slice(5, 15), request, false);

          request.page = 2;
          testMoreMessages(messages.slice(15, 30), request, true);

          // If nextURL is twice the same
          // then disable feature
          request.page = 3;
          testMoreMessages(messages.slice(30, 35), request, true);

          request = RouterStore.getLastFetch();
          request.page = 4;
          request.isComplete = true;
          request.hasNextPage = false;
          testMoreMessages(messages.slice(10, 20), request, true);
        });


        it.skip('With 5 MSGBYPAGE', () => {
          const messagesPerPage = 5;
          const nbTotal = 13;

          // Change MaxSize of mailbox
          // to fit to this test
          const mailbox = AccountStore.getMailbox(accountID, mailboxID).toJS();
          mailbox.nbTotal = nbTotal;
          Dispatcher.dispatch({
            type: ActionTypes.RECEIVE_MAILBOX_CREATE,
            value: mailbox,
          });

          // Update messagesPerPage
          // and select the right mailbox
          Dispatcher.dispatch({
            type: ActionTypes.ROUTE_CHANGE,
            value: { action, mailboxID, messagesPerPage },
          });

          messages = createMessages(mailbox.nbTotal);

          let request = {
            page: 0,
            isComplete: false,
            hasNextPage: true,
          };
          testMoreMessages(messages.slice(0, 1), request, false);

          request.page = 1;
          testMoreMessages(messages.slice(1, 5), request, true);

          request.page = 2;
          testMoreMessages(messages.slice(2, 8), request, true);

          request = RouterStore.getLastFetch();
          request.page = 3;
          request.hasNextPage = true;
          testMoreMessages(messages.slice(0, 3), request, true);

          request.page = 4;
          request.isComplete = false;
          request.hasNextPage = true;
          delete request.start;
          testMoreMessages(messages.slice(8, 13), request, true);

          request = RouterStore.getLastFetch();
          request.page = 5;
          request.isComplete = true;
          request.hasNextPage = false;
          testMoreMessages(messages.slice(0, 13), request, true);
        });
      });

      it.skip('Each request should be saved with a uniq URI', () => {
        // TODO: update URL with several mailboxID && flags or filters
        // each pageValue should be saved for each request path
      });


      it.skip('Nothing should be stored with falsy `params`', () => {

      });


      function createMessages(max) {
        const result = [];
        if (undefined === max) max = 1;
        let counter = max;
        while (counter > 0) {
          const date = new Date(2014, 1, counter);
          result.push(MessageFixtures.createMessage({ account, date }));
          --counter;
        }
        return result;
      }


      function testMoreMessages(messages, req, isPageComplete) {
        const request = _.cloneDeep(req);
        const hasNextPage = request.hasNextPage;
        delete request.hasNextPage;

        if (undefined === request.start) {
          request.start = _.last(messages).date;
        }

        Dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FETCH_SUCCESS,
          value: { result: { messages }, url: RouterStore.getNextRequest() },
        });

        assert.equal(RouterStore.hasNextPage(), hasNextPage);
        assert.deepEqual(RouterStore.getLastFetch(), request);

        // Get filtered messages from all messages
        RouterStore.getMessagesList();

        // Test min-length
        assert.equal(RouterStore.isPageComplete(), isPageComplete);
      }
    });

    describe.skip('getNearestMessage', () => {

    });

    describe.skip('getConversation', () => {

    });

    describe.skip('getNextConversation', () => {

    });

    describe.skip('getPreviousConversation', () => {

    });

    describe.skip('getConversationLength', () => {

    });
  });


  describe('Actions', () => {
    beforeEach(() => {
      resetStore();
    });
    // testé dans tous les tests précédents
    // cf getCOnversationID, getMessageID, getAccountID etc.
    // it.skip('ROUTE_CHANGE', () => {
    //
    // });

    // testé dans tous les tests précédents
    // cf getRouter
    // it.skip('ROUTES_INITIALIZE', () => {
    // });

    it('REMOVE_ACCOUNT_SUCCESS', () => {
      accounts = AccountStore.getAll();
      const accountIDs = _.keys(accounts.toJS());
      const firstAccount = accountIDs.shift();

      // while we are editing the account
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: {
          action: AccountActions.EDIT,
          accountID: firstAccount },
      });

      console.log(RouterStore.getRouteObject())

      // No changes
      Dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: { accountID: firstAccount, silent: true },
      });

      console.log(RouterStore.getRouteObject())

      // ROMAINEDIT : action is never null
      assert.equal(RouterStore.getAction(), AccountActions.EDIT);
      assert.notEqual(RouterStore.getAccountID(), firstAccount);


      // If an account is found,
      // then edit default account
      Dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: { accountID: accountIDs.shift() },
      });
      assert.equal(RouterStore.getAction(), AccountActions.EDIT);

      console.log(RouterStore.getRouteObject())

      // If no account found,
      // then create a new account
      Dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: { accountID: accountIDs.shift() },
      });
      assert.equal(RouterStore.getAction(), AccountActions.CREATE);
    });

    it.skip('MESSAGE_FETCH_SUCCESS', () => {
      /*
        1. should update URL:
           - if fetch is about conversationID displayed

        2. should update _lastPage[_URI]
      */
    });

    it('DISPLAY_MODAL', () => {
      assert.equal(RouterStore.getModalParams(), null);
      Dispatcher.dispatch({
        type: ActionTypes.DISPLAY_MODAL,
        value: 'plop',
      });
      assert.equal(RouterStore.getModalParams(), 'plop');
    });

    it('HIDE_MODAL', () => {
      Dispatcher.dispatch({
        type: ActionTypes.DISPLAY_MODAL,
        value: 'plop',
      });
      assert.equal(RouterStore.getModalParams(), 'plop');

      Dispatcher.dispatch({
        type: ActionTypes.HIDE_MODAL,
      });
      assert.equal(RouterStore.getModalParams(), null);
    });

    it.skip('MESSAGE_TRASH_REQUEST', () => {
      //  select neareastMessage if {(target: {messageID})} === _messageID
    });

    it.skip('MESSAGE_TRASH_SUCCESS', () => {
      /*
        Should select nearest message if {(target: {messageID})} === _messageID
        should updateURL (URIbefore/URIafter)
      */
    });

    it.skip('MESSAGE_TRASH_FAILURE', () => {
      // Reset _nearestMessage
    });

    it.skip('RECEIVE_MESSAGE_DELETE', () => {
        /*
          Should find nearest message from messageID
          Should select nearest message if {(target: {messageID})} === _messageID
          should updateURL (URIbefore/URIafter)
        */
    });

    it.skip('MESSAGE_FLAGS_SUCCESS', () => {
      //  Should test RouterStore.emit.change is emitted
    });

    it.skip('SETTINGS_UPDATE_REQUEST', () => {
      //  Should test RouterStore.emit.change is emitted
    });
  });


  function resetStore() {
    accounts = [
      AccountFixtures.createAccount(),
      AccountFixtures.createAccount(),
      AccountFixtures.createAccount(),
    ];
    account = accounts[0];
    global.window = { accounts };
    const tools = makeTestDispatcher();
    Dispatcher = tools.Dispatcher;
    MessageStore = tools.makeStateFullGetter(MessageGetter);
    AccountStore = tools.makeStateFullGetter(AccountGetter);
    RouterStore = tools.makeStateFullGetter(RouterGetter);
  }


  function toQueryParameters(data) {
    if (data) {
      const key = encodeURI(_.keys(data)[0]);

      // Be carefull of Array values
      let value = _.values(data)[0];
      if (_.isArray(value)) value = value.join('&');

      return `?${key}=${encodeURI(value)}`;
    }
    return '';
  }
});
