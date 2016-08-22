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


  describe.skip('Methods', () => {
    it('create', () => {

    });

    it('edit', () => {

    });

    it('check', () => {

    });

    it('remove', () => {

    });

    it('discover', () => {

    });

    it('mailboxCreate', () => {

    });

    it('mailboxUpdate', () => {

    });

    it('mailboxDelete', () => {

    });

    it('mailboxExpunge', () => {

    });

    it('saveEditTab', () => {

    });
  });
});
