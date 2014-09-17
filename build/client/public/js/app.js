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
require.register("AppDispatcher", function(exports, require, module) {
var AppDispatcher, Dispatcher, PayloadSources,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Dispatcher = require('./libs/flux/dispatcher/Dispatcher');

PayloadSources = require('./constants/AppConstants').PayloadSources;


/*
    Custom dispatcher class to add semantic method.
 */

AppDispatcher = (function(_super) {
  __extends(AppDispatcher, _super);

  function AppDispatcher() {
    return AppDispatcher.__super__.constructor.apply(this, arguments);
  }

  AppDispatcher.prototype.handleViewAction = function(action) {
    var payload;
    payload = {
      source: PayloadSources.VIEW_ACTION,
      action: action
    };
    return this.dispatch(payload);
  };

  AppDispatcher.prototype.handleServerAction = function(action) {
    var payload;
    payload = {
      source: PayloadSources.SERVER_ACTION,
      action: action
    };
    return this.dispatch(payload);
  };

  return AppDispatcher;

})(Dispatcher);

module.exports = new AppDispatcher();
});

;require.register("actions/AccountActionCreator", function(exports, require, module) {
var AccountActionCreator, AccountStore, ActionTypes, AppDispatcher, XHRUtils;

XHRUtils = require('../utils/XHRUtils');

AppDispatcher = require('../AppDispatcher');

ActionTypes = require('../constants/AppConstants').ActionTypes;

AccountStore = require('../stores/AccountStore');

module.exports = AccountActionCreator = {
  create: function(inputValues) {
    AccountActionCreator._setNewAccountWaitingStatus(true);
    return XHRUtils.createAccount(inputValues, function(error, account) {
      return setTimeout(function() {
        AccountActionCreator._setNewAccountWaitingStatus(false);
        if (error != null) {
          return AccountActionCreator._setNewAccountError(error);
        } else {
          return AppDispatcher.handleViewAction({
            type: ActionTypes.ADD_ACCOUNT,
            value: account
          });
        }
      }, 2000);
    });
  },
  edit: function(inputValues, accountID) {
    var account, newAccount;
    AccountActionCreator._setNewAccountWaitingStatus(true);
    account = AccountStore.getByID(accountID);
    newAccount = account.mergeDeep(inputValues);
    return XHRUtils.editAccount(newAccount, function(error, rawAccount) {
      return setTimeout(function() {
        AccountActionCreator._setNewAccountWaitingStatus(false);
        if (error != null) {
          return AccountActionCreator._setNewAccountError(error);
        } else {
          return AppDispatcher.handleViewAction({
            type: ActionTypes.EDIT_ACCOUNT,
            value: rawAccount
          });
        }
      }, 2000);
    });
  },
  remove: function(accountID) {
    AppDispatcher.handleViewAction({
      type: ActionTypes.REMOVE_ACCOUNT,
      value: accountID
    });
    XHRUtils.removeAccount(accountID);
    return window.router.navigate('', true);
  },
  _setNewAccountWaitingStatus: function(status) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.NEW_ACCOUNT_WAITING,
      value: status
    });
  },
  _setNewAccountError: function(errorMessage) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.NEW_ACCOUNT_ERROR,
      value: errorMessage
    });
  },
  selectAccount: function(accountID) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SELECT_ACCOUNT,
      value: accountID
    });
  }
};
});

;require.register("actions/LayoutActionCreator", function(exports, require, module) {
var AccountActionCreator, AccountStore, ActionTypes, AlertLevel, AppDispatcher, LayoutActionCreator, LayoutStore, MessageActionCreator, SearchActionCreator, XHRUtils, _ref;

XHRUtils = require('../utils/XHRUtils');

AccountStore = require('../stores/AccountStore');

LayoutStore = require('../stores/LayoutStore');

AppDispatcher = require('../AppDispatcher');

_ref = require('../constants/AppConstants'), ActionTypes = _ref.ActionTypes, AlertLevel = _ref.AlertLevel;

AccountActionCreator = require('./AccountActionCreator');

MessageActionCreator = require('./MessageActionCreator');

SearchActionCreator = require('./SearchActionCreator');

module.exports = LayoutActionCreator = {
  showReponsiveMenu: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SHOW_MENU_RESPONSIVE,
      value: null
    });
  },
  hideReponsiveMenu: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.HIDE_MENU_RESPONSIVE,
      value: null
    });
  },
  alert: function(level, message) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.DISPLAY_ALERT,
      value: {
        level: level,
        message: message
      }
    });
  },
  alertSuccess: function(message) {
    return LayoutActionCreator.alert(AlertLevel.SUCCESS, message);
  },
  alertInfo: function(message) {
    return LayoutActionCreator.alert(AlertLevel.INFO, message);
  },
  alertWarning: function(message) {
    return LayoutActionCreator.alert(AlertLevel.WARNING, message);
  },
  alertError: function(message) {
    return LayoutActionCreator.alert(AlertLevel.ERROR, message);
  },
  showMessageList: function(panelInfo, direction) {
    var accountID, mailboxID, numPage;
    LayoutActionCreator.hideReponsiveMenu();
    accountID = panelInfo.parameters[0];
    mailboxID = panelInfo.parameters[1];
    numPage = panelInfo.parameters[2];
    AccountActionCreator.selectAccount(accountID);
    return XHRUtils.fetchMessagesByFolder(mailboxID, numPage, function(err, rawMessage) {
      if (err != null) {
        return LayoutActionCreator.alertError(err);
      } else {
        return MessageActionCreator.receiveRawMessages(rawMessage);
      }
    });
  },
  showConversation: function(panelInfo, direction) {
    LayoutActionCreator.hideReponsiveMenu();
    return XHRUtils.fetchConversation(panelInfo.parameters[0], function(err, rawMessage) {
      var selectedAccount;
      if (err != null) {
        return LayoutActionCreator.alertError(err);
      } else {
        MessageActionCreator.receiveRawMessage(rawMessage);
        selectedAccount = AccountStore.getSelected();
        if ((selectedAccount == null) && (rawMessage != null ? rawMessage.mailbox : void 0)) {
          return AccountActionCreator.selectAccount(rawMessage.mailbox);
        }
      }
    });
  },
  showComposeNewMessage: function(panelInfo, direction) {
    var defaultAccount, selectedAccount;
    LayoutActionCreator.hideReponsiveMenu();
    selectedAccount = AccountStore.getSelected();
    if (selectedAccount == null) {
      defaultAccount = AccountStore.getDefault();
      return AccountActionCreator.selectAccount(defaultAccount.get('id'));
    }
  },
  showCreateAccount: function(panelInfo, direction) {
    LayoutActionCreator.hideReponsiveMenu();
    return AccountActionCreator.selectAccount(-1);
  },
  showConfigAccount: function(panelInfo, direction) {
    LayoutActionCreator.hideReponsiveMenu();
    return AccountActionCreator.selectAccount(panelInfo.parameters[0]);
  },
  showSearch: function(panelInfo, direction) {
    var page, query, _ref1;
    AccountActionCreator.selectAccount(-1);
    _ref1 = panelInfo.parameters, query = _ref1[0], page = _ref1[1];
    SearchActionCreator.setQuery(query);
    return XHRUtils.search(query, page, function(err, results) {
      if (err != null) {
        return console.log(err);
      } else {
        return SearchActionCreator.receiveRawSearchResults(results);
      }
    });
  },
  showSettings: function(panelInfo, direction) {
    return LayoutActionCreator.hideReponsiveMenu();
  }
};
});

;require.register("actions/MessageActionCreator", function(exports, require, module) {
var ActionTypes, AppDispatcher, XHRUtils;

AppDispatcher = require('../AppDispatcher');

ActionTypes = require('../constants/AppConstants').ActionTypes;

XHRUtils = require('../utils/XHRUtils');

module.exports = {
  receiveRawMessages: function(messages) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RECEIVE_RAW_MESSAGES,
      value: messages
    });
  },
  receiveRawMessage: function(message) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RECEIVE_RAW_MESSAGE,
      value: message
    });
  },
  send: function(message, callback) {
    return XHRUtils.messageSend(message, function(error, message) {
      if (!(error != null)) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.SEND_MESSAGE,
          value: message
        });
      }
      return callback(error);
    });
  }
};
});

;require.register("actions/SearchActionCreator", function(exports, require, module) {
var ActionTypes, AppDispatcher, SearchActionCreator;

AppDispatcher = require('../AppDispatcher');

ActionTypes = require('../constants/AppConstants').ActionTypes;

module.exports = SearchActionCreator = {
  setQuery: function(query) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SET_SEARCH_QUERY,
      value: query
    });
  },
  receiveRawSearchResults: function(results) {
    SearchActionCreator.clearSearch(false);
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RECEIVE_RAW_SEARCH_RESULTS,
      value: results
    });
  },
  clearSearch: function(clearQuery) {
    if (clearQuery == null) {
      clearQuery = true;
    }
    if (clearQuery) {
      SearchActionCreator.setQuery("");
    }
    return AppDispatcher.handleViewAction({
      type: ActionTypes.CLEAR_SEARCH_RESULTS,
      value: null
    });
  }
};
});

;require.register("actions/SettingsActionCreator", function(exports, require, module) {
var ActionTypes, AppDispatcher, SettingsActionCreator, SettingsStore, XHRUtils;

XHRUtils = require('../utils/XHRUtils');

AppDispatcher = require('../AppDispatcher');

ActionTypes = require('../constants/AppConstants').ActionTypes;

SettingsStore = require('../stores/SettingsStore');

module.exports = SettingsActionCreator = {
  edit: function(inputValues) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SETTINGS_UPDATED,
      value: inputValues
    });
  }
};
});

