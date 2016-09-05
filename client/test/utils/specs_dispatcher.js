'use strict';

function clearCache(mod) {
  if (require.cache[mod.id]) {
    const children = require.cache[mod.id].children || [];
    delete require.cache[mod.id];
    children.forEach(clearCache);
  }
}

function freshRequire(path) {
  const modpath = require.resolve(path);
  clearCache({ id: modpath });
  return require(path); // eslint-disable-line global-require
}

module.exports = () => {
  const store = freshRequire('../../app/redux_store');

  function makeStateFullGetter(stateLessGetter) {
    return Object.keys(stateLessGetter).reduce((acc, fnName) => {
      acc[fnName] = (...fnargs) => {
        const args = [store.getState()].concat(fnargs);
        return stateLessGetter[fnName].apply(stateLessGetter, args);
      };
      return acc;
    }, {});
  }

  return {
    Dispatcher: store,
    makeStateFullGetter,
  };
};
