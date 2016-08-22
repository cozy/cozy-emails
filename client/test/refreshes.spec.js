/* eslint-env mocha */

'use strict';

const ActionTypes = require('../app/constants/app_constants').ActionTypes;
const fixtures = require('./fixtures/refreshes');
const makeTestDispatcher = require('./utils/specs_dispatcher');

describe('Refreshes', () => {
  let dispatcher;

  before(() => {
    const tools = makeTestDispatcher();
    dispatcher = tools.Dispatcher;
  });

  it('distpatch RECEIVE_REFRESH_STATUS', () => {
    dispatcher.dispatch({
      type: ActionTypes.RECEIVE_REFRESH_STATUS,
      value: fixtures,
    });
  });

  it('distpatch RECEIVE_REFRESH_STATUS', () => {
    dispatcher.dispatch({
      type: ActionTypes.RECEIVE_REFRESH_UPDATE,
      value: {},
    });
  });
});
