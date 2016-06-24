const TestDispatcher = function TestDispatcher() {
  this._callbacks = [];
};

TestDispatcher.prototype.register = function register(callback) {
  this._callbacks.push(callback);
};


TestDispatcher.prototype.dispatch = function dispatch(payload) {
  this._callbacks.forEach((callback) => {
    callback.call(this, payload);
  });
};

TestDispatcher.prototype.waitFor = function waitFor(events) {
};

module.exports = TestDispatcher;
