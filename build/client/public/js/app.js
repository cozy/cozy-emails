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
require.register("actions/email_actions", function(exports, require, module) {
module.exports = {
  receiveRawEmails: function(emails) {
    return this.dispatch('RECEIVE_RAW_EMAILS', emails);
  },
  receiveRawEmail: function(email) {
    return this.dispatch('RECEIVE_RAW_EMAIL', email);
  }
};
});

;require.register("actions/layout_actions", function(exports, require, module) {
var XHRUtils;

XHRUtils = require('../utils/XHRUtils');

module.exports = {
  showReponsiveMenu: function() {
    return this.dispatch('SHOW_MENU_RESPONSIVE');
  },
  hideReponsiveMenu: function() {
    return this.dispatch('HIDE_MENU_RESPONSIVE');
  },
  showEmailList: function(panelInfo, direction) {
    var defaultMailbox, flux, mailboxID;
    this.dispatch('HIDE_MENU_RESPONSIVE');
    this.dispatch('SELECT_MAILBOX', panelInfo.parameters[0]);
    flux = require('../fluxxor');
    defaultMailbox = flux.store('MailboxStore').getDefault();
    mailboxID = panelInfo.parameters[0] || (defaultMailbox != null ? defaultMailbox.id : void 0);
    if (mailboxID != null) {
      return XHRUtils.fetchEmailsByMailbox(mailboxID);
    }
  },
  showEmailThread: function(panelInfo, direction) {
    this.dispatch('HIDE_MENU_RESPONSIVE');
    return XHRUtils.fetchEmailThread(panelInfo.parameters[0]);
  },
  showComposeNewEmail: function(panelInfo, direction) {
    return this.dispatch('HIDE_MENU_RESPONSIVE');
  },
  showCreateMailbox: function(panelInfo, direction) {
    this.dispatch('HIDE_MENU_RESPONSIVE');
    return this.dispatch('SELECT_MAILBOX', -1);
  },
  showConfigMailbox: function(panelInfo, direction) {
    this.dispatch('HIDE_MENU_RESPONSIVE');
    return this.dispatch('SELECT_MAILBOX', panelInfo.parameters[0]);
  }
};
});

;require.register("actions/mailbox_actions", function(exports, require, module) {
var XHRUtils;

XHRUtils = require('../utils/XHRUtils');

module.exports = {
  create: function(inputValues) {
    this.dispatch('NEW_MAILBOX_WAITING', true);
    return XHRUtils.createMailbox(inputValues, (function(_this) {
      return function(error, mailbox) {
        return setTimeout(function() {
          _this.dispatch('NEW_MAILBOX_WAITING', false);
          if (error != null) {
            return _this.dispatch('NEW_MAILBOX_ERROR', error);
          } else {
            return _this.dispatch('ADD_MAILBOX', mailbox);
          }
        }, 2000);
      };
    })(this));
  },
  edit: function(inputValues) {
    this.dispatch('NEW_MAILBOX_WAITING', true);
    return XHRUtils.editMailbox(inputValues, (function(_this) {
      return function(error, mailbox) {
        return setTimeout(function() {
          _this.dispatch('NEW_MAILBOX_WAITING', false);
          if (error != null) {
            return _this.dispatch('NEW_MAILBOX_ERROR', error);
          } else {
            return _this.dispatch('EDIT_MAILBOX', mailbox);
          }
        }, 2000);
      };
    })(this));
  },
  remove: function(mailboxID) {
    this.dispatch('REMOVE_MAILBOX', mailboxID);
    XHRUtils.removeMailbox(mailboxID);
    return window.router.navigate('', true);
  }
};
});

