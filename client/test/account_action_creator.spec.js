/* eslint-env mocha */
'use strict';

const sinon = require('sinon');
const mockeryUtils = require('./utils/mockery_utils');
const makeTestDispatcher = require('./utils/specs_dispatcher');

describe('AccountActionCreator', () => {
  let Dispatcher;
  let spy;


  before(() => {
    const tools = makeTestDispatcher();
    Dispatcher = tools.Dispatcher;
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
    it.skip('create', () => {

    });

    it.skip('edit', () => {

    });

    it.skip('check', () => {

    });

    it.skip('remove', () => {

    });

    it.skip('discover', () => {

    });

    it.skip('mailboxCreate', () => {

    });

    it.skip('mailboxUpdate', () => {

    });

    it.skip('mailboxDelete', () => {

    });

    it.skip('mailboxExpunge', () => {

    });

    it.skip('saveEditTab', () => {

    });
  });
});
