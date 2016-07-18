const AppRouter = require('../../app/router');

const TestRouter = function TestRouter() {
  this._uri = null;
  this.routes = AppRouter.prototype.routes;
};

TestRouter.prototype.navigate = function navigate(URI) {
  this._uri = URI;
};

module.exports = TestRouter;