;require.register("components/account-config", function(exports, require, module) {
var AccountActionCreator, button, classer, div, form, h3, input, label, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button;

classer = React.addons.classSet;

AccountActionCreator = require('../actions/AccountActionCreator');

module.exports = React.createClass({
  displayName: 'AccountConfig',
  mixins: [React.addons.LinkedStateMixin],
  render: function() {
    var buttonLabel, titleLabel;
    titleLabel = this.props.initialAccountConfig != null ? t("mailbox edit") : t("mailbox new");
    if (this.props.isWaiting) {
      buttonLabel = 'Saving...';
    } else if (this.props.initialAccountConfig != null) {
      buttonLabel = 'Edit';
    } else {
      buttonLabel = t("mailbox add");
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
    }, t("mailbox label")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-label',
      valueLink: this.linkState('label'),
      type: 'text',
      className: 'form-control',
      placeholder: t("mailbox name short")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-name',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("mailbox user name")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-name',
      valueLink: this.linkState('name'),
      type: 'text',
      className: 'form-control',
      placeholder: t("mailbox user fullname")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-email-address',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("mailbox address")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-email-address',
      valueLink: this.linkState('login'),
      type: 'email',
      className: 'form-control',
      placeholder: t("mailbox address placeholder")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-password',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('mailbox password')), div({
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
    }, t("mailbox sending server")), div({
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
    }, t("mailbox receiving server")), div({
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
    }, this.props.initialAccountConfig != null ? button({
      className: 'btn btn-cozy',
      onClick: this.onRemove
    }, t("mailbox remove")) : void 0, button({
      className: 'btn btn-cozy',
      onClick: this.onSubmit
    }, buttonLabel)))));
  },
  onSubmit: function(event) {
    var accountValue;
    event.preventDefault();
    accountValue = this.state;
    if (this.props.initialAccountConfig != null) {
      return AccountActionCreator.edit(accountValue, this.props.initialAccountConfig.get('id'));
    } else {
      return AccountActionCreator.create(accountValue);
    }
  },
  onRemove: function(event) {
    event.preventDefault();
    return AccountActionCreator.remove(this.props.initialAccountConfig.get('id'));
  },
  componentWillReceiveProps: function(props) {
    if (!props.isWaiting) {
      if (props.initialAccountConfig != null) {
        return this.setState(props.initialAccountConfig.toJS());
      } else {
        return this.setState(this.getInitialState(true));
      }
    }
  },
  getInitialState: function(forceDefault) {
    if ((this.props.initialAccountConfig != null) && !forceDefault) {
      return {
        label: this.props.initialAccountConfig.get('label'),
        name: this.props.initialAccountConfig.get('name'),
        login: this.props.initialAccountConfig.get('login'),
        password: this.props.initialAccountConfig.get('password'),
        smtpServer: this.props.initialAccountConfig.get('smtpServer'),
        smtpPort: this.props.initialAccountConfig.get('smtpPort'),
        imapServer: this.props.initialAccountConfig.get('imapServer'),
        imapPort: this.props.initialAccountConfig.get('imapPort')
      };
    } else {
      return {
        label: '',
        name: '',
        login: '',
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

;require.register("components/alert", function(exports, require, module) {
var AlertLevel, button, div, span, strong, _ref;

_ref = React.DOM, div = _ref.div, button = _ref.button, span = _ref.span, strong = _ref.strong;

AlertLevel = require('../constants/AppConstants').AlertLevel;

module.exports = React.createClass({
  displayName: 'Alert',
  render: function() {
    var alert, levels;
    alert = this.props.alert;
    if (alert.level != null) {
      levels = {};
      levels[AlertLevel.SUCCESS] = 'alert-success';
      levels[AlertLevel.INFO] = 'alert-info';
      levels[AlertLevel.WARNING] = 'alert-warning';
      levels[AlertLevel.ERROR] = 'alert-danger';
    }
    return div({
      className: 'row'
    }, alert.level != null ? div({
      className: "alert " + levels[alert.level] + " alert-dismissible",
      role: "alert"
    }, button({
      type: "button",
      className: "close",
      "data-dismiss": "alert"
    }, span({
      'aria-hidden': "true"
    }, "×"), span({
      className: "sr-only"
    }, t("app alert close"))), strong > null, alert.message) : void 0);
  }
});
});

;require.register("components/application", function(exports, require, module) {
var AccountConfig, AccountStore, Alert, Application, Compose, Conversation, LayoutActionCreator, LayoutStore, MailboxList, Menu, MessageList, MessageStore, ReactCSSTransitionGroup, RouterMixin, SearchForm, SearchStore, Settings, SettingsStore, StoreWatchMixin, a, body, button, classer, div, form, i, input, p, span, strong, _ref;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span, a = _ref.a, button = _ref.button, strong = _ref.strong;

AccountConfig = require('./account-config');

Alert = require('./alert');

Compose = require('./compose');

Conversation = require('./conversation');

MailboxList = require('./mailbox-list');

Menu = require('./menu');

MessageList = require('./message-list');

Settings = require('./settings');

SearchForm = require('./search-form');

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

StoreWatchMixin = require('../mixins/StoreWatchMixin');

AccountStore = require('../stores/AccountStore');

MessageStore = require('../stores/MessageStore');

LayoutStore = require('../stores/LayoutStore');

SettingsStore = require('../stores/SettingsStore');

SearchStore = require('../stores/SearchStore');

LayoutActionCreator = require('../actions/LayoutActionCreator');


/*
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly

    About routing: it uses Backbone.Router as a source of truth for the layout.
    (based on: https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592)
 */

module.exports = Application = React.createClass({
  displayName: 'Application',
  mixins: [StoreWatchMixin([AccountStore, MessageStore, LayoutStore, SearchStore]), RouterMixin],
  render: function() {
    var alert, configMailboxUrl, firstPanelLayoutMode, isFullWidth, layout, panelClasses, responsiveBackUrl, responsiveClasses, showMailboxConfigButton;
    layout = this.props.router.current;
    if (layout == null) {
      return div(null, t("app loading"));
    }
    isFullWidth = layout.secondPanel == null;
    firstPanelLayoutMode = isFullWidth ? 'full' : 'first';
    panelClasses = this.getPanelClasses(isFullWidth);
    showMailboxConfigButton = (this.state.selectedAccount != null) && layout.firstPanel.action !== 'account.new';
    if (showMailboxConfigButton) {
      if (layout.firstPanel.action === 'account.config') {
        configMailboxUrl = this.buildUrl({
          direction: 'first',
          action: 'account.mailbox.messages',
          parameters: this.state.selectedAccount.get('id'),
          fullWidth: true
        });
      } else {
        configMailboxUrl = this.buildUrl({
          direction: 'first',
          action: 'account.config',
          parameters: this.state.selectedAccount.get('id'),
          fullWidth: true
        });
      }
    }
    responsiveBackUrl = this.buildUrl({
      firstPanel: layout.firstPanel,
      fullWidth: true
    });
    responsiveClasses = classer({
      'col-xs-12 col-md-11': true,
      'pushed': this.state.isResponsiveMenuShown
    });
    alert = this.state.alertMessage;
    return div({
      className: 'container-fluid'
    }, div({
      className: 'row'
    }, Menu({
      accounts: this.state.accounts,
      selectedAccount: this.state.selectedAccount,
      isResponsiveMenuShown: this.state.isResponsiveMenuShown,
      layout: this.props.router.current,
      favoriteMailboxes: this.state.favoriteMailboxes
    }), div({
      id: 'page-content',
      className: responsiveClasses
    }, Alert({
      alert: alert
    }), div({
      id: 'quick-actions',
      className: 'row'
    }, layout.secondPanel ? a({
      href: responsiveBackUrl,
      className: 'responsive-handler hidden-md hidden-lg'
    }, i({
      className: 'fa fa-chevron-left hidden-md hidden-lg pull-left'
    }), t("app back")) : a({
      onClick: this.onResponsiveMenuClick,
      className: 'responsive-handler hidden-md hidden-lg'
    }, i({
      className: 'fa fa-bars pull-left'
    }), t("app menu")), div({
      className: 'col-md-6 hidden-xs hidden-sm pull-left'
    }, form({
      className: 'form-inline col-md-12'
    }, MailboxList({
      selectedAccount: this.state.selectedAccount,
      mailboxes: this.state.mailboxes,
      selectedMailbox: this.state.selectedMailbox
    }), SearchForm({
      query: this.state.searchQuery
    }))), div({
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
      className: panelClasses.firstPanel,
      key: 'left-panel-' + layout.firstPanel.action + '-' + layout.firstPanel.parameters.join('-')
    }, this.getPanelComponent(layout.firstPanel, firstPanelLayoutMode)), !isFullWidth && (layout.secondPanel != null) ? div({
      className: panelClasses.secondPanel,
      key: 'right-panel-' + layout.secondPanel.action + '-' + layout.secondPanel.parameters.join('-')
    }, this.getPanelComponent(layout.secondPanel, 'second')) : void 0))));
  },
  getPanelClasses: function(isFullWidth) {
    var classes, first, layout, previous, second, wasFullWidth;
    previous = this.props.router.previous;
    layout = this.props.router.current;
    first = layout.firstPanel;
    second = layout.secondPanel;
    if (isFullWidth) {
      classes = {
        firstPanel: 'panel col-xs-12 col-md-12'
      };
      if ((previous != null) && first.action === 'account.config') {
        classes.firstPanel += ' moveFromTopRightCorner';
      } else if ((previous != null) && previous.secondPanel) {
        if (previous.secondPanel.action === layout.firstPanel.action && _.difference(previous.secondPanel.parameters, layout.firstPanel.parameters).length === 0) {
          classes.firstPanel += ' expandFromRight';
        }
      } else if (previous != null) {
        classes.firstPanel += ' moveFromLeft';
      }
    } else {
      classes = {
        firstPanel: 'panel col-xs-12 col-md-6 hidden-xs hidden-sm',
        secondPanel: 'panel col-xs-12 col-md-6'
      };
      if (previous != null) {
        wasFullWidth = previous.secondPanel == null;
        if (wasFullWidth && !isFullWidth) {
          if (previous.firstPanel.action === second.action && _.difference(previous.firstPanel.parameters, second.parameters).length === 0) {
            classes.firstPanel += ' moveFromLeft';
            classes.secondPanel += ' slide-in-from-left';
          } else {
            classes.secondPanel += ' slide-in-from-right';
          }
        } else if (!isFullWidth) {
          classes.secondPanel += ' slide-in-from-left';
        }
      }
    }
    return classes;
  },
  getPanelComponent: function(panelInfo, layout) {
    var accountID, accounts, action, conversation, direction, error, firstOfPage, initialAccountConfig, isWaiting, lastOfPage, mailboxID, message, messagesCount, numPerPage, openMessage, otherPanelInfo, pageNum, results, selectedAccount, settings, _ref1;
    if (panelInfo.action === 'account.mailbox.messages') {
      accountID = panelInfo.parameters[0];
      mailboxID = panelInfo.parameters[1];
      pageNum = (_ref1 = panelInfo.parameters[2]) != null ? _ref1 : 1;
      numPerPage = this.state.settings.get('messagesPerPage');
      firstOfPage = (pageNum - 1) * numPerPage;
      lastOfPage = pageNum * numPerPage;
      openMessage = null;
      direction = layout === 'first' ? 'secondPanel' : 'firstPanel';
      otherPanelInfo = this.props.router.current[direction];
      if ((otherPanelInfo != null ? otherPanelInfo.action : void 0) === 'message') {
        openMessage = MessageStore.getByID(otherPanelInfo.parameters[0]);
      }
      messagesCount = MessageStore.getMessagesCountByMailbox(mailboxID);
      return MessageList({
        messages: MessageStore.getMessagesByMailbox(mailboxID, firstOfPage, lastOfPage),
        messagesCount: messagesCount,
        accountID: accountID,
        mailboxID: mailboxID,
        layout: layout,
        openMessage: openMessage,
        messagesPerPage: numPerPage,
        pageNum: pageNum,
        emptyListMessage: t('list empty'),
        counterMessage: t('list count', messagesCount),
        buildPaginationUrl: (function(_this) {
          return function(numPage) {
            return _this.buildUrl({
              direction: 'first',
              action: 'account.mailbox.messages',
              parameters: [accountID, mailboxID, numPage]
            });
          };
        })(this)
      });
    } else if (panelInfo.action === 'account.config') {
      initialAccountConfig = this.state.selectedAccount;
      error = AccountStore.getError();
      isWaiting = AccountStore.isWaiting();
      return AccountConfig({
        layout: layout,
        error: error,
        isWaiting: isWaiting,
        initialAccountConfig: initialAccountConfig
      });
    } else if (panelInfo.action === 'account.new') {
      error = AccountStore.getError();
      isWaiting = AccountStore.isWaiting();
      return AccountConfig({
        layout: layout,
        error: error,
        isWaiting: isWaiting
      });
    } else if (panelInfo.action === 'message') {
      message = MessageStore.getByID(panelInfo.parameters[0]);
      conversation = MessageStore.getMessagesByConversation(panelInfo.parameters[0]);
      selectedAccount = this.state.selectedAccount;
      return Conversation({
        message: message,
        conversation: conversation,
        selectedAccount: selectedAccount,
        layout: layout
      });
    } else if (panelInfo.action === 'compose') {
      selectedAccount = this.state.selectedAccount;
      accounts = this.state.accounts;
      message = null;
      action = null;
      return Compose({
        selectedAccount: selectedAccount,
        layout: layout,
        accounts: accounts,
        message: message,
        action: action
      });
    } else if (panelInfo.action === 'settings') {
      settings = this.state.settings;
      return Settings({
        settings: settings
      });
    } else if (panelInfo.action === 'search') {
      accountID = null;
      mailboxID = null;
      pageNum = panelInfo.parameters[1];
      numPerPage = this.state.settings.get('messagesPerPage');
      firstOfPage = (pageNum - 1) * numPerPage;
      lastOfPage = pageNum * numPerPage;
      openMessage = null;
      direction = layout === 'first' ? 'secondPanel' : 'firstPanel';
      otherPanelInfo = this.props.router.current[direction];
      if ((otherPanelInfo != null ? otherPanelInfo.action : void 0) === 'message') {
        openMessage = MessageStore.getByID(otherPanelInfo.parameters[0]);
      }
      results = SearchStore.getResults();
      return MessageList({
        messages: results,
        messagesCount: results.count(),
        accountID: accountID,
        mailboxID: mailboxID,
        layout: layout,
        openMessage: openMessage,
        messagesPerPage: numPerPage,
        pageNum: pageNum,
        emptyListMessage: t('list search empty', {
          query: this.state.searchQuery
        }),
        counterMessage: t('list search count', results.count()),
        buildPaginationUrl: (function(_this) {
          return function(numPage) {
            return _this.buildUrl({
              direction: 'first',
              action: 'search',
              parameters: [_this.state.searchQuery, numPage]
            });
          };
        })(this)
      });
    } else {
      return div(null, 'Unknown component');
    }
  },
  getStateFromStores: function() {
    var firstPanelInfo, selectedAccount, selectedAccountID, selectedMailboxID, _ref1;
    selectedAccount = AccountStore.getSelected();
    selectedAccountID = (selectedAccount != null ? selectedAccount.get('id') : void 0) || null;
    firstPanelInfo = (_ref1 = this.props.router.current) != null ? _ref1.firstPanel : void 0;
    if ((firstPanelInfo != null ? firstPanelInfo.action : void 0) === 'account.mailbox.messages') {
      selectedMailboxID = firstPanelInfo.parameters[1];
    } else {
      selectedMailboxID = null;
    }
    return {
      accounts: AccountStore.getAll(),
      selectedAccount: selectedAccount,
      isResponsiveMenuShown: LayoutStore.isMenuShown(),
      alertMessage: LayoutStore.getAlert(),
      mailboxes: AccountStore.getSelectedMailboxes(true),
      selectedMailbox: AccountStore.getSelectedMailbox(selectedMailboxID),
      favoriteMailboxes: AccountStore.getSelectedFavorites(),
      searchQuery: SearchStore.getQuery(),
      settings: SettingsStore.get()
    };
  },
  componentWillMount: function() {
    this.onRoute = (function(_this) {
      return function(params) {
        var firstPanelInfo, secondPanelInfo;
        firstPanelInfo = params.firstPanelInfo, secondPanelInfo = params.secondPanelInfo;
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
      return LayoutActionCreator.hideReponsiveMenu();
    } else {
      return LayoutActionCreator.showReponsiveMenu();
    }
  }
});
});

;require.register("components/compose", function(exports, require, module) {
var AccountStore, Compose, ComposeActions, LayoutActionCreator, MessageActionCreator, MessageUtils, RouterMixin, SettingsStore, a, button, classer, div, form, h3, i, input, label, li, span, textarea, ul, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, a = _ref.a, i = _ref.i, textarea = _ref.textarea, form = _ref.form, label = _ref.label, button = _ref.button, span = _ref.span, ul = _ref.ul, li = _ref.li, input = _ref.input;

classer = React.addons.classSet;

AccountStore = require('../stores/AccountStore');

SettingsStore = require('../stores/SettingsStore');

ComposeActions = require('../constants/AppConstants').ComposeActions;

MessageUtils = require('../utils/MessageUtils');

LayoutActionCreator = require('../actions/LayoutActionCreator');

MessageActionCreator = require('../actions/MessageActionCreator');

RouterMixin = require('../mixins/RouterMixin');

module.exports = Compose = React.createClass({
  displayName: 'Compose',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  render: function() {
    var accounts, classInput, classLabel, closeUrl, collapseUrl, expandUrl, _ref1;
    expandUrl = this.buildUrl({
      direction: 'first',
      action: 'compose',
      fullWidth: true
    });
    collapseUrl = this.buildUrl({
      firstPanel: {
        action: 'account.mailbox.messages',
        parameters: (_ref1 = this.state.currentAccount) != null ? _ref1.get('id') : void 0
      },
      secondPanel: {
        action: 'compose'
      }
    });
    closeUrl = this.buildClosePanelUrl(this.props.layout);
    classLabel = 'col-sm-2 col-sm-offset-0 control-label';
    classInput = 'col-sm-8';
    accounts = AccountStore.getAll();
    return div({
      id: 'email-compose'
    }, h3(null, a({
      href: closeUrl,
      className: 'close-email hidden-xs hidden-sm'
    }, i({
      className: 'fa fa-times'
    })), t('compose'), this.props.layout !== 'full' ? a({
      href: expandUrl,
      className: 'expand hidden-xs hidden-sm'
    }, i({
      className: 'fa fa-arrows-h'
    })) : a({
      href: collapseUrl,
      className: 'close-email pull-right'
    }, i({
      className: 'fa fa-compress'
    }))), form({
      className: 'form-horizontal'
    }, div({
      className: 'form-group'
    }, label({
      htmlFor: 'compose-from',
      className: classLabel
    }, t("compose from")), div({
      className: classInput
    }, button({
      id: 'compose-from',
      className: 'btn btn-default dropdown-toggle',
      type: 'button',
      'data-toggle': 'dropdown'
    }, null, span({
      ref: 'account'
    }, this.state.currentAccount.get('label')), span({
      className: 'caret'
    })), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, accounts.map((function(_this) {
      return function(account, key) {
        return _this.getAccountRender(account, key);
      };
    })(this)).toJS()))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'compose-to',
      className: classLabel
    }, t("compose to")), div({
      className: classInput
    }, input({
      id: 'compose-to',
      ref: 'to',
      valueLink: this.linkState('to'),
      type: 'text',
      className: 'form-control',
      placeholder: t("compose to help")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'compose-cc',
      className: classLabel
    }, t("compose cc")), div({
      className: classInput
    }, input({
      id: 'compose-cc',
      ref: 'cc',
      valueLink: this.linkState('cc'),
      type: 'text',
      className: 'form-control',
      placeholder: t("compose cc help")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'compose-bcc',
      className: classLabel
    }, t("compose bcc")), div({
      className: classInput
    }, input({
      id: 'compose-bcc',
      ref: 'bcc',
      valueLink: this.linkState('bcc'),
      type: 'text',
      className: 'form-control',
      placeholder: t("compose bcc help")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'compose-subject',
      className: classLabel
    }, t("compose subject")), div({
      className: classInput
    }, input({
      id: 'compose-subject',
      ref: 'subject',
      valueLink: this.linkState('subject'),
      type: 'text',
      className: 'form-control',
      placeholder: t("compose subject help")
    }))), div({
      className: 'form-group'
    }, this.state.composeInHTML ? div({
      className: 'rt-editor',
      contentEditable: true,
      dangerouslySetInnerHTML: {
        __html: this.linkState('html').value
      }
    }) : textarea({
      className: 'editor',
      ref: 'content',
      defaultValue: this.linkState('body').value
    })), div({
      className: 'composeToolbox'
    }, div({
      className: 'btn-toolbar',
      role: 'toolbar'
    }, div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: this.onDraft
    }, span({
      className: 'fa fa-save'
    }), span({
      className: 'tool-long'
    }, t('compose action draft')))), div({
      className: 'btn-group btn-group-lg'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: this.onSend
    }, span({
      className: 'fa fa-send'
    }), span({
      className: 'tool-long'
    }, t('compose action send'))))))));
  },
  componentDidMount: function() {
    var node;
    node = this.getDOMNode();
    node.scrollIntoView();
    if (this.state.composeInHTML) {
      return jQuery('#email-compose .rt-editor').on('keypress', function(e) {
        if (e.keyCode === 13) {
          return setTimeout(function() {
            var after, before, inserted, matchesSelector, parent, process, rangeAfter, rangeBefore, sel, target;
            matchesSelector = document.documentElement.matches || document.documentElement.matchesSelector || document.documentElement.webkitMatchesSelector || document.documentElement.mozMatchesSelector || document.documentElement.oMatchesSelector || document.documentElement.msMatchesSelector;
            target = document.getSelection().anchorNode;
            if ((matchesSelector != null) && !target.matches('.rt-editor blockquote *')) {
              return;
            }
            if (target.lastChild) {
              target = target.lastChild.previousElementSibling;
            }
            parent = target;
            process = function() {
              var current;
              current = parent;
              return parent = parent.parentNode;
            };
            process();
            while ((parent != null) && !parent.classList.contains('rt-editor')) {
              process();
            }
            rangeBefore = document.createRange();
            rangeBefore.setEnd(target, 0);
            rangeBefore.setStartBefore(parent.firstChild);
            rangeAfter = document.createRange();
            if (target.nextSibling != null) {
              rangeAfter.setStart(target.nextSibling, 0);
            } else {
              rangeAfter.setStart(target, 0);
            }
            rangeAfter.setEndAfter(parent.lastChild);
            before = rangeBefore.cloneContents();
            after = rangeAfter.cloneContents();
            inserted = document.createElement('p');
            inserted.innerHTML = "<br />";
            parent.innerHTML = "";
            parent.appendChild(before);
            parent.appendChild(inserted);
            parent.appendChild(after);

            /*
             * alternative 2
             * We move every node from the caret to the end of the
             * message to a new DOM tree, then insert a blank line
             * and the new tree
            parent = target
            p2 = null
            p3 = null
            process = ->
                p3 = p2
                current = parent
                parent = parent.parentNode
                p2 = parent.cloneNode false
                if p3?
                    p2.appendChild p3
                s = current.nextSibling
                while s?
                    p2.appendChild(s.cloneNode(true))
                    s2 = s.nextSibling
                    parent.removeChild s
                    s = s2
            process()
            process() while (parent.parentNode? and
                not parent.parentNode.classList.contains 'rt-editor')
            after = p2
            inserted = document.createElement 'p'
            inserted.innerHTML = "<br />"
            if parent.nextSibling
                parent.parentNode.insertBefore inserted, parent.nextSibling
                parent.parentNode.insertBefore after, parent.nextSibling
            else
                parent.parentNode.appendChild inserted
                parent.parentNode.appendChild after
             */
            inserted.focus();
            sel = window.getSelection();
            return sel.collapse(inserted, 0);
          }, 0);
        }
      });
    }
  },
  getAccountRender: function(account, key) {
    var isSelected, _ref1;
    isSelected = ((this.state.currentAccount == null) && key === 0) || ((_ref1 = this.state.currentAccount) != null ? _ref1.get('id') : void 0) === account.get('id');
    if (!isSelected) {
      return li({
        role: 'presentation',
        key: key
      }, a({
        role: 'menuitem',
        onClick: this.onAccountChange,
        'data-value': key
      }, account.get('label')));
    }
  },
  getInitialState: function(forceDefault) {
    var date, dateHuman, formatter, html, message, sender, state, text, today;
    message = this.props.message;
    state = {
      currentAccount: this.props.selectedAccount,
      composeInHTML: SettingsStore.get('composeInHTML')
    };
    if (message != null) {
      today = moment();
      date = moment(message.get('createdAt'));
      if (date.isBefore(today, 'year')) {
        formatter = 'DD/MM/YYYY';
      } else if (date.isBefore(today, 'day')) {
        formatter = 'DD MMMM';
      } else {
        formatter = 'hh:mm';
      }
      dateHuman = date.format(formatter);
      sender = MessageUtils.displayAddresses(message.get('from'));
      text = message.get('text');
      html = message.get('html');
      if (text && !html && state.composeInHTML) {
        html = markdown.toHTML(text);
      }
      if (html && !text && !state.composeInHTML) {
        text = toMarkdown(html);
      }
    }
    switch (this.props.action) {
      case ComposeActions.REPLY:
        state.to = MessageUtils.displayAddresses(message.getReplyToAddress(), true);
        state.cc = '';
        state.bcc = '';
        state.subject = "" + (t('compose reply prefix')) + (message.get('subject'));
        state.body = t('compose reply separator', {
          date: dateHuman,
          sender: sender
        }) + MessageUtils.generateReplyText(text) + "\n";
        state.html = "<p><br /></p>\n<p>" + (t('compose reply separator', {
          date: dateHuman,
          sender: sender
        })) + "</p>\n<blockquote>" + html + "</blockquote>";
        break;
      case ComposeActions.REPLY_ALL:
        state.to = MessageUtils.displayAddresses(message.getReplyToAddress(), true);
        state.cc = MessageUtils.displayAddresses(Array.concat(message.get('to'), message.get('cc')), true);
        state.bcc = '';
        state.subject = "" + (t('compose reply prefix')) + (message.get('subject'));
        state.body = t('compose reply separator', {
          date: dateHuman,
          sender: sender
        }) + MessageUtils.generateReplyText(text) + "\n";
        state.html = "<p><br /></p>\n<p>" + (t('compose reply separator', {
          date: dateHuman,
          sender: sender
        })) + "</p>\n<blockquote>" + html + "</blockquote>";
        break;
      case ComposeActions.FORWARD:
        state.to = '';
        state.cc = '';
        state.bcc = '';
        state.subject = "" + (t('compose forward prefix')) + (message.get('subject'));
        state.body = t('compose forward separator', {
          date: dateHuman,
          sender: sender
        }) + text;
        state.html = ("<p>" + (t('compose forward separator', {
          date: dateHuman,
          sender: sender
        })) + "</p>") + html;
        break;
      case null:
        state.to = '';
        state.cc = '';
        state.bcc = '';
        state.subject = '';
        state.body = t('compose default');
    }
    return state;
  },
  onAccountChange: function(args) {
    var selected;
    selected = args.target.dataset.value;
    if (selected !== this.state.currentAccount.get('id')) {
      return this.setState({
        currentAccount: AccountStore.getByID(selected)
      });
    }
  },
  onDraft: function(args) {
    return LayoutActionCreator.alertWarning(t("app unimplemented"));
  },
  onSend: function(args) {
    var callback, message, msg, msgId, references;
    message = {
      from: this.state.currentAccount.get('login'),
      to: this.refs.to.getDOMNode().value.trim(),
      cc: this.refs.cc.getDOMNode().value.trim(),
      bcc: this.refs.bcc.getDOMNode().value.trim(),
      subject: this.refs.subject.getDOMNode().value.trim()
    };
    if (this.state.composeInHTML) {
      message.html = this.refs.html.getDOMNode().innerHTML;
      message.content = toMarkdown(message.html);
    } else {
      message.content = this.refs.content.getDOMNode().value.trim();
    }
    if (this.props.message != null) {
      msg = this.props.message;
      msgId = msg.get('id');
      message.inReplyTo = msgId;
      references = msg.references;
      if (references != null) {
        message.references = references + msgId;
      } else {
        message.references = msgId;
      }
    }
    callback = this.props.callback;
    return MessageActionCreator.send(message, function(error) {
      if (error != null) {
        LayoutActionCreator.alertError(t("message action sent ko")) + error;
      } else {
        LayoutActionCreator.alertSuccess(t("message action sent ok"));
      }
      if (callback != null) {
        return callback(error);
      }
    });
  }
});
});

;require.register("components/conversation", function(exports, require, module) {
var Message, RouterMixin, a, classer, div, h3, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a;

Message = require('./message');

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

module.exports = React.createClass({
  displayName: 'Conversation',
  mixins: [RouterMixin],
  render: function() {
    var closeIcon, closeUrl, collapseUrl, expandUrl, isLast, key, message, selectedAccount, selectedAccountID;
    if ((this.props.message == null) || !this.props.conversation) {
      return p(null, t("app loading"));
    }
    expandUrl = this.buildUrl({
      direction: 'first',
      action: 'message',
      parameters: this.props.message.get('id'),
      fullWidth: true
    });
    if (window.router.previous != null) {
      try {
        selectedAccountID = this.props.selectedAccount.get('id');
      } catch (_error) {
        selectedAccountID = this.props.conversation[0].mailbox;
      }
    } else {
      selectedAccountID = this.props.conversation[0].mailbox;
    }
    collapseUrl = this.buildUrl({
      firstPanel: {
        action: 'account.mailbox.messages',
        parameters: selectedAccountID
      },
      secondPanel: {
        action: 'message',
        parameters: this.props.conversation[0].get('id')
      }
    });
    if (this.props.layout === 'full') {
      closeUrl = this.buildUrl({
        direction: 'first',
        action: 'account.mailbox.messages',
        parameters: selectedAccountID,
        fullWidth: true
      });
    } else {
      closeUrl = this.buildClosePanelUrl(this.props.layout);
    }
    closeIcon = this.props.layout === 'full' ? 'fa-th-list' : 'fa-times';
    return div({
      className: 'conversation'
    }, h3(null, a({
      href: closeUrl,
      className: 'close-conversation hidden-xs hidden-sm'
    }, i({
      className: 'fa ' + closeIcon
    })), this.props.message.get('subject'), this.props.layout !== 'full' ? a({
      href: expandUrl,
      className: 'expand hidden-xs hidden-sm'
    }, i({
      className: 'fa fa-arrows-h'
    })) : a({
      href: collapseUrl,
      className: 'close-conversation pull-right'
    }, i({
      className: 'fa fa-compress'
    }))), ul({
      className: 'thread list-unstyled'
    }, (function() {
      var _i, _len, _ref1, _results;
      _ref1 = this.props.conversation;
      _results = [];
      for (key = _i = 0, _len = _ref1.length; _i < _len; key = ++_i) {
        message = _ref1[key];
        isLast = key === this.props.conversation.length - 1;
        selectedAccount = this.props.selectedAccount;
        _results.push(Message({
          message: message,
          key: key,
          isLast: isLast,
          selectedAccount: selectedAccount
        }));
      }
      return _results;
    }).call(this)));
  }
});
});

;require.register("components/mailbox-list", function(exports, require, module) {
var RouterMixin, a, button, div, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, a = _ref.a, button = _ref.button;

RouterMixin = require('../mixins/RouterMixin');

module.exports = React.createClass({
  displayName: 'MailboxList',
  mixins: [RouterMixin],
  render: function() {
    var firstItem;
    if (this.props.mailboxes.length > 0 && (this.props.selectedMailbox != null)) {
      firstItem = this.props.selectedMailbox;
      return div({
        className: 'dropdown pull-left'
      }, button({
        className: 'btn btn-default dropdown-toggle',
        type: 'button',
        'data-toggle': 'dropdown'
      }, firstItem.get('label'), span({
        className: 'caret'
      }, '')), ul({
        className: 'dropdown-menu',
        role: 'menu'
      }, this.props.mailboxes.map((function(_this) {
        return function(mailbox, key) {
          if (mailbox.get('id') !== _this.props.selectedMailbox.get('id')) {
            return _this.getMailboxRender(mailbox, key);
          }
        };
      })(this)).toJS()));
    } else {
      return div(null, "");
    }
  },
  getMailboxRender: function(mailbox, key) {
    var i, pusher, url, _i, _ref1;
    url = this.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: [this.props.selectedAccount.get('id'), mailbox.get('id')]
    });
    pusher = "";
    for (i = _i = 1, _ref1 = mailbox.get('depth'); _i <= _ref1; i = _i += 1) {
      pusher += "--";
    }
    return li({
      role: 'presentation',
      key: key
    }, a({
      href: url,
      role: 'menuitem'
    }, "" + pusher + (mailbox.get('label'))));
  }
});
});

