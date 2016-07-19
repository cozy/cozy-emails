'use strict';

const assert = require('chai').assert;
const Immutable = require('immutable');
const map = Immutable.Map;
const _ = require('lodash');

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const SpecRouter = require('./utils/specs_router');
const sinon = require('sinon');

const UtilConstants = require('../../server/utils/constants');
const Constants = require('../app/constants/app_constants');
const ActionTypes = Constants.ActionTypes;
const AccountActions = Constants.AccountActions;
const MessageActions = Constants.MessageActions;
const MessageFilter = Constants.MessageFilter;
const MessageFlags = Constants.MessageFlags;

const getUID = require('./utils/guid').getUID;
const AccountFixtures = require('./fixtures/account')
const MessageFixtures = require('./fixtures/message')


describe('RouterStore', () => {
  let RouterStore;
  let AccountStore;
  let MessageStore;
  let Dispatcher;
  let account;
  let routes;
  const router = new SpecRouter();

  /*
   * Problem noticed:
   *
   * * FIXME: Private methods are melted with public ones.
   * * FIXME: Code is shared between client and server.
   */

  before(() => {
    Dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(Dispatcher);

    mockeryUtils.initForStores([
      '../stores/account_store',
      '../app/stores/account_store',
      '../stores/message_store',
      '../app/stores/message_store',
      '../stores/requests_store',
      '../app/stores/router_store',
      '../../../server/utils/constants',
    ]);
    AccountStore = require('../app/stores/account_store');
    MessageStore = require('../app/stores/message_store');
    RouterStore = require('../app/stores/router_store');
  });


  after(() => {
    mockeryUtils.clean();
  });

  beforeEach(() => {
    Dispatcher.dispatch({
      type: ActionTypes.ROUTES_INITIALIZE,
      value: router,
    });

    // Reverse relation value to simplify tests
    // ie. routes['messageList'] = url
    if (undefined === routes) {
      routes = RouterStore.getRouter().routes;
      routes = _.transform(routes, (result, value, key) => {
        result[value] = key;
      }, {});
    }
  });


  describe('Basics', () => {

    beforeEach(() => {
      createAccountFixtures()
    });

    afterEach(() => {
      resetAccountFixtures()
    });


    it('getRouter', () => {
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

      it('Should save `value`', () => {
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
      it('Shouldnt find `(default) Account`', () => {
        assert.equal(RouterStore.getAccount(), undefined);
      });

      it('Should save `Account`', () => {
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
          value: { accountID: input.get('id') }
        });
        const output = RouterStore.getAccount(input.get('id'));
        assert.equal(output.get('id'), input.get('id'));
      });
    });


    it('getDefaultAccount', () => {
      const input = AccountStore.getAll().first();
      const output = RouterStore.getDefaultAccount();
      assert.deepEqual(input.toJS(), output.toJS())
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

      it('Should save `mailboxID`', () => {
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

      it('Should find `(default) Account.mailbox`', () => {
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
          value: { mailboxID: input.get('inboxMailbox') }
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

      it('Should return `(default) Account`', () => {
        const input = accounts[0].get('mailboxes');
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        const output = RouterStore.getAllMailboxes();
        assert.deepEqual(input.toJS(), output.toJS())
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
      })

      it('Should return `null`', () => {
        assert.equal(RouterStore.getMessageID(), null);
      });

      it('Shouldnt be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        assert.equal(RouterStore.getMessageID(), null);

        // MessageID always works with conversationID
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { messageID }
        });
        assert.equal(RouterStore.getMessageID(), null);
      });

      it('Should be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { messageID, conversationID }
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
      })

      it('Should return `null`', () => {
        assert.equal(RouterStore.getConversationID(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
        });
        assert.equal(RouterStore.getConversationID(), null);
      });

      it('Shouldnt be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { conversationID }
        });
        assert.equal(RouterStore.getConversationID(), null);
      });

      it('Should be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { messageID, conversationID }
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
        assert.equal(RouterStore.getAction(), null)
      });

      it('Should be updated', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: 'ploups' },
        });
        assert.equal(RouterStore.getAction(), 'ploups');
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
        const flags = MessageFilter.UNSEEN
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: {flags} }
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
          value: { filter: null }
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
          value: { filter: { flags: MessageFilter.UNSEEN } }
        });
        assert.isTrue(RouterStore.isUnread());

        // Add Flagged filter into URI
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.FLAGGED } }
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
        let message = MessageStore.getAll().find((message) => {
         return !message.get('flags').length;
        });
        assert.notEqual(message, undefined);
        assert.isTrue(RouterStore.isUnread(message));

        // Test on read message
        message = MessageStore.getAll().find((message) => {
         return message.get('flags').length;
        });
        assert.notEqual(message, undefined);
        assert.isFalse(RouterStore.isUnread(message));
      });

    });


    describe('isFlagged', () => {
      it('Should return `mailbox.flagged`', () => {
        assert.isFalse(RouterStore.isFlagged());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.FLAGGED } }
        });
        assert.isTrue(RouterStore.isFlagged());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.ATTACH } }
        });
        let message = MessageStore.getAll().find((message) => {
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
        let message = MessageStore.getAll().find((message) => {
          return -1 < message.get('flags').indexOf(MessageFlags.FLAGGED)
        });
        assert.notEqual(message, undefined);
        assert.isTrue(RouterStore.isFlagged(message));

        // Test on un-flagged message
        message = MessageStore.getAll().find((message) => {
          return -1 === message.get('flags').indexOf(MessageFlags.FLAGGED)
        });
        assert.notEqual(message, undefined);
        assert.isFalse(RouterStore.isFlagged(message));
      });
    });


    describe('isAttached', () => {
      it('Should return `mailbox.attached`', () => {
        assert.isFalse(RouterStore.isAttached());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.ATTACH } }
        });
        assert.isTrue(RouterStore.isAttached());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { filter: { flags: MessageFilter.UNREAD } }
        });
        assert.isFalse(RouterStore.isAttached());
      });

      it('Should return `mailbox.attached`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: MessageFixtures.createAttached({ account }),
        });
        let message = MessageStore.getAll().find((message) => {
          return message.get('attachments').size
        });
        assert.notEqual(message, undefined);
        assert.isTrue(RouterStore.isAttached(message));

        message = MessageStore.getAll().find((message) => {
          return -1 === message.get('flags').indexOf(MessageFlags.ATTACH)
        });
        assert.notEqual(message, undefined);
        assert.isFalse(RouterStore.isAttached(message));
      });
    });


    describe('isDeleted', () => {
      it('Should return `mailbox.deleted`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.inboxMailbox }
        });
        assert.isFalse(RouterStore.isDeleted());

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.trashMailbox }
        });
        assert.isTrue(RouterStore.isDeleted());
      });

      it('Should return `message.deleted`', () => {
        const input = MessageFixtures.createTrash({ account });

        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: input,
        });
        let message = MessageStore.getByID(input.id);
        assert.notEqual(message, undefined);
        assert.isTrue(RouterStore.isDeleted(message));

        message = MessageStore.getAll().find((message) => {
          return message.get('mailboxIDs')[account.trashMailbox] === undefined;
        });
        assert.notEqual(message, undefined);
        assert.isFalse(RouterStore.isDeleted(message));
      });
    });

    // Add test for MessageStore.isDraft()
    describe('isDraft', () => {
      it('Should return `false`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.inboxMailbox }
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
        assert.isTrue(RouterStore.isDraft(message));

        message = MessageStore.getAll().find((message) => {
          return -1 === message.get('flags').indexOf(MessageFlags.DRAFT);
        });
        assert.notEqual(message, undefined);
        assert.isFalse(RouterStore.isDraft(message));
      });

      it('Should return `mailbox.isDraft`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.draftMailbox }
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
          value: { mailboxID: account.inboxMailbox }
        });

        const mailbox = RouterStore.getMailbox();
        const value = RouterStore.getMailboxTotal();
        assert.equal(value, mailbox.get('nbTotal'));
      });

      it('Should return `flaggedMailbox.nbTotal`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { mailboxID: account.flaggedMailbox }
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
          value: { mailboxID: account.unreadMailbox }
        });
        const inbox = getInbox();
        const mailbox = RouterStore.getMailbox();
        const value = RouterStore.getMailboxTotal();
        assert.equal(value, inbox.get('nbUnread'));
        assert.equal(value, mailbox.get('nbTotal'));
      });

      function getInbox() {
        const account = RouterStore.getAccount();
        const accountID = account.get('id');
        const mailboxID = account.get('inboxMailbox');
        return AccountStore.getMailbox(accountID, mailboxID);
      }
    });


    describe('getSelectedTab', () => {

      it('Should return `null`', () => {
        assert.equal(RouterStore.getSelectedTab(), null);
      });

      it('Shouldnt be stored (err)', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.CREATE }
        });
        assert.equal(RouterStore.getSelectedTab(), null);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.CREATE, tab: 'plip' }
        });
        assert.equal(RouterStore.getSelectedTab(), null);
      });

      it('Should return (default) `value`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.EDIT }
        });
        assert.equal(RouterStore.getSelectedTab(), 'account');
        assert.equal(RouterStore.getSelectedTab(), RouterStore.getDefaultTab());
      });

      it('Should save dispatched `value`', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: AccountActions.EDIT, tab: 'plip' }
        });
        assert.equal(RouterStore.getSelectedTab(), 'plip');
      });

      it('Should reset `value` when `action` changes', () => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: MessageActions.SHOW }
        });
        assert.equal(RouterStore.getSelectedTab(), null);
      });
    });
  });


  describe('Routing', () => {

    describe('getURL', () => {

      afterEach(() => {
        resetAccountFixtures()
      });

      describe('defaultView', () => {
        it('Should goto `AccountNew` (no account found)', () => {
          let url = RouterStore.getURL().replace('#', '');
          assert.equal(url, routes['accountNew']);
          assert.equal(url, RouterStore.getURL({ isServer: true }));
        });

        it('Should goto `MessageList` (default account)', () => {
          testMessagesList();
        });
      });

      describe('messagesList', () => {
        it('Shouldnt handle filters', () => {
          testMessagesList();
        });

        it('Should handle filter', () => {
          const filter = {'plop': 'one value'};
          testMessagesList({filter});
        });

        it('Should handle all filters', () => {
          const filter = {'plop': ['several', 'values', 'with special chars']};
          testMessagesList({filter});
        });
      });

      it('accountNew', () => {
        const action = AccountActions.CREATE;
        testAccountURI({action}, 'accountNew');
      });

      it('accountEdit', () => {
        const action = AccountActions.EDIT;
        testAccountURI({action}, 'accountEdit');
      });

      it('messageNew', () => {
        const action = MessageActions.CREATE;
        testMessage({action}, 'messageNew');
      });

      it('messageEdit', () => {
        const action = MessageActions.EDIT;
        testMessage({action}, 'messageEdit');
      });

      it('messageForward', () => {
        const action = MessageActions.FORWARD;
        testMessage({action}, 'messageForward');
      });

      it('messageReply', () => {
        const action = MessageActions.REPLY;
        testMessage({action}, 'messageReply');
      });

      it('messageReplyAll', () => {
        const action = MessageActions.REPLY_ALL;
        testMessage({action}, 'messageReplyAll');
      });

      it('messageShow', () => {
        const action = MessageActions.SHOW;
        testMessage({action}, 'messageShow');
      });


      function testAccountURI(data, keyRoute) {
        let route = _.cloneDeep(routes[keyRoute]);
        let params = Object.assign({
          mailboxID: 'mailboxID',
          accountID: 'accountID',
          tab: RouterStore.getDefaultTab(),
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
        Dispatcher.dispatch({
          type: ActionTypes.ADD_ACCOUNT_SUCCESS,
          value: { account: AccountFixtures.createAccount() },
        });

        const params = Object.assign({
          action: MessageActions.SHOW_ALL,
          mailboxID: RouterStore.getDefaultAccount().get('inboxMailbox')
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


    // TODO: testser avec options et parmas par défaut
    describe('getCurrentURL', () => {
      let action = MessageActions.EDIT;
      let spy;

      beforeEach(() => {
        if (undefined === spy) spy = sinon.spy(RouterStore, 'getURL');
      });

      afterEach(() => {
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action: null },
        });
        spy.reset();
      });


      it('Should get saved data', () => {
        // No actions saved
        let url = RouterStore.getCurrentURL();
        assert.equal(spy.callCount, 0);

        // No actions saved
        url = RouterStore.getCurrentURL({ messageID: 'plop' });
        assert.equal(spy.callCount, 0);

        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action },
        });
        spy.reset();

        url = RouterStore.getCurrentURL({ messageID: 'plop' });
        assert.equal(spy.callCount, 1);
      });

      it('Shouldnt be called', () => {
        let url = RouterStore.getCurrentURL({ messageID: 'plop' });
        assert.equal(spy.callCount, 0);

        url = RouterStore.getCurrentURL({ action, messageID: 'plop' });
        assert.equal(spy.callCount, 1);
      });

      it('Should send validated params', () => {
        const url = RouterStore.getCurrentURL({ action });
        const params = {
          isServer: true,
          action,
          mailboxID: null,
          conversationID: null,
          messageID: null,
        }
        assert.equal(spy.callCount, 1);
        assert.deepEqual(spy.getCall(0).args, [params]);
      });

    });

    describe('getURI', () => {

      afterEach(() => {
        resetAccountFixtures()
      });

      it('defaultView', () => {
        assert.isNull(RouterStore.getURI());
      });

      it('messagesList', () => {
        const action = MessageActions.SHOW_ALL;
        testMessageURI(action)
      });

      it('messageNew', () => {
        const action = MessageActions.CREATE;
        testMessageURI(action)
      });

      it('messageEdit', () => {
        const action = MessageActions.EDIT;
        testMessageURI(action)
      });

      it('messageForward', () => {
        const action = MessageActions.FORWARD;
        testMessageURI(action)
      });

      it('messageReply', () => {
        const action = MessageActions.REPLY;
        testMessageURI(action)
      });

      it('messageReplyAll', () => {
        const action = MessageActions.REPLY_ALL;
        testMessageURI(action)
      });

      it('messageShow', () => {
        const action = MessageActions.SHOW;
        testMessageURI(action)
      });

      it('accountNew', () => {
        const action = AccountActions.CREATE;
        testAccountURI(action);
      });

      it('accountEdit', () => {
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
        result = `action=${action}`
        if (undefined !== accountID) result += `&accountID=null`;
        assert.equal(RouterStore.getURI(), result);

        // With accountID
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID, mailboxID: 'PLOP' },
        });
        result = `action=${action}`
        if (undefined !== accountID) result += `&accountID=${accountID}`;
        assert.equal(RouterStore.getURI(), result);

        // With one filter
        let filter = {'plop': 'one value'}
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, filter },
        });
        result = `action=${action}`
        if (undefined !== accountID) result += `&accountID=null`;
        assert.equal(RouterStore.getURI(), result);
      }

      function testMessageURI(action) {
        const mailboxID = 'mailboxID';
        const accountID = 'accountID';

        let conversationID;
        let messageID;

        if (MessageActions.SHOW_ALL !== action) {
          conversationID = 'conversationID'
          messageID = 'messageID';
        }

        // Without any params
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action },
        });
        let result = `action=${action}&accountID=null&mailboxID=null`;
        if (undefined !== conversationID) result += `&conversationID=null`;
        if (undefined !== messageID) result += `&messageID=null`;
        assert.equal(RouterStore.getURI(), result);

        // Without mailboxID
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID },
        });
        result = `action=${action}&accountID=${accountID}&mailboxID=null`
        if (undefined !== conversationID) result += `&conversationID=null`;
        if (undefined !== messageID) result += `&messageID=null`;
        assert.equal(RouterStore.getURI(), result);

        // With all params
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID, mailboxID, conversationID, messageID },
        });
        result = `action=${action}&accountID=${accountID}&mailboxID=${mailboxID}`
        if (undefined !== conversationID) result += `&conversationID=${conversationID}`;
        if (undefined !== messageID) result += `&messageID=${messageID}`;
        assert.equal(RouterStore.getURI(), result);

        // With one filter
        let filter = {'plop': 'one value'}
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID, mailboxID, conversationID, messageID, filter },
        });
        result = `action=${action}&accountID=${accountID}&mailboxID=${mailboxID}`
        if (undefined !== conversationID) result += `&conversationID=${conversationID}`;
        if (undefined !== messageID) result += `&messageID=${messageID}`;
        result += `&query=${toQueryParameters(filter)}`
        assert.equal(RouterStore.getURI(), result);

        // With several filters
        filter = {'plop': ['several', 'values', 'with special chars']};
        Dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { action, accountID, mailboxID, conversationID, messageID, filter },
        });
        result = `action=${action}&accountID=${accountID}&mailboxID=${mailboxID}`
        if (undefined !== conversationID) result += `&conversationID=${conversationID}`;
        if (undefined !== messageID) result += `&messageID=${messageID}`;
        result += `&query=${toQueryParameters(filter)}`
        assert.equal(RouterStore.getURI(), result);
      }
    });

    it.skip('getMessagesPerPage', () => {

    });

    it.skip('hasNextPage', () => {

    });

    it.skip('getLastPage', () => {

    });

    it.skip('isPageComplete', () => {

    });



    describe.skip('getMessagesList', () => {

    });

    describe.skip('filterByFlags', () => {
      /*
        1. ajouter un flag
        2. tester un message de la même mailbox
        3. tester un message d'une autre mailbox
      */
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


  describe.skip('Actions', () => {

    beforeEach(() => {
      createAccountFixtures()
    });

    afterEach(() => {
      resetAccountFixtures()
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
      const accounts = AccountStore.getAll();
      const accountIDs = _.keys(accounts.toJS());

      // No changes
      Dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: { accountID: accountIDs.shift(), silent: true },
      });
      assert.equal(RouterStore.getAction(), null);

      // If an account is found,
      // then cedit default account
      Dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: { accountID: accountIDs.shift() },
      });
      assert.equal(RouterStore.getAction(), AccountActions.EDIT);

      // If no account found,
      // then create a new account
      Dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: { accountID: accountIDs.shift() },
      });
      assert.equal(RouterStore.getAction(), AccountActions.CREATE);
    });

    // TODO: should be removed soon
    // it.skip('ADD_ACCOUNT_SUCCESS', () => {
    // });

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


  function createAccountFixtures() {
    // Add 3 accounts to test
    // several usecases
    account = AccountFixtures.createAccount();
    Dispatcher.dispatch({
      type: ActionTypes.ADD_ACCOUNT_SUCCESS,
      value: { account },
    });
    Dispatcher.dispatch({
      type: ActionTypes.ADD_ACCOUNT_SUCCESS,
      value: { account: AccountFixtures.createAccount() },
    });
    Dispatcher.dispatch({
      type: ActionTypes.ADD_ACCOUNT_SUCCESS,
      value: { account: AccountFixtures.createAccount() },
    });

    // Add messages
    // that belongs to defaultAccount
    const conversationID = `coucou-${getUID()}`;
    const params = {conversationID, account};
    const messages = [];
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    Dispatcher.dispatch({
      type: ActionTypes.RECEIVE_RAW_MESSAGES,
      value: messages,
    });
  }

  function resetAccountFixtures() {
    Dispatcher.dispatch({
      type: ActionTypes.MESSAGE_RESET_REQUEST,
    });
    Dispatcher.dispatch({
      type: ActionTypes.RESET_ACCOUNT_REQUEST,
    });
  }

  function toQueryParameters(data) {
    if (data) {
      let key = encodeURI(_.keys(data)[0]);

      // Be carefull of Array values
      let value = _.values(data)[0];
      if (_.isArray(value)) value = value.join('&');

      return `?${key}=${encodeURI(value)}`;
    }
    return '';
  }
});
