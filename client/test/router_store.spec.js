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
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    Dispatcher.dispatch({
      type: ActionTypes.RECEIVE_RAW_MESSAGES,
      value: messages,
    });
  });

  afterEach(() => {
    Dispatcher.dispatch({
      type: ActionTypes.MESSAGE_RESET_REQUEST,
    });
    Dispatcher.dispatch({
      type: ActionTypes.RESET_ACCOUNT_REQUEST,
    });
  });

  describe('Methods', () => {

    it('getRouter', () => {
      const result = RouterStore.getRouter();
      assert.equal(result, router);
      assert.equal(typeof result, 'object');
      assert.isTrue(!!result);
    });


    it('getAccountID', () => {
      const accounts = AccountStore.getAll().toArray();

      // Get default value
      let output = RouterStore.getAccountID();
      assert.equal(output, undefined);

      // Save direct value
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
      });
      output = RouterStore.getAccountID();
      assert.equal(output, accounts[0].get('id'));
      assert.notEqual(output, undefined);

      // Save direct value
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { accountID: accounts[1].get('id') },
      });
      output = RouterStore.getAccountID();
      assert.equal(output, accounts[1].get('id'));
      assert.notEqual(output, undefined);

      // Get AccountID from mailboxID
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: accounts[2].get('inboxMailbox') },
      });
      output = RouterStore.getAccountID();
      assert.equal(output, accounts[2].get('id'));
      assert.notEqual(output, undefined);
    });

    it('getAccount', () => {
      // Default value is undefined
      assert.equal(RouterStore.getAccount(), undefined);

      // Should save defaultValue
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
      });
      let input = AccountStore.getDefault();
      let output = RouterStore.getAccount();
      assert.equal(output.get('id'), input.get('id'));

      // Should save accountID
      input = AccountStore.getAll().toArray()[1];
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { accountID: input.get('id') }
      });
      output = RouterStore.getAccount(input.get('id'));
      assert.equal(output.get('id'), input.get('id'));
    });

    it('getDefaultAccount', () => {
      const input = AccountStore.getAll().first();
      const output = RouterStore.getDefaultAccount();
      assert.deepEqual(input.toJS(), output.toJS())
    });


    it('getMailboxID', () => {
      const accounts = AccountStore.getAll().toArray();

      // Get default value
      let output = RouterStore.getMailboxID();
      assert.equal(output, undefined);

      // Save direct value
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
      });
      output = RouterStore.getMailboxID();
      assert.equal(output, accounts[0].get('inboxMailbox'));
      assert.notEqual(output, undefined);

      // Save direct value
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: accounts[1].get('inboxMailbox') },
      });
      output = RouterStore.getMailboxID();
      assert.equal(output, accounts[1].get('inboxMailbox'));
      assert.notEqual(output, undefined);

      // Get AccountID from mailboxID
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { accountID: accounts[2].get('id') },
      });
      output = RouterStore.getMailboxID();
      assert.equal(output, accounts[2].get('inboxMailbox'));
      assert.notEqual(output, undefined);
    });

    it('getMailbox', () => {
      // Default value is undefined
      assert.equal(RouterStore.getMailbox(), undefined);

      // Should save defaultValue
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
      });
      let input = AccountStore.getAll().toArray()[0];
      let output = RouterStore.getMailbox();
      assert.equal(output.get('id'), input.get('inboxMailbox'));
      assert.equal(output.get('id'), RouterStore.getMailboxID());

      // Should save value
      input = AccountStore.getAll().toArray()[1];
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: input.get('inboxMailbox') }
      });
      output = RouterStore.getMailbox();
      assert.equal(output.get('id'), input.get('inboxMailbox'));
    });

    it('getAllMailboxes', () => {
      const accounts = AccountStore.getAll().toArray();

      // Default value is undefined
      assert.equal(RouterStore.getAllMailboxes(), undefined);

      // Test default Account
      let input = accounts[0].get('mailboxes');
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
      });

      let output = RouterStore.getAllMailboxes();
      assert.deepEqual(input.toJS(), output.toJS())

      // Test with defined account
      input = accounts[2].get('mailboxes');
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { accountID: accounts[2].get('id') },
      });
      output = RouterStore.getAllMailboxes(accounts[2].get('id'));
      assert.deepEqual(input.toJS(), output.toJS());
    });


    it('getMessageID', () => {
      assert.equal(RouterStore.getMessageID(), null);

      // Preset value
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
      });
      assert.equal(RouterStore.getMessageID(), null);

      // MessageID always works with conversationID
      const messages = MessageStore.getAll().toArray();
      let messageID = messages[2].get('id');
      let conversationID = messages[2].get('conversationID');
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { messageID }
      });
      assert.equal(RouterStore.getMessageID(), null);

      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { messageID, conversationID }
      });
      assert.equal(RouterStore.getMessageID(), messageID);
    });

    it('getConversationID', () => {
      assert.equal(RouterStore.getConversationID(), null);

      // Preset value
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
      });
      assert.equal(RouterStore.getConversationID(), null);

      // MessageID always works with conversationID
      const messages = MessageStore.getAll().toArray();
      let messageID = messages[1].get('id');
      let conversationID = messages[1].get('conversationID');
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { conversationID }
      });
      assert.equal(RouterStore.getConversationID(), null);

      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { messageID, conversationID }
      });
      assert.equal(RouterStore.getConversationID(), conversationID);
    });


    it('getAction', () => {
      const accounts = AccountStore.getAll();
      const accountIDs = _.keys(accounts.toJS());

      // Default value
      assert.equal(RouterStore.getAction(), null)

      //  Set action
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { action: 'ploups' },
      });
      assert.equal(RouterStore.getAction(), 'ploups');
    });


    // TODO: add test for value, sort, before and after
    // when it will be handled by components
    it('getFilter', () => {
      const defaultValue = RouterStore.getFilter();
      assert.notEqual(defaultValue, undefined);
      assert.equal(defaultValue.sort, '-date');
      assert.isNull(defaultValue.flags);
      assert.isNull(defaultValue.value);
      assert.isNull(defaultValue.before);
      assert.isNull(defaultValue.after);

      let flags = MessageFilter.UNSEEN
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { filter: {flags} }
      });

      // Filter.flags should have change
      let filter = RouterStore.getFilter();
      assert.equal(filter.flags, flags);
      assert.equal(filter.sort, defaultValue.sort);
      assert.equal(filter.value, defaultValue.value);
      assert.equal(filter.before, defaultValue.before);
      assert.equal(filter.after, defaultValue.after);

      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { filter: null }
      });

      // Filter should be reset
      filter = RouterStore.getFilter();
      assert.deepEqual(filter, defaultValue);
    });

    it('isUnread', () => {
      assert.isFalse(RouterStore.isUnread());

      // Add Unseen filter into URI
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { filter: { flags: MessageFilter.UNSEEN } }
      });
      assert.isTrue(RouterStore.isUnread());

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

      // Add Flagged filter into URI
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { filter: { flags: MessageFilter.FLAGGED } }
      });
      assert.isFalse(RouterStore.isUnread());
    });


    it('isFlagged', () => {
      assert.isFalse(RouterStore.isFlagged());

      // Add Unseen filter into URI
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { filter: { flags: MessageFilter.FLAGGED } }
      });
      assert.isTrue(RouterStore.isFlagged());

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

      // Add Flagged filter into URI
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { filter: { flags: MessageFilter.ATTACH } }
      });
      assert.notEqual(message, undefined);
      assert.isFalse(RouterStore.isFlagged());

    });


    it('isAttached', () => {
      assert.isFalse(RouterStore.isAttached());

      // Add Attach filter into URI
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { filter: { flags: MessageFilter.ATTACH } }
      });
      assert.isTrue(RouterStore.isAttached());

      // Add Attached message
      Dispatcher.dispatch({
        type: ActionTypes.RECEIVE_RAW_MESSAGE,
        value: MessageFixtures.createAttached({ account }),
      });

      // Test Attached message
      let message = MessageStore.getAll().find((message) => {
        return message.get('attachments').size
      });
      assert.notEqual(message, undefined);
      assert.isTrue(RouterStore.isAttached(message));

      // Test a none attached message
      message = MessageStore.getAll().find((message) => {
        return -1 === message.get('flags').indexOf(MessageFlags.ATTACH)
      });
      assert.notEqual(message, undefined);
      assert.isFalse(RouterStore.isAttached(message));

      // Add Attach filter into URI
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { filter: { flags: MessageFilter.UNREAD } }
      });
      assert.isFalse(RouterStore.isAttached());
    });


    it('isDeleted', () => {
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: account.inboxMailbox }
      });
      assert.isFalse(RouterStore.isDeleted());

      // Add Attached message
      Dispatcher.dispatch({
        type: ActionTypes.RECEIVE_RAW_MESSAGE,
        value: MessageFixtures.createTrash({ account }),
      });

      // Test Attached message
      let message = MessageStore.getAll().find((message) => {
        return message.get('mailboxIDs')[account.trashMailbox] !== undefined;
      });
      assert.notEqual(message, undefined);
      assert.isTrue(RouterStore.isDeleted(message));

      // Test a none attached message
      message = MessageStore.getAll().find((message) => {
        return message.get('mailboxIDs')[account.trashMailbox] === undefined;
      });
      assert.notEqual(message, undefined);
      assert.isFalse(RouterStore.isDeleted(message));

      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: account.trashMailbox }
      });
      assert.isTrue(RouterStore.isDeleted());
    });

    // Add test for MessageStore.isDraft()
    it('isDraft', () => {
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: account.inboxMailbox }
      });
      assert.isFalse(RouterStore.isDraft());

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

      // Test a no-draft message
      message = MessageStore.getAll().find((message) => {
        return -1 === message.get('flags').indexOf(MessageFlags.DRAFT);
      });
      assert.notEqual(message, undefined);
      assert.isFalse(RouterStore.isDraft(message));


      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: account.draftMailbox }
      });
      assert.isTrue(RouterStore.isDraft());
    });

    it('getMailboxTotal', () => {
      assert.equal(RouterStore.getMailboxTotal(), 0);

      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: account.inboxMailbox }
      });
      const _account = RouterStore.getAccount();
      const accountID = _account.get('id');
      const inboxID = _account.get('inboxMailbox');
      const inbox = AccountStore.getMailbox(accountID, inboxID);

      let mailbox = RouterStore.getMailbox();
      assert.equal(RouterStore.getMailboxTotal(), mailbox.get('nbTotal'));

      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: account.flaggedMailbox }
      });
      mailbox = RouterStore.getMailbox();
      assert.equal(RouterStore.getMailboxTotal(), inbox.get('nbFlagged'));
      assert.equal(RouterStore.getMailboxTotal(), mailbox.get('nbTotal'));

      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { mailboxID: account.unreadMailbox }
      });
      mailbox = RouterStore.getMailbox();
      assert.equal(RouterStore.getMailboxTotal(), inbox.get('nbUnread'));
      assert.equal(RouterStore.getMailboxTotal(), mailbox.get('nbTotal'));
    });


    it('getURL', () => {

    });


    it.skip('getCurrentURL', () => {

    });

    it.skip('getURI', () => {

    });


    it.skip('getMessagesPerPage', () => {

    });

    it.skip('hasNextPage', () => {

    });

    it.skip('getLastPage', () => {

    });

    it.skip('isPageComplete', () => {

    });


    it('getSelectedTab', () => {
      // Not defined value
      assert.equal(RouterStore.getSelectedTab(), null);

      // Shoulndt be setted: bad actions
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

      // Default Value
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { action: AccountActions.EDIT }
      });
      assert.equal(RouterStore.getSelectedTab(), 'account');

      // Defined Value
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { action: AccountActions.EDIT, tab: 'plip' }
      });
      assert.equal(RouterStore.getSelectedTab(), 'plip');

      // Change route: reset
      Dispatcher.dispatch({
        type: ActionTypes.ROUTE_CHANGE,
        value: { action: MessageActions.SHOW }
      });
      assert.equal(RouterStore.getSelectedTab(), null);
    });

    it.skip('getMessagesList', () => {

    });

    it.skip('filterByFlags', () => {
      /*
        1. ajouter un flag
        2. tester un message de la même mailbox
        3. tester un message d'une autre mailbox
      */
    });

    it.skip('getNearestMessage', () => {

    });

    it.skip('getConversation', () => {

    });

    it.skip('getNextConversation', () => {

    });

    it.skip('getPreviousConversation', () => {

    });

    it.skip('getConversationLength', () => {

    });
  });


  describe('Actions', () => {

    beforeEach(() => {

    });

    afterEach(() => {

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
});