;require.register("components/menu", function(exports, require, module) {
var AccountStore, Menu, RouterMixin, a, classer, div, i, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i;

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

AccountStore = require('../stores/AccountStore');

module.exports = Menu = React.createClass({
  displayName: 'Menu',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !Immutable.is(nextProps.accounts, this.props.accounts) || !Immutable.is(nextProps.selectedAccount, this.props.selectedAccount) || !_.isEqual(nextProps.layout, this.props.layout) || nextProps.isResponsiveMenuShown !== this.props.isResponsiveMenuShown || !Immutable.is(nextProps.favoriteMailboxes, this.props.favoriteMailboxes);
  },
  render: function() {
    var classes, composeUrl, newMailboxUrl, selectedAccountUrl, settingsUrl, _ref1, _ref2, _ref3;
    selectedAccountUrl = this.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: (_ref1 = this.props.selectedAccount) != null ? _ref1.get('id') : void 0,
      fullWidth: true
    });
    if (this.props.layout.firstPanel.action === 'compose' || ((_ref2 = this.props.layout.secondPanel) != null ? _ref2.action : void 0) === 'compose') {
      composeUrl = selectedAccountUrl;
    } else {
      composeUrl = this.buildUrl({
        direction: 'second',
        action: 'compose',
        parameters: null,
        fullWidth: false
      });
    }
    if (this.props.layout.firstPanel.action === 'account.new') {
      newMailboxUrl = selectedAccountUrl;
    } else {
      newMailboxUrl = this.buildUrl({
        direction: 'first',
        action: 'account.new',
        fullWidth: true
      });
    }
    if (this.props.layout.firstPanel.action === 'settings' || ((_ref3 = this.props.layout.secondPanel) != null ? _ref3.action : void 0) === 'settings') {
      settingsUrl = selectedAccountUrl;
    } else {
      settingsUrl = this.buildUrl({
        direction: 'first',
        action: 'settings',
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
      className: 'item-label'
    }, t('menu compose'))), ul({
      id: 'account-list',
      className: 'list-unstyled'
    }, this.props.accounts.map((function(_this) {
      return function(account, key) {
        return _this.getAccountRender(account, key);
      };
    })(this)).toJS()), a({
      href: newMailboxUrl,
      className: 'menu-item new-account-action'
    }, i({
      className: 'fa fa-inbox'
    }), span({
      className: 'item-label'
    }, t('menu account new'))), a({
      href: settingsUrl,
      className: 'menu-item settings-action'
    }, i({
      className: 'fa fa-cog'
    }), span({
      className: 'item-label'
    }, t('menu settings'))));
  },
  getAccountRender: function(account, key) {
    var accountClasses, accountID, defaultMailbox, isSelected, url, _ref1;
    isSelected = ((this.props.selectedAccount == null) && key === 0) || ((_ref1 = this.props.selectedAccount) != null ? _ref1.get('id') : void 0) === account.get('id');
    accountClasses = classer({
      active: isSelected
    });
    accountID = account.get('id');
    defaultMailbox = AccountStore.getDefaultMailbox(accountID);
    url = this.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: [accountID, defaultMailbox.get('id')],
      fullWidth: false
    });
    return li({
      className: accountClasses,
      key: key
    }, a({
      href: url,
      className: 'menu-item ' + accountClasses
    }, i({
      className: 'fa fa-inbox'
    }), span({
      className: 'badge'
    }, account.get('unreadCount')), span({
      className: 'item-label'
    }, account.get('label'))), ul({
      className: 'list-unstyled submenu mailbox-list'
    }, this.props.favoriteMailboxes.map((function(_this) {
      return function(mailbox, key) {
        return _this.getMailboxRender(account, mailbox, key);
      };
    })(this)).toJS()));
  },
  getMailboxRender: function(account, mailbox, key) {
    var mailboxUrl;
    mailboxUrl = this.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: [account.get('id'), mailbox.get('id')]
    });
    return a({
      href: mailboxUrl,
      className: 'menu-item',
      key: key
    }, i({
      className: 'fa fa-star'
    }), span({
      className: 'badge'
    }, Math.floor((Math.random() * 10) + 1)), span({
      className: 'item-label'
    }, mailbox.get('label')));
  }
});
});

