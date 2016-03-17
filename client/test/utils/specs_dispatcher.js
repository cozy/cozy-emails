var TestDispatcher = function TestDispatcher() {
    this._callbacks = []
}

TestDispatcher.prototype.register = function (callback) {
    this._callbacks.push(callback)
};


TestDispatcher.prototype.dispatch = function (payload) {
    this._callbacks.forEach(function (callback) {
        callback.call(this, {action: payload})
    });
};

module.exports = TestDispatcher