;require.register("components/application", function(exports, require, module) {
var Application, Compose, EmailList, EmailThread, FluxMixin, Fluxxor, ImapFolderList, MailboxConfig, Menu, React, ReactCSSTransitionGroup, RouterMixin, StoreWatchMixin, a, body, classer, div, form, i, input, p, span, _ref;

Fluxxor = require('fluxxor');

React = require('react/addons');

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span, a = _ref.a;

Menu = require('./menu');

EmailList = require('./email-list');

EmailThread = require('./email-thread');

Compose = require('./compose');

MailboxConfig = require('./mailbox-config');

ImapFolderList = require('./imap-folder-list');

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

FluxMixin = Fluxxor.FluxMixin(React);

StoreWatchMixin = Fluxxor.StoreWatchMixin;

RouterMixin = require('../mixins/router');


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
  mixins: [FluxMixin, StoreWatchMixin("MailboxStore", "EmailStore", "LayoutStore"), RouterMixin],
  render: function() {
    var configMailboxUrl, isFullWidth, layout, leftPanelLayoutMode, panelClasses, responsiveBackUrl, responsiveClasses, showMailboxConfigButton;
    layout = this.props.router.current;
    if (layout == null) {
      return div(null, "Loading...");
    }
    isFullWidth = layout.rightPanel == null;
    leftPanelLayoutMode = isFullWidth ? 'full' : 'left';
    panelClasses = this.getPanelClasses(isFullWidth);
    showMailboxConfigButton = (this.state.selectedMailbox != null) && layout.leftPanel.action !== 'mailbox.new';
    if (showMailboxConfigButton) {
      if (layout.leftPanel.action === 'mailbox.config') {
        configMailboxUrl = this.buildUrl({
          direction: 'left',
          action: 'mailbox.emails',
          parameters: this.state.selectedMailbox.id,
          fullWidth: true
        });
      } else {
        configMailboxUrl = this.buildUrl({
          direction: 'left',
          action: 'mailbox.config',
          parameters: this.state.selectedMailbox.id,
          fullWidth: true
        });
      }
    }
    responsiveBackUrl = this.buildUrl({
      leftPanel: layout.leftPanel,
      fullWidth: true
    });
    responsiveClasses = classer({
      'col-xs-12 col-md-11': true,
      'pushed': this.state.isResponsiveMenuShown
    });
    return div({
      className: 'container-fluid'
    }, div({
      className: 'row'
    }, Menu({
      mailboxes: this.state.mailboxes,
      selectedMailbox: this.state.selectedMailbox,
      isResponsiveMenuShown: this.state.isResponsiveMenuShown,
      layout: this.props.router.current
    }), div({
      id: 'page-content',
      className: responsiveClasses
    }, div({
      id: 'quick-actions',
      className: 'row'
    }, layout.rightPanel ? a({
      href: responsiveBackUrl,
      className: 'responsive-handler hidden-md hidden-lg'
    }, i({
      className: 'fa fa-chevron-left hidden-md hidden-lg pull-left'
    }), 'Back') : a({
      onClick: this.onResponsiveMenuClick,
      className: 'responsive-handler hidden-md hidden-lg'
    }, i({
      className: 'fa fa-bars pull-left'
    }), 'Menu'), div({
      className: 'col-md-6 hidden-xs hidden-sm pull-left'
    }, form({
      className: 'form-inline col-md-12'
    }, ImapFolderList({
      selectedMailbox: this.state.selectedMailbox
    }), div({
      className: 'form-group pull-left'
    }, div({
      className: 'input-group'
    }, input({
      className: 'form-control',
      type: 'text',
      placeholder: 'Search...',
      onFocus: this.onFocusSearchInput,
      onBlur: this.onBlurSearchInput
    }), div({
      className: 'input-group-addon btn btn-cozy'
    }, span({
      className: 'fa fa-search'
    })))))), div({
      id: 'contextual-actions',
      className: 'col-md-6 hidden-xs hidden-sm pull-left text-right'
    }, ReactCSSTransitionGroup({
      transitionName: 'fade'
    }, showMailboxConfigButton ? a({
      href: configMailboxUrl,
      className: 'btn btn-cozy mailbox-config'
    }, i({
      className: 'fa fa-cog'
    })) : void 0))), div({
      id: 'panels',
      className: 'row'
    }, div({
      className: panelClasses.leftPanel,
      key: 'left-panel-' + layout.leftPanel.action + '-' + layout.leftPanel.parameters.join('-')
    }, this.getPanelComponent(layout.leftPanel, leftPanelLayoutMode)), !isFullWidth && (layout.rightPanel != null) ? div({
      className: panelClasses.rightPanel,
      key: 'right-panel-' + layout.rightPanel.action + '-' + layout.rightPanel.parameters.join('-')
    }, this.getPanelComponent(layout.rightPanel, 'right')) : void 0))));
  },
  getPanelClasses: function(isFullWidth) {
    var classes, layout, left, previous, right, wasFullWidth;
    previous = this.props.router.previous;
    layout = this.props.router.current;
    left = layout.leftPanel;
    right = layout.rightPanel;
    if (isFullWidth) {
      classes = {
        leftPanel: 'panel col-xs-12 col-md-12'
      };
      if ((previous != null) && left.action === 'mailbox.config') {
        classes.leftPanel += ' moveFromTopRightCorner';
      } else if ((previous != null) && previous.rightPanel) {
        if (previous.rightPanel.action === layout.leftPanel.action && _.difference(previous.rightPanel.parameters, layout.leftPanel.parameters).length === 0) {
          classes.leftPanel += ' expandFromRight';
        }
      } else if (previous != null) {
        classes.leftPanel += ' moveFromLeft';
      }
    } else {
      classes = {
        leftPanel: 'panel col-xs-12 col-md-6 hidden-xs hidden-sm',
        rightPanel: 'panel col-xs-12 col-md-6'
      };
      if (previous != null) {
        wasFullWidth = previous.rightPanel == null;
        if (wasFullWidth && !isFullWidth) {
          if (previous.leftPanel.action === right.action && _.difference(previous.leftPanel.parameters, right.parameters).length === 0) {
            classes.leftPanel += ' moveFromLeft';
            classes.rightPanel += ' slide-in-from-left';
          } else {
            classes.rightPanel += ' slide-in-from-right';
          }
        } else if (!isFullWidth) {
          classes.rightPanel += ' slide-in-from-left';
        }
      }
    }
    return classes;
  },
  getPanelComponent: function(panelInfo, layout) {
    var direction, email, emailStore, error, firstMailbox, flux, initialMailboxConfig, isWaiting, mailboxID, openEmail, otherPanelInfo, selectedMailbox, thread;
    flux = this.getFlux();
    if (panelInfo.action === 'mailbox.emails') {
      firstMailbox = flux.store('MailboxStore').getDefault();
      openEmail = null;
      direction = layout === 'left' ? 'rightPanel' : 'leftPanel';
      otherPanelInfo = this.props.router.current[direction];
      if ((otherPanelInfo != null ? otherPanelInfo.action : void 0) === 'email') {
        openEmail = flux.store('EmailStore').getByID(otherPanelInfo.parameters[0]);
      }
      if ((panelInfo.parameters != null) && panelInfo.parameters.length > 0) {
        emailStore = flux.store('EmailStore');
        mailboxID = panelInfo.parameters[0];
        return EmailList({
          emails: emailStore.getEmailsByMailbox(mailboxID),
          mailboxID: mailboxID,
          layout: layout,
          openEmail: openEmail
        });
      } else if (((panelInfo.parameters == null) || panelInfo.parameters.length === 0) && (firstMailbox != null)) {
        emailStore = flux.store('EmailStore');
        mailboxID = firstMailbox.id;
        return EmailList({
          emails: emailStore.getEmailsByMailbox(mailboxID),
          mailboxID: mailboxID,
          layout: layout,
          openEmail: openEmail
        });
      } else {
        return div(null, 'Handle no mailbox or mailbox not found case');
      }
    } else if (panelInfo.action === 'mailbox.config') {
      initialMailboxConfig = this.state.selectedMailbox;
      error = flux.store('MailboxStore').getError();
      isWaiting = flux.store('MailboxStore').isWaiting();
      return MailboxConfig({
        layout: layout,
        error: error,
        isWaiting: isWaiting,
        initialMailboxConfig: initialMailboxConfig
      });
    } else if (panelInfo.action === 'mailbox.new') {
      error = flux.store('MailboxStore').getError();
      isWaiting = flux.store('MailboxStore').isWaiting();
      return MailboxConfig({
        layout: layout,
        error: error,
        isWaiting: isWaiting
      });
    } else if (panelInfo.action === 'email') {
      email = flux.store('EmailStore').getByID(panelInfo.parameters[0]);
      thread = flux.store('EmailStore').getEmailsByThread(panelInfo.parameters[0]);
      selectedMailbox = flux.store('MailboxStore').getSelectedMailbox();
      return EmailThread({
        email: email,
        thread: thread,
        selectedMailbox: selectedMailbox,
        layout: layout
      });
    } else if (panelInfo.action === 'compose') {
      selectedMailbox = flux.store('MailboxStore').getSelectedMailbox();
      return Compose({
        selectedMailbox: selectedMailbox,
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
      selectedMailbox: flux.store('MailboxStore').getSelectedMailbox(),
      emails: flux.store('EmailStore').getAll(),
      isResponsiveMenuShown: flux.store('LayoutStore').isMenuShown()
    };
  },
  componentWillMount: function() {
    this.onRoute = (function(_this) {
      return function(params) {
        var leftPanelInfo, rightPanelInfo;
        leftPanelInfo = params.leftPanelInfo, rightPanelInfo = params.rightPanelInfo;
        return _this.forceUpdate();
      };
    })(this);
    return this.props.router.on('fluxRoute', this.onRoute);
  },
  componentWillUnmount: function() {
    return this.props.router.off('fluxRoute', this.onRoute);
  },
  onResponsiveMenuClick: function(event) {
    event.preventDefault();
    if (this.state.isResponsiveMenuShown) {
      return this.getFlux().actions.layout.hideReponsiveMenu();
    } else {
      return this.getFlux().actions.layout.showReponsiveMenu();
    }
  }
});
});

