'use strict'

const assert = require('chai').assert

const mockeryUtils   = require('./utils/mockery_utils')
const SpecDispatcher = require('./utils/specs_dispatcher')
const ActionTypes  = require('../app/constants/app_constants').ActionTypes


describe("Requests Store", () => {
  let requestsStore;
  let dispatcher;

  before(() => {
    dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(dispatcher);
    mockeryUtils.initForStores(['../app/stores/requests_store']);
    requestsStore = require('../app/stores/message_store');
  });
})