;require.register("components/message-list", function(exports, require, module) {
var MessageUtils, RouterMixin, a, classer, div, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, p = _ref.p;

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

MessageUtils = require('../utils/MessageUtils');

module.exports = React.createClass({
  displayName: 'MessageList',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !Immutable.is(nextProps.messages, this.props.messages) || !Immutable.is(nextProps.openMessage, this.props.openMessage);
  },
  render: function() {
    var curPage, nbPages;
    curPage = parseInt(this.props.pageNum, 10);
    nbPages = Math.ceil(this.props.messagesCount / this.props.messagesPerPage);
    return div({
      className: 'message-list'
    }, this.getPagerRender(curPage, nbPages), this.props.messages.count() === 0 ? p(null, this.props.emptyListMessage) : div(null, p(null, this.props.counterMessage), ul({
      className: 'list-unstyled'
    }, this.props.messages.map((function(_this) {
      return function(message, key) {
        var isActive;
        if (true) {
          isActive = (_this.props.openMessage != null) && _this.props.openMessage.get('id') === message.get('id');
          return _this.getMessageRender(message, key, isActive);
        }
      };
    })(this)).toJS())), this.getPagerRender(curPage, nbPages));
  },
  getMessageRender: function(message, key, isActive) {
    var classes, date, formatter, today, url;
    classes = classer({
      read: message.get('isRead'),
      active: isActive
    });
    url = this.buildUrl({
      direction: 'second',
      action: 'message',
      parameters: message.get('id')
    });
    today = moment();
    date = moment(message.get('createdAt'));
    if (date.isBefore(today, 'year')) {
      formatter = 'DD/MM/YYYY';
    } else if (date.isBefore(today, 'day')) {
      formatter = 'DD MMMM';
    } else {
      formatter = 'hh:mm';
    }
    return li({
      className: 'message ' + classes,
      key: key
    }, a({
      href: url
    }, i({
      className: 'fa fa-user'
    }), span({
      className: 'participants'
    }, this.getParticipants(message)), div({
      className: 'preview'
    }, span({
      className: 'title'
    }, message.get('subject')), p(null, message.get('text'))), span({
      className: 'hour'
    }, date.format(formatter))));
  },
  getPagerRender: function(curPage, nbPages) {
    var classCurr, classFirst, classLast, j, maxPage, minPage, urlCurr, urlFirst, urlLast;
    if (nbPages < 2) {
      return;
    }
    classFirst = curPage === 1 ? 'disabled' : '';
    classLast = curPage === nbPages ? 'disabled' : '';
    if (nbPages < 11) {
      minPage = 1;
      maxPage = nbPages;
    } else {
      minPage = curPage < 5 ? 1 : curPage - 2;
      maxPage = minPage + 4;
      if (maxPage > nbPages) {
        maxPage = nbPages;
      }
    }
    urlFirst = this.props.buildPaginationUrl(1);
    urlLast = this.props.buildPaginationUrl(nbPages);
    return div({
      className: 'pagination-box'
    }, ul({
      className: 'pagination'
    }, li({
      className: classFirst
    }, a({
      href: urlFirst
    }, '«')), minPage > 1 ? li({
      className: 'disabled'
    }, a({
      href: urlFirst
    }, '…')) : void 0, (function() {
      var _i, _results;
      _results = [];
      for (j = _i = minPage; _i <= maxPage; j = _i += 1) {
        classCurr = j === curPage ? 'current' : '';
        urlCurr = this.props.buildPaginationUrl(j);
        _results.push(li({
          className: classCurr,
          key: j
        }, a({
          href: urlCurr
        }, j)));
      }
      return _results;
    }).call(this), maxPage < nbPages ? li({
      className: 'disabled'
    }, a({
      href: urlFirst
    }, '…')) : void 0, li({
      className: classLast
    }, a({
      href: urlLast
    }, '»'))));
  },
  getParticipants: function(message) {
    return "" + (MessageUtils.displayAddresses(message.get('from'))) + ", " + (MessageUtils.displayAddresses(message.get('to').concat(message.get('cc'))));
  }
});
});

