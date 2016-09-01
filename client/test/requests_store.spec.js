/* eslint-env mocha */
'use strict';

const makeTestDispatcher = require('./utils/specs_dispatcher');
const RequestsGetter = require('../app/puregetters/requests');


describe('Requests Store', () => {
  let requestsStore;
  let dispatcher;

  before(() => {
    const tools = makeTestDispatcher();
    dispatcher = tools.Dispatcher;
    requestsStore = tools.makeStateFullGetter(RequestsGetter);
  });
});