;require.register("components/compose", function(exports, require, module) {
var Compose, React, RouterMixin, a, classer, div, h3, i, textarea, _ref;

React = require('react/addons');

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, a = _ref.a, i = _ref.i, textarea = _ref.textarea;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router');

module.exports = Compose = React.createClass({
  displayName: 'Compose',
  mixins: [RouterMixin],
  render: function() {
    var closeUrl, collapseUrl, expandUrl;
    expandUrl = this.buildUrl({
      direction: 'left',
      action: 'compose',
      fullWidth: true
    });
    collapseUrl = this.buildUrl({
      leftPanel: {
        action: 'mailbox.emails',
        parameters: this.props.selectedMailbox.id
      },
      rightPanel: {
        action: 'compose'
      }
    });
    closeUrl = this.buildClosePanelUrl(this.props.layout);
    return div({
      id: 'email-compose'
    }, h3(null, a({
      href: closeUrl,
      className: 'close-email hidden-xs hidden-sm'
    }, i({
      className: 'fa fa-times'
    })), 'Compose new email', this.props.layout !== 'full' ? a({
      href: expandUrl,
      className: 'expand hidden-xs hidden-sm'
    }, i({
      className: 'fa fa-arrows-h'
    })) : a({
      href: collapseUrl,
      className: 'close-email pull-right'
    }, i({
      className: 'fa fa-compress'
    }))), textarea({
      defaultValue: 'Hello, how are you doing today?'
    }));
  }
});
});

;require.register("components/email-list", function(exports, require, module) {
var EmailList, FluxChildMixin, Fluxxor, Immutable, React, RouterMixin, a, classer, div, i, li, moment, p, span, ul, _ref;

Fluxxor = require('fluxxor');

React = require('react/addons');

Immutable = require('immutable');

moment = require('moment');

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, p = _ref.p;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router');

FluxChildMixin = Fluxxor.FluxChildMixin(React);

module.exports = EmailList = React.createClass({
  displayName: 'EmailList',
  mixins: [RouterMixin, FluxChildMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !Immutable.is(nextProps.emails, this.props.emails) || !Immutable.is(nextProps.openEmail, this.props.openEmail);
  },
  render: function() {
    return div({
      id: 'email-list'
    }, ul({
      className: 'list-unstyled'
    }, this.props.emails.map((function(_this) {
      return function(email, key) {
        var isActive;
        if (email.inReplyTo.length === 0) {
          isActive = (_this.props.openEmail != null) && _this.props.openEmail.id === email.id;
          return _this.getEmailRender(email, key, isActive);
        }
      };
    })(this)).toJS()));
  },
  getEmailRender: function(email, key, isActive) {
    var classes, date, formatter, today, url;
    classes = classer({
      read: email.isRead,
      active: isActive
    });
    url = this.buildUrl({
      direction: 'right',
      action: 'email',
      parameters: email.id
    });
    today = moment();
    date = moment(email.createdAt);
    if (date.isBefore(today, 'year')) {
      formatter = 'DD/MM/YYYY';
    } else if (date.isBefore(today, 'day')) {
      formatter = 'DD MMMM';
    } else {
      formatter = 'hh:mm';
    }
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
    }, email.subject), p(null, email.text)), span({
      className: 'email-hour'
    }, date.format(formatter))));
  },
  getParticipants: function(email) {
    return email.from + ', ' + email.to;
  }
});
});

