const mockery = require('mockery');
const superagent = require('./specs_superagent');
const redux = require('redux');

// Bunch of functions to make tests less verbosed.
module.exports = {

  // Register test dispatcher as a replacement of the official dispatcher.
  initDispatcher: (dispatcher) => {
    global.__DEV__ = true;
    // this feels hacky, but only wait for
    // mockery to not bother about all redux dependencies:
    mockery.registerMock('redux', redux);
    // mockery.registerMock('../dispatcher/dispatcher', dispatcher);
  },

  initActionsStores: () => {
    mockery.registerMock('superagent', superagent);
    mockery.registerMock('socket.io-client', {});
  },


  // Configure mockery to run properly with stores.
  initForStores: (allowables) => {
    if(allowables === undefined) allowables = [];
    mockery.enable({
      warnOnUnregistered: true,
      useCleanCache: true,
    });

    mockery.registerMock('../stores/notification_store', {});
    mockery.registerAllowables([

      '../routes',

      '../getters/router',
      '../getters/messages',
      '../getters/pagination',
      '../getters/requests',
      './messages',
      './accounts',

      '../models/message',
      '../models/route',

      // reducers can only be required from reducers/_store
      '../reducers/_store',
      './root',
      './message',
      './selection',
      './route',
      './modal',
      './requests',
      './layout',
      './contact',
      './refreshes',
      './messagefetch',

      'superagent-throttle',
      'node-event-emitter',
      'immutable',
      'redux',
      'react-redux',
      'jquery',
      'moment',
      'lodash',
      'underscore',
      './constants/app_constants',
      '../constants/app_constants',
      '../libs/xhr',
      '../libs/mappers/contact',
      '../libs/urikey',
      '../libs/realtime',
      '../libs/attachment_types',
      '../libs/accounts',
      '../libs/notification',
      '../../../server/utils/constants',
      '../invariant',
    ].concat(allowables));
  },

  // Unregister all mockery previously set.
  clean: () => {
    mockery.disable();
    mockery.deregisterAll();
  },
};