;require.register("components/message", function(exports, require, module) {
var AccountStore, Compose, ComposeActions, LayoutActionCreator, MailboxList, MessageUtils, a, button, classer, div, h3, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a, button = _ref.button;

MailboxList = require('./mailbox-list');

Compose = require('./compose');

MessageUtils = require('../utils/MessageUtils');

ComposeActions = require('../constants/AppConstants').ComposeActions;

LayoutActionCreator = require('../actions/LayoutActionCreator');

AccountStore = require('../stores/AccountStore');

classer = React.addons.classSet;

module.exports = React.createClass({
  displayName: 'Message',
  getInitialState: function() {
    return {
      active: false,
      composing: false,
      composeAction: ''
    };
  },
  render: function() {
    var action, callback, classes, clickHandler, date, formatter, html, layout, message, selectedAccount, text, today;
    message = this.props.message;
    text = message.get('text');
    html = message.get('html');
    if (text && !html && state.composeInHTML) {
      html = markdown.toHTML(text);
    }
    if (html && !text && !state.composeInHTML) {
      text = toMarkdown(html);
    }
    clickHandler = this.props.isLast ? null : this.onFold;
    classes = classer({
      message: true,
      active: this.state.active
    });
    today = moment();
    date = moment(message.get('createdAt'));
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
    }, this.getToolboxRender(), div({
      className: 'header'
    }, i({
      className: 'fa fa-user'
    }), div({
      className: 'participants'
    }, span({
      className: 'sender'
    }, MessageUtils.displayAddresses(message.get('from'), true)), span({
      className: 'receivers'
    }, t("mail receivers", {
      dest: MessageUtils.displayAddresses(message.get('to'), true)
    })), span({
      className: 'receivers'
    }, t("mail receivers cc", {
      dest: MessageUtils.displayAddresses(message.get('cc'), true)
    }))), span({
      className: 'hour'
    }, date.format(formatter))), div({
      className: 'preview'
    }, p(null, message.get('text'))), div({
      className: 'content',
      dangerouslySetInnerHTML: {
        __html: html
      }
    }), div({
      className: 'clearfix'
    }), this.state.composing ? (selectedAccount = this.props.selectedAccount, layout = 'second', message = message, action = this.state.composeAction, callback = (function(_this) {
      return function(error) {
        if (error == null) {
          return _this.setState({
            composing: false
          });
        }
      };
    })(this), Compose({
      selectedAccount: selectedAccount,
      layout: layout,
      message: message,
      action: action,
      callback: callback
    })) : void 0);
  },
  getToolboxRender: function() {
    var mailboxes;
    mailboxes = AccountStore.getSelectedMailboxes(true);
    return div({
      className: 'messageToolbox'
    }, div({
      className: 'btn-toolbar',
      role: 'toolbar'
    }, div({
      className: 'btn-group btn-group-sm btn-group-justified'
    }, div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: this.onReply
    }, span({
      className: 'fa fa-reply'
    }), span({
      className: 'tool-long'
    }, t('mail action reply')))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: this.onReplyAll
    }, span({
      className: 'fa fa-reply-all'
    }), span({
      className: 'tool-long'
    }, t('mail action reply all')))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: this.onForward
    }, span({
      className: 'fa fa-mail-forward'
    }), span({
      className: 'tool-long'
    }, t('mail action forward')))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: this.onDelete
    }, span({
      className: 'fa fa-trash-o'
    }), span({
      className: 'tool-long'
    }, t('mail action delete')))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default dropdown-toggle',
      type: 'button',
      'data-toggle': 'dropdown',
      onClick: this.onMark
    }, t('mail action mark', span({
      className: 'caret'
    }))), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, li(null, a({
      href: '#'
    }, t('mail mark fav'))), li(null, a({
      href: '#'
    }, t('mail mark nofav'))), li(null, a({
      href: '#'
    }, t('mail mark spam'))), li(null, a({
      href: '#'
    }, t('mail mark nospam'))), li(null, a({
      href: '#'
    }, t('mail mark read'))), li(null, a({
      href: '#'
    }, t('mail mark unread'))))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default dropdown-toggle',
      type: 'button',
      'data-toggle': 'dropdown',
      onClick: this.onMove
    }, t('mail action move', span({
      className: 'caret'
    }))), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, mailboxes.map((function(_this) {
      return function(mailbox, key) {
        return _this.getMailboxRender(mailbox, key);
      };
    })(this)).toJS())))));
  },
  getMailboxRender: function(mailbox, key) {
    var j, pusher, url, _i, _ref1;
    pusher = "";
    for (j = _i = 1, _ref1 = mailbox.get('depth'); _i <= _ref1; j = _i += 1) {
      pusher += "--";
    }
    url = '';
    return li({
      role: 'presentation',
      key: key
    }, a({
      href: url,
      role: 'menuitem'
    }, "" + pusher + (mailbox.get('label'))));
  },
  onFold: function(args) {
    return this.setState({
      active: !this.state.active
    });
  },
  onReply: function(args) {
    this.setState({
      composing: true
    });
    return this.setState({
      composeAction: ComposeActions.REPLY
    });
  },
  onReplyAll: function(args) {
    this.setState({
      composing: true
    });
    return this.setState({
      composeAction: ComposeActions.REPLY_ALL
    });
  },
  onForward: function(args) {
    this.setState({
      composing: true
    });
    return this.setState({
      composeAction: ComposeActions.FORWARD
    });
  },
  onDelete: function(args) {
    return LayoutActionCreator.alertWarning(t("app unimplemented"));
  },
  onCopy: function(args) {
    return LayoutActionCreator.alertWarning(t("app unimplemented"));
  },
  onMove: function(args) {
    return LayoutActionCreator.alertWarning(t("app unimplemented"));
  }
});
});

;require.register("components/search-form", function(exports, require, module) {
var ENTER_KEY, RouterMixin, SearchActionCreator, classer, div, input, span, _ref;

_ref = React.DOM, div = _ref.div, input = _ref.input, span = _ref.span;

classer = React.addons.classSet;

SearchActionCreator = require('../actions/SearchActionCreator');

ENTER_KEY = 13;

RouterMixin = require('../mixins/RouterMixin');

module.exports = React.createClass({
  displayName: 'SearchForm',
  mixins: [RouterMixin],
  render: function() {
    return div({
      className: 'form-group pull-left'
    }, div({
      className: 'input-group'
    }, input({
      className: 'form-control',
      type: 'text',
      placeholder: t('app search'),
      onKeyPress: this.onKeyPress,
      ref: 'searchInput',
      defaultValue: this.props.query
    }), div({
      className: 'input-group-addon btn btn-cozy',
      onClick: this.onSubmit
    }, span({
      className: 'fa fa-search'
    }))));
  },
  onSubmit: function() {
    var query;
    query = encodeURIComponent(this.refs.searchInput.getDOMNode().value.trim());
    if (query.length > 3) {
      return this.redirect({
        direction: 'first',
        action: 'search',
        parameters: [query]
      });
    }
  },
  onKeyPress: function(evt) {
    var query;
    if (evt.charCode === ENTER_KEY) {
      this.onSubmit();
      evt.preventDefault();
      return false;
    } else {
      query = this.refs.searchInput.getDOMNode().value;
      return SearchActionCreator.setQuery(query);
    }
  }
});
});

