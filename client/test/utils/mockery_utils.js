const mockery = require('mockery');


// Bunch of functions to make tests less verbosed.
module.exports = {

  // Register test dispatcher as a replacement of the official dispatcher.
  initDispatcher: (dispatcher) => {
    mockery.registerMock('../dispatcher/dispatcher', dispatcher);
    mockery.registerMock(
      '../libs/flux/dispatcher/dispatcher', dispatcher);
  },

  // Configure mockery to run properly with stores.
  initForStores: (allowables) => {
    if (allowables === null) allowables = [];
    mockery.enable({
      warnOnUnregistered: true,
      useCleanCache: true,
    });

    mockery.registerAllowables([
      'node-event-emitter',
      'immutable',
      'lodash',
      '../constants/app_constants',
      '../libs/flux/store/store',
      '../invariant',
    ].concat(allowables));
  },

  // Unregister all mockery previously set.
  clean: () => {
    mockery.disable();
    mockery.deregisterAll();
  },
};
