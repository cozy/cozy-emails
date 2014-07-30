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
require.register("actions/layout_actions", function(exports, require, module) {
module.exports = {
  showRoute: function(name, leftPanelInfo, rightPanelInfo) {
    return this.dispatch('SHOW_ROUTE', {
      name: name,
      leftPanelInfo: leftPanelInfo,
      rightPanelInfo: rightPanelInfo
    });
  }
};
});

;require.register("components/application", function(exports, require, module) {
var Application, Compose, EmailList, EmailThread, FluxMixin, Menu, StoreWatchMixin, body, div, form, i, input, p, span, _ref;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span;

Menu = require('./menu');

EmailList = require('./email-list');

EmailThread = require('./email-thread');

Compose = require('./compose');

FluxMixin = Fluxxor.FluxMixin(React);

StoreWatchMixin = Fluxxor.StoreWatchMixin;


/*
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly

    About routing: it uses Backbone.Router as a source of truth for the layout.
    (based on: https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592)

    Fluxxor reference:
     - FluxMixin: http://fluxxor.com/documentation/flux-mixin.html
     - StoreWatchMixin: http://fluxxor.com/documentation/store-watch-mixin.html
 */

module.exports = Application = React.createClass({
  displayName: 'Application',
  mixins: [FluxMixin, StoreWatchMixin("MailboxStore", "EmailStore", "LayoutStore")],
  render: function() {
    var isFullWidth, layout, leftPanelLayoutMode, panelClasses;
    layout = this.state.layout;
    isFullWidth = this.state.isLayoutFullWidth;
    leftPanelLayoutMode = isFullWidth ? 'full' : 'left';
    panelClasses = this.getPanelClasses(isFullWidth);
    return div({
      className: 'container-fluid'
    }, div({
      className: 'row'
    }, Menu({
      mailboxes: this.state.mailboxes
    }), div({
      id: 'page-content',
      className: 'col-xs-12 col-md-11'
    }, div({
      id: 'quick-actions',
      className: 'row'
    }, i({
      className: 'fa fa-bars hidden-md hidden-lg pull-left'
    }), form({
      className: 'form-inline col-md-6 hidden-xs hidden-sm pull-left'
    }, div({
      className: 'form-group'
    }, div({
      className: 'input-group'
    }, input({
      className: 'form-control',
      type: 'text',
      placeholder: 'Search...'
    }), div({
      className: 'input-group-addon btn btn-cozy'
    }, span({
      className: 'fa fa-search'
    })))))), div({
      id: 'panels',
      className: 'row'
    }, div({
      className: panelClasses.leftPanel
    }, this.getPanelComponent(layout.leftPanel, leftPanelLayoutMode)), !isFullWidth ? div({
      className: panelClasses.rightPanel
    }, this.getPanelComponent(layout.rightPanel, 'right')) : void 0))));
  },
  getPanelClasses: function(isFullWidth) {
    var classes;
    if (isFullWidth) {
      classes = {
        leftPanel: 'panel col-xs-12 col-md-12'
      };
    } else {
      classes = {
        leftPanel: 'panel col-xs-12 col-md-6',
        rightPanel: 'panel col-xs-12 col-md-6 hidden-xs hidden-sm'
      };
    }
    return classes;
  },
  getPanelComponent: function(panelInfo, layout) {
    var email, emailStore, firstMailbox, mailboxID;
    if (panelInfo.action === 'mailbox.emails') {
      firstMailbox = this.getFlux().store('MailboxStore').getDefault();
      if (panelInfo.parameter != null) {
        emailStore = this.getFlux().store('EmailStore');
        mailboxID = parseInt(panelInfo.parameter);
        return EmailList({
          emails: emailStore.getEmailsByMailbox(mailboxID),
          layout: layout
        });
      } else if ((panelInfo.parameter == null) && (firstMailbox != null)) {
        emailStore = this.getFlux().store('EmailStore');
        mailboxID = firstMailbox.id;
        return EmailList({
          emails: emailStore.getEmailsByMailbox(mailboxID),
          layout: layout
        });
      } else {
        return div(null, 'Handle empty mailbox case');
      }
    } else if (panelInfo.action === 'mailbox.config') {
      return div(null, 'Mailbox configuration/creation');
    } else if (panelInfo.action === 'email') {
      email = this.getFlux().store('EmailStore').getByID(panelInfo.parameter);
      return EmailThread({
        email: email,
        layout: layout
      });
    } else if (panelInfo.action === 'compose') {
      return Compose({
        layout: layout
      });
    } else {
      return div(null, 'Unknown component');
    }
  },
  getStateFromFlux: function() {
    var flux;
    flux = this.getFlux();
    return {
      mailboxes: flux.store('MailboxStore').getAll(),
      emails: flux.store('EmailStore').getAll(),
      layout: flux.store('LayoutStore').getState(),
      isLayoutFullWidth: flux.store('LayoutStore').isFullWidth()
    };
  },
  componentWillMount: function() {
    this.onRoute = (function(_this) {
      return function(route, params) {};
    })(this);
    return this.props.router.on('route', this.onRoute);
  },
  componentWillUnmount: function() {
    return this.props.router.off('route', this.onRoute);
  }
});
});

