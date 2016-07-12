// 'use strict';
//
// const assert = require('chai').assert;
// const _ = require('lodash');
// const sinon = require('sinon');
//
// const mockeryUtils = require('./utils/mockery_utils');
// const SpecDispatcher = require('./utils/specs_dispatcher');
//
// const ActionTypes = require('../app/constants/app_constants').ActionTypes;
//
//
// describe('MessagesActionCreator', () => {
//   let XHRUtils;
//   let MessageActionCreator;
//   let Dispatcher;
//   let spy;
//
//
//   before(() => {
//     Dispatcher = new SpecDispatcher();
//     mockeryUtils.initDispatcher(Dispatcher);
//     mockeryUtils.initActionsStores();
//
//     const path = '../app/actions/message_action_creator';
//     mockeryUtils.initForStores(['superagent-throttle', '../app/libs/xhr', '../libs/xhr', path]);
//     XHRUtils = require('../app/libs/xhr');
//     MessageActionCreator = require(path);
//   });
//
//   after(() => {
//     mockeryUtils.clean();
//   });
//
//
//   beforeEach(() => {
//     if (spy === undefined) {
//       spy = sinon.spy(Dispatcher, 'dispatch');
//     }
//   });
//
//   afterEach(() => {
//     spy.reset();
//   });
//
//
//   describe('Methods', () => {
//     it('receiveRawMessages', () => {
//       let value = ['msg1', 'msg2', 'msg3'];
//       const result = { type: ActionTypes.RECEIVE_RAW_MESSAGES, value };
//       MessageActionCreator.receiveRawMessages(value);
//
//       assert.equal(Dispatcher.dispatch.callCount, 1);
//       assert.isTrue(Dispatcher.dispatch.calledWith(result));
//      });
//
//
//      it('receiveRawMessage', () => {
//        let value = 'msg1';
//        const result = { type: ActionTypes.RECEIVE_RAW_MESSAGE, value };
//        MessageActionCreator.receiveRawMessage(value);
//
//        assert.equal(Dispatcher.dispatch.callCount, 1);
//        assert.isTrue(Dispatcher.dispatch.calledWith(result));
//      });
//
//
//      it('displayImages', () => {
//       const messageID = 'plop';
//
//       let result = {
//         type: ActionTypes.SETTINGS_UPDATE_REQUEST,
//         value: { messageID, displayImages: true }
//       };
//
//       MessageActionCreator.displayImages({ messageID, displayImages: undefined });
//       assert.equal(Dispatcher.dispatch.callCount, 1);
//       assert.isTrue(Dispatcher.dispatch.calledWith(result));
//
//       result.value.displayImages = false;
//       MessageActionCreator.displayImages({ messageID, displayImages: false });
//       assert.equal(Dispatcher.dispatch.callCount, 2);
//       assert.isTrue(Dispatcher.dispatch.calledWith(result));
//
//       result.value.displayImages = true;
//       MessageActionCreator.displayImages({ messageID, displayImages: true });
//       assert.equal(Dispatcher.dispatch.callCount, 3);
//       assert.isTrue(Dispatcher.dispatch.calledWith(result));
//     });
//
//
//     it.skip('send', () => {
//       let action = 'mon action';
//       let message = { conversationID: 'plop', text: 'coucou' };
//       let result = {
//         type: ActionTypes.MESSAGE_SEND_SUCCESS,
//         value: {
//           action,
//           message: {
//             conversationID: 'plop',
//             text: 'coucou',
//             html: 'coucou'
//           }
//         }
//       };
//
//       var spy0 = sinon.spy(XHRUtils, 'messageSend');
//       MessageActionCreator.send(action, message);
//
//       assert.equal(spy0.callCount, 1);
//
//       // Dis is supposed to be called twice
//       // 1rst one for REQUEST
//       // Last one for SUCCESS
//       assert.equal(Dispatcher.dispatch.callCount, 2);
//
//       let args = Dispatcher.dispatch.getCall(1).args[0];
//       assert.equal(args.type, result.type);
//       assert.equal(args.value.action, result.value.action);
//       _.each(JSON.parse(args.value.message), (value, key) => {
//         assert.equal(value, result.value.message[key]);
//       });
//
//       spy0.reset();
//     });
//
//
//     it.skip('mark', () => {
//
//     });
//
//
//     it.skip('markAsRead', () => {
//
//     });
//
//
//     it('deleteMessage({ messageID })', () => {
//       const type = ActionTypes.MESSAGE_TRASH_REQUEST;
//       const target = { accountID: 'accountID', messageID: 'messageID' };
//
//       // Nothing should happen
//       // with these values in arguments
//
//       MessageActionCreator.deleteMessage({});
//       assert.equal(Dispatcher.dispatch.callCount, 0);
//
//       MessageActionCreator.deleteMessage(null);
//       assert.equal(Dispatcher.dispatch.callCount, 0);
//
//       MessageActionCreator.deleteMessage(undefined);
//       assert.equal(Dispatcher.dispatch.callCount, 0);
//
//       MessageActionCreator.deleteMessage();
//       assert.equal(Dispatcher.dispatch.callCount, 0);
//
//       MessageActionCreator.deleteMessage('plop');
//       assert.equal(Dispatcher.dispatch.callCount, 0);
//
//       let spyXHR = sinon.spy(XHRUtils, 'batchDelete');
//       MessageActionCreator.deleteMessage(target);
//
//       // Check REQUEST call
//       assert.equal(spyXHR.callCount, 1);
//       assert.equal(spyXHR.args[0].length, 2);
//       assert.deepEqual(spyXHR.args[0][0], target);
//       assert.equal(typeof spyXHR.args[0][1], 'function');
//
//       // 2 dispatch should be done
//       // 1rst REQUEST then SUCCESS
//       assert.equal(Dispatcher.dispatch.callCount, 2);
//
//       // Checkout SUCCESS dispatch
//       let value = {
//         type: ActionTypes.MESSAGE_TRASH_SUCCESS,
//         value: { target, updated: [] }
//       };
//       assert.isTrue(Dispatcher.dispatch.getCall(1).calledWith(value));
//
//       spyXHR.reset();
//     });
//
//
//     it.skip('deleteMessage({ conversationID })', () => {
//
//     });
//
//
//     it.skip('deleteMessage({ conversationIDs })', () => {
//
//     });
//
//
//     it.skip('deleteMessage({ messageIDs })', () => {
//
//     });
//
//   });
// });
