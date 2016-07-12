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
// describe('AccountActionCreator', () => {
//   let XHRUtils;
//   let AccountUtils;
//   let AccountActionCreator;
//   let Dispatcher;
//   let spy;
//
//
//   before(() => {
//     Dispatcher = new SpecDispatcher();
//     mockeryUtils.initDispatcher(Dispatcher);
//     mockeryUtils.initActionsStores();
//
//     const path = '../app/actions/account_action_creator';
//     mockeryUtils.initForStores(['../app/libs/xhr', '../app/libs/accounts', path]);
//     XHRUtils = require('../app/libs/xhr');
//     AccountUtils = require('../app/libs/accounts');
//     AccountActionCreator = require(path);
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
//     it.skip('create', () => {
//
//     });
//
//     it.skip('edit', () => {
//
//     });
//
//     it.skip('check', () => {
//
//     });
//
//     it.skip('remove', () => {
//
//     });
//
//     it.skip('discover', () => {
//
//     });
//
//     it.skip('mailboxCreate', () => {
//
//     });
//
//     it.skip('mailboxUpdate', () => {
//
//     });
//
//     it.skip('mailboxDelete', () => {
//
//     });
//
//     it.skip('mailboxExpunge', () => {
//
//     });
//
//     it.skip('saveEditTab', () => {
//
//     });
//   });
// });