;require.register("components/compose", function(exports, require, module) {
var Compose, RouterMixin, a, classer, div, h3, i, textarea, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, a = _ref.a, i = _ref.i, textarea = _ref.textarea;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router');

module.exports = Compose = React.createClass({
  displayName: 'Compose',
  mixins: [RouterMixin],
  render: function() {
    var closeUrl, expandUrl;
    expandUrl = this.buildUrl({
      direction: 'left',
      action: 'compose',
      parameter: null,
      fullWidth: true
    });
    closeUrl = this.buildClosePanelUrl(this.props.layout);
    return div({
      id: 'email-compose'
    }, h3(null, a({
      href: expandUrl,
      className: 'expand'
    }, i({
      className: 'fa fa-angle-left'
    })), 'Compose new email', a({
      href: closeUrl,
      className: 'close-email'
    }, i({
      className: 'fa fa-times'
    }))), textarea({
      defaultValue: 'Hello, how are you doing today?'
    }));
  }
});
});

;require.register("components/email-list", function(exports, require, module) {
var EmailList, RouterMixin, a, classer, div, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, p = _ref.p;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router');

module.exports = EmailList = React.createClass({
  displayName: 'EmailList',
  mixins: [RouterMixin],
  render: function() {
    var email, key;
    return div({
      id: 'email-list'
    }, ul({
      className: 'list-unstyled'
    }, (function() {
      var _i, _len, _ref1, _results;
      _ref1 = this.props.emails;
      _results = [];
      for (key = _i = 0, _len = _ref1.length; _i < _len; key = ++_i) {
        email = _ref1[key];
        _results.push(this.getEmailRender(email, key));
      }
      return _results;
    }).call(this)));
  },
  getEmailRender: function(email, key) {
    var classes, url;
    classes = classer({
      read: email.isRead
    });
    url = this.buildUrl({
      direction: 'right',
      action: 'email',
      parameter: email.id
    });
    return li({
      className: 'email ' + classes,
      key: key
    }, a({
      href: url
    }, i({
      className: 'fa fa-user'
    }), span({
      className: 'email-participants'
    }, this.getParticipants(email)), div({
      className: 'email-preview'
    }, span({
      className: 'email-title'
    }, email.title), p(null, email.content)), span({
      className: 'email-hour'
    }, email.date)));
  },
  getParticipants: function(email) {
    var list;
    list = [email.sender].concat(email.receivers);
    return list.join(', ');
  }
});
});