;require.register("components/email-thread", function(exports, require, module) {
var Email, EmailThread, FluxChildMixin, Fluxxor, React, RouterMixin, a, classer, div, h3, i, li, p, span, ul, _ref;

Fluxxor = require('fluxxor');

React = require('react/addons');

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a;

Email = require('./email');

classer = React.addons.classSet;

RouterMixin = require('../mixins/router');

FluxChildMixin = Fluxxor.FluxChildMixin(React);

module.exports = EmailThread = React.createClass({
  displayName: 'EmailThread',
  mixins: [RouterMixin, FluxChildMixin],
  render: function() {
    var closeIcon, closeUrl, collapseUrl, email, expandUrl, isLast, key, selectedMailboxID;
    if ((this.props.email == null) || !this.props.thread) {
      return p(null, 'Loading...');
    }
    expandUrl = this.buildUrl({
      direction: 'left',
      action: 'email',
      parameters: this.props.email.id,
      fullWidth: true
    });
    if (window.router.previous != null) {
      selectedMailboxID = this.props.selectedMailbox.id;
    } else {
      selectedMailboxID = this.props.thread[0].mailbox;
    }
    collapseUrl = this.buildUrl({
      leftPanel: {
        action: 'mailbox.emails',
        parameters: selectedMailboxID
      },
      rightPanel: {
        action: 'email',
        parameters: this.props.thread[0].id
      }
    });
    if (this.props.layout === 'full') {
      closeUrl = this.buildUrl({
        direction: 'left',
        action: 'mailbox.emails',
        parameters: this.props.selectedMailbox.id,
        fullWidth: true
      });
    } else {
      closeUrl = this.buildClosePanelUrl(this.props.layout);
    }
    closeIcon = this.props.layout === 'full' ? 'fa-th-list' : 'fa-times';
    return div({
      id: 'email-thread'
    }, h3(null, a({
      href: closeUrl,
      className: 'close-email hidden-xs hidden-sm'
    }, i({
      className: 'fa ' + closeIcon
    })), this.props.email.subject, this.props.layout !== 'full' ? a({
      href: expandUrl,
      className: 'expand hidden-xs hidden-sm'
    }, i({
      className: 'fa fa-arrows-h'
    })) : a({
      href: collapseUrl,
      className: 'close-email pull-right'
    }, i({
      className: 'fa fa-compress'
    }))), ul({
      className: 'email-thread list-unstyled'
    }, (function() {
      var _i, _len, _ref1, _results;
      _ref1 = this.props.thread;
      _results = [];
      for (key = _i = 0, _len = _ref1.length; _i < _len; key = ++_i) {
        email = _ref1[key];
        isLast = key === this.props.thread.length - 1;
        _results.push(Email({
          email: email,
          key: key,
          isLast: isLast
        }));
      }
      return _results;
    }).call(this)));
  }
});
});

;require.register("components/email", function(exports, require, module) {
var EmailThread, React, a, classer, div, h3, i, li, moment, p, span, ul, _ref;

React = require('react/addons');

moment = require('moment');

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a;

classer = React.addons.classSet;

module.exports = EmailThread = React.createClass({
  displayName: 'Email',
  getInitialState: function() {
    return {
      active: false
    };
  },
  render: function() {
    var classes, clickHandler, date, formatter, today;
    clickHandler = this.props.isLast ? null : this.onClick;
    classes = classer({
      email: true,
      active: this.state.active
    });
    today = moment();
    date = moment(this.props.email.createdAt);
    if (date.isBefore(today, 'year')) {
      formatter = 'DD/MM/YYYY';
    } else if (date.isBefore(today, 'day')) {
      formatter = 'DD MMMM';
    } else {
      formatter = 'hh:mm';
    }
    return li({
      className: classes,
      key: this.props.key,
      onClick: clickHandler
    }, div({
      className: 'email-header'
    }, i({
      className: 'fa fa-user'
    }), div({
      className: 'email-participants'
    }, span({
      className: 'sender'
    }, this.props.email.from), span({
      className: 'receivers'
    }, 'À ' + this.props.email.to)), span({
      className: 'email-hour'
    }, date.format(formatter))), div({
      className: 'email-preview'
    }, p(null, this.props.email.text)), div({
      className: 'email-content'
    }, this.props.email.text), div({
      className: 'clearfix'
    }));
  },
  onClick: function(args) {
    return this.setState({
      active: !this.state.active
    });
  }
});
});

;require.register("components/imap-folder-list", function(exports, require, module) {
var ImapFolderList, React, RouterMixin, a, button, div, li, span, ul, _ref;

React = require('react/addons');

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, a = _ref.a, button = _ref.button;

RouterMixin = require('../mixins/router');

module.exports = ImapFolderList = React.createClass({
  displayName: 'ImapFolderList',
  mixins: [RouterMixin],
  render: function() {
    var folder, folders, key;
    folders = ['Favorite', 'Spam', 'Trash', 'Draft'];
    return div({
      className: 'dropdown pull-left'
    }, button({
      className: 'btn btn-default dropdown-toggle',
      type: 'button',
      'data-toggle': 'dropdown'
    }, 'Boite de réception', span({
      className: 'caret'
    }, '')), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, (function() {
      var _i, _len, _results;
      _results = [];
      for (key = _i = 0, _len = folders.length; _i < _len; key = ++_i) {
        folder = folders[key];
        _results.push(this.getImapFolderRender(folder, key));
      }
      return _results;
    }).call(this)));
  },
  getImapFolderRender: function(folder, key) {
    var url;
    url = this.buildUrl({
      direction: 'left',
      action: 'mailbox.imap.emails',
      parameters: [this.props.selectedMailbox.id, folder.toLowerCase()]
    });
    return li({
      role: 'presentation',
      key: key
    }, a({
      href: url,
      role: 'menuitem'
    }, folder));
  }
});
});

