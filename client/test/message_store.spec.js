'use strict';
const assert = require('chai').assert;

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;

describe('Message Store', () => {
  let messageStore;
  let dispatcher;

  function addMessages(messages, isRaw, timestamp) {
    const conversationLength = {};
    let action;
    let value;

    if (isRaw) {
      action = ActionTypes.RECEIVE_RAW_MESSAGES;
      value = messages;
    } else {
      action = ActionTypes.MESSAGE_FETCH_SUCCESS;
      value = {
        result: { messages, conversationLength },
        timestamp: timestamp || new Date().getTime(),
      };
    }

    messages.forEach((message) => {
      if (message !== null && message !== undefined) {
        if (conversationLength[message.conversationID] === undefined) {
          conversationLength[message.conversationID] = 1;
        } else {
          conversationLength[message.conversationID] += 1;
        }
      }
    });
    dispatcher.dispatch({
      type: action,
      value,
    });
  }

  before(() => {
    dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(dispatcher);
    mockeryUtils.initForStores();
    messageStore = require('../app/stores/message_store');
  });

  /*
   * Problems noticed:
   *
   * * Usage of underscore instead of lodash.
   * * The fact that the conversation length is calculated remotely, is
   *   not clear.
   * * Coffee file is not linted.
   * * Most operations like getting raw messages don't update conversation
   *   length.
   * * Action values are not normalized.
   * * SETTINGS_UPDATE_RESQUEST action has a typo inside its name. And it's not
   *   sure it's still used.
   * * Line 55, length should be used instead of size.
   */
  describe('Actions', () => {
    it('MESSAGE_FETCH_SUCCESS', () => {
      const message1 = {
        id: 'ai1',
        accountID: 'aa1',
        messageID: 'am1',
        conversationID: 'ac1',
        mailboxIDs: { inbox: 1 },
      };
      const message2 = {
        id: 'ai2',
        accountID: 'aa2',
        messageID: 'am2',
        conversationID: 'ac2',
        mailboxIDs: { mb1: 1, inbox: 1 },
      };
      const message3 = {
        id: 'ai3',
        accountID: 'aa2',
        messageID: 'am3',
        conversationID: 'ac2',
        mailboxIDs: { mb1: 1, inbox: 1 },
      };
      addMessages([message1, message2, message3]);

      const messages = messageStore.getAll();
      assert.deepEqual(messages.get('ai1').toObject(), message1);
      assert.deepEqual(messages.get('ai2').toObject(), message2);
      assert.deepEqual(messages.get('ai3').toObject(), message3);

      let length = messageStore.getConversationLength('ac2');
      assert.equal(length, 2);
      length = messageStore.getConversationLength('ac1');
      assert.equal(length, 1);

      message3.flags = ['\\Seen'];

      // Test that update don't occur with older timestamp
      addMessages([message1, message2, message3], false,
                  new Date().getTime() - 100000);
      let message = messageStore.getByID('ai3');
      assert.equal(message.get('flags').length, 0);

      // Test that update occur with newest addition
      addMessages([message1, message2, message3]);
      message = messageStore.getByID('ai3');
      assert.equal(message.get('flags')[0], '\\Seen');
    });
    it('RECEIVE_RAW_MESSAGE', () => {
      const message = {
        id: 'rai1',
        accountID: 'ra1',
        messageID: 'rm1',
        conversationID: 'rc1',
        mailboxIDs: { inbox: 1 },
      };
      dispatcher.dispatch({
        type: ActionTypes.RECEIVE_RAW_MESSAGE,
        value: message,
      });
      const messages = messageStore.getAll();
      assert.deepEqual(messages.get('rai1').toObject(), message);
    });
    it('RECEIVE_RAW_MESSAGE_REALTIME', () => {
      const message = {
        id: 'rai2',
        accountID: 'ra2',
        messageID: 'rm2',
        conversationID: 'rc2',
        mailboxIDs: { inbox: 1 },
      };
      dispatcher.dispatch({
        type: ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME,
        value: message,
      });
      const messages = messageStore.getAll();
      assert.deepEqual(messages.get('rai2').toObject(), message);
    });
    it('RECEIVE_RAW_MESSAGES', () => {
      const message4 = {
        id: 'ai4',
        accountID: 'aa4',
        messageID: 'am4',
        conversationID: 'ac4',
        mailboxIDs: { inbox: 1 },
      };
      const message5 = {
        id: 'ai5',
        accountID: 'aa5',
        messageID: 'am5',
        conversationID: 'ac5',
        mailboxIDs: { inbox: 1 },
      };
      const message6 = {
        id: 'ai6',
        messageID: 'am6',
        accountID: 'aa5',
        conversationID: 'ac5',
        mailboxIDs: { inbox: 1 },
      };
      addMessages([message4, null, message5, message6], true);
      const messages = messageStore.getAll();
      assert.deepEqual(messages.get('ai4').toObject(), message4);
      assert.deepEqual(messages.get('ai5').toObject(), message5);
      assert.deepEqual(messages.get('ai6').toObject(), message6);
    });
    it('REMOVE_ACCOUNT_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: 'aa5',
      });
      const messages = messageStore.getAll();
      assert.isUndefined(messages.get('ai5'));
      assert.isUndefined(messages.get('ai6'));
    });
    it('MESSAGE_FLAGS_SUCCESS', () => {
      const message1 = {
        id: 'ai1',
        accountID: 'aa1',
        messageID: 'am1',
        conversationID: 'ac1',
        flags: ['\\Seen'],
        mailboxIDs: { inbox: 1 },
      };
      const message2 = {
        id: 'ai2',
        accountID: 'aa2',
        messageID: 'am2',
        conversationID: 'ac2',
        flags: ['\\Seen'],
        mailboxIDs: { mb1: 1, inbox: 1 },
      };
      dispatcher.dispatch({
        type: ActionTypes.MESSAGE_FLAGS_SUCCESS,
        value: { updated: [message1, message2] },
      });
      const messages = messageStore.getAll();
      assert.deepEqual(messages.get('ai1').toObject(), message1);
      assert.deepEqual(messages.get('ai2').toObject(), message2);
    });
    it.skip('MESSAGE_MOVE_SUCCESS', () => {
    });
    it.skip('MESSAGE_SEND_SUCCESS', () => {
    });
    it('RECEIVE_MESSAGE_DELETE', () => {
      dispatcher.dispatch({
        type: ActionTypes.RECEIVE_MESSAGE_DELETE,
        value: 'ai4',
      });
      const messages = messageStore.getAll();
      assert.isUndefined(messages.get('ai4'));
    });
    it('MAILBOX_EXPUNGE', () => {
      dispatcher.dispatch({
        type: ActionTypes.MAILBOX_EXPUNGE,
        value: 'mb1',
      });
      const messages = messageStore.getAll();
      assert.isDefined(messages.get('ai1'));
      assert.isUndefined(messages.get('ai2'));
      assert.isUndefined(messages.get('ai3'));
    });
    it('SEARCH_SUCCESS', () => {
      const message7 = {
        id: 'ai7',
        accountID: 'aa7',
        messageID: 'am7',
        conversationID: 'ac7',
        mailboxIDs: { inbox: 1 },
      };
      const message8 = {
        id: 'ai8',
        accountID: 'aa8',
        messageID: 'am8',
        conversationID: 'ac8',
        mailboxIDs: { inbox: 1 },
      };
      const message9 = {
        id: 'ai9',
        messageID: 'am9',
        accountID: 'aa8',
        conversationID: 'ac8',
        mailboxIDs: { inbox: 1 },
      };
      dispatcher.dispatch({
        type: ActionTypes.SEARCH_SUCCESS,
        value: { result: { rows: [message7, message8, message9] } },
      });
      const messages = messageStore.getAll();
      assert.deepEqual(messages.get('ai7').toObject(), message7);
      assert.deepEqual(messages.get('ai8').toObject(), message8);
      assert.deepEqual(messages.get('ai9').toObject(), message9);
    });
    it('SETTINGS_UPDATE_REQUEST', () => {
      dispatcher.dispatch({
        type: ActionTypes.SETTINGS_UPDATE_RESQUEST,
        value: { messageID: 'ai9', displayImages: true },
      });
      assert.isTrue(messageStore.getByID('ai9').__displayImages);
    });
  });

  describe('Methods', () => {
    let message1;
    let message2;
    let message3;

    it('getByID', () => {
      message1 = {
        id: 'i1',
        accountID: 'a1',
        messageID: 'm1',
        conversationID: 'c1',
        mailboxIDs: ['inbox'],
      };
      message2 = {
        id: 'i2',
        accountID: 'a2',
        messageID: 'm2',
        conversationID: 'c2',
        mailboxIDs: ['inbox'],
      };
      message3 = {
        id: 'i3',
        messageID: 'm3',
        accountID: 'a2',
        conversationID: 'c2',
        mailboxIDs: ['inbox'],
      };
      addMessages([message1, message2, message3]);
      assert.deepEqual(messageStore.getByID('i1').toObject(), message1);
    });
    it('getConversation', () => {
      const messages = messageStore.getConversation('c2');
      if (messages[0].get('id') === 'i2') {
        assert.deepEqual(messages[0].toObject(), message2);
        assert.deepEqual(messages[1].toObject(), message3);
      } else {
        assert.deepEqual(messages[1].toObject(), message2);
        assert.deepEqual(messages[0].toObject(), message3);
      }
    });
    it('getConversationLength', () => {
      let length = messageStore.getConversationLength('c2');
      assert.equal(length, 2);
      length = messageStore.getConversationLength('c1');
      assert.equal(length, 1);
      length = messageStore.getConversationLength('c5');
      assert.isUndefined(length);
    });
  });

  after(() => {
    mockeryUtils.clean();
  });
});
