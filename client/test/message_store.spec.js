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
        // ({result, timestamp})
        // const messages = MessageStore.getAll();
        // assert.deepEqual(messages.get(id1).toObject(), fixtures.message1);
        // assert.deepEqual(messages.get(id2).toObject(), fixtures.message2);
        // assert.deepEqual(messages.get(id3).toObject(), fixtures.message3);
        //
        // let length = MessageStore.getConversationLength(conversationId2);
        // assert.equal(length, 2);
        // length = MessageStore.getConversationLength(conversationId1);
        // assert.equal(length, 1);
        //
        // fixtures.message3.flags = seenFlags;
        //
        // // Test that update don't occur with older timestamp
        // // addMessages([fixtures.message1, fixtures.message2, fixtures.message3],
        // //             false,
        // //             new Date().getTime() - 100000);
        // let message = MessageStore.getByID(id3);
        // assert.equal(message.get('flags').length, 0);
        //
        // // Test that update occur with newest addition
        // addMessages([fixtures.message1, fixtures.message2, fixtures.message3]);
        // message = MessageStore.getByID(id3);
        // assert.equal(message.get('flags')[0], seenFlags);
      });

      it('RECEIVE_RAW_MESSAGES', () => {
        // (messages)
        // addMessages([
        //   fixtures.message4,
        //   null,
        //   fixtures.message5,
        //   fixtures.message6,
        // ],
        // true);
        // const messages = MessageStore.getAll();
        // const id4 = fixtures.message4.id;
        // const id5 = fixtures.message5.id;
        // const id6 = fixtures.message6.id;
        // assert.deepEqual(messages.get(id4).toObject(), fixtures.message4);
        // assert.deepEqual(messages.get(id5).toObject(), fixtures.message5);
        // assert.deepEqual(messages.get(id6).toObject(), fixtures.message6);
      });

      it('RECEIVE_RAW_MESSAGE', () => {
        // (message)
        // dispatcher.dispatch({
        //   type: ActionTypes.RECEIVE_RAW_MESSAGE,
        //   value: fixtures.rawMessage1,
        // });
        // const messages = MessageStore.getAll();
        // const idr1 = fixtures.rawMessage1.id;
        // assert.deepEqual(messages.get(idr1).toObject(), fixtures.rawMessage1);
      });

      it('RECEIVE_RAW_MESSAGE_REALTIME', () => {
        // (message)
        // dispatcher.dispatch({
        //   type: ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME,
        //   value: fixtures.rawMessage2,
        // });
        // const messages = MessageStore.getAll();
        // const idr2 = fixtures.rawMessage2.id;
        // assert.deepEqual(messages.get(idr2).toObject(), fixtures.rawMessage2);
      });

      // TODO: this feature is not fixed yet
      // 1. fix the feature
      // 2. add test
      it.skip('MESSAGE_SEND_SUCCESS', () => {
        // ({message})
      });
    });


    describe('Should UPDATE message(s)', () => {

      it('MESSAGE_FLAGS_SUCCESS', () => {
        // ({result, timestamp})
        // const changes = { flags: seenFlags };
        // const message1 = _.extend({}, fixtures.message1, changes);
        // const message2 = _.extend({}, fixtures.message2, changes);
        // const updated = { messages: [message1, message2]}
        // dispatcher.dispatch({
        //   type: ActionTypes.MESSAGE_FLAGS_SUCCESS,
        //   value: { updated, timestamp: Date.now() },
        // });
        //
        // const id1 = fixtures.message1.id;
        // const id2 = fixtures.message2.id;
        // const messages = MessageStore.getAll();
        //
        // assert.deepEqual(messages.get(id1).toObject(), message1);
        // assert.deepEqual(messages.get(id2).toObject(), message2);
      });

      // TODO: this feature is not fixed yet
      // 1. fix the feature
      // 2. add test
      it.skip('MESSAGE_MOVE_SUCCESS', () => {
          // ({updated})
      });

      // TODO: this feature is not fixed yet
      // 1. fix the feature
      // 2. add test
      it.skip('SEARCH_SUCCESS', () => {
        // ((message))
      });

      it('SETTINGS_UPDATE_REQUEST', () => {
        // ({messageID, displayImages=true})
        // const id1 = fixtures.message1.id;
        //
        // // Message must exist into MessageStore
        // assert.equal(MessageStore.getByID(id1).get('id'), id1);
        // assert.isUndefined(MessageStore.getByID(id1).get('_displayImages'));
        //
        // // displayImage value has changed
        // dispatcher.dispatch({
        //   type: ActionTypes.SETTINGS_UPDATE_REQUEST,
        //   value: { messageID: id1, displayImages: true },
        // });
        // assert.isTrue(MessageStore.getByID(id1).get('_displayImages'));
        //
        // // displayImage value has changed
        // dispatcher.dispatch({
        //   type: ActionTypes.SETTINGS_UPDATE_REQUEST,
        //   value: { messageID: id1, displayImages: false },
        // });
        // assert.isFalse(MessageStore.getByID(id1).get('_displayImages'));
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
      let length = MessageStore.getConversationLength(conversationID);
      assert.equal(length, conversationLength[conversationID]);

      length = MessageStore.getConversation(conversationID, account.inboxMailbox).length;
      assert.equal(length, conversationLength[conversationID]);
    });
  });

});
