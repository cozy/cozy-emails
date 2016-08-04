/* eslint-env mocha */

'use strict';

const ActionTypes = require('../app/constants/app_constants').ActionTypes;
const Dispatcher = require('./utils/specs_dispatcher');
const dispatcher = new Dispatcher();
const fixtures = require('./fixtures/refreshes');

describe('Refreshes', () => {
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
