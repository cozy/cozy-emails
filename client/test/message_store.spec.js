'use strict';

const assert = require('chai').assert;
const _ = require('lodash');
const Map = require('immutable').Map;

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;

const getUID = require('./utils/guid').getUID;
const MessageFixtures = require('./fixtures/message');
const AccountFixture = require('./fixtures/account');

describe('Message Store', () => {
  let MessageStore;
  let Dispatcher;

  const conversationID = `plop-${getUID()}`;
  const account = AccountFixture.createAccount();

  const date = new Date();

  const message = MessageFixtures.createMessage({date});
  const messageUnread = MessageFixtures.createUnread({date});
  const messageFlagged = MessageFixtures.createFlagged({date});
  const messageDraft = MessageFixtures.createDraft({date});
  const messageAttached = MessageFixtures.createAttached({date});

  let conversationLength = {};
  const messages = [];


  function isDate(key) {
    return -1 < ['date', 'updated', 'createdAt'].indexOf(key)
  }

  function testValues(output, input) {
    output = output.toJS();
    if (undefined === input) input = message;

    assert.equal(input.mailboxID, undefined);
    assert.equal(typeof output.mailboxID, 'string');
    delete output.mailboxID;

    if (undefined === input.attachments) {
      assert.equal(input.attachments, undefined);
      assert.deepEqual(output.attachments, []);
      delete output.attachments;
    }

    // When Message is only flagged as Unread
    // sometime value can be undefined
    // instead of []
    if (undefined === input.flags) {
      delete output.flags;
    }

    _.each(output, (value, property) => {
      if ('object' === typeof value) {
        assert.deepEqual(value, input[property]);
      } else if (!isDate(property)) {
        assert.equal(value, input[property]);
      }
    });
  }

  function testConversationLength (id, mailboxID) {
    let length = MessageStore.getConversationLength(id);
    assert.equal(length, conversationLength[id]);

    length = MessageStore.getConversation(id, mailboxID).length;
    assert.equal(length, conversationLength[id]);
  }

  function testMessageAction(action, value) {
    assert.equal(MessageStore.getAll().size, 0);

    Dispatcher.dispatch({
      type: ActionTypes[action],
      value,
    });

    assert.equal(MessageStore.getAll().size, 1);
    testValues(MessageStore.getByID(message.id), message);
  }

  function testMessagesAction(action, value) {
    assert.equal(MessageStore.getAll().size, 0);

    Dispatcher.dispatch({
      type: ActionTypes[action],
      value,
    });

    assert.equal(MessageStore.getAll().size, messages.length);
    messages.forEach((msg) => testValues(MessageStore.getByID(msg.id), msg));
  }


  before(() => {
    // Add several messages
    // to create a conversation
    let params = {date, conversationID, account};
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));

    messages.push(message);
    messages.push(MessageFixtures.createMessage({date}));
    messages.push(MessageFixtures.createMessage({date}));
    messages.push(MessageFixtures.createMessage({images: true, date}));
    messages.push(MessageFixtures.createMessage({images: false, date}));

    // Add flagged messages
    messages.push(messageAttached);
    messages.push(messageUnread);
    messages.push(messageFlagged);
    messages.push(messageDraft);

    // Define conversationLength
    // from messages entries
    let keys = messages.map((msg) => msg.conversationID);
    let values = _.groupBy(messages, 'conversationID');
    conversationLength = _.mapValues(values, (value) => value.length);

    const path = '../app/stores/message_store';
    Dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(Dispatcher);
    mockeryUtils.initForStores([path]);
    MessageStore = require(path);
  });

  after(() => {
    mockeryUtils.clean();
  });


  /*
   * Problems noticed in the store file:
   * FIXME Underscore is used instead of lodash.
   * FIXME Action values are not normalized.
   */

  describe('Actions', () => {

    beforeEach(() => {

    });

    afterEach(() => {
      Dispatcher.dispatch({
        type: ActionTypes.MESSAGE_RESET_REQUEST,
      });
    });


    describe('Should ADD message(s)', () => {

      it('MESSAGE_FETCH_SUCCESS', () => {
        testMessagesAction('MESSAGE_FETCH_SUCCESS', {result: { messages }});
      });

      it('RECEIVE_RAW_MESSAGES', () => {
        testMessagesAction('RECEIVE_RAW_MESSAGES', messages);
      });

      it('RECEIVE_RAW_MESSAGE', () => {
        testMessageAction('RECEIVE_RAW_MESSAGE', message);
      });

      it('RECEIVE_RAW_MESSAGE_REALTIME', () => {
        testMessageAction('RECEIVE_RAW_MESSAGE_REALTIME', message);
      });

      it('MESSAGE_SEND_SUCCESS', () => {
        testMessageAction('MESSAGE_SEND_SUCCESS', {message});
      });
    });


    describe('Should UPDATE message(s)', () => {

      beforeEach(() => {
        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_RAW_MESSAGES,
          value: messages,
        });
      });

      afterEach(() => {
        Dispatcher.dispatch({
          type: ActionTypes.MESSAGE_RESET_REQUEST,
        });
      });


      it('MESSAGE_FLAGS_SUCCESS', () => {
        let message0 = _.cloneDeep(message);
        let output = MessageStore.getByID(message0.id);
        let defaultValue = message0.flags;
        assert.deepEqual(output.get('flags'), message0.flags);

        // Change values
        Object.assign(message0, {
          flags: [],
          updated: (new Date()).toISOString()
        });

        // Dispatch change
        Dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FLAGS_SUCCESS,
          value: { updated: { messages: [message0] } },
        });

        output = MessageStore.getByID(message0.id);
        assert.deepEqual(output.get('flags'), message0.flags);

        // Try changes that are older
        defaultValue = message0.flags;
        Object.assign(message0, {
          flags: defaultValue,
          updated: (new Date('2014-1-1')).toISOString(),
        })
        Dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FLAGS_SUCCESS,
          value: { updated: { messages: [message0] } },
        });
        output = MessageStore.getByID(message0.id);
      });

      it('MESSAGE_MOVE_SUCCESS', () => {
        // 1. dispatcher l'action
        // 2. vérifier que le messge du store a bien été modifier
        // 3. vérifier propriétés par propriétés

        // ({updated})
      });

      it('SEARCH_SUCCESS', () => {
        // 1. dispatcher l'action
        // 2. vérifier que le messge du store a bien été modifier
        // 3. vérifier propriétés par propriétés

        // ((message))
      });

      it('SETTINGS_UPDATE_REQUEST', () => {
        // 1. mettre à jour la valeur _displayImages
        // testter pour les valeurs, true, false, undefined, NaN, Number, String

        // ({messageID, displayImages=true})
      });
    });


    describe('Should REMOVE message(s)', () => {

      // TODO: this feature is not fixed yet
      // 1. fix the feature
      // 2. add test
      it.skip('MAILBOX_EXPUNGE', () => {
        // (mailboxID),
        // should remove all message from mailbox
        // const id1 = fixtures.message1.id;
        // const id2 = fixtures.message2.id;
        // const id3 = fixtures.message3.id;
        // const mailboxId = Object.keys(fixtures.message3.mailboxIDs)[0];
        // dispatcher.dispatch({
        //   type: ActionTypes.MAILBOX_EXPUNGE,
        //   value: mailboxId,
        // });
        // const messages = MessageStore.getAll();
        // assert.isDefined(messages.get(id1));
        // assert.isUndefined(messages.get(id2));
        // assert.isUndefined(messages.get(id3));
      });

      it('REMOVE_ACCOUNT_SUCCESS', () => {
          // (accountID)
          // should delete all messages from this account
          // const accountId = fixtures.message5.accountID;
          // const id5 = fixtures.message5.id;
          // const id6 = fixtures.message6.id;
          // dispatcher.dispatch({
          //   type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
          //   value: accountId,
          // });
          // const messages = MessageStore.getAll();
          // assert.isUndefined(messages.get(id5));
          // assert.isUndefined(messages.get(id6));
      });

      // TODO: this feature is not fixed yet
      // 1. fix the feature
      // 2. add test
      it.skip('MESSAGE_TRASH_SUCCESS', () => {
        // MESSAGE_TRASH_SUCCESS, (target)
      });

      // TODO: this feature is not fixed yet
      // 1. fix the feature
      // 2. add test
      it.skip('RECEIVE_MESSAGE_DELETE', () => {
        // RECEIVE_MESSAGE_DELETE, (messageID)
        // const id4 = fixtures.message2.id;
        // dispatcher.dispatch({
        //   type: ActionTypes.RECEIVE_MESSAGE_DELETE,
        //   value: id4,
        // });
        // const messages = MessageStore.getAll();
        // assert.isUndefined(messages.get(id4));
      });
    });
  });

  describe('Methods', () => {

    beforeEach(() => {
      const result = {messages, conversationLength}
      Dispatcher.dispatch({
        type: ActionTypes.MESSAGE_FETCH_SUCCESS,
        value: {result},
      });
    });

    afterEach(() => {
      Dispatcher.dispatch({
        type: ActionTypes.MESSAGE_RESET_REQUEST,
      });
    });


    it('getByID', () => {
      testValues(MessageStore.getByID(message.id));
    });

    it('getAll', () => {
      messages.forEach((input) => {
        testValues(MessageStore.getByID(input.id), input);
      });
    });

    it('isImagesDisplayed', () => {
      messages.forEach((input) => {
        const msg = MessageStore.getByID(input.id);
        testValues(MessageStore.getByID(input.id), input);
      });
    });

    it('isUnread', () => {
      let input = _.cloneDeep(messageUnread);
      assert.isTrue(MessageStore.isUnread({message: input}));

      input = _.cloneDeep(messageFlagged);
      assert.isFalse(MessageStore.isUnread({message: input}));

      input = _.cloneDeep(message);
      assert.isFalse(MessageStore.isUnread({message: input}));
    });

    it('isFlagged', () => {
      let input = _.cloneDeep(messageFlagged);
      assert.isTrue(MessageStore.isFlagged({message: input}));

      input = _.cloneDeep(messageAttached);
      assert.isFalse(MessageStore.isFlagged({message: input}));

      input = _.cloneDeep(message);
      assert.isFalse(MessageStore.isFlagged({message: input}));
    });

    it('isAttached', () => {
      let input = _.cloneDeep(messageAttached);
      assert.isTrue(MessageStore.isAttached({message: input}));

      input = _.cloneDeep(messageFlagged);
      assert.isFalse(MessageStore.isAttached({message: input}));

      input = _.cloneDeep(message);
      assert.isFalse(MessageStore.isAttached({message: input}));
    });

    it('getConversation', () => {
      account.mailboxes.forEach((mailbox) => {
        const output = MessageStore.getConversation(conversationID, mailbox.id);
        output.forEach((msg) => {
          // All messages must have the same
          // conversationID && mailboxID
          assert.equal(msg.get('conversationID'), conversationID);
          assert.notEqual(msg.get('mailboxIDs')[mailbox.id], undefined);
        });

        // All messages should belongs to inbox otherwise
        // conversationLength must be smaller or equal
        if (mailbox.id === account.inboxMailbox) {
          assert.equal(output.length, conversationLength[conversationID]);
        } else {
          assert.isTrue(output.length <= conversationLength[conversationID]);
        }
      });
    });

    it('getConversationLength', () => {
      testConversationLength(conversationID, account.inboxMailbox);
    });
  });

});
