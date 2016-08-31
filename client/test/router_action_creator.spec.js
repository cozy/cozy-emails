'use strict';

const assert = require('chai').assert;
const _ = require('lodash');
const sinon = require('sinon');

const ActionTypes = require('../app/constants/app_constants').ActionTypes;


describe.skip('RouterActionCreator', () => {
  let XHRUtils;
  let RouterActionCreator;
  let Dispatcher;
  let spy;


  before(() => {
    Dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(Dispatcher);
    mockeryUtils.initActionsStores();

    const path = '../app/actions/router_action_creator';
    mockeryUtils.initForStores(['../app/libs/xhr', path]);
    XHRUtils = require('../app/libs/xhr');
    RouterActionCreator = require(path);
  });

  after(() => {
    mockeryUtils.clean();
  });


  beforeEach(() => {
    if (spy === undefined) {
      spy = sinon.spy(Dispatcher, 'dispatch');
    }
  });

  afterEach(() => {
    spy.reset();
  });


  describe('Methods', () => {
    it.skip('refreshMailbox', () => {

    });

    it.skip('getCurrentPage', () => {

    });

    it.skip('gotoNextPage', () => {

    });

    it.skip('gotoCompose', () => {

    });

    it.skip('gotoConversation', () => {

    });

    it.skip('gotoMessage', () => {

    });

    it.skip('gotoPreviousConversation', () => {

    });

    it.skip('gotoNextConversation', () => {

    });

    it.skip('closeConversation', () => {

    });

    it.skip('closeModal', () => {

    });

    it.skip('showMessageList', () => {

    });

    it.skip('addFilter', () => {

    });

    it.skip('searchAll', () => {

    });
  });
});