;require.register("components/email-thread", function(exports, require, module) {
var EmailThread, RouterMixin, a, classer, div, h3, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router');

module.exports = EmailThread = React.createClass({
  displayName: 'EmailThread',
  mixins: [RouterMixin],
  render: function() {
    var closeUrl, expandUrl;
    expandUrl = this.buildUrl({
      direction: 'left',
      action: 'email',
      parameter: this.props.email.id,
      fullWidth: true
    });
    closeUrl = this.buildClosePanelUrl(this.props.layout);
    return div({
      id: 'email-thread'
    }, h3(null, a({
      href: expandUrl,
      className: 'expand'
    }, i({
      className: 'fa fa-angle-left'
    })), this.props.email.title, a({
      href: closeUrl,
      className: 'close-email'
    }, i({
      className: 'fa fa-times'
    }))), ul({
      className: 'email-thread list-unstyled'
    }, li({
      className: 'email unread'
    }, div({
      className: 'email-header'
    }, i({
      className: 'fa fa-user'
    }), div({
      className: 'email-participants'
    }, span({
      className: 'sender'
    }, 'Joseph'), span({
      className: 'receivers'
    }, 'À Frank Rousseau')), span({
      className: 'email-hour'
    }, this.props.email.date)), div({
      className: 'email-preview'
    }, p(null, this.props.email.content)), div({
      className: 'email-content'
    }, this.props.email.content), div({
      className: 'clearfix'
    }))));
  }
});
});

;require.register("components/menu", function(exports, require, module) {
var Menu, RouterMixin, a, classer, div, i, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router');

module.exports = Menu = React.createClass({
  displayName: 'Menu',
  mixins: [RouterMixin],
  getInitialState: function() {
    return {
      activeMailbox: null
    };
  },
  render: function() {
    var composeUrl, key, mailbox;
    composeUrl = this.buildUrl({
      direction: 'right',
      action: 'compose',
      parameter: null,
      fullWidth: false
    });
    return div({
      id: 'menu',
      className: 'col-xs-12 col-md-1 hidden-xs hidden-sm'
    }, a({
      href: composeUrl,
      className: 'menu-item compose-action'
    }, i({
      className: 'fa fa-edit'
    }), span({
      className: 'mailbox-label'
    }, 'Compose')), ul({
      id: 'mailbox-list',
      className: 'list-unstyled'
    }, (function() {
      var _i, _len, _ref1, _results;
      _ref1 = this.props.mailboxes;
      _results = [];
      for (key = _i = 0, _len = _ref1.length; _i < _len; key = ++_i) {
        mailbox = _ref1[key];
        _results.push(this.getMailboxRender(mailbox, key));
      }
      return _results;
    }).call(this)), a({
      href: '#',
      className: 'menu-item new-mailbox-action'
    }, i({
      className: 'fa fa-inbox'
    }), span({
      className: 'mailbox-label'
    }, 'New mailbox')));
  },
  getMailboxRender: function(mailbox, key) {
    var isActive, mailboxClasses, url;
    isActive = (!this.state.activeMailbox && key === 0) || this.state.activeMailbox === mailbox.id;
    mailboxClasses = classer({
      active: isActive
    });
    url = this.buildUrl({
      direction: 'left',
      action: 'mailbox.emails',
      parameter: mailbox.id,
      fullWidth: false
    });
    return li({
      className: mailboxClasses,
      key: key
    }, a({
      href: url,
      className: 'menu-item ' + mailboxClasses
    }, i({
      className: 'fa fa-inbox'
    }), span({
      className: 'badge'
    }, mailbox.unreadCount), span({
      className: 'mailbox-label'
    }, mailbox.label)), ul({
      className: 'list-unstyled submenu'
    }, a({
      href: '#',
      className: 'menu-item'
    }, i({
      className: 'fa fa-star'
    }), span({
      className: 'badge'
    }, 3), span({
      className: 'mailbox-label'
    }, 'Favorite')), a({
      href: '#',
      className: 'menu-item'
    }, i({
      className: 'fa fa-send'
    }), span({
      className: 'badge'
    }, ''), span({
      className: 'mailbox-label'
    }, 'Sent')), a({
      href: '#',
      className: 'menu-item'
    }, i({
      className: 'fa fa-trash-o'
    }), span({
      className: 'badge'
    }, ''), span({
      className: 'mailbox-label'
    }, 'Trash'))));
  }
});
});

