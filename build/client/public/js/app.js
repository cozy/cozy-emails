(function(/*! Brunch !*/) {
  'use strict';

  var globals = typeof window !== 'undefined' ? window : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\.\.?(\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return globals.require(absolute, path);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    cache[name] = module;
    definition(module.exports, localRequire(name), module);
    return module.exports;
  };

  var require = function(name, loaderPath) {
    var path = expand(name, '.');
    if (loaderPath == null) loaderPath = '/';

    if (has(cache, path)) return cache[path].exports;
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex].exports;
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
  };

  var define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  var list = function() {
    var result = [];
    for (var item in modules) {
      if (has(modules, item)) {
        result.push(item);
      }
    }
    return result;
  };

  globals.require = require;
  globals.require.define = define;
  globals.require.register = define;
  globals.require.list = list;
  globals.require.brunch = true;
})();
require.register("components/application", function(exports, require, module) {
var Application, body, div, p, _ref;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p;

module.exports = Application = React.createClass({
  displayName: 'Application',
  render: function() {
    return body(null, p(null, 'coucou'));
  }
});
});

;require.register("initialize", function(exports, require, module) {
$(function() {
  var Router, RouterInterface;
  Router = require('router');
  RouterInterface = require('./lib/router-interface');
  this.router = new Router();
  React.renderComponent(RouterInterface({
    router: this.router
  }), document.body);
  Backbone.history.start();
  if (typeof Object.freeze === 'function') {
    return Object.freeze(this);
  }
});
});

;require.register("lib/router-interface", function(exports, require, module) {
var Application;

Application = require('../components/application');


/*
    The RouterInterface uses Backbone.Router as a source of truth
    and is the binding between the router and the React application.
    Based on https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592
 */

module.exports = React.createClass({
  displayName: 'RouterInterface',
  componentWillMount: function() {
    this.callback = (function(_this) {
      return function() {
        return _this.forceUpdate();
      };
    })(this);
    return this.props.router.on('route', this.callback);
  },
  componentWillUnmount: function() {
    return this.props.router.off('route', this.callback);
  },
  render: function() {
    if (this.props.router.current === 'main') {
      return Application();
    } else {
      return React.DOM.div(null, '');
    }
  }
});
});

;require.register("router", function(exports, require, module) {

/*
    Very simple routing component. We let Backbone handling browser stuff
    and we bind it to the React application with the `RouterInterface`
 */
var Router,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.routes = {
    '': 'main'
  };

  Router.prototype.main = function() {
    return this.current = 'main';
  };

  return Router;

})(Backbone.Router);
});

;
//# sourceMappingURL=app.js.map