;require.register("components/settings", function(exports, require, module) {
var SettingsActionCreator, SettingsStore, button, classer, div, form, h3, input, label, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button;

classer = React.addons.classSet;

SettingsActionCreator = require('../actions/SettingsActionCreator');

SettingsStore = require('../stores/SettingsStore');

module.exports = React.createClass({
  displayName: 'AccountConfig',
  mixins: [React.addons.LinkedStateMixin],
  render: function() {
    var titleLabel;
    titleLabel = this.props.initialAccountConfig != null ? t("mailbox edit") : t("mailbox new");
    return div({
      id: 'mailbox-config'
    }, h3({
      className: null
    }, t("settings title")), this.props.error ? div({
      className: 'error'
    }, this.props.error) : void 0, form({
      className: 'form-horizontal'
    }, div({
      className: 'form-group'
    }, label({
      htmlFor: 'settings-mpp',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("settings label mpp")), div({
      className: 'col-sm-3'
    }, input({
      id: 'settings-mpp',
      valueLink: this.linkState('messagesPerPage'),
      type: 'number',
      min: 5,
      max: 100,
      step: 5,
      className: 'form-control'
    })))), form({
      className: 'form-horizontal'
    }, div({
      className: 'form-group'
    }, label({
      htmlFor: 'settings-compose',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("settings label compose")), div({
      className: 'col-sm-3'
    }, input({
      id: 'settings-compose',
      checkedLink: this.linkState('composeInHTML'),
      type: 'checkbox',
      className: 'form-control'
    }))), div({
      className: 'form-group'
    }, div({
      className: 'col-sm-offset-2 col-sm-5 text-right'
    }, button({
      className: 'btn btn-cozy',
      onClick: this.onSubmit
    }, t("settings button save"))))));
  },
  onSubmit: function(event) {
    var settingsValue;
    event.preventDefault();
    settingsValue = this.state;
    return SettingsActionCreator.edit(this.state);
  },
  getInitialState: function(forceDefault) {
    var settings;
    settings = this.props.settings;
    return settings.toObject();
  }
});
});

;require.register("constants/AppConstants", function(exports, require, module) {
module.exports = {
  ActionTypes: {
    'ADD_ACCOUNT': 'ADD_ACCOUNT',
    'REMOVE_ACCOUNT': 'REMOVE_ACCOUNT',
    'EDIT_ACCOUNT': 'EDIT_ACCOUNT',
    'SELECT_ACCOUNT': 'SELECT_ACCOUNT',
    'NEW_ACCOUNT_WAITING': 'NEW_ACCOUNT_WAITING',
    'NEW_ACCOUNT_ERROR': 'NEW_ACCOUNT_ERROR',
    'RECEIVE_RAW_MESSAGE': 'RECEIVE_RAW_MESSAGE',
    'RECEIVE_RAW_MESSAGES': 'RECEIVE_RAW_MESSAGES',
    'SEND_MESSAGE': 'SEND_MESSAGE',
    'SET_SEARCH_QUERY': 'SET_SEARCH_QUERY',
    'RECEIVE_RAW_SEARCH_RESULTS': 'RECEIVE_RAW_SEARCH_RESULTS',
    'CLEAR_SEARCH_RESULTS': 'CLEAR_SEARCH_RESULTS',
    'SHOW_MENU_RESPONSIVE': 'SHOW_MENU_RESPONSIVE',
    'HIDE_MENU_RESPONSIVE': 'HIDE_MENU_RESPONSIVE',
    'SELECT_ACCOUNT': 'SELECT_ACCOUNT',
    'DISPLAY_ALERT': 'DISPLAY_ALERT',
    'RECEIVE_RAW_MAILBOXES': 'RECEIVE_RAW_MAILBOXES',
    'SETTINGS_UPDATED': 'SETTINGS_UPDATED'
  },
  PayloadSources: {
    'VIEW_ACTION': 'VIEW_ACTION',
    'SERVER_ACTION': 'SERVER_ACTION'
  },
  ComposeActions: {
    'REPLY': 'REPLY',
    'REPLY_ALL': 'REPLY_ALL',
    'FORWARD': 'FORWARD'
  },
  AlertLevel: {
    'SUCCESS': 'SUCCESS',
    'INFO': 'INFO',
    'WARNING': 'WARNING',
    'ERROR': 'ERROR'
  }
};
});

;require.register("initialize", function(exports, require, module) {
window.onload = function() {
  var AccountStore, Application, LayoutStore, MessageStore, Router, SearchStore, SettingsStore, application, err, locale, locales, polyglot;
  window.__DEV__ = window.location.hostname === 'localhost';
  locale = window.locale || window.navigator.language || "en";
  moment.locale(locale);
  locales = {};
  try {
    locales = require("./locales/" + locale);
  } catch (_error) {
    err = _error;
    console.log(err);
    locales = require("./locales/en");
  }
  polyglot = new Polyglot();
  polyglot.extend(locales);
  window.t = polyglot.t.bind(polyglot);
  AccountStore = require('./stores/AccountStore');
  LayoutStore = require('./stores/LayoutStore');
  MessageStore = require('./stores/MessageStore');
  SettingsStore = require('./stores/SettingsStore');
  SearchStore = require('./stores/SearchStore');
  Router = require('./router');
  this.router = new Router();
  window.router = this.router;
  Application = require('./components/application');
  application = Application({
    router: this.router
  });
  React.renderComponent(application, document.body);
  Backbone.history.start();
  if (typeof Object.freeze === 'function') {
    return Object.freeze(this);
  }
};
});

;require.register("libs/PanelRouter", function(exports, require, module) {

/*
    Routing component. We let Backbone handling browser stuff
    and we format the varying parts of the layout.

    URLs are built in the following way:
        - a first part that represents the first panel
        - a second part that represents the second panel
        - if there is just one part, it represents a full width panel

    Since Backbone.Router only handles one part, routes initialization mechanism
    is overriden so we can post-process the second part of the URL.

    Example: a defined pattern will generates two routes.
        - `mailbox/a/path/:id`
        - `mailbox/a/path/:id/*secondPanel`

        Each pattern is actually the pattern itself plus the pattern itself and
        another pattern.
 */
var LayoutActionCreator, Router,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LayoutActionCreator = require('../actions/LayoutActionCreator');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.patterns = {};

  Router.prototype.routes = {};

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
      this.routes["" + route.pattern + "/*secondPanel"] = key;
    }
    this._bindRoutes();
    return this.on('route', (function(_this) {
      return function(name, args) {
        var firstAction, firstPanelInfo, secondAction, secondPanelInfo, _ref1;
        _ref1 = _this._processSubRouting(name, args), firstPanelInfo = _ref1[0], secondPanelInfo = _ref1[1];
        firstAction = _this.fluxActionFactory(firstPanelInfo);
        secondAction = _this.fluxActionFactory(secondPanelInfo);
        _this.previous = _this.current;
        _this.current = {
          firstPanel: firstPanelInfo,
          secondPanel: secondPanelInfo
        };
        if (firstAction != null) {
          firstAction(firstPanelInfo, 'first');
        }
        if (secondAction != null) {
          secondAction(secondPanelInfo, 'second');
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
      fluxAction = LayoutActionCreator[pattern.fluxAction];
      if (fluxAction == null) {
        console.warn(("`" + pattern.fluxAction + "` method not found in ") + "layout actions.");
      }
      return fluxAction;
    }
  };


  /*
      Extracts and matches the second part of the URl if it exists.
   */

  Router.prototype._processSubRouting = function(name, args) {
    var firstPanelInfo, firstPanelParameters, params, route, secondPanelInfo, secondPanelString;
    args.pop();
    secondPanelString = args.pop();
    params = this.patterns[name].pattern.match(/:[\w]+/g) || [];
    if (params.length > args.length && (secondPanelString != null)) {
      args.push(secondPanelString);
      secondPanelString = null;
    }
    firstPanelParameters = args;
    route = _.first(_.filter(this.cachedPatterns, function(element) {
      return element.pattern.test(secondPanelString);
    }));
    if (route != null) {
      args = this._extractParameters(route.pattern, secondPanelString);
      args.pop();
      secondPanelInfo = {
        action: route.key,
        parameters: args
      };
    } else {
      secondPanelInfo = null;
    }
    firstPanelInfo = {
      action: name,
      parameters: firstPanelParameters
    };
    return [firstPanelInfo, secondPanelInfo];
  };


  /*
      Builds a route from panel information.
      Two modes:
          - options has firstPanel and/or secondPanel attributes with the
            panel(s) information.
          - options has the panel information along a `direction` attribute
            that can be `first` or `second`. It's the short version.
   */

  Router.prototype.buildUrl = function(options) {
    var firstPanelInfo, firstPart, isFirstDirection, secondPanelInfo, secondPart, url;
    if ((options.firstPanel != null) || (options.secondPanel != null)) {
      firstPanelInfo = options.firstPanel || this.current.firstPanel;
      secondPanelInfo = options.secondPanel || this.current.secondPanel;
    } else {
      if (options.direction != null) {
        if (options.direction === 'first') {
          firstPanelInfo = options;
          secondPanelInfo = this.current.secondPanel;
        } else if (options.direction === 'second') {
          firstPanelInfo = this.current.firstPanel;
          secondPanelInfo = options;
        } else {
          console.warn('`direction` should be `first`, `second`.');
        }
      } else {
        console.warn('`direction` parameter is mandatory when ' + 'using short call.');
      }
    }
    isFirstDirection = (options.firstPanel != null) || options.direction === 'first';
    if (isFirstDirection && options.fullWidth) {
      if ((options.secondPanel != null) && options.direction === 'second') {
        console.warn("You shouldn't use the fullWidth option with " + "a second panel");
      }
      secondPanelInfo = null;
    }
    firstPart = this._getURLFromRoute(firstPanelInfo);
    secondPart = this._getURLFromRoute(secondPanelInfo);
    url = "#" + firstPart;
    if ((secondPart != null) && secondPart.length > 0) {
      url = "" + url + "/" + secondPart;
    }
    return url;
  };


  /*
      Closes a panel given a direction. If a full-width panel is closed,
      the URL points to the default route.
   */

  Router.prototype.buildClosePanelUrl = function(direction) {
    var panelInfo;
    if (direction === 'first' || direction === 'full') {
      panelInfo = _.clone(this.current.secondPanel);
    } else {
      panelInfo = _.clone(this.current.firstPanel);
    }
    if (panelInfo != null) {
      panelInfo.direction = 'first';
      panelInfo.fullWidth = true;
      return this.buildUrl(panelInfo);
    } else {
      return '#';
    }
  };

  Router.prototype._getURLFromRoute = function(panel) {
    var defaultParameter, defaultParameters, filledPattern, key, paramInPattern, paramValue, parametersInPattern, pattern, _i, _j, _len, _len1;
    panel = _.clone(panel);
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
      if (panel.parameters) {
        for (key = _j = 0, _len1 = parametersInPattern.length; _j < _len1; key = ++_j) {
          paramInPattern = parametersInPattern[key];
          paramValue = panel.parameters[key];
          filledPattern = filledPattern.replace(paramInPattern, paramValue);
        }
      }
      return filledPattern;
    } else {
      return '';
    }
  };

  return Router;

})(Backbone.Router);
});

;require.register("libs/flux/dispatcher/Dispatcher", function(exports, require, module) {

/*

    -- Coffee port of Facebook's flux dispatcher. It was in ES6 and I haven't been
    successful in adding a transpiler. --

    Copyright (c) 2014, Facebook, Inc.
    All rights reserved.

    This source code is licensed under the BSD-style license found in the
    LICENSE file in the root directory of this source tree. An additional grant
    of patent rights can be found in the PATENTS file in the same directory.
 */
var Dispatcher, invariant, _lastID, _prefix;

invariant = require('../invariant');

_lastID = 1;

_prefix = 'ID_';

module.exports = Dispatcher = Dispatcher = (function() {
  function Dispatcher() {
    this._callbacks = {};
    this._isPending = {};
    this._isHandled = {};
    this._isDispatching = false;
    this._pendingPayload = null;
  }


  /*
      Registers a callback to be invoked with every dispatched payload. Returns
      a token that can be used with `waitFor()`.
  
      @param {function} callback
      @return {string}
   */

  Dispatcher.prototype.register = function(callback) {
    var id;
    id = _prefix + _lastID++;
    this._callbacks[id] = callback;
    return id;
  };


  /*
      Removes a callback based on its token.
  
      @param {string} id
   */

  Dispatcher.prototype.unregister = function(id) {
    invariant(this._callbacks[id], 'Dispatcher.unregister(...): `%s` does not map to a registered callback.', id);
    return delete this._callbacks[id];
  };


  /*
      Waits for the callbacks specified to be invoked before continuing execution
      of the current callback. This method should only be used by a callback in
      response to a dispatched payload.
  
      @param {array<string>} ids
   */

  Dispatcher.prototype.waitFor = function(ids) {
    var id, ii, _i, _ref, _results;
    invariant(this._isDispatching, 'Dispatcher.waitFor(...): Must be invoked while dispatching.');
    _results = [];
    for (ii = _i = 0, _ref = ids.length - 1; _i <= _ref; ii = _i += 1) {
      id = ids[ii];
      if (this._isPending[id]) {
        invariant(this._isHandled[id], 'Dispatcher.waitFor(...): Circular dependency detected while waiting for `%s`.', id);
        continue;
      }
      invariant(this._callbacks[id], 'Dispatcher.waitFor(...): `%s` does not map to a registered callback.', id);
      _results.push(this._invokeCallback(id));
    }
    return _results;
  };


  /*
      Dispatches a payload to all registered callbacks.
  
      @param {object} payload
   */

  Dispatcher.prototype.dispatch = function(payload) {
    var id, _results;
    invariant(!this._isDispatching, 'Dispatch.dispatch(...): Cannot dispatch in the middle of a dispatch.');
    this._startDispatching(payload);
    try {
      _results = [];
      for (id in this._callbacks) {
        if (this._isPending[id]) {
          continue;
        }
        _results.push(this._invokeCallback(id));
      }
      return _results;
    } finally {
      this._stopDispatching();
    }
  };


  /*
      Is this Dispatcher currently dispatching.
  
      @return {boolean}
   */

  Dispatcher.prototype.isDispatching = function() {
    return this._isDispatching;
  };


  /*
      Call the callback stored with the given id. Also do some internal
      bookkeeping.
  
      @param {string} id
      @internal
   */

  Dispatcher.prototype._invokeCallback = function(id) {
    this._isPending[id] = true;
    this._callbacks[id](this._pendingPayload);
    return this._isHandled[id] = true;
  };


  /*
      Set up bookkeeping needed when dispatching.
  
      @param {object} payload
      @internal
   */

  Dispatcher.prototype._startDispatching = function(payload) {
    var id;
    for (id in this._callbacks) {
      this._isPending[id] = false;
      this._isHandled[id] = false;
    }
    this._pendingPayload = payload;
    return this._isDispatching = true;
  };


  /*
      Clear bookkeeping used for dispatching.
  
      @internal
   */

  Dispatcher.prototype._stopDispatching = function() {
    this._pendingPayload = null;
    return this._isDispatching = false;
  };

  return Dispatcher;

})();
});

;require.register("libs/flux/invariant", function(exports, require, module) {
/**
 * Copyright (c) 2014, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule invariant
 */

"use strict";

/**
 * Use invariant() to assert state which your program assumes to be true.
 *
 * Provide sprintf-style format (only %s is supported) and arguments
 * to provide information about what broke and what you were
 * expecting.
 *
 * The invariant message will be stripped in production, but the invariant
 * will remain to ensure logic does not differ in production.
 */

var invariant = function(condition, format, a, b, c, d, e, f) {
  if (__DEV__) {
    if (format === undefined) {
      throw new Error('invariant requires an error message argument');
    }
  }

  if (!condition) {
    var error;
    if (format === undefined) {
      error = new Error(
        'Minified exception occurred; use the non-minified dev environment ' +
        'for the full error message and additional helpful warnings.'
      );
    } else {
      var args = [a, b, c, d, e, f];
      var argIndex = 0;
      error = new Error(
        'Invariant Violation: ' +
        format.replace(/%s/g, function() { return args[argIndex++]; })
      );
    }

    error.framesToPop = 1; // we don't care about invariant's own frame
    throw error;
  }
};

module.exports = invariant;
});

;require.register("libs/flux/store/Store", function(exports, require, module) {
var AppDispatcher, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

AppDispatcher = require('../../../AppDispatcher');

module.exports = Store = (function(_super) {
  var _addHandlers, _handlers, _nextUniqID, _processBinding;

  __extends(Store, _super);

  Store.prototype.uniqID = null;

  _nextUniqID = 0;

  _handlers = {};

  _addHandlers = function(type, callback) {
    if (_handlers[this.uniqID] == null) {
      _handlers[this.uniqID] = {};
    }
    return _handlers[this.uniqID][type] = callback;
  };

  _processBinding = function() {
    return this.dispatchToken = AppDispatcher.register((function(_this) {
      return function(payload) {
        var callback, type, value, _ref;
        _ref = payload.action, type = _ref.type, value = _ref.value;
        if ((callback = _handlers[_this.uniqID][type]) != null) {
          return callback.call(_this, value);
        }
      };
    })(this));
  };

  function Store() {
    Store.__super__.constructor.call(this);
    this.uniqID = _nextUniqID++;
    this.__bindHandlers(_addHandlers.bind(this));
    _processBinding.call(this);
  }

  Store.prototype.__bindHandlers = function(handle) {
    if (__DEV__) {
      throw new Error("The store " + this.constructor.name + " must define a `__bindHandlers` method");
    }
  };

  return Store;

})(EventEmitter);
});

;require.register("locales/en", function(exports, require, module) {
module.exports = {
  "app loading": "Loading…",
  "app back": "Back",
  "app menu": "Menu",
  "app search": "Search…",
  "app alert close": "Close",
  "app unimplemented": "Not implemented yet",
  "compose": "Compose new email",
  "compose default": 'Hello, how are you doing today ?',
  "compose from": "From",
  "compose to": "To",
  "compose to help": "Recipients list",
  "compose cc": "Cc",
  "compose cc help": "Copy list",
  "compose bcc": "Bcc",
  "compose bcc help": "Hidden copy list",
  "compose subject": "Subject",
  "compose subject help": "Message subject",
  "compose reply prefix": "Re: ",
  "compose reply separator": "\n\nOn %{date}, %{sender} wrote \n",
  "compose forward prefix": "Fwd: ",
  "compose forward separator": "\n\nOn %{date}, %{sender} wrote \n",
  "compose action draft": "Save draft",
  "compose action send": "Send",
  "menu compose": "Compose",
  "menu account new": "New account",
  "menu settings": "Paramètres",
  "list empty": "No email in this box.",
  "list search empty": "No result found for the query \"%{query}\".",
  "list count": "%{smart_count} message in this box |||| %{smart_count} messages in this box",
  "list search count": "%{smart_count} result found. |||| %{smart_count} results found.",
  "mail receivers": "To %{dest}",
  "mail receivers cc": "Cc %{dest}",
  "mail action reply": "Reply",
  "mail action reply all": "Reply all",
  "mail action forward": "Forward",
  "mail action delete": "Delete",
  "mail action mark": "Mark as…",
  "mail action copy": "Copy…",
  "mail action move": "Move…",
  "mail mark spam": "Spam",
  "mail mark nospam": "No spam",
  "mail mark fav": "Important",
  "mail mark nofav": "Not important",
  "mail mark read": "Read",
  "mail mark unread": "Not read",
  "mailbox new": "New account",
  "mailbox edit": "Edit account",
  "mailbox add": "Add",
  "mailbox label": "Label",
  "mailbox name short": "A short mailbox name",
  "mailbox user name": "Your name",
  "mailbox user fullname": "Your name, as it will be displayed",
  "mailbox address": "Email address",
  "mailbox address placeholder": "Your email address",
  "mailbox password": "Password",
  "mailbox sending server": "Sending server",
  "mailbox receiving server": "IMAP server",
  "mailbox remove": "Remove",
  "message action sent ok": "Message sent",
  "message action sent ko": "Error sending message: ",
  "settings title": "Settings",
  "settings button save": "Save",
  "settings label mpp": "Messages per page",
  "settings label compose": "Rich message editor"
};
});

;require.register("locales/fr", function(exports, require, module) {
module.exports = {
  "app loading": "Chargement…",
  "app back": "Retour",
  "app menu": "Menu",
  "app search": "Rechercher…",
  "app alert close": "Fermer",
  "app unimplemented": "Non implémenté",
  "compose": "Écrire un nouveau message",
  "compose default": "Bonjour, comment ça va ?",
  "compose from": "De",
  "compose to": "À",
  "compose to help": "Liste des destinataires principaux",
  "compose cc": "Cc",
  "compose cc help": "Liste des destinataires en copie",
  "compose bcc": "Cci",
  "compose bcc help": "Liste des destinataires en copie caché",
  "compose subject": "Objet",
  "compose subject help": "Objet du message",
  "compose reply prefix": "Re: ",
  "compose reply separator": "\n\nLe %{date}, %{sender} a écrit \n",
  "compose forward prefix": "Fwd: ",
  "compose forward separator": "\n\nLe %{date}, %{sender} a écrit \n",
  "compose action draft": "Save as draft",
  "compose action send": "Send",
  "menu compose": "Nouveau",
  "menu account new": "Ajouter un compte",
  "menu settings": "Paramètres",
  "list empty": "Pas d'email dans cette boîte..",
  "list search empty": "Aucun résultat trouvé pour la requête \"%{query}\".",
  "list count": "%{smart_count} message dans cette boite |||| %{smart_count} messages dans cette boite",
  "list search count": "%{smart_count} résultat trouvé. |||| %{smart_count} résultats trouvés.",
  "mail receivers": "À %{dest}",
  "mail receivers cc": "Copie %{dest}",
  "mail action reply": "Répondre",
  "mail action reply all": "Répondre à tous",
  "mail action forward": "Transférer",
  "mail action delete": "Supprimer",
  "mail action mark": "Marquer comme",
  "mail action copy": "Copier…",
  "mail action move": "Déplacer…",
  "mail mark spam": "Pourriel",
  "mail mark nospam": "Légitime",
  "mail mark fav": "Important",
  "mail mark nofav": "Normal",
  "mail mark read": "Lu",
  "mail mark unread": "Non lu",
  "mailbox new": "Nouveau compte",
  "mailbox edit": "Modifier le compte",
  "mailbox add": "Créer",
  "mailbox label": "Nom",
  "mailbox name short": "Nom abbrégé",
  "mailbox user name": "Votre nom",
  "mailbox user fullname": "Votre nom, tel qu'il sera affiché",
  "mailbox address": "Adresse",
  "mailbox address placeholder": "Votre adresse électronique",
  "mailbox password": "Maot de passe",
  "mailbox sending server": "Serveur sortant",
  "mailbox receiving server": "Serveur IMAP",
  "mailbox remove": "Supprimer",
  "message action sent ok": "Message envoyé !",
  "message action sent ko": "Une erreur est survenue : ",
  "settings title": "Paramètres",
  "settings button save": "Enregistrer",
  "settings label mpp": "Nombre de messages par page",
  "settings label compose": "Éditeur riche"
};
});

;require.register("mixins/RouterMixin", function(exports, require, module) {

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
  },
  redirect: function(options) {
    var url;
    url = typeof options === "string" ? options : this.buildUrl(options);
    return router.navigate(url, true);
  }
};
});