;require.register("components/new-mailbox", function(exports, require, module) {
var a, classer, div, form, h3, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, form = _ref.form, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, p = _ref.p;

classer = React.addons.classSet;

module.exports = React.createClass({
  displayName: 'NewMailbox',
  render: function() {
    return div({
      id: 'mailbox-new'
    }, h3(null, 'New mailbox'));
  }
});
});

;require.register("initialize", function(exports, require, module) {
$(function() {
  var Application, EmailStore, LayoutStore, MailboxStore, Router, actions, application, flux, stores;
  MailboxStore = require('./stores/mailboxes');
  EmailStore = require('./stores/emails');
  LayoutStore = require('./stores/layout');
  stores = {
    MailboxStore: new MailboxStore(),
    EmailStore: new EmailStore(),
    LayoutStore: new LayoutStore()
  };
  actions = {
    layout: require('./actions/layout_actions')
  };
  flux = new Fluxxor.Flux(stores, actions);
  Router = require('router');
  this.router = new Router({
    flux: flux
  });
  window.router = this.router;
  Backbone.history.start();
  Application = require('./components/application');
  application = Application({
    router: this.router,
    flux: flux
  });
  React.renderComponent(application, document.body);
  if (typeof Object.freeze === 'function') {
    return Object.freeze(this);
  }
});
});

;require.register("mixins/router", function(exports, require, module) {

/*
    Router mixin.
    Aliases `buildUrl` and `buildClosePanelUrl`
 */
var router;

router = window.router;

module.exports = {
  buildUrl: function(options) {
    return router.buildUrl.call(router, options);
  },
  buildClosePanelUrl: function(direction) {
    return router.buildClosePanelUrl.call(router, direction);
  }
};
});

