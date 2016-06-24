'use strict';
const assert = require('chai').assert;
const _ = require('lodash');

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;

const fixtures = {
  message1: {
    id: 'i1',
    accountID: 'a1',
    messageID: 'm1',
    conversationID: 'ac1',
    mailboxIDs: { inbox: 1 },
  },
  message2: {
    id: 'i2',
    accountID: 'a2',
    messageID: 'm2',
    conversationID: 'c2',
    mailboxIDs: { mb1: 1, inbox: 1 },
  },
  message3: {
    id: 'i3',
    accountID: 'a2',
    messageID: 'm3',
    conversationID: 'c2',
    mailboxIDs: { mb1: 1, inbox: 1 },
  },
  message4: {
    id: 'i4',
    accountID: 'a4',
    messageID: 'm4',
    conversationID: 'c4',
    mailboxIDs: { inbox: 1 },
  },
  message5: {
    id: 'i5',
    accountID: 'a5',
    messageID: 'm5',
    conversationID: 'c5',
    mailboxIDs: { inbox: 1 },
  },
  message6: {
    id: 'i6',
    messageID: 'm6',
    accountID: 'a5',
    conversationID: 'c5',
    mailboxIDs: { inbox: 1 },
  },
  message7: {
    id: 'i7',
    accountID: 'a7',
    messageID: 'm7',
    conversationID: 'c7',
    mailboxIDs: { inbox: 1 },
  },
  message8: {
    id: 'i8',
    accountID: 'a8',
    messageID: 'm8',
    conversationID: 'c8',
    mailboxIDs: { inbox: 1 },
  },
  message9: {
    id: 'i9',
    messageID: 'm9',
    accountID: 'a8',
    conversationID: 'c8',
    mailboxIDs: { inbox: 1 },
  },
  message10: {
    id: 'i10',
    accountID: 'a10',
    messageID: 'm10',
    conversationID: 'c10',
    mailboxIDs: { inbox: 1 },
  },
  message11: {
    id: 'i11',
    accountID: 'a11',
    messageID: 'm11',
    conversationID: 'c11',
    mailboxIDs: { inbox: 1 },
  },
  message12: {
    id: 'i12',
    accountID: 'a12',
    messageID: 'm12',
    conversationID: 'c11',
    mailboxIDs: { inbox: 1 },
  },
  rawMessage1: {
    id: 'rai1',
    accountID: 'ra1',
    messageID: 'rm1',
    conversationID: 'rc1',
    mailboxIDs: { inbox: 1 },
  },
  rawMessage2: {
    id: 'rai2',
    accountID: 'ra2',
    messageID: 'rm2',
    conversationID: 'rc2',
    mailboxIDs: { inbox: 1 },
  },
};

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
    mockeryUtils.initForStores(['../app/stores/message_store']);
  });

  /*
   * Problems noticed in the store file:
   *
   * FIXME Underscore is used instead of lodash.
   * FIXME The fact that the conversation length is calculated remotely, is
   *       not clear for the developer.
   * FIXME The coffeescript code is not linted.
   * FIXME Most operations, like getting raw messages, don't update
   *       conversation length.
   * FIXME Action values are not normalized.
   */
  describe('Actions', () => {
    const id1 = fixtures.message1.id;
    const id2 = fixtures.message2.id;
    const id3 = fixtures.message3.id;
    const conversationId1 = fixtures.message1.conversationID;
    const conversationId2 = fixtures.message2.conversationID;
    const seenFlags = ['\\Seen'];

    // Reinit a new MessageStore before each test
    beforeEach(() => {
      messageStore = require('../app/stores/message_store');
      addMessages([fixtures.message1, fixtures.message2, fixtures.message3]);
    });

    it('MESSAGE_FETCH_SUCCESS', () => {
      const messages = messageStore.getAll();
      assert.deepEqual(messages.get(id1).toObject(), fixtures.message1);
      assert.deepEqual(messages.get(id2).toObject(), fixtures.message2);
      assert.deepEqual(messages.get(id3).toObject(), fixtures.message3);

      let length = messageStore.getConversationLength(conversationId2);
      assert.equal(length, 2);
      length = messageStore.getConversationLength(conversationId1);
      assert.equal(length, 1);

      fixtures.message3.flags = seenFlags;

      // Test that update don't occur with older timestamp
      addMessages([fixtures.message1, fixtures.message2, fixtures.message3],
                  false,
                  new Date().getTime() - 100000);
      let message = messageStore.getByID(id3);
      assert.equal(message.get('flags').length, 0);

      // Test that update occur with newest addition
      addMessages([fixtures.message1, fixtures.message2, fixtures.message3]);
      message = messageStore.getByID(id3);
      assert.equal(message.get('flags')[0], seenFlags);
    });
    it('RECEIVE_RAW_MESSAGE', () => {
      dispatcher.dispatch({
        type: ActionTypes.RECEIVE_RAW_MESSAGE,
        value: fixtures.rawMessage1,
      });
      const messages = messageStore.getAll();
      const idr1 = fixtures.rawMessage1.id;
      assert.deepEqual(messages.get(idr1).toObject(), fixtures.rawMessage1);
    });
    it('RECEIVE_RAW_MESSAGE_REALTIME', () => {
      dispatcher.dispatch({
        type: ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME,
        value: fixtures.rawMessage2,
      });
      const messages = messageStore.getAll();
      const idr2 = fixtures.rawMessage2.id;
      assert.deepEqual(messages.get(idr2).toObject(), fixtures.rawMessage2);
    });
    it('RECEIVE_RAW_MESSAGES', () => {
      addMessages([
        fixtures.message4,
        null,
        fixtures.message5,
        fixtures.message6,
      ],
      true);
      const messages = messageStore.getAll();
      const id4 = fixtures.message4.id;
      const id5 = fixtures.message5.id;
      const id6 = fixtures.message6.id;
      assert.deepEqual(messages.get(id4).toObject(), fixtures.message4);
      assert.deepEqual(messages.get(id5).toObject(), fixtures.message5);
      assert.deepEqual(messages.get(id6).toObject(), fixtures.message6);
    });
    it('REMOVE_ACCOUNT_SUCCESS', () => {
      const accountId = fixtures.message5.accountID;
      const id5 = fixtures.message5.id;
      const id6 = fixtures.message6.id;
      dispatcher.dispatch({
        type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
        value: accountId,
      });
      const messages = messageStore.getAll();
      assert.isUndefined(messages.get(id5));
      assert.isUndefined(messages.get(id6));
    });
    it('MESSAGE_FLAGS_SUCCESS', () => {
      const changes = { flags: seenFlags };
      const message1 = _.extend({}, fixtures.message1, changes);
      const message2 = _.extend({}, fixtures.message2, changes);
      const updated = { messages: [message1, message2]}
      dispatcher.dispatch({
        type: ActionTypes.MESSAGE_FLAGS_SUCCESS,
        value: { updated, timestamp: Date.now() },
      });

      const id1 = fixtures.message1.id;
      const id2 = fixtures.message2.id;
      const messages = messageStore.getAll();
      assert.deepEqual(messages.get(id1).toObject(), message1);
      assert.deepEqual(messages.get(id2).toObject(), message2);
    });
    it.skip('MESSAGE_MOVE_SUCCESS', () => {
      // FIXME: Don't know how to implement this test.
    });
    it.skip('MESSAGE_SEND_SUCCESS', () => {
      // FIXME: Don't know how to implement this test.
    });
    it('RECEIVE_MESSAGE_DELETE', () => {
      const id4 = fixtures.message2.id;
      dispatcher.dispatch({
        type: ActionTypes.RECEIVE_MESSAGE_DELETE,
        value: id4,
      });
      const messages = messageStore.getAll();
      assert.isUndefined(messages.get(id4));
    });
    it('MAILBOX_EXPUNGE', () => {
      const id1 = fixtures.message1.id;
      const id2 = fixtures.message2.id;
      const id3 = fixtures.message3.id;
      const mailboxId = Object.keys(fixtures.message3.mailboxIDs)[0];
      dispatcher.dispatch({
        type: ActionTypes.MAILBOX_EXPUNGE,
        value: mailboxId,
      });
      const messages = messageStore.getAll();
      assert.isDefined(messages.get(id1));
      assert.isUndefined(messages.get(id2));
      assert.isUndefined(messages.get(id3));
    });
    it.skip('SEARCH_SUCCESS', () => {
      // TODO: update this test when feature will be back
      dispatcher.dispatch({
        type: ActionTypes.SEARCH_SUCCESS,
        value: { result: { rows: [
          fixtures.message7, fixtures.message8, fixtures.message9,
        ] } },
      });
      const messages = messageStore.getAll();
      const id7 = fixtures.message7.id;
      const id8 = fixtures.message8.id;
      const id9 = fixtures.message9.id;
      assert.deepEqual(messages.get(id7).toObject(), fixtures.message7);
      assert.deepEqual(messages.get(id8).toObject(), fixtures.message8);
      assert.deepEqual(messages.get(id9).toObject(), fixtures.message9);
    });
    it('SETTINGS_UPDATE_REQUEST', () => {
      const id1 = fixtures.message1.id;

      // Message must exist into messageStore
      assert.equal(messageStore.getByID(id1).get('id'), id1);
      assert.isUndefined(messageStore.getByID(id1).get('_displayImages'));

      // displayImage value has changed
      dispatcher.dispatch({
        type: ActionTypes.SETTINGS_UPDATE_REQUEST,
        value: { messageID: id1, displayImages: true },
      });
      assert.isTrue(messageStore.getByID(id1).get('_displayImages'));

      // displayImage value has changed
      dispatcher.dispatch({
        type: ActionTypes.SETTINGS_UPDATE_REQUEST,
        value: { messageID: id1, displayImages: false },
      });
      assert.isFalse(messageStore.getByID(id1).get('_displayImages'));
    });
  });

  describe('Methods', () => {

    // Reinit a new MessageStore before each test
    beforeEach(() => {
      messageStore = require('../app/stores/message_store');
      addMessages([fixtures.message10, fixtures.message11, fixtures.message12]);
    });


    it('getByID', () => {
      const id10 = fixtures.message10.id;
      assert.deepEqual(
        messageStore.getByID(id10).toObject(),
        fixtures.message10
      );
    });
    it('getConversation', () => {
      const id11 = fixtures.message11.id;
      const mailbox11 = _.keys(fixtures.message11.mailboxIDs)[0];
      const conversationId = fixtures.message11.conversationID;
      const messages = messageStore.getConversation(conversationId, mailbox11);
      if (messages[0].get('id') === id11) {
        assert.deepEqual(messages[0].toObject(), fixtures.message11);
        assert.deepEqual(messages[1].toObject(), fixtures.message12);
      } else {
        assert.deepEqual(messages[1].toObject(), fixtures.message11);
        assert.deepEqual(messages[0].toObject(), fixtures.message12);
      }

      //  If conversation doesnt exist
      // then return empty Array
      const id5 = fixtures.message5.id;
      const conversation5 = messageStore.getConversation(id5, 'inbox')
      assert.deepEqual(messageStore.getConversation(id5, 'inbox'), []);
    });
    it('getConversationLength', () => {
      const id1 = fixtures.message10.id;
      const conversationId1 = fixtures.message10.conversationID;

      // Message10 should exist into messageStore
      assert.deepEqual(messageStore.getByID(id1).toObject(), fixtures.message10);

      // Its length is 1
      let length = messageStore.getConversationLength(conversationId1);
      assert.equal(length, 1);

      const id2 = fixtures.message11.id;
      const conversationId2 = fixtures.message11.conversationID;

      // Message11 should exist into messageStore
      assert.deepEqual(messageStore.getByID(id2).toObject(), fixtures.message11);

      // Its length is 2
      length = messageStore.getConversationLength(conversationId2);
      assert.equal(length, 2);

      // Empty conversation should return length: null
      length = messageStore.getConversationLength('c5');
      assert.isNull(length);
    });
  });

  after(() => {
    mockeryUtils.clean();
  });
});
