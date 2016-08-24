/* eslint-env mocha */

'use strict';

const assert = require('chai').assert;
const _ = require('lodash');

const ActionTypes = require('../app/constants/app_constants').ActionTypes;

const getUID = require('./utils/guid').getUID;
const MessageFixtures = require('./fixtures/message');
const AccountFixture = require('./fixtures/account');
const makeTestDispatcher = require('./utils/specs_dispatcher');
const MessageGetter = require('../app/getters/messages');


describe('Message Store', () => {
  let MessageStore;
  let Dispatcher;

  const conversationID = `plop-${getUID()}`;
  const account = AccountFixture.createAccount();

  const date = new Date();

  const message = MessageFixtures.createMessage({ date });
  const messageUnread = MessageFixtures.createUnread({ date });
  const messageFlagged = MessageFixtures.createFlagged({ date });
  const messageDraft = MessageFixtures.createDraft({ date });
  const messageAttached = MessageFixtures.createAttached({ date });

  let conversationLength = {};
  const messages = [];


  before(() => {
    // Add several messages
    // to create a conversation
    const params = { date, conversationID, account };
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));
    messages.push(MessageFixtures.createMessage(params));

    messages.push(message);
    messages.push(MessageFixtures.createMessage({ date }));
    messages.push(MessageFixtures.createMessage({ date }));
    messages.push(MessageFixtures.createMessage({ images: true, date }));
    messages.push(MessageFixtures.createMessage({ images: false, date }));

    // Add flagged messages
    messages.push(messageAttached);
    messages.push(messageUnread);
    messages.push(messageFlagged);
    messages.push(messageDraft);

    // Define conversationLength
    // from messages entries
    const values = _.groupBy(messages, 'conversationID');
    conversationLength = _.mapValues(values, (value) => value.length);

    global.t = (x) => x;

    const tools = makeTestDispatcher();
    Dispatcher = tools.Dispatcher;
    MessageStore = tools.makeStateFullGetter(MessageGetter);
  });

  after(() => {
    delete global.t;
  });


  /*
   * Problems noticed in the store file:
   * FIXME Action values are not normalized.
   */


  describe('Methods', () => {
    beforeEach(() => {
      const result = { messages, conversationLength };
      Dispatcher.dispatch({
        type: ActionTypes.MESSAGE_FETCH_SUCCESS,
        value: { result },
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
        testValues(MessageStore.getByID(input.id), input);
      });
    });

    it.skip('isUnread', () => {
      let input = _.cloneDeep(messageUnread);
      assert.isTrue(MessageStore.isUnread({ message: input }));

      input = _.cloneDeep(messageFlagged);
      assert.isFalse(MessageStore.isUnread({ message: input }));

      input = _.cloneDeep(message);
      assert.isFalse(MessageStore.isUnread({ message: input }));
    });

    it.skip('isFlagged', () => {
      let input = _.cloneDeep(messageFlagged);
      assert.isTrue(MessageStore.isFlagged({ message: input }));

      input = _.cloneDeep(messageAttached);
      assert.isFalse(MessageStore.isFlagged({ message: input }));

      input = _.cloneDeep(message);
      assert.isFalse(MessageStore.isFlagged({ message: input }));
    });

    it.skip('isAttached', () => {
      let input = _.cloneDeep(messageAttached);
      assert.isTrue(MessageStore.isAttached({ message: input }));

      input = _.cloneDeep(messageFlagged);
      assert.isFalse(MessageStore.isAttached({ message: input }));

      input = _.cloneDeep(message);
      assert.isFalse(MessageStore.isAttached({ message: input }));
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
          assert.equal(output.size, conversationLength[conversationID]);
        } else {
          assert.isTrue(output.size <= conversationLength[conversationID]);
        }
      });
    });

    it('getConversationLength', () => {
      testConversationLength(conversationID, account.inboxMailbox);
    });
  });


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
        testMessagesAction('MESSAGE_FETCH_SUCCESS', { result: { messages } });
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
        testMessageAction('MESSAGE_SEND_SUCCESS', { message });
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
        const message0 = _.cloneDeep(message);
        let output = MessageStore.getByID(message0.id);
        let defaultValue = message0.flags;
        assert.deepEqual(output.get('flags'), message0.flags);

        const timestamp = (new Date()).valueOf();

        // Change values
        Object.assign(message0, {
          flags: [],
          updated: timestamp,
        });

        // Dispatch change
        Dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FLAGS_SUCCESS,
          value: { updated: { messages: [message0] } },
        });

        output = MessageStore.getByID(message0.id);
        assert.deepEqual(output.get('flags'), message0.flags);

        // Try to change with older data
        defaultValue = message0.flags;
        Object.assign(message0, {
          flags: defaultValue,
          updated: (new Date('2014-1-1')).valueOf(),
        });
        Dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FLAGS_SUCCESS,
          value: { updated: { messages: [message0] } },
        });
        output = MessageStore.getByID(message0.id);
        assert.deepEqual(output.get('flags'), []);
      });

      it('MESSAGE_MOVE_SUCCESS', () => {
        let message0 = message;
        let selectedValue;
        let previousValue;

        function getMailboxIDs() {
          return _.keys(MessageStore.getByID(message0.id).get('mailboxIDs'));
        }

        function getMailboxID() {
          return getMailboxIDs().find((id) => id !== message0.mailboxID);
        }

        function updateMessage(mailboxID, date) {
          message0 = _.cloneDeep(message0);
          message0.mailboxID = mailboxID;
          message0.updated = (date).valueOf();
          Dispatcher.dispatch({
            type: ActionTypes.MESSAGE_MOVE_SUCCESS,
            value: { updated: { messages: [message0] } },
          });
          previousValue = selectedValue;
          selectedValue = getMailboxIDs()[0];
        }

        // Change MailboxID
        let mailboxID = getMailboxID();
        updateMessage(mailboxID, new Date());
        assert.notEqual(selectedValue, previousValue);
        assert.equal(selectedValue, mailboxID);

        // Change mailboxID
        // but set as older update
        mailboxID = getMailboxID();
        updateMessage(mailboxID, new Date('2013-1-1'));
        assert.equal(selectedValue, previousValue);
        assert.notEqual(selectedValue, mailboxID);

        // Change mailboxID
        // but with fake value
        mailboxID = NaN;
        updateMessage(mailboxID, new Date());
        assert.equal(selectedValue, previousValue);
        assert.notEqual(selectedValue, mailboxID);

        // Change mailboxID
        // but with fake value
        mailboxID = undefined;
        updateMessage(mailboxID, new Date());
        assert.equal(selectedValue, previousValue);
        assert.notEqual(selectedValue, mailboxID);

        // Change mailboxID
        // but with fake value
        mailboxID = '     ';
        updateMessage(mailboxID, new Date());
        assert.equal(selectedValue, previousValue);
        assert.notEqual(selectedValue, mailboxID);
      });

      it('SETTINGS_UPDATE_REQUEST', () => {
        let output = MessageStore.getByID(message.id);
        assert.equal(output.get('_displayImages'), !!message._displayImages);

        function testDisplayImage(value, result) {
          Dispatcher.dispatch({
            type: ActionTypes.SETTINGS_UPDATE_REQUEST,
            value: { messageID: message.id, displayImages: value },
          });
          output = MessageStore.getByID(message.id);
          assert.equal(output.get('_displayImages'), result);
        }

        testDisplayImage(true, true);
        testDisplayImage('plop', true);
        testDisplayImage('2', true);
        testDisplayImage('0', true);

        testDisplayImage(false, false);
        testDisplayImage(0, false);
        testDisplayImage(null, false);
        testDisplayImage(undefined, false);
        testDisplayImage(NaN, false);
        testDisplayImage({}, false);
        testDisplayImage([], false);
      });
    });


    describe('Should REMOVE message(s)', () => {
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

      it('MAILBOX_EXPUNGE', () => {
        const mailboxID = getMailboxID();
        const countAfter = MessageStore.getAll().filter((msg) => (
          msg.get('mailboxIDs')[mailboxID] === undefined
        )).size;

        assert.isTrue(!!MessageStore.getByID(message.id));

        Dispatcher.dispatch({
          type: ActionTypes.MAILBOX_EXPUNGE,
          value: mailboxID,
        });
        assert.isUndefined(MessageStore.getByID(message.id));
        assert.equal(MessageStore.getAll().size, countAfter);

        function getMailboxID(mailboxID) {
          return _.keys(message.mailboxIDs).find((id) => id !== mailboxID);
        }
      });

      it('REMOVE_ACCOUNT_SUCCESS', () => {
        const accountID = message.accountID;
        let output = MessageStore.getByID(message.id);

        const countAfter = MessageStore.getAll().filter((msg) => (
            msg.get('accountID') !== accountID
        )).size;
        Dispatcher.dispatch({
          type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
          value: accountID,
        });
        output = MessageStore.getByID(message.id);
        assert.isUndefined(output);
        assert.equal(MessageStore.getAll().size, countAfter);
      });

      it('MESSAGE_TRASH_SUCCESS', () => {
        assert.isTrue(!!MessageStore.getByID(message.id));

        Dispatcher.dispatch({
          type: ActionTypes.MESSAGE_TRASH_SUCCESS,
          value: { target: { messageID: message.id } },
        });

        assert.isUndefined(MessageStore.getByID(message.id));
      });

      it('RECEIVE_MESSAGE_DELETE', () => {
        assert.isTrue(!!MessageStore.getByID(message.id));

        Dispatcher.dispatch({
          type: ActionTypes.RECEIVE_MESSAGE_DELETE,
          value: message.id,
        });

        assert.isUndefined(MessageStore.getByID(message.id));
      });
    });
  });

  function isDate(key) {
    return ['date', 'updated', 'createdAt', 'isDeleted'].indexOf(key) > -1;
  }

  function testValues(output, input) {
    output = output.toJS();
    if (undefined === input) input = message;

    assert.equal(input.mailboxID, undefined);
    assert.equal(typeof output.mailboxID, 'string');
    delete output.mailboxID;

    if (undefined === input.attachments) {
      assert.deepEqual(output.attachments, []);
      delete output.attachments;
    }

    if (undefined === input._displayImages) {
      assert.equal(output._displayImages, false);
      delete output._displayImages;
    }

    // When Message is only flagged as Unread
    // sometime value can be undefined
    // instead of []
    if (undefined === input.flags) {
      delete output.flags;
    }

    _.each(output, (value, property) => {
      if (typeof(value) === 'object') {
        assert.deepEqual(value, input[property]);
      } else if (!isDate(property)) {
        assert.equal(value, input[property]);
      }
    });
  }

  function testConversationLength(id, mailboxID) {
    let length = MessageStore.getConversationLength(id);
    assert.equal(length, conversationLength[id]);

    length = MessageStore.getConversation(id, mailboxID).size;
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
});
