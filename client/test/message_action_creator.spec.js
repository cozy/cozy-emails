'use strict';

const assert = require('chai').assert;
const _ = require('lodash');
const sinon = require('sinon');

const mockeryUtils = require('./utils/mockery_utils');


const ActionTypes = require('../app/constants/app_constants').ActionTypes;


describe.skip('MessagesActionCreator', () => {
  let XHRUtils;
  let MessageActionCreator;
  let Dispatcher;
  let spyDispatcher;


  before(() => {
    Dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(Dispatcher);
    mockeryUtils.initActionsStores();

    const path = '../app/actions/message_action_creator';
    mockeryUtils.initForStores([
      'superagent-throttle',
      '../app/libs/xhr',
      '../libs/xhr',
      path
    ]);
    XHRUtils = require('../app/libs/xhr');
    MessageActionCreator = require(path);
  });

  after(() => {
    mockeryUtils.clean();
  });


  beforeEach(() => {
    if (spyDispatcher === undefined) {
      spyDispatcher = sinon.spy(Dispatcher, 'dispatch');
    }
  });

  afterEach(() => {
    spyDispatcher.reset();
  });


  describe('Methods', () => {
    it('receiveRawMessages', () => {
      let value = ['msg1', 'msg2', 'msg3'];
      const result = { type: ActionTypes.RECEIVE_RAW_MESSAGES, value };
      MessageActionCreator.receiveRawMessages(value);

      assert.equal(spyDispatcher.callCount, 1);
      assert.isTrue(spyDispatcher.calledWith(result));
     });


     it('receiveRawMessage', () => {
       let value = 'msg1';
       const result = { type: ActionTypes.RECEIVE_RAW_MESSAGE, value };
       MessageActionCreator.receiveRawMessage(value);

       assert.equal(spyDispatcher.callCount, 1);
       assert.isTrue(spyDispatcher.calledWith(result));
     });


     it('displayImages', () => {
      const messageID = 'plop';

      let result = {
        type: ActionTypes.SETTINGS_UPDATE_REQUEST,
        value: { messageID, displayImages: true }
      };

      MessageActionCreator.displayImages({ messageID, displayImages: undefined });
      assert.equal(spyDispatcher.callCount, 1);
      assert.isTrue(spyDispatcher.calledWith(result));

      result.value.displayImages = false;
      MessageActionCreator.displayImages({ messageID, displayImages: false });
      assert.equal(spyDispatcher.callCount, 2);
      assert.isTrue(spyDispatcher.calledWith(result));

      result.value.displayImages = true;
      MessageActionCreator.displayImages({ messageID, displayImages: true });
      assert.equal(spyDispatcher.callCount, 3);
      assert.isTrue(spyDispatcher.calledWith(result));
    });


    describe('send', () => {
      let spySend;
      let callback;
      let action = 'mon action';
      const message = { conversationID: 'plop', text: 'coucou' };

      beforeEach(() => {
        if (spySend === undefined) {
          spySend = sinon.spy(XHRUtils, 'messageSend');
        }
      });

      afterEach(() => {
        spySend.reset();
      });


      it('should MESSAGE_SEND_SUCCESS dispatched', () => {
        const type = ActionTypes.MESSAGE_SEND_SUCCESS;

        MessageActionCreator.send(action, message);

        assert.equal(spySend.callCount, 1);

        callback = spySend.getCall(0).args[1];
        assert.equal(typeof callback, 'function');

        // Dis is supposed to be called twice
        // 1rst one for REQUEST
        // Last one for SUCCESS
        assert.equal(spyDispatcher.callCount, 2);

        let args = spyDispatcher.getCall(1).args[0];
        assert.equal(args.type, type);

        let res = { conversationID: 'plop', text: 'coucou', html: 'coucou'};
        assert.equal(args.value.action, action);
        _.each(JSON.parse(args.value.message), (value, key) => {
          assert.equal(value, res[key]);
        });
      });


      it('should MESSAGE_SEND_FAILURE dispatched', () => {
        const error = 'PLOP';
        callback(error);

        assert.equal(spyDispatcher.callCount, 1);
        assert.isTrue(spyDispatcher.getCall(0).calledWith({
          type: ActionTypes.MESSAGE_SEND_FAILURE,
          value: { error, action, message: undefined }
        }));
      })
    });


    it.skip('mark', () => {

    });


    it.skip('markAsRead', () => {

    });


    describe('deleteMessage({ messageID })', () => {

      const type = ActionTypes.MESSAGE_TRASH_REQUEST;
      const target = { accountID: 'accountID', messageID: 'messageID' };
      let spyDelete;
      let callback;

      beforeEach(() => {
        if (spyDelete === undefined) {
          spyDelete = sinon.spy(XHRUtils, 'batchDelete');
        }
      });

      afterEach(() => {
        spyDelete.reset();
      });


      it('should nothing dispatched', () => {
          MessageActionCreator.deleteMessage({});
          assert.equal(spyDispatcher.callCount, 0);

          MessageActionCreator.deleteMessage(null);
          assert.equal(spyDispatcher.callCount, 0);

          MessageActionCreator.deleteMessage(undefined);
          assert.equal(spyDispatcher.callCount, 0);

          MessageActionCreator.deleteMessage();
          assert.equal(spyDispatcher.callCount, 0);

          MessageActionCreator.deleteMessage('plop');
          assert.equal(spyDispatcher.callCount, 0);
      });

      it('should MESSAGE_TRASH_SUCCESS dispatched', () => {
        MessageActionCreator.deleteMessage(target);

        // Check REQUEST call
        assert.equal(spyDelete.callCount, 1);
        assert.equal(spyDelete.getCall(0).args.length, 2);
        assert.deepEqual(spyDelete.getCall(0).args[0], target);

        callback = spyDelete.getCall(0).args[1];
        assert.equal(typeof callback, 'function');

        // 2 dispatch should be done
        // 1rst REQUEST then SUCCESS
        assert.equal(spyDispatcher.callCount, 2);

        // Checkout SUCCESS dispatch
        let value = {
          type: ActionTypes.MESSAGE_TRASH_SUCCESS,
          value: { target, updated: [] }
        };
        assert.isTrue(spyDispatcher.getCall(1).calledWith(value));

      });

      it('should MESSAGE_TRASH_FAILURE dispatched', () => {
        const error = 'PLOP';
        callback(error);

        assert.equal(spyDispatcher.callCount, 1);
        assert.isTrue(spyDispatcher.getCall(0).calledWith({
          type: ActionTypes.MESSAGE_TRASH_FAILURE,
          value: { target, updated: [], error }
        }));
      });
    });


    it.skip('deleteMessage({ conversationID })', () => {

    });


    it.skip('deleteMessage({ conversationIDs })', () => {

    });


    it.skip('deleteMessage({ messageIDs })', () => {

    });

  });
});
