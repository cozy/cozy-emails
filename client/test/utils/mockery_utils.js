const mockery = require('mockery');
const superagent = require('./specs_superagent');

// Bunch of functions to make tests less verbosed.
module.exports = {

  // Register test dispatcher as a replacement of the official dispatcher.
  initDispatcher: (dispatcher) => {
    global.__DEV__ = true;
    mockery.registerMock('../dispatcher/dispatcher', dispatcher);
    mockery.registerMock(
      '../libs/flux/dispatcher/dispatcher', dispatcher);
  },

  initActionsStores: () => {
    mockery.registerMock('superagent', superagent);
    mockery.registerMock('socket.io-client', {});

    mockery.registerMock('../stores/router_store', {});
    mockery.registerMock('../stores/account_store', {});
    mockery.registerMock('../stores/message_store', {});
    mockery.registerMock('../stores/layout_store', {});
    mockery.registerMock('../stores/contact_store', {});
    mockery.registerMock('../stores/requests_store', {});
    mockery.registerMock('../stores/settings_store', {});
  },


  // Configure mockery to run properly with stores.
  initForStores: (allowables) => {
    if (allowables === null) allowables = [];
    mockery.enable({
      warnOnUnregistered: true,
      useCleanCache: true,
    });

    mockery.registerAllowables([
      'superagent-throttle',
      'node-event-emitter',
      'immutable',
      'redux',
      'jquery',
      'moment',
      'lodash',
      'underscore',
      '../constants/app_constants',
      '../libs/flux/store/store',
      '../libs/xhr',
      '../libs/realtime',
      '../libs/accounts',
      '../libs/notification',
      '../invariant',
    ].concat(allowables));
  },

  // Unregister all mockery previously set.
  clean: () => {
    mockery.disable();
    mockery.deregisterAll();
  },
};