;require.register("components/mailbox-config", function(exports, require, module) {
var FluxChildMixin, Fluxxor, React, button, classer, div, form, h3, input, label, _ref;

React = require('react/addons');

Fluxxor = require('fluxxor');

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button;

classer = React.addons.classSet;

FluxChildMixin = Fluxxor.FluxChildMixin(React);

module.exports = React.createClass({
  displayName: 'MailboxConfig',
  mixins: [FluxChildMixin, React.addons.LinkedStateMixin],
  render: function() {
    var buttonLabel, titleLabel;
    titleLabel = this.props.initialMailboxConfig != null ? 'Edit mailbox' : 'New mailbox';
    if (this.props.isWaiting) {
      buttonLabel = 'Saving...';
    } else if (this.props.initialMailboxConfig != null) {
      buttonLabel = 'Edit';
    } else {
      buttonLabel = 'Add';
    }
    return div({
      id: 'mailbox-config'
    }, h3({
      className: null
    }, titleLabel), this.props.error ? div({
      className: 'error'
    }, this.props.error) : void 0, form({
      className: 'form-horizontal'
    }, div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-label',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, 'Label'), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-label',
      valueLink: this.linkState('label'),
      type: 'text',
      className: 'form-control',
      placeholder: 'A short mailbox name'
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-name',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, 'Your name'), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-name',
      valueLink: this.linkState('name'),
      type: 'text',
      className: 'form-control',
      placeholder: 'Your name, as it will be displayed'
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-email-address',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, 'Email address'), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-email-address',
      valueLink: this.linkState('email'),
      type: 'email',
      className: 'form-control',
      placeholder: 'Your email address'
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-password',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, 'Password'), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-password',
      valueLink: this.linkState('password'),
      type: 'password',
      className: 'form-control'
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-smtp-server',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, 'Sending server'), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-smtp-server',
      valueLink: this.linkState('smtpServer'),
      type: 'text',
      className: 'form-control',
      placeholder: 'smtp.provider.tld'
    })), label({
      htmlFor: 'mailbox-smtp-port',
      className: 'col-sm-1 control-label'
    }, 'Port'), div({
      className: 'col-sm-1'
    }, input({
      id: 'mailbox-smtp-port',
      valueLink: this.linkState('smtpPort'),
      type: 'text',
      className: 'form-control'
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-imap-server',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, 'Receiving server'), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-imap-server',
      valueLink: this.linkState('imapServer'),
      type: 'text',
      className: 'form-control',
      placeholder: 'imap.provider.tld'
    })), label({
      htmlFor: 'mailbox-imap-port',
      className: 'col-sm-1 control-label'
    }, 'Port'), div({
      className: 'col-sm-1'
    }, input({
      id: 'mailbox-imap-port',
      valueLink: this.linkState('imapPort'),
      type: 'text',
      className: 'form-control'
    }))), div({
      className: 'form-group'
    }, div({
      className: 'col-sm-offset-2 col-sm-5 text-right'
    }, this.props.initialMailboxConfig != null ? button({
      className: 'btn btn-cozy',
      onClick: this.onRemove
    }, 'Remove') : void 0, button({
      className: 'btn btn-cozy',
      onClick: this.onSubmit
    }, buttonLabel)))));
  },
  onSubmit: function(event) {
    var mailboxValue;
    event.preventDefault();
    mailboxValue = this.state;
    if (this.props.initialMailboxConfig != null) {
      mailboxValue.id = this.props.initialMailboxConfig.id;
      return this.getFlux().actions.mailbox.edit(this.state);
    } else {
      return this.getFlux().actions.mailbox.create(this.state);
    }
  },
  onRemove: function(event) {
    event.preventDefault();
    return this.getFlux().actions.mailbox.remove(this.props.initialMailboxConfig.id);
  },
  componentWillReceiveProps: function(props) {
    if (!props.isWaiting) {
      if (props.initialMailboxConfig != null) {
        return this.setState(props.initialMailboxConfig);
      } else {
        return this.setState(this.getInitialState(true));
      }
    }
  },
  getInitialState: function(forceDefault) {
    if (this.props.initialMailboxConfig && !forceDefault) {
      return {
        label: this.props.initialMailboxConfig.label,
        name: this.props.initialMailboxConfig.name,
        email: this.props.initialMailboxConfig.email,
        password: this.props.initialMailboxConfig.password,
        smtpServer: this.props.initialMailboxConfig.smtpServer,
        smtpPort: this.props.initialMailboxConfig.smtpPort,
        imapServer: this.props.initialMailboxConfig.imapServer,
        imapPort: this.props.initialMailboxConfig.imapPort
      };
    } else {
      return {
        label: '',
        name: '',
        email: '',
        password: '',
        smtpServer: '',
        smtpPort: 993,
        imapServer: '',
        imapPort: 465
      };
    }
  }
});
});