;require.register("router", function(exports, require, module) {

/*
    Routing component. We let Backbone handling browser stuff
    and we format the varying parts of the layout.

    URLs are built in the following way:
        - a first part that represents the left panel
        - a second part that represents the right panel
        - if there is just one part, it represents a full width panel

    Since Backbone.Router only handles one part, routes initialization mechanism
    is overriden so we can post-process the second part of the URL.

    Example: a defined pattern will generates two routes.
        - `mailbox/a/path/:id`
        - `mailbox/a/path/:id/*rightPanel`

        Each pattern is actually the pattern itself plus the pattern and
        another pattern.

    Currently, only one parameter is supported per pattern.
 */
var Router,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.patterns = {
    'mailbox.config': {
      pattern: 'mailbox/:id/config',
      callback: 'mailbox.config'
    },
    'mailbox.new': {
      pattern: 'mailbox/new',
      callback: 'mailbox.new'
    },
    'mailbox.emails': {
      pattern: 'mailbox/:id',
      callback: 'mailbox.emails'
    },
    'email': {
      pattern: 'email/:id',
      callback: 'email'
    },
    'compose': {
      pattern: 'compose',
      callback: 'compose'
    }
  };

  Router.prototype.routes = {
    '': 'mailbox.emails'
  };

  Router.prototype.cachedPatterns = [];

  Router.prototype.initialize = function(options) {
    var key, route, _ref;
    _ref = this.patterns;
    for (key in _ref) {
      route = _ref[key];
      this.cachedPatterns.push({
        key: key,
        pattern: this._routeToRegExp(route.pattern)
      });
      this.routes[route.pattern] = route.callback;
      this.routes["" + route.pattern + "/*rightPanel"] = route.callback;
    }
    this._bindRoutes();
    this.flux = options.flux;
    return this.on('route', (function(_this) {
      return function(name, args) {
        var leftPanelInfo, rightPanelInfo, _ref1;
        _ref1 = _this._processSubRouting(args), leftPanelInfo = _ref1[0], rightPanelInfo = _ref1[1];
        return _this.flux.actions.layout.showRoute(name, leftPanelInfo, rightPanelInfo);
      };
    })(this));
  };


  /*
      Extracts and matches the second part of the URl if it exists.
   */

  Router.prototype._processSubRouting = function(args) {
    var isNumber, leftPanelInfo, rightPanelInfo, route;
    leftPanelInfo = args[0], rightPanelInfo = args[1];
    isNumber = /[0-9]+/.test(leftPanelInfo);
    if ((rightPanelInfo == null) && (leftPanelInfo != null) && leftPanelInfo.indexOf(':') === -1) {
      rightPanelInfo = leftPanelInfo;
    }
    route = _.first(_.filter(this.cachedPatterns, function(element) {
      return element.pattern.test(rightPanelInfo);
    }));
    if (route != null) {
      args = this._extractParameters(route.pattern, rightPanelInfo);
      rightPanelInfo = {
        action: route.key,
        parameter: args[0]
      };
    } else {
      rightPanelInfo = null;
    }
    return [leftPanelInfo, rightPanelInfo];
  };


  /*
      Builds a route from panel information.
      Two modes:
          - options has leftPanel and/or rightPanel attributes with the
            panel(s) information.
          - options has the panel information along a `direction` attribute
            that can be `left` or `right`. It's the short version.
   */

  Router.prototype.buildUrl = function(options) {
    var leftPanelInfo, leftPart, rightPanelInfo, rightPart, url;
    this.current = this.flux.store('LayoutStore').getState();
    if ((options.leftPanel != null) || (options.rightPanel != null)) {
      leftPanelInfo = options.leftPanel || this.current.leftPanel;
      rightPanelInfo = options.rightPanel || this.current.rightPanel;
    } else {
      if (options.direction != null) {
        if (options.direction === 'left') {
          leftPanelInfo = options;
          rightPanelInfo = this.current.rightPanel;
        } else if (options.direction === 'right') {
          leftPanelInfo = this.current.leftPanel;
          rightPanelInfo = options;
        } else {
          console.warn('`direction` should be `left`, `right`.');
        }
      } else {
        console.warn('`direction` parameter is mandatory when using short call.');
      }
    }
    if (((options.leftPanel != null) || options.direction === 'left') && options.fullWidth) {
      if ((options.leftPanel != null) || options.direction === 'right') {
        console.warn("You shouldn't use the fullWidth option with a right panel");
      }
      rightPanelInfo = null;
    }
    leftPart = this._getURLFromCurrentRoute(leftPanelInfo);
    rightPart = this._getURLFromCurrentRoute(rightPanelInfo);
    url = "#" + leftPart;
    if ((rightPart != null) && rightPart.length > 0) {
      url = "" + url + "/" + rightPart;
    }
    return url;
  };


  /*
      Closes a panel given a direction. If a full-width panel is closed,
      the URL points to the default route.
   */

  Router.prototype.buildClosePanelUrl = function(direction) {
    var panelInfo;
    if (direction === 'left' || direction === 'full') {
      panelInfo = this.current.rightPanel;
    } else {
      panelInfo = this.current.leftPanel;
    }
    if (panelInfo != null) {
      panelInfo.direction = 'left';
      panelInfo.fullWidth = true;
      return this.buildUrl(panelInfo);
    } else {
      return '#';
    }
  };

  Router.prototype._getURLFromCurrentRoute = function(panel) {
    var partURL, pattern;
    if (panel != null) {
      pattern = this.patterns[panel.action].pattern;
      if (panel.action === 'mailbox.emails' && (panel.parameter == null)) {
        panel.parameter = this.flux.store('MailboxStore').getDefault().id;
      }
      partURL = pattern.replace(':id', panel.parameter);
      return partURL;
    } else {
      return '';
    }
  };

  return Router;

})(Backbone.Router);
});