;require.register("mixins/StoreWatchMixin", function(exports, require, module) {
var StoreWatchMixin;

module.exports = StoreWatchMixin = function(stores) {
  return {
    componentDidMount: function() {
      return stores.forEach((function(_this) {
        return function(store) {
          return store.on('change', _this._setStateFromStores);
        };
      })(this));
    },
    componentWillUnmount: function() {
      return stores.forEach((function(_this) {
        return function(store) {
          return store.removeListener('change', _this._setStateFromStores);
        };
      })(this));
    },
    getInitialState: function() {
      return this.getStateFromStores();
    },
    _setStateFromStores: function() {
      return this.setState(this.getStateFromStores());
    }
  };
};
});

;require.register("router", function(exports, require, module) {
var AccountStore, PanelRouter, Router,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

PanelRouter = require('./libs/PanelRouter');

AccountStore = require('./stores/AccountStore');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.patterns = {
    'account.config': {
      pattern: 'account/:id/config',
      fluxAction: 'showConfigAccount'
    },
    'account.new': {
      pattern: 'account/new',
      fluxAction: 'showCreateAccount'
    },
    'account.mailbox.messages': {
      pattern: 'account/:id/mailbox/:mailbox/page/:page',
      fluxAction: 'showMessageList'
    },
    'search': {
      pattern: 'search/:query/page/:page',
      fluxAction: 'showSearch'
    },
    'message': {
      pattern: 'message/:id',
      fluxAction: 'showConversation'
    },
    'compose': {
      pattern: 'compose',
      fluxAction: 'showComposeNewMessage'
    },
    'settings': {
      pattern: 'settings',
      fluxAction: 'showSettings'
    }
  };

  Router.prototype.routes = {
    '': 'account.mailbox.messages'
  };

  Router.prototype._getDefaultParameters = function(action) {
    var defaultAccount, defaultMailbox, defaultParameters, _ref;
    switch (action) {
      case 'account.mailbox.messages':
        defaultAccount = AccountStore.getDefault();
        defaultMailbox = defaultAccount != null ? defaultAccount.get('mailboxes').first() : void 0;
        defaultParameters = [defaultAccount != null ? defaultAccount.get('id') : void 0, defaultMailbox != null ? defaultMailbox.get('id') : void 0, 1];
        break;
      case 'account.config':
        defaultAccount = (_ref = AccountStore.getDefault()) != null ? _ref.get('id') : void 0;
        defaultParameters = [defaultAccount];
        break;
      case 'search':
        defaultParameters = ["", 1];
        break;
      default:
        defaultParameters = null;
    }
    return defaultParameters;
  };

  return Router;

})(PanelRouter);
});

;require.register("stores/AccountStore", function(exports, require, module) {
var AccountStore, AccountTranslator, ActionTypes, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/Store');

ActionTypes = require('../constants/AppConstants').ActionTypes;

AccountTranslator = require('../utils/translators/AccountTranslator');

AccountStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _accounts, _newAccountError, _newAccountWaiting, _selectedAccount;

  __extends(AccountStore, _super);

  function AccountStore() {
    return AccountStore.__super__.constructor.apply(this, arguments);
  }

  _accounts = Immutable.Sequence(window.accounts).sort(function(mb1, mb2) {
    if (mb1.label > mb2.label) {
      return 1;
    } else if (mb1.label < mb2.label) {
      return -1;
    } else {
      return 0;
    }
  }).mapKeys(function(_, account) {
    return account.id;
  }).map(function(account) {
    return AccountTranslator.toImmutable(account);
  }).toOrderedMap();

  _selectedAccount = null;

  _newAccountWaiting = false;

  _newAccountError = null;


  /*
      Defines here the action handlers.
   */

  AccountStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.ADD_ACCOUNT, function(account) {
      account = _makeAccountImmutable(account);
      _accounts = _accounts.set(account.get('id'), account);
      return this.emit('change');
    });
    handle(ActionTypes.SELECT_ACCOUNT, function(accountID) {
      _selectedAccount = _accounts.get(accountID) || null;
      return this.emit('change');
    });
    handle(ActionTypes.NEW_ACCOUNT_WAITING, function(payload) {
      _newAccountWaiting = payload;
      return this.emit('change');
    });
    handle(ActionTypes.NEW_ACCOUNT_ERROR, function(error) {
      _newAccountError = error;
      return this.emit('change');
    });
    handle(ActionTypes.EDIT_ACCOUNT, function(rawAccount) {
      var account;
      account = AccountTranslator.toImmutable(rawAccount);
      _accounts = _accounts.set(account.get('id'), account);
      _selectedAccount = _accounts.get(account.get('id'));
      return this.emit('change');
    });
    return handle(ActionTypes.REMOVE_ACCOUNT, function(accountID) {
      _accounts = _accounts["delete"](accountID);
      _selectedAccount = this.getDefault();
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  AccountStore.prototype.getAll = function() {
    return _accounts;
  };

  AccountStore.prototype.getByID = function(accountID) {
    return _accounts.get(accountID);
  };

  AccountStore.prototype.getDefault = function() {
    return _accounts.first() || null;
  };

  AccountStore.prototype.getDefaultMailbox = function(accountID) {
    var account;
    account = _accounts.get(accountID) || this.getDefault();
    return account.get('mailboxes').first();
  };

  AccountStore.prototype.getSelected = function() {
    return _selectedAccount;
  };

  AccountStore.prototype.getSelectedMailboxes = function(flatten) {
    var getFlattenMailboxes, rawMailboxesTree;
    if (flatten == null) {
      flatten = false;
    }
    if (_selectedAccount == null) {
      return Immutable.OrderedMap.empty();
    }
    if (flatten) {
      rawMailboxesTree = _selectedAccount.get('mailboxes').toJS();
      getFlattenMailboxes = function(childrenMailboxes, depth) {
        var children, id, mailbox, rawMailbox, result;
        if (depth == null) {
          depth = 0;
        }
        result = Immutable.OrderedMap();
        for (id in childrenMailboxes) {
          rawMailbox = childrenMailboxes[id];
          children = rawMailbox.children;
          delete rawMailbox.children;
          mailbox = Immutable.Map(rawMailbox);
          mailbox = mailbox.set('depth', depth);
          result = result.set(mailbox.get('id'), mailbox);
          result = result.merge(getFlattenMailboxes(children, depth + 1));
        }
        return result.toOrderedMap();
      };
      return getFlattenMailboxes(rawMailboxesTree).toOrderedMap();
    } else {
      return (_selectedAccount != null ? _selectedAccount.get('mailboxes') : void 0) || Immutable.OrderedMap.empty();
    }
  };

  AccountStore.prototype.getSelectedMailbox = function(selectedID) {
    var mailboxes;
    mailboxes = this.getSelectedMailboxes();
    if (selectedID != null) {
      return mailboxes.get(selectedID);
    } else {
      return mailboxes.first();
    }
  };

  AccountStore.prototype.getSelectedFavorites = function() {
    return this.getSelectedMailboxes().skip(1).take(3).toOrderedMap();
  };

  AccountStore.prototype.getError = function() {
    return _newAccountError;
  };

  AccountStore.prototype.isWaiting = function() {
    return _newAccountWaiting;
  };

  return AccountStore;

})(Store);

module.exports = new AccountStore();
});

