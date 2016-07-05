'use strict';
const assert = require('chai').assert;
const _ = require('lodash');
const Map = require('immutable').Map;

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;

const MessageFixtures = require('./fixtures/message')

describe('Message Store', () => {
  let MessageStore;
  let Dispatcher;
  const date = new Date();
  const message = MessageFixtures.createMessage({date});
  const messageUnread = MessageFixtures.createUnread({date});
  const messageFlagged = MessageFixtures.createFlagged({date});
  const messageDraft = MessageFixtures.createDraft({date});
  const messageAttached = MessageFixtures.createAttached({date});
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
    messages.push(message);
    messages.push(MessageFixtures.createMessage({date}));


    messages.push(MessageFixtures.createMessage({date}));
    messages.push(MessageFixtures.createMessage({images: true, date}));
    messages.push(MessageFixtures.createMessage({images: false, date}));

    messages.push(messageAttached);
    messages.push(messageUnread);
    messages.push(messageFlagged);
    messages.push(messageDraft);

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
          //  MESSAGE_FETCH_SUCCESS, {result, timestamp}
      });

      it('MESSAGE_FETCH_SUCCESS', () => {
          //  RECEIVE_RAW_MESSAGES, (messages)
      });

      it('RECEIVE_RAW_MESSAGE', () => {
        //  RECEIVE_RAW_MESSAGE, (message)
      });

      it('RECEIVE_RAW_MESSAGE_REALTIME', () => {
        //  RECEIVE_RAW_MESSAGE_REALTIME, (message)
      });

      it('MESSAGE_SEND_SUCCESS', () => {
        //  MESSAGE_SEND_SUCCESS, ({message})
      });
    });


    describe('Should UPDATE message(s)', () => {

      it('MESSAGE_FLAGS_SUCCESS', () => {
          // MESSAGE_FLAGS_SUCCESS, {result, timestamp}
      });

      it('MESSAGE_MOVE_SUCCESS', () => {
          // MESSAGE_MOVE_SUCCESS, ({updated})
      });

      it('SEARCH_SUCCESS', () => {
        // SEARCH_SUCCESS, ((message))
      });

      it('SETTINGS_UPDATE_REQUEST', () => {
        // SETTINGS_UPDATE_REQUEST, ({messageID, displayImages=true})
      });
    });


    describe('Should REMOVE message(s)', () => {

        it('MAILBOX_EXPUNGE', () => {
            // MAILBOX_EXPUNGE, (mailboxID),
            // should remove all message frome mailbox
        });

        it('REMOVE_ACCOUNT_SUCCESS', () => {
            // REMOVE_ACCOUNT_SUCCESS, (accountID)
            // should delete all messages from this account
        });

        it('MESSAGE_TRASH_SUCCESS', () => {
          // MESSAGE_TRASH_SUCCESS, (target)
        });

        it('RECEIVE_MESSAGE_DELETE', () => {
          // RECEIVE_MESSAGE_DELETE, (messageID)
        });
    });
    // it('MESSAGE_FETCH_SUCCESS', () => {
    //   // const messages = MessageStore.getAll();
    //   // assert.deepEqual(messages.get(id1).toObject(), fixtures.message1);
    //   // assert.deepEqual(messages.get(id2).toObject(), fixtures.message2);
    //   // assert.deepEqual(messages.get(id3).toObject(), fixtures.message3);
    //   //
    //   // let length = MessageStore.getConversationLength(conversationId2);
    //   // assert.equal(length, 2);
    //   // length = MessageStore.getConversationLength(conversationId1);
    //   // assert.equal(length, 1);
    //   //
    //   // fixtures.message3.flags = seenFlags;
    //   //
    //   // // Test that update don't occur with older timestamp
    //   // // addMessages([fixtures.message1, fixtures.message2, fixtures.message3],
    //   // //             false,
    //   // //             new Date().getTime() - 100000);
    //   // let message = MessageStore.getByID(id3);
    //   // assert.equal(message.get('flags').length, 0);
    //   //
    //   // // Test that update occur with newest addition
    //   // addMessages([fixtures.message1, fixtures.message2, fixtures.message3]);
    //   // message = MessageStore.getByID(id3);
    //   // assert.equal(message.get('flags')[0], seenFlags);
    // });
    // it('RECEIVE_RAW_MESSAGE', () => {
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.RECEIVE_RAW_MESSAGE,
    //   //   value: fixtures.rawMessage1,
    //   // });
    //   // const messages = MessageStore.getAll();
    //   // const idr1 = fixtures.rawMessage1.id;
    //   // assert.deepEqual(messages.get(idr1).toObject(), fixtures.rawMessage1);
    // });
    // it('RECEIVE_RAW_MESSAGE_REALTIME', () => {
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME,
    //   //   value: fixtures.rawMessage2,
    //   // });
    //   // const messages = MessageStore.getAll();
    //   // const idr2 = fixtures.rawMessage2.id;
    //   // assert.deepEqual(messages.get(idr2).toObject(), fixtures.rawMessage2);
    // });
    // it('RECEIVE_RAW_MESSAGES', () => {
    //   // addMessages([
    //   //   fixtures.message4,
    //   //   null,
    //   //   fixtures.message5,
    //   //   fixtures.message6,
    //   // ],
    //   // true);
    //   // const messages = MessageStore.getAll();
    //   // const id4 = fixtures.message4.id;
    //   // const id5 = fixtures.message5.id;
    //   // const id6 = fixtures.message6.id;
    //   // assert.deepEqual(messages.get(id4).toObject(), fixtures.message4);
    //   // assert.deepEqual(messages.get(id5).toObject(), fixtures.message5);
    //   // assert.deepEqual(messages.get(id6).toObject(), fixtures.message6);
    // });
    // it('REMOVE_ACCOUNT_SUCCESS', () => {
    //   // const accountId = fixtures.message5.accountID;
    //   // const id5 = fixtures.message5.id;
    //   // const id6 = fixtures.message6.id;
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.REMOVE_ACCOUNT_SUCCESS,
    //   //   value: accountId,
    //   // });
    //   // const messages = MessageStore.getAll();
    //   // assert.isUndefined(messages.get(id5));
    //   // assert.isUndefined(messages.get(id6));
    // });
    // it('MESSAGE_FLAGS_SUCCESS', () => {
    //   // const changes = { flags: seenFlags };
    //   // const message1 = _.extend({}, fixtures.message1, changes);
    //   // const message2 = _.extend({}, fixtures.message2, changes);
    //   // const updated = { messages: [message1, message2]}
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.MESSAGE_FLAGS_SUCCESS,
    //   //   value: { updated, timestamp: Date.now() },
    //   // });
    //   //
    //   // const id1 = fixtures.message1.id;
    //   // const id2 = fixtures.message2.id;
    //   // const messages = MessageStore.getAll();
    //   //
    //   // assert.deepEqual(messages.get(id1).toObject(), message1);
    //   // assert.deepEqual(messages.get(id2).toObject(), message2);
    // });
    // it.skip('MESSAGE_MOVE_SUCCESS', () => {
    //   // TODO: this feature is not fixed yet
    //   // 1. fix the feature
    //   // 2. add test
    // });
    // it.skip('MESSAGE_SEND_SUCCESS', () => {
    //   // TODO: this feature is not fixed yet
    //   // 1. fix the feature
    //   // 2. add test
    // });
    // it('RECEIVE_MESSAGE_DELETE', () => {
    //   // const id4 = fixtures.message2.id;
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.RECEIVE_MESSAGE_DELETE,
    //   //   value: id4,
    //   // });
    //   // const messages = MessageStore.getAll();
    //   // assert.isUndefined(messages.get(id4));
    // });
    // it('MAILBOX_EXPUNGE', () => {
    //   // const id1 = fixtures.message1.id;
    //   // const id2 = fixtures.message2.id;
    //   // const id3 = fixtures.message3.id;
    //   // const mailboxId = Object.keys(fixtures.message3.mailboxIDs)[0];
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.MAILBOX_EXPUNGE,
    //   //   value: mailboxId,
    //   // });
    //   // const messages = MessageStore.getAll();
    //   // assert.isDefined(messages.get(id1));
    //   // assert.isUndefined(messages.get(id2));
    //   // assert.isUndefined(messages.get(id3));
    // });
    // it.skip('SEARCH_SUCCESS', () => {
    //   // // TODO: update this test when feature will be back
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.SEARCH_SUCCESS,
    //   //   value: { result: { rows: [
    //   //     fixtures.message7, fixtures.message8, fixtures.message9,
    //   //   ] } },
    //   // });
    //   // const messages = MessageStore.getAll();
    //   // const id7 = fixtures.message7.id;
    //   // const id8 = fixtures.message8.id;
    //   // const id9 = fixtures.message9.id;
    //   // assert.deepEqual(messages.get(id7).toObject(), fixtures.message7);
    //   // assert.deepEqual(messages.get(id8).toObject(), fixtures.message8);
    //   // assert.deepEqual(messages.get(id9).toObject(), fixtures.message9);
    // });
    // it('SETTINGS_UPDATE_REQUEST', () => {
    //   // const id1 = fixtures.message1.id;
    //   //
    //   // // Message must exist into MessageStore
    //   // assert.equal(MessageStore.getByID(id1).get('id'), id1);
    //   // assert.isUndefined(MessageStore.getByID(id1).get('_displayImages'));
    //   //
    //   // // displayImage value has changed
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.SETTINGS_UPDATE_REQUEST,
    //   //   value: { messageID: id1, displayImages: true },
    //   // });
    //   // assert.isTrue(MessageStore.getByID(id1).get('_displayImages'));
    //   //
    //   // // displayImage value has changed
    //   // dispatcher.dispatch({
    //   //   type: ActionTypes.SETTINGS_UPDATE_REQUEST,
    //   //   value: { messageID: id1, displayImages: false },
    //   // });
    //   // assert.isFalse(MessageStore.getByID(id1).get('_displayImages'));
    // });
  });

  describe('Methods', () => {

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
      // const id11 = fixtures.message11.id;
      // const mailbox11 = _.keys(fixtures.message11.mailboxIDs)[0];
      // const conversationId = fixtures.message11.conversationID;
      // const messages = MessageStore.getConversation(conversationId, mailbox11);
      // if (messages[0].get('id') === id11) {
      //   assert.deepEqual(messages[0].toObject(), fixtures.message11);
      //   assert.deepEqual(messages[1].toObject(), fixtures.message12);
      // } else {
      //   assert.deepEqual(messages[1].toObject(), fixtures.message11);
      //   assert.deepEqual(messages[0].toObject(), fixtures.message12);
      // }
      //
      // //  If conversation doesnt exist
      // // then return empty Array
      // const id5 = fixtures.message5.id;
      // const conversation5 = MessageStore.getConversation(id5, 'inbox')
      // assert.deepEqual(MessageStore.getConversation(id5, 'inbox'), []);
    });
    it('getConversationLength', () => {
      // const id1 = fixtures.message10.id;
      // const conversationId1 = fixtures.message10.conversationID;
      //
      // // Message10 should exist into MessageStore
      // assert.deepEqual(MessageStore.getByID(id1).toObject(), fixtures.message10);
      //
      // // Its length is 1
      // let length = MessageStore.getConversationLength(conversationId1);
      // assert.equal(length, 1);
      //
      // const id2 = fixtures.message11.id;
      // const conversationId2 = fixtures.message11.conversationID;
      //
      // // Message11 should exist into MessageStore
      // assert.deepEqual(MessageStore.getByID(id2).toObject(), fixtures.message11);
      //
      // // Its length is 2
      // length = MessageStore.getConversationLength(conversationId2);
      // assert.equal(length, 2);
      //
      // // Empty conversation should return length: null
      // length = MessageStore.getConversationLength('c5');
      // assert.isNull(length);
    });
  });

});
