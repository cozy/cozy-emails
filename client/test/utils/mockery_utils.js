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
    mockery.registerMock('../stores/notification_store', {});
    mockery.registerMock('../stores/search_store', {});
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

    mockery.registerMock('../stores/notification_store', {});
    mockery.registerAllowables([
      '../app/getters/message',

      '../routes',

      '../puregetters/router',
      '../puregetters/messages',
      '../puregetters/pagination',
      '../puregetters/requests',
      './messages',
      './accounts',

      '../getters/message',
      '../getters/router',
      '../getters/file',
      '../models/message',
      '../models/route',

      '../stores/account_store',
      '../stores/search_store',
      '../stores/requests_store',
    //   '../stores/notification_store',

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
      '../libs/flux/store/store',
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
