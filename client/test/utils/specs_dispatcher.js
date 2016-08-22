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

let lastStore = null;

module.exports = () => {
  const store = freshRequire('../../app/reducers/_store');
  if (lastStore && lastStore === store)
    throw new Error('this fish aint fresh');
  lastStore = store;

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
