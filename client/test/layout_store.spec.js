'use strict';
const assert = require('chai').assert;

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;


describe('Layout Store', () => {
  let layoutStore;
  let dispatcher;

  before(() => {
    dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(dispatcher);
    mockeryUtils.initForStores(['../app/stores/layout_store']);
    layoutStore = require('../app/stores/layout_store');
  });

  describe('Actions', () => {
    it.skip('TOASTS_SHOW', () => {
      dispatcher.dispatch({ type: ActionTypes.TOASTS_SHOW });
      assert.equal(layoutStore.isToastHidden(), false);
    });
    it.skip('TOASTS_HIDE', () => {
      dispatcher.dispatch({ type: ActionTypes.TOASTS_HIDE });
      assert.equal(layoutStore.isToastHidden(), true);
    });
    it.skip('INTENT_AVAILABLE', () => {
      dispatcher.dispatch({
        type: ActionTypes.INTENT_AVAILABLE,
        value: true,
      });
      assert.equal(layoutStore.isIntentAvailable(), true);
    });
  });

  after(() => {
    mockeryUtils.clean();
  });
});