;require.register("stores/emails", function(exports, require, module) {
var EmailStore;

module.exports = EmailStore = Fluxxor.createStore({
  initialize: function() {
    return this.emails = [
      {
        id: 1,
        title: 'Question application Email',
        sender: 'joseph.silvestre@cozycloud.cc',
        receivers: ['frank.rousseau@cozycloud.cc'],
        content: 'Salut Frank,\n\nJ\'ai une question concernant l\'application Email : jusqu\'à quel niveau doit-on gérer le responsive ?\n\nJ\'ai commencé à vouloir le faire très proprement mais je me suis dit la chose suivante : personne n\'utilise un navigateur sur mobile pour regarder ses emails. Où je me trompe ?',
        date: '12:38',
        isRead: true,
        mailbox: 1
      }, {
        id: 2,
        title: 'Question application Email',
        sender: 'frank.rousseau@cozycloud.cc',
        receivers: ['joseph.silvestre@cozycloud.cc'],
        content: 'Je pense que ce n\'est utile que pour la démo mais bon c\'est ce que les gens regardent en premier. Notre expérience mobile est assez mauvaise aujourd\'hui (j\'ai testé ça ce week-end, il n\'y que contacts de bien). Du coup pour emails ce serait pas mal d\'avoir quelque chose qui passe aussi (mais vas-y bourrin, quand ça ne rentre pas enlève des éléments/features).\n\nPour le responsive on a en gros quatre tailles :\n\n- 1900px de large pour les grands écrans\n- 1200px de large pour les portables (En général ce qui passe bien sur 1200px passe bien sur 1900px)\n- 960px de large pour les tablettes (en fait ici on fait pour 720px mais on actionne à partir de 960px les modifs).\n- 480px de large pour les téléphones',
        date: '12:38',
        isRead: true,
        mailbox: 1
      }
    ];
  },
  getAll: function() {
    return this.emails;
  },
  getByID: function(emailID) {
    return _.findWhere(this.emails, {
      id: parseInt(emailID)
    });
  },
  getEmailsByMailbox: function(mailboxID) {
    return _.filter(this.emails, function(email) {
      return email.mailbox === mailboxID;
    });
  }
});
});

;require.register("stores/layout", function(exports, require, module) {
var LayoutStore;

module.exports = LayoutStore = Fluxxor.createStore({
  actions: {
    'SHOW_ROUTE': 'onRoute'
  },
  initialize: function() {
    return this.layout = {
      leftPanel: {
        action: 'mailbox.emails',
        parameter: null
      },
      rightPanel: null
    };
  },
  onRoute: function(args) {
    var leftPanelInfo, name, rightPanelInfo;
    name = args.name, leftPanelInfo = args.leftPanelInfo, rightPanelInfo = args.rightPanelInfo;
    this.layout = {
      leftPanel: {
        action: name,
        parameter: leftPanelInfo
      },
      rightPanel: rightPanelInfo
    };
    return this.emit('change');
  },
  getState: function() {
    return this.layout;
  },
  isFullWidth: function() {
    return this.layout.rightPanel == null;
  }
});
});

;require.register("stores/mailboxes", function(exports, require, module) {
var MailboxStore;

module.exports = MailboxStore = Fluxxor.createStore({
  initialize: function() {
    return this.mailboxes = [
      {
        id: 1,
        label: 'joseph.silvestre38@gmail.com',
        unreadCount: 1275
      }, {
        id: 2,
        label: 'joseph.silvestre@cozycloud.cc',
        unreadCount: 369
      }
    ];
  },
  getAll: function() {
    return this.mailboxes;
  },
  getDefault: function() {
    return this.mailboxes[0];
  }
});
});

;
//# sourceMappingURL=app.js.map