;require.register("stores/LayoutStore", function(exports, require, module) {
var ActionTypes, LayoutStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/Store');

ActionTypes = require('../constants/AppConstants').ActionTypes;

LayoutStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _alert, _responsiveMenuShown;

  __extends(LayoutStore, _super);

  function LayoutStore() {
    return LayoutStore.__super__.constructor.apply(this, arguments);
  }

  _responsiveMenuShown = false;

  _alert = {
    level: null,
    message: null
  };


  /*
      Defines here the action handlers.
   */

  LayoutStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.SHOW_MENU_RESPONSIVE, function() {
      _responsiveMenuShown = true;
      return this.emit('change');
    });
    handle(ActionTypes.HIDE_MENU_RESPONSIVE, function() {
      _responsiveMenuShown = false;
      return this.emit('change');
    });
    return handle(ActionTypes.DISPLAY_ALERT, function(value) {
      _alert.level = value.level;
      _alert.message = value.message;
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  LayoutStore.prototype.isMenuShown = function() {
    return _responsiveMenuShown;
  };

  LayoutStore.prototype.getAlert = function() {
    return _alert;
  };

  return LayoutStore;

})(Store);

module.exports = new LayoutStore();
});

;require.register("stores/MessageStore", function(exports, require, module) {
var AccountStore, ActionTypes, AppDispatcher, LayoutActionCreator, MessageStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Store = require('../libs/flux/store/Store');

AppDispatcher = require('../AppDispatcher');

AccountStore = require('./AccountStore');

ActionTypes = require('../constants/AppConstants').ActionTypes;

LayoutActionCreator = require('../actions/LayoutActionCreator');

MessageStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _messages;

  __extends(MessageStore, _super);

  function MessageStore() {
    return MessageStore.__super__.constructor.apply(this, arguments);
  }

  _messages = Immutable.Sequence().mapKeys(function(_, message) {
    return message.id;
  }).map(function(message) {
    return Immutable.fromJS(message);
  }).toOrderedMap();


  /*
      Defines here the action handlers.
   */

  MessageStore.prototype.__bindHandlers = function(handle) {
    var onReceiveRawMessage;
    handle(ActionTypes.RECEIVE_RAW_MESSAGE, onReceiveRawMessage = function(message, silent) {
      if (silent == null) {
        silent = false;
      }
      message = Immutable.Map(message);
      message.getReplyToAddress = function() {
        var reply;
        reply = this.get('replyTo');
        reply = reply.length === 0 ? this.get('from') : reply;
        return reply;
      };
      _messages = _messages.set(message.get('id'), message);
      if (!silent) {
        return this.emit('change');
      }
    });
    handle(ActionTypes.RECEIVE_RAW_MESSAGES, function(messages) {
      var message, _i, _len;
      for (_i = 0, _len = messages.length; _i < _len; _i++) {
        message = messages[_i];
        onReceiveRawMessage(message, true);
      }
      return this.emit('change');
    });
    handle(ActionTypes.REMOVE_ACCOUNT, function(accountID) {
      var messages;
      AppDispatcher.waitFor([AccountStore.dispatchToken]);
      messages = this.getMessagesByAccount(accountID);
      _messages = _messages.withMutations(function(map) {
        return messages.forEach(function(message) {
          return map.remove(message.get('id'));
        });
      });
      return this.emit('change');
    });
    return handle(ActionTypes.SEND_MESSAGE, function(message) {
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  MessageStore.prototype.getAll = function() {
    return _messages;
  };

  MessageStore.prototype.getByID = function(messageID) {
    return _messages.get(messageID) || null;
  };


  /**
  * Get messages from account, with optional pagination
  *
  * @param {String} accountID
  * @param {Number} first     index of first message
  * @param {Number} last      index of last message
  *
  * @return {Array}
   */

  MessageStore.prototype.getMessagesByAccount = function(accountID, first, last) {
    var sequence;
    if (first == null) {
      first = null;
    }
    if (last == null) {
      last = null;
    }
    sequence = _messages.filter(function(message) {
      return message.get('account') === accountID;
    });
    if ((first != null) && (last != null)) {
      sequence = sequence.slice(first, last);
    }
    return sequence.toOrderedMap();
  };

  MessageStore.prototype.getMessagesCountByAccount = function(accountID) {
    return this.getMessagesByAccount(accountID).count();
  };


  /**
  * Get messages from mailbox, with optional pagination
  *
  * @param {String} mailboxID
  * @param {Number} first     index of first message
  * @param {Number} last      index of last message
  *
  * @return {Array}
   */

  MessageStore.prototype.getMessagesByMailbox = function(mailboxID, first, last) {
    var sequence;
    if (first == null) {
      first = null;
    }
    if (last == null) {
      last = null;
    }
    sequence = _messages.filter(function(message) {
      return __indexOf.call(Object.keys(message.get('mailboxIDs')), mailboxID) >= 0;
    });
    if ((first != null) && (last != null)) {
      sequence = sequence.slice(first, last);
    }
    return sequence.toOrderedMap();
  };

  MessageStore.prototype.getMessagesCountByMailbox = function(mailboxID) {
    return this.getMessagesByMailbox(mailboxID).count();
  };

  MessageStore.prototype.getMessagesByConversation = function(messageID) {
    var conversation, idToLook, idsToLook, temp;
    idsToLook = [messageID];
    conversation = [];
    while (idToLook = idsToLook.pop()) {
      conversation.push(this.getByID(idToLook));
      temp = _messages.filter(function(message) {
        return message.get('inReplyTo') === idToLook;
      });
      idsToLook = idsToLook.concat(temp.map(function(item) {
        return item.get('id');
      }).toArray());
    }
    return conversation;
  };

  return MessageStore;

})(Store);

module.exports = new MessageStore();
});

;require.register("stores/SearchStore", function(exports, require, module) {
var ActionTypes, SearchStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/Store');

ActionTypes = require('../constants/AppConstants').ActionTypes;

SearchStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _query, _results;

  __extends(SearchStore, _super);

  function SearchStore() {
    return SearchStore.__super__.constructor.apply(this, arguments);
  }

  _query = "";

  _results = Immutable.OrderedMap.empty();


  /*
      Defines here the action handlers.
   */

  SearchStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.RECEIVE_RAW_SEARCH_RESULTS, function(rawResults) {
      _results = _results.withMutations(function(map) {
        return rawResults.forEach(function(rawResult) {
          var message;
          message = Immutable.Map(rawResult);
          return map.set(message.get('id'), message);
        });
      });
      return this.emit('change');
    });
    handle(ActionTypes.CLEAR_SEARCH_RESULTS, function() {
      _results = Immutable.OrderedMap.empty();
      return this.emit('change');
    });
    return handle(ActionTypes.SET_SEARCH_QUERY, function(query) {
      _query = query;
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  SearchStore.prototype.getResults = function() {
    return _results;
  };

  SearchStore.prototype.getQuery = function() {
    return _query;
  };

  return SearchStore;

})(Store);

module.exports = new SearchStore();
});

;require.register("stores/SettingsStore", function(exports, require, module) {
var ActionTypes, SettingsStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/Store');

ActionTypes = require('../constants/AppConstants').ActionTypes;

SettingsStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _settings;

  __extends(SettingsStore, _super);

  function SettingsStore() {
    return SettingsStore.__super__.constructor.apply(this, arguments);
  }

  _settings = Immutable.Map({
    messagesPerPage: 5,
    displayConversation: false,
    composeInHTML: true
  });


  /*
      Defines here the action handlers.
   */

  SettingsStore.prototype.__bindHandlers = function(handle) {
    return handle(ActionTypes.SETTINGS_UPDATED, function(settings) {
      _settings = Immutable.Map(settings);
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  SettingsStore.prototype.get = function(settingName) {
    if (settingName == null) {
      settingName = null;
    }
    if (settingName != null) {
      return _settings.get(settingName);
    } else {
      return _settings;
    }
  };

  return SettingsStore;

})(Store);

module.exports = new SettingsStore();
});

;require.register("utils/MessageUtils", function(exports, require, module) {
module.exports = {
  displayAddresses: function(addresses, full) {
    var item, res, _i, _len;
    if (full == null) {
      full = false;
    }
    res = [];
    for (_i = 0, _len = addresses.length; _i < _len; _i++) {
      item = addresses[_i];
      if (full) {
        if (item.name != null) {
          res.push("\"" + item.name + "\" <" + item.address + ">");
        } else {
          res.push("<" + item.address + ">");
        }
      } else {
        if (item.name != null) {
          res.push(item.name);
        } else {
          res.push(item.address.split('@')[0]);
        }
      }
    }
    return res.join(", ");
  },
  generateReplyText: function(text) {
    var res;
    text = text.split('\n');
    res = [];
    text.forEach(function(line) {
      return res.push("> " + line);
    });
    return res.join("\n");
  }
};
});

;require.register("utils/XHRUtils", function(exports, require, module) {
var AccountTranslator, SettingsStore, request;

request = superagent;

AccountTranslator = require('./translators/AccountTranslator');

SettingsStore = require('../stores/SettingsStore');

module.exports = {
  fetchConversation: function(emailID, callback) {
    return request.get("message/" + emailID).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback("Something went wrong -- " + res.body);
      }
    });
  },
  fetchMessagesByFolder: function(mailboxID, numPage, callback) {
    var numByPage;
    numByPage = SettingsStore.get('messagesPerPage');
    return request.get("mailbox/" + mailboxID + "/page/" + numPage + "/limit/" + numByPage).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback("Something went wrong -- " + res.body);
      }
    });
  },
  messageSend: function(message, callback) {
    return request.post("/message").send(message).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback("Something went wrong -- " + res.body);
      }
    });
  },
  createAccount: function(account, callback) {
    return request.post('account').send(account).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback(res.body, null);
      }
    });
  },
  editAccount: function(account, callback) {
    var rawAccount;
    rawAccount = AccountTranslator.toRawObject(account);
    return request.put("account/" + rawAccount.id).send(rawAccount).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback(res.body, null);
      }
    });
  },
  removeAccount: function(accountID) {
    return request.del("account/" + accountID).set('Accept', 'application/json').end(function(res) {});
  },
  search: function(query, numPage, callback) {
    var encodedQuery, numByPage;
    encodedQuery = encodeURIComponent(query);
    numByPage = SettingsStore.get('messagesPerPage');
    return request.get("search/" + encodedQuery + "/page/" + numPage + "/limit/" + numByPage).end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback(res.body, null);
      }
    });
  }
};
});

;require.register("utils/translators/AccountTranslator", function(exports, require, module) {
var toRawObject;

module.exports = {
  toImmutable: function(rawAccount) {
    var _createImmutableMailboxes;
    _createImmutableMailboxes = function(children) {
      return Immutable.Sequence(children).mapKeys(function(_, mailbox) {
        return mailbox.id;
      }).map(function(mailbox) {
        mailbox.children = _createImmutableMailboxes(mailbox.children);
        return Immutable.Map(mailbox);
      }).toOrderedMap();
    };
    rawAccount.mailboxes = _createImmutableMailboxes(rawAccount.mailboxes);
    return Immutable.Map(rawAccount);
  },
  toRawObject: toRawObject = function(account) {
    var _createRawObjectMailboxes;
    _createRawObjectMailboxes = function(children) {
      return children != null ? children.map(function(child) {
        return child.set('children', _createRawObjectMailboxes(child.get('children')));
      }).toVector() : void 0;
    };
    account = account.set('mailboxes', _createRawObjectMailboxes(account.get('mailboxes')));
    return account.toJS();
  }
};
});

;
//# sourceMappingURL=app.js.map