;require.register("components/menu", function(exports, require, module) {
var Immutable, Menu, React, RouterMixin, a, classer, div, i, li, span, ul, _, _ref;

React = require('react/addons');

Immutable = require('immutable');

_ = require('underscore');

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router');

module.exports = Menu = React.createClass({
  displayName: 'Menu',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !Immutable.is(nextProps.mailboxes, this.props.mailboxes) || !Immutable.is(nextProps.selectedMailbox, this.props.selectedMailbox) || !_.isEqual(nextProps.layout, this.props.layout);
  },
  render: function() {
    var classes, composeUrl, newMailboxUrl, selectedMailboxUrl, _ref1;
    selectedMailboxUrl = this.buildUrl({
      direction: 'left',
      action: 'mailbox.emails',
      parameters: this.props.selectedMailbox.id,
      fullWidth: true
    });
    if (this.props.layout.leftPanel.action === 'compose' || ((_ref1 = this.props.layout.rightPanel) != null ? _ref1.action : void 0) === 'compose') {
      composeUrl = selectedMailboxUrl;
    } else {
      composeUrl = this.buildUrl({
        direction: 'right',
        action: 'compose',
        parameters: null,
        fullWidth: false
      });
    }
    if (this.props.layout.leftPanel.action === 'mailbox.new') {
      newMailboxUrl = selectedMailboxUrl;
    } else {
      newMailboxUrl = this.buildUrl({
        direction: 'left',
        action: 'mailbox.new',
        fullWidth: true
      });
    }
    classes = classer({
      'hidden-xs hidden-sm': !this.props.isResponsiveMenuShown,
      'col-xs-4 col-md-1': true
    });
    return div({
      id: 'menu',
      className: classes
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
    }, this.props.mailboxes.map((function(_this) {
      return function(mailbox, key) {
        return _this.getMailboxRender(mailbox, key);
      };
    })(this)).toJS()), a({
      href: newMailboxUrl,
      className: 'menu-item new-mailbox-action'
    }, i({
      className: 'fa fa-inbox'
    }), span({
      className: 'mailbox-label'
    }, 'New mailbox')));
  },
  getMailboxRender: function(mailbox, key) {
    var isSelected, mailboxClasses, url;
    isSelected = (!this.props.selectedMailbox && key === 0) || this.props.selectedMailbox.id === mailbox.id;
    mailboxClasses = classer({
      active: isSelected
    });
    url = this.buildUrl({
      direction: 'left',
      action: 'mailbox.emails',
      parameters: mailbox.id,
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

;require.register("fluxxor", function(exports, require, module) {

/*
    We store flux instance a separate file to be able to access it from various
    places of the application (i.e. utils)
 */
var EmailStore, Fluxxor, LayoutStore, MailboxStore, actions, flux, stores;

Fluxxor = require('fluxxor');

MailboxStore = require('./stores/mailboxes');

EmailStore = require('./stores/emails');

LayoutStore = require('./stores/layout');

stores = {
  MailboxStore: new MailboxStore(),
  EmailStore: new EmailStore(),
  LayoutStore: new LayoutStore()
};

actions = {
  layout: require('./actions/layout_actions'),
  mailbox: require('./actions/mailbox_actions'),
  email: require('./actions/email_actions')
};

flux = new Fluxxor.Flux(stores, actions);

module.exports = flux;
});

;require.register("initialize", function(exports, require, module) {
var $, Backbone, React;

$ = require('jquery');

Backbone = require('backbone');

Backbone.$ = $;

React = require('react/addons');

$(function() {
  var Application, Router, application, flux;
  flux = require('./fluxxor');
  Router = require('./router');
  this.router = new Router({
    flux: flux
  });
  window.router = this.router;
  Application = require('./components/application');
  application = Application({
    router: this.router,
    flux: flux
  });
  React.renderComponent(application, document.body);
  Backbone.history.start();
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

        Each pattern is actually the pattern itself plus the pattern itself and
        another pattern.
 */
var Backbone, Router, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Backbone = require('backbone');

_ = require('underscore');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.patterns = {
    'mailbox.config': {
      pattern: 'mailbox/:id/config',
      fluxAction: 'showConfigMailbox'
    },
    'mailbox.new': {
      pattern: 'mailbox/new',
      fluxAction: 'showCreateMailbox'
    },
    'mailbox.imap.emails': {
      pattern: 'mailbox/:id/folder/:folder',
      fluxAction: 'showEmailList'
    },
    'mailbox.emails': {
      pattern: 'mailbox/:id',
      fluxAction: 'showEmailList'
    },
    'email': {
      pattern: 'email/:id',
      fluxAction: 'showEmailThread'
    },
    'compose': {
      pattern: 'compose',
      fluxAction: 'showComposeNewEmail'
    }
  };

  Router.prototype.routes = {
    '': 'mailbox.emails'
  };

  Router.prototype.previous = null;

  Router.prototype.current = null;

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
      this.routes[route.pattern] = key;
      this.routes["" + route.pattern + "/*rightPanel"] = key;
    }
    this._bindRoutes();
    this.flux = options.flux;
    this.flux.router = this;
    return this.on('route', (function(_this) {
      return function(name, args) {
        var leftAction, leftPanelInfo, rightAction, rightPanelInfo, _ref1;
        _ref1 = _this._processSubRouting(name, args), leftPanelInfo = _ref1[0], rightPanelInfo = _ref1[1];
        leftAction = _this.fluxActionFactory(leftPanelInfo);
        rightAction = _this.fluxActionFactory(rightPanelInfo);
        _this.previous = _this.current;
        _this.current = {
          leftPanel: leftPanelInfo,
          rightPanel: rightPanelInfo
        };
        if (leftAction != null) {
          leftAction(leftPanelInfo, 'left');
        }
        if (rightAction != null) {
          rightAction(rightPanelInfo, 'right');
        }
        return _this.trigger('fluxRoute', _this.current);
      };
    })(this));
  };


  /*
      Gets the Flux action to execute given a panel info.
   */

  Router.prototype.fluxActionFactory = function(panelInfo) {
    var fluxAction, pattern;
    fluxAction = null;
    pattern = this.patterns[panelInfo != null ? panelInfo.action : void 0];
    if (pattern != null) {
      fluxAction = this.flux.actions.layout[pattern.fluxAction];
      if (fluxAction == null) {
        console.warn("`" + pattern.fluxAction + "` method not found in layout actions.");
      }
      return fluxAction;
    }
  };


  /*
      Extracts and matches the second part of the URl if it exists.
   */

  Router.prototype._processSubRouting = function(name, args) {
    var leftPanelInfo, leftPanelParameters, params, rightPanelInfo, rightPanelString, route;
    args.pop();
    rightPanelString = args.pop();
    params = this.patterns[name].pattern.match(/:[\w]+/g) || [];
    if (params.length > args.length) {
      args.push(rightPanelString);
      rightPanelString = null;
    }
    leftPanelParameters = args;
    route = _.first(_.filter(this.cachedPatterns, function(element) {
      return element.pattern.test(rightPanelString);
    }));
    if (route != null) {
      args = this._extractParameters(route.pattern, rightPanelString);
      args.pop();
      rightPanelInfo = {
        action: route.key,
        parameters: args
      };
    } else {
      rightPanelInfo = null;
    }
    leftPanelInfo = {
      action: name,
      parameters: leftPanelParameters
    };
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
      if ((options.rightPanel != null) && options.direction === 'right') {
        console.warn("You shouldn't use the fullWidth option with a right panel");
      }
      rightPanelInfo = null;
    }
    leftPart = this._getURLFromRoute(leftPanelInfo);
    rightPart = this._getURLFromRoute(rightPanelInfo);
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

  Router.prototype._getURLFromRoute = function(panel) {
    var defaultParameter, defaultParameters, filledPattern, key, paramInPattern, paramValue, parametersInPattern, pattern, _i, _j, _len, _len1;
    if (panel != null) {
      pattern = this.patterns[panel.action].pattern;
      if ((panel.parameters != null) && !(panel.parameters instanceof Array)) {
        panel.parameters = [panel.parameters];
      }
      if ((defaultParameters = this._getDefaultParameters(panel.action)) != null) {
        if ((panel.parameters == null) || panel.parameters.length === 0) {
          panel.parameters = defaultParameters;
        } else {
          for (key = _i = 0, _len = defaultParameters.length; _i < _len; key = ++_i) {
            defaultParameter = defaultParameters[key];
            if (panel.parameters[key] == null) {
              panel.parameters.splice(key, 0, defaultParameter);
            }
          }
        }
      }
      parametersInPattern = pattern.match(/:[\w]+/gi) || [];
      filledPattern = pattern;
      for (key = _j = 0, _len1 = parametersInPattern.length; _j < _len1; key = ++_j) {
        paramInPattern = parametersInPattern[key];
        paramValue = panel.parameters[key];
        filledPattern = filledPattern.replace(paramInPattern, paramValue);
      }
      return filledPattern;
    } else {
      return '';
    }
  };

  Router.prototype._getDefaultParameters = function(action) {
    var defaultImapFolder, defaultMailbox, defaultParameters;
    switch (action) {
      case 'mailbox.emails':
      case 'mailbox.config':
        defaultMailbox = this.flux.store('MailboxStore').getDefault().id;
        defaultParameters = [defaultMailbox];
        break;
      case 'mailbox.imap.emails':
        defaultMailbox = this.flux.store('MailboxStore').getDefault().id;
        defaultImapFolder = 'lala';
        defaultParameters = [defaultMailbox, defaultImapFolder];
        break;
      default:
        defaultParameters = null;
    }
    return defaultParameters;
  };

  return Router;

})(Backbone.Router);
});

;require.register("stores/emails", function(exports, require, module) {
var EmailStore, Fluxxor, Immutable, request;

request = require('superagent');

Fluxxor = require('fluxxor');

Immutable = require('immutable');

module.exports = EmailStore = Fluxxor.createStore({
  actions: {
    'RECEIVE_RAW_EMAILS': '_receiveRawEmails',
    'RECEIVE_RAW_EMAIL': '_receiveRawEmail',
    'REMOVE_MAILBOX': '_removeMailbox'
  },
  initialize: function() {
    var emails, fixtures;
    fixtures = [
      {
        id: "f1a1dc66df94e19a0407c633e6003a832",
        createdAt: "2014-07-11T08:38:23.000Z",
        docType: "email",
        from: "natacha@provider.com",
        hasAttachments: false,
        html: "Hello, how are you ? bis",
        'imap-folder': "orange-ID-folder1",
        inReplyTo: "",
        mailbox: "orange-ID2",
        reads: false,
        references: "",
        subject: "Hey back",
        text: "Hello, how are you ? bis",
        to: "bob@provider.com"
      }, {
        id: "f1a1dc66df94e19a0407c633e6003b272",
        createdAt: "2014-07-11T08:38:23.000Z",
        docType: "email",
        from: "alice@provider.com",
        hasAttachments: false,
        html: "Hello, how are you ? bis",
        'imap-folder': "orange-ID-folder2",
        inReplyTo: "",
        mailbox: "orange-ID2",
        reads: false,
        references: "",
        subject: "Another email",
        text: "Hello, how are you ? bis",
        to: "bob@provider.com"
      }, {
        id: "f1a1dc66df94e19a0407c633e600112a2",
        createdAt: "2014-07-11T08:38:23.000Z",
        docType: "email",
        from: "alice@provider.com",
        hasAttachments: false,
        html: "Hello, how are you ?",
        'imap-folder': "gmail-ID-folder1",
        inReplyTo: "",
        mailbox: "gmail-ID2",
        reads: false,
        references: "",
        subject: "Hello Cozy Email manager!",
        text: "Hello, how are you ?",
        to: "bob@provider.com"
      }, {
        id: "email-ID-12",
        createdAt: "2014-07-11T08:38:23.000Z",
        docType: "email",
        from: "alice@provider.com",
        hasAttachments: false,
        html: "Hello, how are you ? bis",
        'imap-folder': "gmail-ID-folder1",
        inReplyTo: "",
        mailbox: "gmail-ID2",
        reads: false,
        references: "",
        subject: "First email of thread",
        text: "Hello, how are you ? bis",
        to: "bob@provider.com"
      }, {
        id: "f1a1dc66df94e19a0407c633e60037e52",
        createdAt: "2014-07-11T08:38:23.000Z",
        docType: "email",
        from: "bob@provider.com",
        hasAttachments: false,
        html: "Hello, how are you ? bis",
        'imap-folder': "gmail-ID-folder1",
        inReplyTo: "email-ID-12",
        mailbox: "gmail-ID2",
        reads: false,
        references: "",
        subject: "Email in reply to",
        text: "Hello, how are you ? bis",
        to: "alice@provider.com"
      }
    ];
    emails = [];
    if ((window.mailboxes == null) || window.mailboxes.length === 0) {
      emails = fixtures;
    }
    return this.emails = Immutable.Sequence(emails).mapKeys(function(_, email) {
      return email.id;
    }).map(function(email) {
      return Immutable.Map(email);
    }).toOrderedMap();
  },
  getAll: function() {
    return this.emails;
  },
  getByID: function(emailID) {
    return this.emails.get(emailID) || null;
  },
  getEmailsByMailbox: function(mailboxID) {
    return this.emails.filter(function(email) {
      return email.mailbox === mailboxID;
    }).toOrderedMap();
  },
  getEmailsByThread: function(emailID) {
    var idToLook, idsToLook, temp, thread;
    idsToLook = [emailID];
    thread = [];
    while (idToLook = idsToLook.pop()) {
      thread.push(this.getByID(idToLook));
      temp = this.emails.filter(function(email) {
        return email.inReplyTo === idToLook;
      });
      idsToLook = idsToLook.concat(temp.map(function(item) {
        return item.id;
      }).toArray());
    }
    return thread;
  },
  _receiveRawEmails: function(emails) {
    var email, _i, _len;
    for (_i = 0, _len = emails.length; _i < _len; _i++) {
      email = emails[_i];
      this._receiveRawEmail(email, true);
    }
    return this.emit('change');
  },
  _receiveRawEmail: function(email, silent) {
    if (silent == null) {
      silent = false;
    }
    this.emails = this.emails.set(email.id, email);
    if (silent !== true) {
      return this.emit('change');
    }
  },
  _removeMailbox: function(mailboxID) {
    var emails;
    emails = this.getEmailsByMailbox(mailboxID);
    this.emails = this.emails.withMutations(function(map) {
      return emails.forEach(function(email) {
        return map.remove(email.id);
      });
    });
    return this.emit('change');
  }
});
});

;require.register("stores/layout", function(exports, require, module) {
var Fluxxor, LayoutStore;

Fluxxor = require('fluxxor');

module.exports = LayoutStore = Fluxxor.createStore({
  actions: {
    'SHOW_MENU_RESPONSIVE': '_shownResponsiveMenu',
    'HIDE_MENU_RESPONSIVE': '_hideResponsiveMenu'
  },
  initialize: function() {
    return this.responsiveMenuShown = false;
  },
  _shownResponsiveMenu: function() {
    this.responsiveMenuShown = true;
    return this.emit('change');
  },
  _hideResponsiveMenu: function() {
    this.responsiveMenuShown = false;
    return this.emit('change');
  },
  isMenuShown: function() {
    return this.responsiveMenuShown;
  }
});
});

;require.register("stores/mailboxes", function(exports, require, module) {
var Fluxxor, Immutable, MailboxStore, request;

request = require('superagent');

Fluxxor = require('fluxxor');

Immutable = require('immutable');

module.exports = MailboxStore = Fluxxor.createStore({
  actions: {
    'ADD_MAILBOX': 'onCreate',
    'REMOVE_MAILBOX': 'onRemove',
    'EDIT_MAILBOX': 'onEdit',
    'SELECT_MAILBOX': 'onSelectMailbox',
    'NEW_MAILBOX_WAITING': 'onNewMailboxWaiting',
    'NEW_MAILBOX_ERROR': 'onNewMailboxError'
  },
  initialize: function() {
    var fixtures, mailboxes;
    fixtures = [
      {
        id: "gmail-ID2",
        email: "randomlogin@randomprovider.tld",
        imapPort: 465,
        imapServer: "imap.gmail.com",
        label: "Gmail",
        name: "Random Name",
        password: "randompassword",
        smtpPort: 993,
        smtpServer: "smtp.gmail.com"
      }, {
        id: "orange-ID2",
        email: "randomlogin@randomprovider.tld",
        imapPort: 465,
        imapServer: "imap.orange.fr",
        label: "Orange",
        name: "Random Name",
        password: "randompassword",
        smtpPort: 993,
        smtpServer: "smtp.orange.fr"
      }
    ];
    mailboxes = window.mailboxes || fixtures;
    if (mailboxes.length === 0) {
      mailboxes = fixtures;
    }
    this.mailboxes = Immutable.Sequence(mailboxes).mapKeys(function(_, mailbox) {
      return mailbox.id;
    }).map(function(mailbox) {
      return Immutable.Map(mailbox);
    }).toOrderedMap();
    this.selectedMailbox = null;
    this.newMailboxWaiting = false;
    return this.newMailboxError = null;
  },
  onCreate: function(mailbox) {
    this.mailboxes = this.mailboxes.set(mailbox.id, mailbox);
    return this.emit('change');
  },
  onSelectMailbox: function(mailboxID) {
    this.selectedMailbox = this.mailboxes.get(mailboxID) || null;
    return this.emit('change');
  },
  onNewMailboxWaiting: function(payload) {
    this.newMailboxWaiting = payload;
    return this.emit('change');
  },
  onNewMailboxError: function(error) {
    this.newMailboxError = error;
    return this.emit('change');
  },
  onEdit: function(mailbox) {
    this.mailboxes = this.mailboxes.set(mailbox.id, mailbox);
    this.selectedMailbox = this.mailboxes.get(mailbox.id);
    return this.emit('change');
  },
  onRemove: function(mailboxID) {
    this.mailboxes = this.mailboxes["delete"](mailboxID);
    this.selectedMailbox = this.getDefault();
    return this.emit('change');
  },
  getAll: function() {
    this.mailboxes = this.mailboxes.sortBy(function(mailbox) {
      return mailbox.label;
    }).toOrderedMap();
    return this.mailboxes;
  },
  getDefault: function() {
    return this.mailboxes.first() || null;
  },
  getSelectedMailbox: function() {
    return this.selectedMailbox || this.getDefault();
  },
  getError: function() {
    return this.newMailboxError;
  },
  isWaiting: function() {
    return this.newMailboxWaiting;
  }
});
});

;require.register("utils/XHRUtils", function(exports, require, module) {
var request;

request = require('superagent');

module.exports = {
  fetchEmailsByMailbox: function(mailboxID) {
    var flux;
    flux = require('../fluxxor');
    return request.get("mailbox/" + mailboxID + "/emails").set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return flux.actions.email.receiveRawEmails(res.body);
      } else {
        return console.log("Something went wrong -- " + res.body);
      }
    });
  },
  fetchEmailThread: function(emailID) {
    var flux;
    flux = require('../fluxxor');
    return request.get("email/" + emailID).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return flux.actions.email.receiveRawEmail(res.body);
      } else {
        return console.log("Something went wrong -- " + res.body);
      }
    });
  },
  createMailbox: function(mailbox, callback) {
    return request.post('mailbox').send(mailbox).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback(res.body, null);
      }
    });
  },
  editMailbox: function(mailbox, callback) {
    return request.put("mailbox/" + mailbox.id).send(mailbox).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback(res.body, null);
      }
    });
  },
  removeMailbox: function(mailboxID) {
    return request.del("mailbox/" + mailboxID).set('Accept', 'application/json').end(function(res) {});
  }
};
});

;
//# sourceMappingURL=app.js.map