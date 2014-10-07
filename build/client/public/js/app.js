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
require.register("actions/account_action_creator", function(exports, require, module) {
var AccountActionCreator, AccountStore, ActionTypes, AppDispatcher, XHRUtils;

XHRUtils = require('../utils/xhr_utils');

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

AccountStore = require('../stores/account_store');

module.exports = AccountActionCreator = {
  create: function(inputValues) {
    AccountActionCreator._setNewAccountWaitingStatus(true);
    return XHRUtils.createAccount(inputValues, function(error, account) {
      AccountActionCreator._setNewAccountWaitingStatus(false);
      console.log("THERE", account);
      if ((error != null) || (account == null)) {
        return AccountActionCreator._setNewAccountError(error);
      } else {
        return AppDispatcher.handleViewAction({
          type: ActionTypes.ADD_ACCOUNT,
          value: account
        });
      }
    });
  },
  edit: function(inputValues, accountID) {
    var account, newAccount;
    AccountActionCreator._setNewAccountWaitingStatus(true);
    account = AccountStore.getByID(accountID);
    newAccount = account.mergeDeep(inputValues);
    return XHRUtils.editAccount(newAccount, function(error, rawAccount) {
      AccountActionCreator._setNewAccountWaitingStatus(false);
      if (error != null) {
        return AccountActionCreator._setNewAccountError(error);
      } else {
        return AppDispatcher.handleViewAction({
          type: ActionTypes.EDIT_ACCOUNT,
          value: rawAccount
        });
      }
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
  },
  discover: function(domain, callback) {
    return XHRUtils.accountDiscover(domain, function(err, infos) {
      if (infos == null) {
        infos = [];
      }
      return callback(err, infos);
    });
  }
};
});

;require.register("actions/conversation_action_creator", function(exports, require, module) {
var ActionTypes, AppDispatcher, MessageFlags, XHRUtils;

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

XHRUtils = require('../utils/xhr_utils');

MessageFlags = require('../constants/app_constants').MessageFlags;

module.exports = {
  "delete": function(conversationId, callback) {
    return XHRUtils.conversationDelete(conversationId, function(error, messages) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.RECEIVE_RAW_MESSAGES,
          value: messages
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  move: function(conversationId, to, callback) {
    var conversation, observer, patches;
    conversation = {
      mailboxIDs: []
    };
    observer = jsonpatch.observe(conversation);
    conversation.mailboxIDs.push(to);
    patches = jsonpatch.generate(observer);
    return XHRUtils.conversationPatch(conversationId, patches, function(error, messages) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.RECEIVE_RAW_MESSAGES,
          value: messages
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  seen: function(conversationId, flags, callback) {
    var conversation, observer, patches;
    conversation = {
      flags: []
    };
    observer = jsonpatch.observe(conversation);
    conversation.flags.push(MessageFlags.SEEN);
    patches = jsonpatch.generate(observer);
    return XHRUtils.conversationPatch(conversationId, patches, function(error, messages) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.RECEIVE_RAW_MESSAGES,
          value: messages
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  unseen: function(conversationId, flags, callback) {
    var conversation, observer, patches;
    conversation = {
      flags: [MessageFlags.SEEN]
    };
    observer = jsonpatch.observe(conversation);
    conversation.flags = [];
    patches = jsonpatch.generate(observer);
    return XHRUtils.conversationPatch(conversationId, patches, function(error, messages) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.RECEIVE_RAW_MESSAGES,
          value: messages
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  }
};
});

;require.register("actions/layout_action_creator", function(exports, require, module) {
var AccountActionCreator, AccountStore, ActionTypes, AlertLevel, AppDispatcher, LayoutActionCreator, LayoutStore, MessageActionCreator, SearchActionCreator, XHRUtils, _ref;

XHRUtils = require('../utils/xhr_utils');

AccountStore = require('../stores/account_store');

LayoutStore = require('../stores/layout_store');

AppDispatcher = require('../app_dispatcher');

_ref = require('../constants/app_constants'), ActionTypes = _ref.ActionTypes, AlertLevel = _ref.AlertLevel;

AccountActionCreator = require('./account_action_creator');

MessageActionCreator = require('./message_action_creator');

SearchActionCreator = require('./search_action_creator');

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
    var accountID, mailboxID, page, _ref1;
    LayoutActionCreator.hideReponsiveMenu();
    _ref1 = panelInfo.parameters, accountID = _ref1.accountID, mailboxID = _ref1.mailboxID, page = _ref1.page;
    AccountActionCreator.selectAccount(accountID);
    return XHRUtils.fetchMessagesByFolder(mailboxID, page, function(err, rawMessage) {
      if (err != null) {
        return LayoutActionCreator.alertError(err);
      } else {
        return MessageActionCreator.receiveRawMessages(rawMessage);
      }
    });
  },
  showConversation: function(panelInfo, direction) {
    var messageID;
    LayoutActionCreator.hideReponsiveMenu();
    messageID = panelInfo.parameters.messageID;
    return XHRUtils.fetchConversation(messageID, function(err, rawMessage) {
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
    return AccountActionCreator.selectAccount(panelInfo.parameters.accountID);
  },
  showSearch: function(panelInfo, direction) {
    var page, query, _ref1;
    AccountActionCreator.selectAccount(-1);
    _ref1 = panelInfo.parameters, query = _ref1.query, page = _ref1.page;
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

;require.register("actions/message_action_creator", function(exports, require, module) {
var ActionTypes, AppDispatcher, XHRUtils;

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

XHRUtils = require('../utils/xhr_utils');

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
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.MESSAGE_SEND,
          value: message
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  "delete": function(message, account, callback) {
    var msg, observer, patches, trash;
    trash = account.get('trashMailbox');
    if (trash == null) {
      return LayoutActionCreator.alertError("" + (t("message idelete no trash")) + " " + error);
    } else {
      msg = message.toObject();
      observer = jsonpatch.observe(msg);
      msg.mailboxIDs = {};
      msg.mailboxIDs[trash] = -1;
      patches = jsonpatch.generate(observer);
      return XHRUtils.messagePatch(message.get('id'), patches, function(error, message) {
        if (error == null) {
          AppDispatcher.handleViewAction({
            type: ActionTypes.MESSAGE_DELETE,
            value: message
          });
        }
        if (callback != null) {
          return callback(error);
        }
      });
    }
  },
  move: function(message, from, to, callback) {
    var msg, observer, patches;
    msg = message.toObject();
    observer = jsonpatch.observe(msg);
    delete msg.mailboxIDs[from];
    msg.mailboxIDs[to] = -1;
    patches = jsonpatch.generate(observer);
    return XHRUtils.messagePatch(message.get('id'), patches, function(error, message) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: message
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  updateFlag: function(message, flags, callback) {
    var msg, patches;
    msg = message.toObject();
    patches = jsonpatch.compare({
      flags: msg.flags
    }, {
      flags: flags
    });
    return XHRUtils.messagePatch(message.get('id'), patches, function(error, message) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: message
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  }
};
});

;require.register("actions/search_action_creator", function(exports, require, module) {
var ActionTypes, AppDispatcher, SearchActionCreator;

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

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

;require.register("actions/settings_action_creator", function(exports, require, module) {
var ActionTypes, AppDispatcher, SettingsActionCreator, SettingsStore, XHRUtils;

XHRUtils = require('../utils/xhr_utils');

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

SettingsStore = require('../stores/settings_store');

module.exports = SettingsActionCreator = {
  edit: function(inputValues) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SETTINGS_UPDATED,
      value: inputValues
    });
  }
};
});

;require.register("app_dispatcher", function(exports, require, module) {
var AppDispatcher, Dispatcher, PayloadSources,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Dispatcher = require('./libs/flux/dispatcher/dispatcher');

PayloadSources = require('./constants/app_constants').PayloadSources;


/*
    Custom dispatcher class to add semantic method.
 */

AppDispatcher = (function(_super) {
  __extends(AppDispatcher, _super);

  function AppDispatcher() {
    return AppDispatcher.__super__.constructor.apply(this, arguments);
  }

  AppDispatcher.prototype.handleViewAction = function(action) {
    var domEvent, payload;
    payload = {
      source: PayloadSources.VIEW_ACTION,
      action: action
    };
    this.dispatch(payload);
    domEvent = new CustomEvent(PayloadSources.VIEW_ACTION, {
      detail: action
    });
    return window.dispatchEvent(domEvent);
  };

  AppDispatcher.prototype.handleServerAction = function(action) {
    var domEvent, payload;
    payload = {
      source: PayloadSources.SERVER_ACTION,
      action: action
    };
    this.dispatch(payload);
    domEvent = new CustomEvent(PayloadSources.SERVER_ACTION, {
      detail: action
    });
    return window.dispatchEvent(domEvent);
  };

  return AppDispatcher;

})(Dispatcher);

module.exports = new AppDispatcher();
});

;require.register("components/account-config", function(exports, require, module) {
var AccountActionCreator, AccountStore, MailboxList, StoreWatchMixin, button, classer, div, form, h3, input, label, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button;

classer = React.addons.classSet;

MailboxList = require('./mailbox-list');

AccountStore = require('../stores/account_store');

AccountActionCreator = require('../actions/account_action_creator');

StoreWatchMixin = require('../mixins/store_watch_mixin');

module.exports = React.createClass({
  displayName: 'AccountConfig',
  mixins: [StoreWatchMixin([AccountStore]), React.addons.LinkedStateMixin],
  render: function() {
    var buttonLabel, mailboxes, titleLabel;
    titleLabel = this.props.initialAccountConfig != null ? t("account edit") : t("account new");
    if (this.props.isWaiting) {
      buttonLabel = 'Saving...';
    } else if (this.props.initialAccountConfig != null) {
      buttonLabel = t("account save");
    } else {
      buttonLabel = t("account add");
    }
    if (this.props.initialAccountConfig != null) {
      mailboxes = AccountStore.getSelectedMailboxes(true);
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
    }, t("account label")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-label',
      valueLink: this.linkState('label'),
      type: 'text',
      className: 'form-control',
      placeholder: t("account name short")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-name',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("account user name")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-name',
      valueLink: this.linkState('name'),
      type: 'text',
      className: 'form-control',
      placeholder: t("account user fullname")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-email-address',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("account address")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-email-address',
      valueLink: this.linkState('login'),
      ref: 'login',
      onBlur: this.discover,
      type: 'email',
      className: 'form-control',
      placeholder: t("account address placeholder")
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-password',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account password')), div({
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
    }, t("account sending server")), div({
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
    }, t("account receiving server")), div({
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
    }))), this.props.initialAccountConfig != null ? div({
      className: 'form-group'
    }, label({
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account draft mailbox')), div({
      className: 'col-sm-3'
    }, MailboxList({
      allowUndefined: true,
      mailboxes: mailboxes,
      selectedMailbox: this.state.draftMailbox,
      onChange: (function(_this) {
        return function(mailbox) {
          return _this.setState({
            'draftMailbox': mailbox
          });
        };
      })(this)
    }))) : void 0, this.props.initialAccountConfig != null ? div({
      className: 'form-group'
    }, label({
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account sent mailbox')), div({
      className: 'col-sm-3'
    }, MailboxList({
      allowUndefined: true,
      mailboxes: mailboxes,
      selectedMailbox: this.state.sentMailbox,
      onChange: (function(_this) {
        return function(mailbox) {
          return _this.setState({
            'sentMailbox': mailbox
          });
        };
      })(this)
    }))) : void 0, this.props.initialAccountConfig != null ? div({
      className: 'form-group'
    }, label({
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account trash mailbox')), div({
      className: 'col-sm-3'
    }, MailboxList({
      allowUndefined: true,
      mailboxes: mailboxes,
      selectedMailbox: this.state.trashMailbox,
      onChange: (function(_this) {
        return function(mailbox) {
          return _this.setState({
            'trashMailbox': mailbox
          });
        };
      })(this)
    }))) : void 0, div({
      className: 'form-group'
    }, div({
      className: 'col-sm-offset-2 col-sm-5 text-right'
    }, this.props.initialAccountConfig != null ? button({
      className: 'btn btn-cozy',
      onClick: this.onRemove
    }, t("account remove")) : void 0, button({
      className: 'btn btn-cozy',
      onClick: this.onSubmit
    }, buttonLabel)))));
  },
  onSubmit: function(event) {
    var accountValue;
    event.preventDefault();
    accountValue = this.state;
    accountValue.draftMailbox = accountValue.draftMailbox;
    accountValue.sentMailbox = accountValue.sentMailbox;
    accountValue.trashMailbox = accountValue.trashMailbox;
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
  discover: function() {
    var login;
    login = this.refs.login.getDOMNode().value.trim();
    return AccountActionCreator.discover(login.split('@')[1], (function(_this) {
      return function(err, provider) {
        var getInfos, infos, server, _i, _len;
        if (err == null) {
          infos = {};
          getInfos = function(server) {
            if (server.type === 'imap' && (infos.imapServer == null)) {
              infos.imapServer = server.hostname;
              infos.imapPort = server.port;
            }
            if (server.type === 'smtp' && (infos.smtpServer == null)) {
              infos.smtpServer = server.hostname;
              return infos.smtpPort = server.port;
            }
          };
          for (_i = 0, _len = provider.length; _i < _len; _i++) {
            server = provider[_i];
            getInfos(server);
          }
          if (infos.imapServer == null) {
            infos.imapServer = '';
            infos.imapPort = '';
          }
          if (infos.smtpServer == null) {
            infos.smtpServer = '';
            infos.smtpPort = '';
          }
          return _this.setState(infos);
        }
      };
    })(this));
  },
  componentWillReceiveProps: function(props) {
    if (!props.isWaiting) {
      return this.setState(this._accountToState(props.initialAccountConfig));
    }
  },
  getStateFromStores: function() {
    return this._accountToState(this.props.initialAccountConfig);
  },
  _accountToState: function(account) {
    if (account != null) {
      return {
        label: account.get('label'),
        name: account.get('name'),
        login: account.get('login'),
        password: account.get('password'),
        smtpServer: account.get('smtpServer'),
        smtpPort: account.get('smtpPort'),
        imapServer: account.get('imapServer'),
        imapPort: account.get('imapPort'),
        draftMailbox: account.get('draftMailbox'),
        sentMailbox: account.get('sentMailbox'),
        trashMailbox: account.get('trashMailbox')
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
        imapPort: 465,
        draftMailbox: '',
        sentMailbox: '',
        trashMailbox: ''
      };
    }
  }
});
});

;require.register("components/alert", function(exports, require, module) {
var AlertLevel, button, div, span, strong, _ref;

_ref = React.DOM, div = _ref.div, button = _ref.button, span = _ref.span, strong = _ref.strong;

AlertLevel = require('../constants/app_constants').AlertLevel;

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
var AccountConfig, AccountStore, Alert, Application, Compose, Conversation, LayoutActionCreator, LayoutStore, MailboxList, Menu, MessageList, MessageStore, ReactCSSTransitionGroup, RouterMixin, SearchForm, SearchStore, Settings, SettingsStore, StoreWatchMixin, TasksStore, Toast, a, body, button, classer, div, form, i, input, p, span, strong, _ref;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span, a = _ref.a, button = _ref.button, strong = _ref.strong;

AccountConfig = require('./account-config');

Alert = require('./alert');

Toast = require('./toast');

Compose = require('./compose');

Conversation = require('./conversation');

MailboxList = require('./mailbox-list');

Menu = require('./menu');

MessageList = require('./message-list');

Settings = require('./settings');

SearchForm = require('./search-form');

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

StoreWatchMixin = require('../mixins/store_watch_mixin');

AccountStore = require('../stores/account_store');

MessageStore = require('../stores/message_store');

LayoutStore = require('../stores/layout_store');

SettingsStore = require('../stores/settings_store');

SearchStore = require('../stores/search_store');

TasksStore = require('../stores/tasks_store');

LayoutActionCreator = require('../actions/layout_action_creator');


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
  mixins: [StoreWatchMixin([AccountStore, MessageStore, LayoutStore, SearchStore, TasksStore]), RouterMixin],
  render: function() {
    var alert, configMailboxUrl, firstPanelLayoutMode, getUrl, isFullWidth, layout, panelClasses, responsiveBackUrl, responsiveClasses, showMailboxConfigButton, _ref1;
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
    getUrl = (function(_this) {
      return function(mailbox) {
        var _ref1;
        return _this.buildUrl({
          direction: 'first',
          action: 'account.mailbox.messages',
          parameters: [(_ref1 = _this.state.selectedAccount) != null ? _ref1.get('id') : void 0, mailbox.get('id')]
        });
      };
    })(this);
    return div({
      className: 'container-fluid'
    }, div({
      className: 'row'
    }, Menu({
      accounts: this.state.accounts,
      selectedAccount: this.state.selectedAccount,
      isResponsiveMenuShown: this.state.isResponsiveMenuShown,
      layout: this.props.router.current,
      favoriteMailboxes: this.state.favoriteMailboxes,
      unreadCounts: this.state.unreadCounts
    }), div({
      id: 'page-content',
      className: responsiveClasses
    }, Alert({
      alert: alert
    }), div({
      className: 'toasts-container'
    }, this.state.toasts.map(function(toast) {
      return Toast({
        toast: toast
      });
    }).toJS()), div({
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
      getUrl: getUrl,
      mailboxes: this.state.mailboxes,
      selectedMailbox: (_ref1 = this.state.selectedMailbox) != null ? _ref1.get('id') : void 0
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
      key: 'left-panel-' + layout.firstPanel.action + '-' + Object.keys(layout.firstPanel.parameters).join('-')
    }, this.getPanelComponent(layout.firstPanel, firstPanelLayoutMode)), !isFullWidth && (layout.secondPanel != null) ? div({
      className: panelClasses.secondPanel,
      key: 'right-panel-' + layout.secondPanel.action + '-' + Object.keys(layout.secondPanel.parameters).join('-')
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
    var accountID, accounts, action, conversation, direction, error, firstOfPage, initialAccountConfig, isWaiting, lastOfPage, mailboxID, message, messageID, messagesCount, numPerPage, openMessage, otherPanelInfo, pageNum, plugins, results, selectedAccount, selectedMailbox, settings, _ref1;
    if (panelInfo.action === 'account.mailbox.messages') {
      accountID = panelInfo.parameters.accountID;
      mailboxID = panelInfo.parameters.mailboxID;
      pageNum = (_ref1 = panelInfo.parameters.page) != null ? _ref1 : 1;
      numPerPage = this.state.settings.get('messagesPerPage');
      firstOfPage = (pageNum - 1) * numPerPage;
      lastOfPage = pageNum * numPerPage;
      openMessage = null;
      direction = layout === 'first' ? 'secondPanel' : 'firstPanel';
      otherPanelInfo = this.props.router.current[direction];
      if ((otherPanelInfo != null ? otherPanelInfo.action : void 0) === 'message') {
        openMessage = MessageStore.getByID(otherPanelInfo.parameters.messageID);
      }
      messagesCount = MessageStore.getMessagesCounts().get(mailboxID);
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
      messageID = panelInfo.parameters.messageID;
      message = MessageStore.getByID(messageID);
      conversation = MessageStore.getMessagesByConversation(messageID);
      selectedAccount = this.state.selectedAccount;
      selectedMailbox = this.state.selectedMailbox;
      return Conversation({
        message: message,
        conversation: conversation,
        selectedAccount: selectedAccount,
        layout: layout,
        selectedMailbox: selectedMailbox
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
      plugins = this.state.plugins;
      return Settings({
        settings: settings,
        plugins: plugins
      });
    } else if (panelInfo.action === 'search') {
      accountID = null;
      mailboxID = null;
      pageNum = panelInfo.parameters.page;
      numPerPage = this.state.settings.get('messagesPerPage');
      firstOfPage = (pageNum - 1) * numPerPage;
      lastOfPage = pageNum * numPerPage;
      openMessage = null;
      direction = layout === 'first' ? 'secondPanel' : 'firstPanel';
      otherPanelInfo = this.props.router.current[direction];
      if ((otherPanelInfo != null ? otherPanelInfo.action : void 0) === 'message') {
        messageID = otherPanelInfo.parameters.messageID;
        openMessage = MessageStore.getByID(messageID);
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
    if (selectedAccount == null) {
      selectedAccount = AccountStore.getDefault();
    }
    selectedAccountID = (selectedAccount != null ? selectedAccount.get('id') : void 0) || null;
    firstPanelInfo = (_ref1 = this.props.router.current) != null ? _ref1.firstPanel : void 0;
    if ((firstPanelInfo != null ? firstPanelInfo.action : void 0) === 'account.mailbox.messages') {
      selectedMailboxID = firstPanelInfo.parameters.mailboxID;
    } else {
      selectedMailboxID = null;
    }
    return {
      accounts: AccountStore.getAll(),
      selectedAccount: selectedAccount,
      isResponsiveMenuShown: LayoutStore.isMenuShown(),
      alertMessage: LayoutStore.getAlert(),
      toasts: TasksStore.getTasks(),
      mailboxes: AccountStore.getSelectedMailboxes(true),
      selectedMailbox: AccountStore.getSelectedMailbox(selectedMailboxID),
      favoriteMailboxes: AccountStore.getSelectedFavorites(),
      unreadCounts: MessageStore.getUnreadMessagesCounts(),
      searchQuery: SearchStore.getQuery(),
      settings: SettingsStore.get(),
      plugins: window.plugins
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
var AccountStore, Compose, ComposeActions, FilePicker, LayoutActionCreator, MessageActionCreator, MessageUtils, RouterMixin, SettingsStore, a, button, classer, div, form, h3, i, input, label, li, span, textarea, ul, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, a = _ref.a, i = _ref.i, textarea = _ref.textarea, form = _ref.form, label = _ref.label, button = _ref.button, span = _ref.span, ul = _ref.ul, li = _ref.li, input = _ref.input;

classer = React.addons.classSet;

FilePicker = require('./file-picker');

AccountStore = require('../stores/account_store');

SettingsStore = require('../stores/settings_store');

ComposeActions = require('../constants/app_constants').ComposeActions;

MessageUtils = require('../utils/message_utils');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

RouterMixin = require('../mixins/router_mixin');

module.exports = Compose = React.createClass({
  displayName: 'Compose',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  render: function() {
    var accounts, classInput, classLabel, closeUrl, collapseUrl, expandUrl, onAttachmentsUpdate, _ref1;
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
    onAttachmentsUpdate = function(files) {
      return this.setState({
        attachments: files
      });
    };
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
    })(this)).toJS()), div({
      className: 'btn-toolbar compose-toggle',
      role: 'toolbar'
    }, div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: this.onToggleCc
    }, span({
      className: 'tool-long'
    }, t('compose toggle cc')))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: this.onToggleBcc
    }, span({
      className: 'tool-long'
    }, t('compose toggle bcc'))))))), div({
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
      className: 'form-group compose-cc'
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
      className: 'form-group compose-bcc'
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
      className: 'rt-editor form-control',
      ref: 'html',
      contentEditable: true,
      dangerouslySetInnerHTML: {
        __html: this.linkState('html').value
      }
    }) : textarea({
      className: 'editor',
      ref: 'content',
      defaultValue: this.linkState('body').value
    })), div({
      className: 'attachements'
    }, FilePicker({
      editable: true,
      form: false,
      onAttachmentsUpdate: onAttachmentsUpdate,
      files: this.state.attachments
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
            if ((matchesSelector != null) && !matchesSelector.call(target, '.rt-editor blockquote *')) {
              return;
            }
            if (target.lastChild) {
              target = target.lastChild.previousElementSibling;
            }
            parent = target;
            process = function() {
              var current;
              current = parent;
              return parent = parent != null ? parent.parentNode : void 0;
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
    var attachments, dateHuman, html, message, sender, state, text;
    message = this.props.message;
    state = {
      currentAccount: this.props.selectedAccount,
      composeInHTML: SettingsStore.get('composeInHTML'),
      attachments: []
    };
    if (message != null) {
      dateHuman = MessageUtils.formatDate(message.get('createdAt'));
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
        attachments = message.get('attachments' || []);
        state.attachments = attachments.map(MessageUtils.convertAttachments);
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
    return this._doSend(true);
  },
  onSend: function(args) {
    return this._doSend(false);
  },
  _doSend: function(isDraft) {
    var attach, callback, file, message, msg, msgId, references, _i, _len, _ref1;
    message = {
      from: this.state.currentAccount.get('login'),
      to: this.refs.to.getDOMNode().value.trim(),
      cc: this.refs.cc.getDOMNode().value.trim(),
      bcc: this.refs.bcc.getDOMNode().value.trim(),
      subject: this.refs.subject.getDOMNode().value.trim(),
      attachments: [],
      isDraft: isDraft
    };
    attach = function(file) {
      var f;
      f = {
        filename: file.name,
        content: file.content
      };
      return message.attachments.push(f);
    };
    _ref1 = this.state.attachments;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      file = _ref1[_i];
      attach(file);
    }
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
      var msgKo, msgOk;
      if (isDraft) {
        msgKo = t("message action draft ko");
        msgOk = t("message action draft ok");
      } else {
        msgKo = t("message action sent ko");
        msgOk = t("message action sent ok");
      }
      if (error != null) {
        LayoutActionCreator.alertError("" + msgKo + " :  error");
      } else {
        LayoutActionCreator.alertSuccess(msgOk);
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  onToggleCc: function(e) {
    var toggle, _i, _len, _ref1, _results;
    toggle = function(e) {
      return e.classList.toggle('shown');
    };
    _ref1 = this.getDOMNode().querySelectorAll('.compose-cc');
    _results = [];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      e = _ref1[_i];
      _results.push(toggle(e));
    }
    return _results;
  },
  onToggleBcc: function(e) {
    var toggle, _i, _len, _ref1, _results;
    toggle = function(e) {
      return e.classList.toggle('shown');
    };
    _ref1 = this.getDOMNode().querySelectorAll('.compose-bcc');
    _results = [];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      e = _ref1[_i];
      _results.push(toggle(e));
    }
    return _results;
  }
});
});

;require.register("components/conversation", function(exports, require, module) {
var Message, RouterMixin, a, classer, div, h3, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a;

Message = require('./message');

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

module.exports = React.createClass({
  displayName: 'Conversation',
  mixins: [RouterMixin],
  render: function() {
    var closeIcon, closeUrl, collapseUrl, expandUrl, isLast, key, message, selectedAccount, selectedAccountID, selectedMailbox;
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
        selectedMailbox = this.props.selectedMailbox;
        _results.push(Message({
          message: message,
          key: key,
          isLast: isLast,
          selectedAccount: selectedAccount,
          selectedMailbox: selectedMailbox
        }));
      }
      return _results;
    }).call(this)));
  }
});
});

;require.register("components/file-picker", function(exports, require, module) {
var FileItem, FilePicker, MessageUtils, a, div, form, i, input, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, form = _ref.form, input = _ref.input, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, a = _ref.a;

MessageUtils = require('../utils/message_utils');


/*
 * File picker
 *
 * Available props
 * - editable: boolean (false)
 * - files: array
 * - form: boolean (true) embed component inside a form element
 * - display: function(Object) : called when a file is selected
 * - onUpdate: function(Array) : called when file list is updated
 */

FilePicker = React.createClass({
  displayName: 'FilePicker',
  propTypes: {
    files: React.PropTypes.array,
    editable: React.PropTypes.bool,
    form: React.PropTypes.bool,
    display: React.PropTypes.func,
    onUpdate: React.PropTypes.func
  },
  getDefaultProps: function() {
    return {
      editable: false,
      form: true,
      files: [],
      onUpdate: function() {}
    };
  },
  getInitialState: function() {
    return {
      files: this._convertFileList(this.props.files)
    };
  },
  componentWillReceiveProps: function(props) {
    return this.setState({
      files: this._convertFileList(props.files)
    });
  },
  render: function() {
    var container, files;
    files = this.state.files.map((function(_this) {
      return function(file) {
        var doDelete, options;
        doDelete = function() {
          var updated;
          updated = _this.state.files.filter(function(f) {
            return f.name !== file.name;
          });
          _this.props.onUpdate(updated);
          return _this.setState({
            files: updated
          });
        };
        options = {
          key: file.name,
          file: file,
          editable: _this.props.editable,
          "delete": doDelete
        };
        if (_this.props.display != null) {
          options.display = function() {
            return _this.props.display(file);
          };
        }
        return FileItem(options);
      };
    })(this));
    container = this.props.form ? form : div;
    return container({
      className: 'file-picker'
    }, ul({
      className: 'files list-unstyled'
    }, files), this.props.editable ? div(null, span({
      className: "file-wrapper"
    }, input({
      type: "file",
      multiple: "multiple",
      ref: "file",
      onChange: this.handleFiles
    })), div({
      className: "dropzone"
    }, {
      ref: "dropzone",
      onDragOver: this.allowDrop,
      onDrop: this.handleFiles,
      onClick: this.onOpenFile
    }, i({
      className: "fa fa-paperclip"
    }), span(null, t("picker drop here")))) : void 0);
  },
  onOpenFile: function(e) {
    e.preventDefault();
    return jQuery(this.refs.file.getDOMNode()).trigger("click");
  },
  allowDrop: function(e) {
    return e.preventDefault();
  },
  handleFiles: function(e) {
    var currentFiles, file, files, handle, parsed, _i, _len, _ref1, _results;
    e.preventDefault();
    files = e.target.files || e.dataTransfer.files;
    currentFiles = this.state.files;
    parsed = 0;
    handle = (function(_this) {
      return function(file) {
        var reader;
        reader = new FileReader();
        reader.readAsDataURL(file);
        return reader.onloadend = function(e) {
          var txt;
          txt = e.target.result;
          file.content = txt;
          currentFiles.push(file);
          parsed++;
          if (parsed === files.length) {
            _this.props.onUpdate(currentFiles);
            return _this.setState({
              files: currentFiles
            });
          }
        };
      };
    })(this);
    _ref1 = this._convertFileList(files);
    _results = [];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      file = _ref1[_i];
      _results.push(handle(file));
    }
    return _results;
  },
  _convertFileList: function(files) {
    var convert;
    convert = (function(_this) {
      return function(file) {
        if (File.prototype.isPrototypeOf(file)) {
          _this._fromDOM(file);
        }
        return file;
      };
    })(this);
    return Array.prototype.map.call(files, convert);
  },
  _fromDOM: function(file) {
    return {
      name: file.name,
      size: file.size,
      type: file.type,
      originalName: null,
      contentDisposition: null,
      contentId: null,
      transferEncoding: null,
      content: null,
      url: null
    };
  }
});

module.exports = FilePicker;


/*
 * Display a file item
 *
 * Props:
 *  - file
 *  - editable: boolean (false) allow to delete file
 *  - (display): function
 *  - (delete): function
 */

FileItem = React.createClass({
  displayName: 'FileItem',
  propTypes: {
    file: React.PropTypes.shape({
      name: React.PropTypes.string,
      type: React.PropTypes.string,
      size: React.PropTypes.number
    }).isRequired,
    editable: React.PropTypes.bool,
    display: React.PropTypes.func,
    "delete": React.PropTypes.func
  },
  getDefaultProps: function() {
    return {
      editable: false
    };
  },
  getInitialState: function() {
    return {};
  },
  render: function() {
    var file, iconClass, icons, name, type;
    file = this.props.file;
    type = MessageUtils.getAttachmentType(file.type);
    icons = {
      'archive': 'fa-file-archive-o',
      'audio': 'fa-file-audio-o',
      'code': 'fa-file-code-o',
      'image': 'fa-file-image-o',
      'pdf': 'fa-file-pdf-o',
      'word': 'fa-file-word-o',
      'presentation': 'fa-file-powerpoint-o',
      'spreadsheet': 'fa-file-excel-o',
      'text': 'fa-file-text-o',
      'video': 'fa-file-video-o',
      'word': 'fa-file-word-o'
    };
    iconClass = icons[type] || 'fa-file-o';
    if (this.props.display != null) {
      name = a({
        className: 'file-name',
        target: '_blank',
        onClick: this.doDisplay
      }, file.name);
    } else {
      name = span({
        className: 'file-name'
      }, file.name);
    }
    return li({
      className: "file-item",
      key: file.name
    }, i({
      className: "mime fa " + iconClass
    }), this.props.editable ? i({
      className: "fa fa-times delete",
      onClick: this.doDelete
    }) : void 0, name, div({
      className: 'file-detail'
    }, span({
      'data-file-url': file.url
    }, "" + ((file.size / 1000).toFixed(2)) + "Ko")));
  },
  doDisplay: function(e) {
    e.preventDefault;
    return this.props.display();
  },
  doDelete: function(e) {
    e.preventDefault;
    return this.props["delete"]();
  }
});
});

;require.register("components/mailbox-list", function(exports, require, module) {
var RouterMixin, a, button, div, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, a = _ref.a, button = _ref.button;

RouterMixin = require('../mixins/router_mixin');

module.exports = React.createClass({
  displayName: 'MailboxList',
  mixins: [RouterMixin],
  onChange: function(boxid) {
    var _base;
    return typeof (_base = this.props).onChange === "function" ? _base.onChange(boxid) : void 0;
  },
  render: function() {
    var selected, selectedId;
    selectedId = this.props.selectedMailbox;
    selected = this.props.mailboxes.get(selectedId);
    if (this.props.mailboxes.length > 0) {
      return div({
        className: 'dropdown pull-left'
      }, button({
        className: 'btn btn-default dropdown-toggle',
        type: 'button',
        'data-toggle': 'dropdown'
      }, (selected != null ? selected.get('label') : void 0) || t('mailbox pick one'), span({
        className: 'caret'
      }, '')), ul({
        className: 'dropdown-menu',
        role: 'menu'
      }, this.props.allowUndefined && selected ? li({
        role: 'presentation',
        key: null,
        onClick: this.onChange.bind(this, null)
      }, a({
        role: 'menuitem'
      }, t('mailbox pick null'))) : void 0, this.props.mailboxes.map((function(_this) {
        return function(mailbox, key) {
          if (mailbox.get('id') !== selectedId) {
            return _this.getMailboxRender(mailbox, key);
          }
        };
      })(this)).toJS()));
    } else {
      return div(null, "");
    }
  },
  getMailboxRender: function(mailbox, key) {
    var i, onChange, pusher, url, _base, _i, _ref1;
    url = typeof (_base = this.props).getUrl === "function" ? _base.getUrl(mailbox) : void 0;
    onChange = this.onChange.bind(this, key);
    pusher = "";
    for (i = _i = 1, _ref1 = mailbox.get('depth'); _i <= _ref1; i = _i += 1) {
      pusher += "--";
    }
    return li({
      role: 'presentation',
      key: key,
      onClick: onChange
    }, url != null ? a({
      href: url,
      role: 'menuitem'
    }, "" + pusher + (mailbox.get('label'))) : a({
      role: 'menuitem'
    }, "" + pusher + (mailbox.get('label'))));
  }
});
});

;require.register("components/menu", function(exports, require, module) {
var AccountStore, Menu, MessageStore, RouterMixin, a, classer, div, i, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

AccountStore = require('../stores/account_store');

MessageStore = require('../stores/message_store');

module.exports = Menu = React.createClass({
  displayName: 'Menu',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !Immutable.is(nextProps.accounts, this.props.accounts) || !Immutable.is(nextProps.selectedAccount, this.props.selectedAccount) || !_.isEqual(nextProps.layout, this.props.layout) || nextProps.isResponsiveMenuShown !== this.props.isResponsiveMenuShown || !Immutable.is(nextProps.favoriteMailboxes, this.props.favoriteMailboxes) || !Immutable.is(nextProps.unreadCounts, this.props.unreadCounts);
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
    var accountClasses, accountID, defaultMailbox, isSelected, url, _ref1, _ref2;
    isSelected = ((this.props.selectedAccount == null) && key === 0) || ((_ref1 = this.props.selectedAccount) != null ? _ref1.get('id') : void 0) === account.get('id');
    accountClasses = classer({
      active: isSelected
    });
    accountID = account.get('id');
    defaultMailbox = AccountStore.getDefaultMailbox(accountID);
    url = this.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: [accountID, defaultMailbox != null ? defaultMailbox.get('id') : void 0],
      fullWidth: true
    });
    return li({
      className: accountClasses,
      key: key
    }, a({
      href: url,
      className: 'menu-item account ' + accountClasses
    }, i({
      className: 'fa fa-inbox'
    }), span({
      className: 'badge'
    }, this.props.unreadCounts.get(defaultMailbox != null ? defaultMailbox.get('id') : void 0)), span({
      className: 'item-label'
    }, account.get('label'))), ul({
      className: 'list-unstyled submenu mailbox-list'
    }, (_ref2 = this.props.favoriteMailboxes) != null ? _ref2.map((function(_this) {
      return function(mailbox, key) {
        return _this.getMailboxRender(account, mailbox, key);
      };
    })(this)).toJS() : void 0));
  },
  getMailboxRender: function(account, mailbox, key) {
    var mailboxUrl, unread;
    mailboxUrl = this.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: [account.get('id'), mailbox.get('id')]
    });
    unread = this.props.unreadCounts.get(mailbox.get('id'));
    return a({
      href: mailboxUrl,
      className: 'menu-item',
      key: key
    }, i({
      className: 'fa fa-star'
    }), span({
      className: 'badge'
    }, unread), span({
      className: 'item-label'
    }, mailbox.get('label')));
  }
});
});

;require.register("components/message-list", function(exports, require, module) {
var MessageFlags, MessageUtils, RouterMixin, a, classer, div, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, p = _ref.p;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

MessageUtils = require('../utils/message_utils');

MessageFlags = require('../constants/app_constants').MessageFlags;

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
    var classes, date, url;
    classes = classer({
      read: message.get('isRead'),
      active: isActive,
      'unseen': message.get('flags').indexOf(MessageFlags.SEEN) === -1,
      'has-attachments': message.get('hasAttachments'),
      'is-fav': message.get('flags').indexOf(MessageFlags.FLAGGED) !== -1
    });
    url = this.buildUrl({
      direction: 'second',
      action: 'message',
      parameters: message.get('id')
    });
    date = MessageUtils.formatDate(message.get('createdAt'));
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
    }, date), i({
      className: 'attach fa fa-paperclip'
    }), i({
      className: 'fav fa fa-star'
    })));
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
var AccountStore, Compose, ComposeActions, ConversationActionCreator, FilePicker, FlagsConstants, LayoutActionCreator, MessageActionCreator, MessageFlags, MessageUtils, RouterMixin, SettingsStore, a, button, classer, div, h3, i, iframe, li, p, pre, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a, button = _ref.button, pre = _ref.pre, iframe = _ref.iframe;

Compose = require('./compose');

FilePicker = require('./file-picker');

MessageUtils = require('../utils/message_utils');

_ref1 = require('../constants/app_constants'), ComposeActions = _ref1.ComposeActions, MessageFlags = _ref1.MessageFlags;

LayoutActionCreator = require('../actions/layout_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

SettingsStore = require('../stores/settings_store');

RouterMixin = require('../mixins/router_mixin');

AccountStore = require('../stores/account_store');

FlagsConstants = {
  SEEN: MessageFlags.SEEN,
  UNSEEN: "Unseen",
  FLAGGED: MessageFlags.FLAGGED,
  NOFLAG: "Noflag"
};

classer = React.addons.classSet;

module.exports = React.createClass({
  displayName: 'Message',
  mixins: [RouterMixin],
  getInitialState: function() {
    return {
      active: false,
      composing: false,
      composeAction: '',
      messageDisplayHTML: SettingsStore.get('messageDisplayHTML'),
      messageDisplayImages: SettingsStore.get('messageDisplayImages')
    };
  },
  _prepareMessage: function() {
    var fullHeaders, html, key, message, text, value, _ref2;
    message = this.props.message;
    fullHeaders = [];
    _ref2 = message.get('headers');
    for (key in _ref2) {
      value = _ref2[key];
      if (Array.isArray(value)) {
        fullHeaders.push("" + key + ": " + (value.join('\n    ')));
      } else {
        fullHeaders.push("" + key + ": " + value);
      }
    }
    text = message.get('text');
    html = message.get('html');
    if (html && !text && !this.state.messageDisplayHTML) {
      text = toMarkdown(html);
    }
    return {
      attachments: message.get('attachments') || [],
      flags: message.get('flags') || [],
      fullHeaders: fullHeaders,
      text: text,
      html: html,
      date: MessageUtils.formatDate(message.get('createdAt'))
    };
  },
  componentWillMount: function() {
    return this._markRead(this.props.message);
  },
  componentWillReceiveProps: function() {
    this._markRead(this.props.message);
    return this.setState(this.getInitialState());
  },
  _markRead: function(message) {
    var flags;
    flags = message.get('flags').slice();
    if (flags.indexOf(MessageFlags.SEEN) === -1) {
      flags.push(MessageFlags.SEEN);
      return MessageActionCreator.updateFlag(message, flags);
    }
  },
  render: function() {
    var classes, clickHandler, display, doc, hasAttachments, hideImage, images, img, leftClass, message, parser, prepared, _i, _len;
    message = this.props.message;
    prepared = this._prepareMessage();
    hasAttachments = prepared.attachments.length;
    if (this.state.messageDisplayHTML && prepared.html) {
      parser = new DOMParser();
      doc = parser.parseFromString(prepared.html, "text/html");
      if (doc && !this.state.messageDisplayImages) {
        hideImage = function(img) {
          img.dataset.src = img.getAttribute('src');
          return img.setAttribute('src', '');
        };
        images = doc.querySelectorAll('IMG[src]');
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          img = images[_i];
          hideImage(img);
        }
      } else {
        images = [];
      }
      this._htmlContent = doc.body.innerHTML;
    }
    clickHandler = this.props.isLast ? null : this.onFold;
    classes = classer({
      message: true,
      active: this.state.active
    });
    leftClass = hasAttachments ? 'col-md-8' : 'col-md-12';
    display = function(file) {
      var url;
      url = "/message/" + (message.get('id')) + "/attachments/" + file.name;
      return window.open(url);
    };
    return li({
      className: classes,
      key: this.props.key,
      onClick: clickHandler,
      'data-id': this.props.message.get('id')
    }, this.getToolboxRender(message.get('id'), prepared), div({
      className: 'header row'
    }, div({
      className: leftClass
    }, i({
      className: 'sender-avatar fa fa-user'
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
    }, prepared.date)), hasAttachments ? div({
      className: 'col-md-4'
    }, FilePicker({
      editable: false,
      files: prepared.attachments.map(MessageUtils.convertAttachments),
      display: display
    })) : void 0), div({
      className: 'full-headers'
    }, pre(null, prepared.fullHeaders.join("\n"))), this.state.messageDisplayHTML && prepared.html ? div(null, images.length > 0 && !this.state.messageDisplayImages ? div({
      className: "imagesWarning content-action",
      ref: "imagesWarning"
    }, span(null, t('message images warning')), button({
      className: 'btn btn-default',
      type: "button",
      ref: 'imagesDisplay'
    }, t('message images display'))) : void 0, iframe({
      className: 'content',
      ref: 'content',
      sandbox: 'allow-same-origin',
      allowTransparency: true,
      frameBorder: 0
    }, '')) : div(null, div({
      className: "content-action"
    }, button({
      className: 'btn btn-default',
      type: "button",
      onClick: this.displayHTML
    }, t('message html display'))), div({
      className: 'preview'
    }, p(null, prepared.text))), div({
      className: 'clearfix'
    }), this.getComposeRender());
  },
  getComposeRender: function() {
    var action, callback, layout, message, selectedAccount;
    if (this.state.composing) {
      selectedAccount = this.props.selectedAccount;
      layout = 'second';
      message = this.props.message;
      action = this.state.composeAction;
      callback = (function(_this) {
        return function(error) {
          if (error == null) {
            return _this.setState({
              composing: false
            });
          }
        };
      })(this);
      return Compose({
        selectedAccount: selectedAccount,
        layout: layout,
        message: message,
        action: action,
        callback: callback
      });
    }
  },
  getToolboxRender: function(id, prepared) {
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
      'data-toggle': 'dropdown'
    }, t('mail action mark', span({
      className: 'caret'
    }))), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, prepared.flags.indexOf(FlagsConstants.SEEN) === -1 ? li(null, a({
      role: 'menuitem',
      onClick: this.onMark,
      'data-value': FlagsConstants.SEEN
    }, t('mail mark read'))) : li(null, a({
      role: 'menuitem',
      onClick: this.onMark,
      'data-value': FlagsConstants.UNSEEN
    }, t('mail mark unread'))), prepared.flags.indexOf(FlagsConstants.FLAGGED) === -1 ? li(null, a({
      role: 'menuitem',
      onClick: this.onMark,
      'data-value': FlagsConstants.FLAGGED
    }, t('mail mark fav'))) : li(null, a({
      role: 'menuitem',
      onClick: this.onMark,
      'data-value': FlagsConstants.NOFLAG
    }, t('mail mark nofav'))))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default dropdown-toggle',
      type: 'button',
      'data-toggle': 'dropdown'
    }, t('mail action move', span({
      className: 'caret'
    }))), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, mailboxes.map((function(_this) {
      return function(mailbox, key) {
        return _this.getMailboxRender(mailbox, key);
      };
    })(this)).toJS())), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default dropdown-toggle',
      type: 'button',
      'data-toggle': 'dropdown'
    }, t('mail action more', span({
      className: 'caret'
    }))), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, li({
      role: 'presentation'
    }, a({
      onClick: this.onHeaders,
      'data-message-id': id
    }, t('mail action headers'))), li({
      role: 'presentation'
    }, a({
      onClick: this.onConversation,
      'data-action': 'delete'
    }, t('mail action conversation delete'))), li({
      role: 'presentation'
    }, a({
      onClick: this.onConversation,
      'data-action': 'seen'
    }, t('mail action conversation seen'))), li({
      role: 'presentation'
    }, a({
      onClick: this.onConversation,
      'data-action': 'unseen'
    }, t('mail action conversation unseen'))), li({
      role: 'presentation',
      className: 'divider'
    }), li({
      role: 'presentation'
    }, t('mail action conversation move')), mailboxes.map((function(_this) {
      return function(mailbox, key) {
        return _this.getMailboxRender(mailbox, key, true);
      };
    })(this)).toJS(), li({
      role: 'presentation',
      className: 'divider'
    }))))));
  },
  getMailboxRender: function(mailbox, key, conversation) {
    var j, pusher, _i, _ref2;
    if (mailbox.get('id') === this.props.selectedMailbox.get('id')) {
      return;
    }
    pusher = "";
    for (j = _i = 1, _ref2 = mailbox.get('depth'); _i <= _ref2; j = _i += 1) {
      pusher += "--";
    }
    return li({
      role: 'presentation',
      key: key
    }, a({
      role: 'menuitem',
      onClick: this.onMove,
      'data-value': key,
      'data-conversation': conversation
    }, "" + pusher + (mailbox.get('label'))));
  },
  _initFrame: function() {
    var doc, frame, rect;
    if (this.state.messageDisplayHTML) {
      frame = this.refs.content.getDOMNode();
      doc = frame.contentDocument || frame.contentWindow.document;
      doc.body.innerHTML = this._htmlContent;
      rect = doc.body.getBoundingClientRect();
      frame.style.height = "" + (rect.height + 40) + "px";
      if (!this.state.messageDisplayImages && (this.refs.imagesDisplay != null)) {
        return this.refs.imagesDisplay.getDOMNode().addEventListener('click', (function(_this) {
          return function() {
            return _this.setState({
              messageDisplayImages: true
            });
          };
        })(this));
      }
    }
  },
  componentDidMount: function() {
    return this._initFrame();
  },
  componentDidUpdate: function() {
    return this._initFrame();
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
    if (window.confirm(t('mail confirm delete'))) {
      return MessageActionCreator["delete"](this.props.message, this.props.selectedAccount, (function(_this) {
        return function(error) {
          if (error != null) {
            return LayoutActionCreator.alertError("" + (t("message action delete ko")) + " " + error);
          } else {
            LayoutActionCreator.alertSuccess(t("message action delete ok"));
            return _this.redirect({
              direction: 'first',
              action: 'account.mailbox.messages',
              parameters: [_this.props.selectedAccount.get('id'), _this.props.selectedMailbox.get('id'), 1],
              fullWidth: true
            });
          }
        };
      })(this));
    }
  },
  onCopy: function(args) {
    return LayoutActionCreator.alertWarning(t("app unimplemented"));
  },
  onMove: function(args) {
    var newbox, oldbox;
    newbox = args.target.dataset.value;
    if (args.target.dataset.conversation != null) {
      return ConversationActionCreator.move(this.props.message.get('conversationID'), newbox, (function(_this) {
        return function(error) {
          if (error != null) {
            return LayoutActionCreator.alertError("" + (t("conversation move ko")) + " " + error);
          } else {
            LayoutActionCreator.alertSuccess(t("conversation move ok"));
            return _this.redirect({
              direction: 'first',
              action: 'account.mailbox.messages',
              parameters: [_this.props.selectedAccount.get('id'), _this.props.selectedMailbox.get('id'), 1],
              fullWidth: true
            });
          }
        };
      })(this));
    } else {
      oldbox = this.props.selectedMailbox.get('id');
      return MessageActionCreator.move(this.props.message, oldbox, newbox, (function(_this) {
        return function(error) {
          if (error != null) {
            return LayoutActionCreator.alertError("" + (t("message action move ko")) + " " + error);
          } else {
            LayoutActionCreator.alertSuccess(t("message action move ok"));
            return _this.redirect({
              direction: 'first',
              action: 'account.mailbox.messages',
              parameters: [_this.props.selectedAccount.get('id'), _this.props.selectedMailbox.get('id'), 1],
              fullWidth: true
            });
          }
        };
      })(this));
    }
  },
  onMark: function(args) {
    var flag, flags;
    flags = this.props.message.get('flags').slice();
    flag = args.target.dataset.value;
    switch (flag) {
      case FlagsConstants.SEEN:
        flags.push(MessageFlags.SEEN);
        break;
      case FlagsConstants.UNSEEN:
        flags = flags.filter(function(e) {
          return e !== FlagsConstants.SEEN;
        });
        break;
      case FlagsConstants.FLAGGED:
        flags.push(MessageFlags.FLAGGED);
        break;
      case FlagsConstants.NOFLAG:
        flags = flags.filter(function(e) {
          return e !== FlagsConstants.FLAGGED;
        });
    }
    return MessageActionCreator.updateFlag(this.props.message, flags, function(error) {
      if (error != null) {
        return LayoutActionCreator.alertError("" + (t("message action mark ko")) + " " + error);
      } else {
        return LayoutActionCreator.alertSuccess(t("message action mark ok"));
      }
    });
  },
  onConversation: function(args) {
    var action, id;
    id = this.props.message.get('conversationID');
    action = args.target.dataset.action;
    switch (action) {
      case 'delete':
        return ConversationActionCreator["delete"](id, function(error) {
          if (error != null) {
            return LayoutActionCreator.alertError("" + (t("conversation delete ko")) + " " + error);
          } else {
            return LayoutActionCreator.alertSuccess(t("conversation delete ok"));
          }
        });
      case 'seen':
        return ConversationActionCreator.seen(id, function(error) {
          if (error != null) {
            return LayoutActionCreator.alertError("" + (t("conversation seen ok ")) + " " + error);
          } else {
            return LayoutActionCreator.alertSuccess(t("conversation seen ko "));
          }
        });
      case 'unseen':
        return ConversationActionCreator.unseen(id, function(error) {
          if (error != null) {
            return LayoutActionCreator.alertError("" + (t("conversation unseen ok")) + " " + error);
          } else {
            return LayoutActionCreator.alertSuccess(t("conversation unseen ko"));
          }
        });
    }
  },
  onHeaders: function(event) {
    var messageId;
    event.preventDefault();
    messageId = event.target.dataset.messageId;
    return document.querySelector(".conversation [data-id='" + messageId + "']").classList.toggle('with-headers');
  },
  displayHTML: function(event) {
    event.preventDefault();
    return this.setState({
      messageDisplayHTML: true
    });
  }
});
});

;require.register("components/search-form", function(exports, require, module) {
var ENTER_KEY, RouterMixin, SearchActionCreator, classer, div, input, span, _ref;

_ref = React.DOM, div = _ref.div, input = _ref.input, span = _ref.span;

classer = React.addons.classSet;

SearchActionCreator = require('../actions/search_action_creator');

ENTER_KEY = 13;

RouterMixin = require('../mixins/router_mixin');

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
var PluginUtils, SettingsActionCreator, SettingsStore, button, classer, div, fieldset, form, h3, input, label, legend, _ref,
  __hasProp = {}.hasOwnProperty;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button, fieldset = _ref.fieldset, legend = _ref.legend;

classer = React.addons.classSet;

SettingsActionCreator = require('../actions/settings_action_creator');

SettingsStore = require('../stores/settings_store');

PluginUtils = require('../utils/plugin_utils');

module.exports = React.createClass({
  displayName: 'Settings',
  mixins: [React.addons.LinkedStateMixin],
  render: function() {
    var classLabel, pluginConf, pluginName;
    classLabel = 'col-sm-2 col-sm-offset-2 control-label';
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
      className: classLabel
    }, t("settings label mpp")), div({
      className: 'col-sm-3'
    }, input({
      id: 'settings-mpp',
      value: this.state.settings.messagesPerPage,
      onChange: this.handleChange,
      'data-target': 'messagesPerPage',
      type: 'number',
      min: 5,
      max: 100,
      step: 5,
      className: 'form-control'
    })))), this._renderOption('composeInHTML'), this._renderOption('messageDisplayHTML'), this._renderOption('messageDisplayImages'), fieldset(null, legend(null, t('settings plugins')), (function() {
      var _ref1, _results;
      _ref1 = this.state.plugins;
      _results = [];
      for (pluginName in _ref1) {
        if (!__hasProp.call(_ref1, pluginName)) continue;
        pluginConf = _ref1[pluginName];
        _results.push(form({
          className: 'form-horizontal',
          key: pluginName
        }, div({
          className: 'form-group'
        }, label({
          className: classLabel
        }, pluginConf.name), div({
          className: 'col-sm-3'
        }, input({
          checked: this.state.plugins[pluginName].active,
          onChange: this.handleChange,
          'data-target': 'plugin',
          'data-plugin': pluginName,
          type: 'checkbox',
          className: 'form-control'
        })))));
      }
      return _results;
    }).call(this)));
  },
  _renderOption: function(option) {
    var classLabel;
    classLabel = 'col-sm-2 col-sm-offset-2 control-label';
    return form({
      className: 'form-horizontal'
    }, div({
      className: 'form-group'
    }, label({
      htmlFor: 'settings-' + option,
      className: classLabel
    }, t("settings label " + option)), div({
      className: 'col-sm-3'
    }, input({
      id: 'settings-' + option,
      checked: this.state.settings[option],
      onChange: this.handleChange,
      'data-target': option,
      type: 'checkbox',
      className: 'form-control'
    }))));
  },
  handleChange: function(event) {
    var settings, target;
    target = event.target;
    switch (target.dataset.target) {
      case 'messagesPerPage':
        settings = this.state.settings;
        settings.messagesPerPage = target.value;
        this.setState({
          settings: settings
        });
        return SettingsActionCreator.edit(settings);
      case 'composeInHTML':
      case 'messageDisplayHTML':
      case 'messageDisplayImages':
        settings = this.state.settings;
        settings[target.dataset.target] = target.checked;
        this.setState({
          settings: settings
        });
        return SettingsActionCreator.edit(settings);
      case 'plugin':
        if (target.checked) {
          PluginUtils.activate(target.dataset.plugin);
        } else {
          PluginUtils.deactivate(target.dataset.plugin);
        }
        return this.setState({
          plugins: window.plugins
        });
    }
  },
  getInitialState: function(forceDefault) {
    return {
      settings: this.props.settings.toObject(),
      plugins: this.props.plugins
    };
  }
});
});

;require.register("components/toast", function(exports, require, module) {
var SocketUtils, button, div, span, strong, _ref;

_ref = React.DOM, div = _ref.div, button = _ref.button, span = _ref.span, strong = _ref.strong;

SocketUtils = require('../utils/socketio_utils');

module.exports = React.createClass({
  displayName: 'Toast',
  acknowledge: function() {
    return SocketUtils.acknowledgeTask(this.props.toast.get('id'));
  },
  render: function() {
    var dismissible, percent, toast;
    toast = this.props.toast.toJS();
    dismissible = toast.finished ? 'alert-dismissible' : '';
    percent = parseInt(100 * toast.done / toast.total);
    return div({
      className: "alert toast alert-info " + dismissible,
      role: "alert"
    }, div({
      className: "progress"
    }, div({
      className: 'progress-bar',
      role: 'progressbar',
      "style": {
        width: "" + percent + "%",
        "aria-valuenow": toast.done,
        "aria-valuemin": 0,
        "aria-valuemax": toast.total
      }
    }, "" + (t("task " + toast.code, toast)) + " : " + percent + "%")), toast.finished ? button({
      type: "button",
      className: "close",
      onClick: this.acknowledge
    }, span({
      'aria-hidden': "true"
    }, "×"), span({
      className: "sr-only"
    }, t("app alert close"))) : void 0);
  }
});
});

;require.register("constants/app_constants", function(exports, require, module) {
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
    'MESSAGE_SEND': 'MESSAGE_SEND',
    'MESSAGE_DELETE': 'MESSAGE_DELETE',
    'MESSAGE_BOXES': 'MESSAGE_BOXES',
    'MESSAGE_FLAG': 'MESSAGE_FLAG',
    'SET_SEARCH_QUERY': 'SET_SEARCH_QUERY',
    'RECEIVE_RAW_SEARCH_RESULTS': 'RECEIVE_RAW_SEARCH_RESULTS',
    'CLEAR_SEARCH_RESULTS': 'CLEAR_SEARCH_RESULTS',
    'SHOW_MENU_RESPONSIVE': 'SHOW_MENU_RESPONSIVE',
    'HIDE_MENU_RESPONSIVE': 'HIDE_MENU_RESPONSIVE',
    'SELECT_ACCOUNT': 'SELECT_ACCOUNT',
    'DISPLAY_ALERT': 'DISPLAY_ALERT',
    'RECEIVE_RAW_MAILBOXES': 'RECEIVE_RAW_MAILBOXES',
    'SETTINGS_UPDATED': 'SETTINGS_UPDATED',
    'RECEIVE_TASK_UPDATE': 'RECEIVE_TASK_UPDATE',
    'RECEIVE_TASK_DELETE': 'RECEIVE_TASK_DELETE'
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
  },
  MessageFlags: {
    'FLAGGED': '\\Flagged',
    'SEEN': '\\Seen',
    'DRAFT': '\\Draft'
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
  require("./utils/plugin_utils").init();
  AccountStore = require('./stores/account_store');
  LayoutStore = require('./stores/layout_store');
  MessageStore = require('./stores/message_store');
  SettingsStore = require('./stores/settings_store');
  SearchStore = require('./stores/search_store');
  Router = require('./router');
  this.router = new Router();
  window.router = this.router;
  Application = require('./components/application');
  application = Application({
    router: this.router
  });
  React.renderComponent(application, document.body);
  Backbone.history.start();
  require('./utils/socketio_utils');
  if (typeof Object.freeze === 'function') {
    return Object.freeze(this);
  }
};
});

;require.register("libs/flux/dispatcher/dispatcher", function(exports, require, module) {

/*

    -- Coffee port of Facebook's flux dispatcher. It was in ES6 and I haven't
    been successful in adding a transpiler. --

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
      Registers a callback to be invoked with every dispatched payload.
      Returns a token that can be used with `waitFor()`.
  
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
    var message;
    message = 'Dispatcher.unregister(...): `%s` does not map to a ' + 'registered callback.';
    invariant(this._callbacks[id], message, id);
    return delete this._callbacks[id];
  };


  /*
      Waits for the callbacks specified to be invoked before continuing
      execution of the current callback. This method should only be used by a
      callback in response to a dispatched payload.
  
      @param {array<string>} ids
   */

  Dispatcher.prototype.waitFor = function(ids) {
    var id, ii, message, message2, _i, _ref, _results;
    invariant(this._isDispatching, 'Dispatcher.waitFor(...): Must be invoked while dispatching.');
    message = 'Dispatcher.waitFor(...): Circular dependency detected ' + 'while waiting for `%s`.';
    message2 = 'Dispatcher.waitFor(...): `%s` does not map to a ' + 'registered callback.';
    _results = [];
    for (ii = _i = 0, _ref = ids.length - 1; _i <= _ref; ii = _i += 1) {
      id = ids[ii];
      if (this._isPending[id]) {
        invariant(this._isHandled[id], message, id);
        continue;
      }
      invariant(this._callbacks[id], message2, id);
      _results.push(this._invokeCallback(id));
    }
    return _results;
  };


  /*
      Dispatches a payload to all registered callbacks.
  
      @param {object} payload
   */

  Dispatcher.prototype.dispatch = function(payload) {
    var id, message, _results;
    message = 'Dispatch.dispatch(...): Cannot dispatch in the middle ' + 'of a dispatch.';
    invariant(!this._isDispatching, message);
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

;require.register("libs/flux/store/store", function(exports, require, module) {
var AppDispatcher, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

AppDispatcher = require('../../../app_dispatcher');

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
    var message;
    if (__DEV__) {
      message = ("The store " + this.constructor.name + " must define a ") + "`__bindHandlers` method";
      throw new Error(message);
    }
  };

  return Store;

})(EventEmitter);
});

;require.register("libs/panel_router", function(exports, require, module) {

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

LayoutActionCreator = require('../actions/layout_action_creator');

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
    firstPanelParameters = this._arrayToNamedParameters(name, args);
    route = _.first(_.filter(this.cachedPatterns, function(element) {
      return element.pattern.test(secondPanelString);
    }));
    if (route != null) {
      args = this._extractParameters(route.pattern, secondPanelString);
      args.pop();
      secondPanelInfo = this._mergeDefaultParameter({
        action: route.key,
        parameters: this._arrayToNamedParameters(route.key, args)
      });
    } else {
      secondPanelInfo = null;
    }
    firstPanelInfo = this._mergeDefaultParameter({
      action: name,
      parameters: firstPanelParameters
    });
    return [firstPanelInfo, secondPanelInfo];
  };


  /*
      Turns a parameters array into an object of named parameters
   */

  Router.prototype._arrayToNamedParameters = function(patternName, parametersArray) {
    var index, namedParameters, paramName, parametersName, unPrefixedParamName, _i, _len;
    namedParameters = {};
    parametersName = this.patterns[patternName].pattern.match(/:[\w]+/g) || [];
    for (index = _i = 0, _len = parametersName.length; _i < _len; index = ++_i) {
      paramName = parametersName[index];
      unPrefixedParamName = paramName.substr(1);
      namedParameters[unPrefixedParamName] = parametersArray[index];
    }
    return namedParameters;
  };


  /*
      Turns a parameters array into an object of named parameters
   */

  Router.prototype._namedParametersToArray = function(patternName, namedParameters) {
    var index, paramName, parametersArray, parametersName, unPrefixedParamName, _i, _len;
    parametersArray = [];
    parametersName = this.patterns[patternName].pattern.match(/:[\w]+/g) || [];
    for (index = _i = 0, _len = parametersName.length; _i < _len; index = ++_i) {
      paramName = parametersName[index];
      unPrefixedParamName = paramName.substr(1);
      parametersArray.push(namedParameters[paramName]);
    }
    return parametersArray;
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
    var action, filledPattern, key, paramInPattern, paramValue, parameters, parametersInPattern, pattern, _i, _len;
    panel = _.clone(panel);
    if ((panel != null ? panel.parameters : void 0) != null) {
      panel.parameters = _.clone(panel.parameters);
    }
    if (panel != null) {
      pattern = this.patterns[panel.action].pattern;
      if ((panel.parameters != null) && !(panel.parameters instanceof Array) && !(panel.parameters instanceof Object)) {
        panel.parameters = [panel.parameters];
      }
      if ((panel.parameters != null) && panel.parameters instanceof Array) {
        action = panel.action, parameters = panel.parameters;
        panel.parameters = this._arrayToNamedParameters(action, parameters);
      }
      panel = this._mergeDefaultParameter(panel);
      parametersInPattern = pattern.match(/:[\w]+/gi) || [];
      filledPattern = pattern;
      if (panel.parameters) {
        for (_i = 0, _len = parametersInPattern.length; _i < _len; _i++) {
          paramInPattern = parametersInPattern[_i];
          key = paramInPattern.substr(1);
          paramValue = panel.parameters[key];
          filledPattern = filledPattern.replace(paramInPattern, paramValue);
        }
      }
      return filledPattern;
    } else {
      return '';
    }
  };

  Router.prototype._mergeDefaultParameter = function(panelInfo) {
    var defaultParameter, defaultParameters, key, parameters;
    panelInfo = _.clone(panelInfo);
    parameters = _.clone(panelInfo.parameters || {});
    if ((defaultParameters = this._getDefaultParameters(panelInfo.action)) != null) {
      for (key in defaultParameters) {
        defaultParameter = defaultParameters[key];
        if (parameters[key] == null) {
          parameters[key] = defaultParameter;
        }
      }
    }
    panelInfo.parameters = parameters;
    return panelInfo;
  };

  return Router;

})(Backbone.Router);
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
  "compose toggle cc": "Cc",
  "compose toggle bcc": "Bcc",
  "menu compose": "Compose",
  "menu account new": "New account",
  "menu settings": "Parameters",
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
  "mail action more": "More…",
  "mail action headers": "Headers",
  "mail mark spam": "Spam",
  "mail mark nospam": "No spam",
  "mail mark fav": "Important",
  "mail mark nofav": "Not important",
  "mail mark read": "Read",
  "mail mark unread": "Not read",
  "mail confirm delete": "Do you really want to delete this message ?",
  "mail action conversation delete": "Delete conversation",
  "mail action conversation move": "Move conversation",
  "mail action conversation seen": "Mark conversation as read",
  "mail action conversation unseen": "Mark conversation as not read",
  "account new": "New account",
  "account edit": "Edit account",
  "account add": "Add",
  "account save": "Save",
  "account label": "Label",
  "account name short": "A short mailbox name",
  "account user name": "Your name",
  "account user fullname": "Your name, as it will be displayed",
  "account address": "Email address",
  "account address placeholder": "Your email address",
  "account password": "Password",
  "account sending server": "Sending server",
  "account receiving server": "IMAP server",
  "account remove": "Remove",
  "account draft mailbox": "Draft box",
  "account sent mailbox": "Sent box",
  "account trash mailbox": "Trash",
  "message action sent ok": "Message sent",
  "message action sent ko": "Error sending message: ",
  "message action draft ok": "Message saved",
  "message action draft ko": "Error saving message: ",
  "message action delete ok": "Message deleted",
  "message action delete ko": "Error deleting message: ",
  "message action move ok": "Message moved",
  "message action move ko": "Error moving message: ",
  "message action mark ok": "Message marked",
  "message action mark ko": "Error marking message: ",
  "conversation move ok": "Conversation moved",
  "conversation move ko": "Error moving conversation",
  "conversation delete ok": "Conversation deleted",
  "conversation delete ko": "Error deleting conversation",
  "conversation seen ok": "Conversation marked as read",
  "conversation seen ko": "Error",
  "conversation unseen ok": "Conversation marked as unread",
  "conversation unseen ko": "Error",
  "message images warning": "Display of images inside message has been blocked",
  "message images display": "Display images",
  "message html display": "Display HTML",
  "message delete no trash": "Please select a Trash folder",
  "settings title": "Settings",
  "settings button save": "Save",
  "settings label mpp": "Messages per page",
  "settings plugins": "Add ons",
  "settings label composeInHTML": "Rich message editor",
  "settings label messageDisplayHTML": "Display message in HTML",
  "settings label messageDisplayImages": "Display images inside messages",
  "picker drop here": "Drop files here",
  "mailbox pick one": "Pick one",
  "mailbox pick null": "No box for this",
  "task diff": 'Comparing %{box} of %{account}',
  "task apply-diff-fetch": 'Fetching mails %{box} of %{account}'
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
  "compose bcc help": "Liste des destinataires en copie cachée",
  "compose subject": "Objet",
  "compose subject help": "Objet du message",
  "compose reply prefix": "Re: ",
  "compose reply separator": "\n\nLe %{date}, %{sender} a écrit \n",
  "compose forward prefix": "Fwd: ",
  "compose forward separator": "\n\nLe %{date}, %{sender} a écrit \n",
  "compose action draft": "Enregistrer en tant que brouillon",
  "compose action send": "Envoyer",
  "compose toggle cc": "Copie à",
  "compose toggle bcc": "Copie cachée à",
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
  "mail action more": "Plus…",
  "mail action headers": "Entêtes",
  "mail mark spam": "Pourriel",
  "mail mark nospam": "Légitime",
  "mail mark fav": "Important",
  "mail mark nofav": "Normal",
  "mail mark read": "Lu",
  "mail mark unread": "Non lu",
  "mail confirm delete": "Voulez-vous vraiment supprimer ce message ?",
  "mail action conversation delete": "Supprimer la conversation",
  "mail action conversation move": "Déplacer la conversation",
  "mail action conversation seen": "Marquer la conversation comme lue",
  "mail action conversation unseen": "Marquer la conversation comme non lue",
  "account new": "Nouveau compte",
  "account edit": "Modifier le compte",
  "account add": "Créer",
  "account save": "Enregistrer",
  "account label": "Nom",
  "account name short": "Nom abrégé",
  "account user name": "Votre nom",
  "account user fullname": "Votre nom, tel qu'il sera affiché",
  "account address": "Adresse",
  "account address placeholder": "Votre adresse électronique",
  "account password": "Mot de passe",
  "account sending server": "Serveur sortant",
  "account receiving server": "Serveur IMAP",
  "account remove": "Supprimer",
  "account draft mailbox": "Enregistrer les brouillons dans",
  "account sent mailbox": "Enregistrer les messages envoyés dans",
  "account trash mailbox": "Corbeille",
  "message action sent ok": "Message envoyé !",
  "message action sent ko": "Une erreur est survenue : ",
  "message action draft ok": "Message sauvegardé !",
  "message action draft ko": "Une erreur est survenue : ",
  "message action delete ok": "Message supprimé",
  "message action delete ko": "Impossible de supprimer le message : ",
  "message action move ok": "Message déplacé",
  "message action move ko": "Le déplacement a échoué",
  "message action mark ok": "Ok",
  "message action mark ko": "L'opération a échoué",
  "conversation move ok": "Conversation déplacée",
  "conversation move ko": "L'opération a échoué",
  "conversation delete ok": "Conversation supprimée",
  "conversation delete ko": "L'opération a échoué",
  "conversation seen ok": "Ok",
  "conversation seen ko": "L'opération a échoué",
  "conversation unseen ok": "Ok",
  "conversation unseen ko": "L'opération a échoué",
  "message images warning": "L'affichage des images du message a été bloqué",
  "message images display": "Afficher les images",
  "message html display": "Afficher en HTML",
  "message delete no trash": "Choisissez d'abord un dossier Corbeille",
  "settings title": "Paramètres",
  "settings button save": "Enregistrer",
  "settings label mpp": "Nombre de messages par page",
  "settings plugins": "Modules complémentaires",
  "settings label composeInHTML": "Éditeur riche",
  "settings label messageDisplayHTML": "Afficher les messages en HTML",
  "settings label messageDisplayImages": "Afficher les images",
  "picker drop here": "Déposer les fichiers ici",
  "mailbox pick one": "Choisissez une boite",
  "mailbox pick null": "Pas de boite pour ça",
  "task diff": 'Comparaison %{box} of %{account}',
  "task apply-diff-fetch": 'Téléchargement emails %{box} of %{account}'
};
});

;require.register("mixins/router_mixin", function(exports, require, module) {

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

;require.register("mixins/store_watch_mixin", function(exports, require, module) {
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

PanelRouter = require('./libs/panel_router');

AccountStore = require('./stores/account_store');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.patterns = {
    'account.config': {
      pattern: 'account/:accountID/config',
      fluxAction: 'showConfigAccount'
    },
    'account.new': {
      pattern: 'account/new',
      fluxAction: 'showCreateAccount'
    },
    'account.mailbox.messages': {
      pattern: 'account/:accountID/mailbox/:mailboxID/page/:page',
      fluxAction: 'showMessageList'
    },
    'search': {
      pattern: 'search/:query/page/:page',
      fluxAction: 'showSearch'
    },
    'message': {
      pattern: 'message/:messageID',
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
        defaultParameters = {
          accountID: defaultAccount != null ? defaultAccount.get('id') : void 0,
          mailboxID: defaultMailbox != null ? defaultMailbox.get('id') : void 0,
          page: 1
        };
        break;
      case 'account.config':
        defaultAccount = (_ref = AccountStore.getDefault()) != null ? _ref.get('id') : void 0;
        defaultParameters = {
          accountID: defaultAccount
        };
        break;
      case 'search':
        defaultParameters = {
          query: "",
          page: 1
        };
        break;
      default:
        defaultParameters = null;
    }
    return defaultParameters;
  };

  return Router;

})(PanelRouter);
});

;require.register("stores/account_store", function(exports, require, module) {
var AccountStore, AccountTranslator, ActionTypes, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Store = require('../libs/flux/store/store');

ActionTypes = require('../constants/app_constants').ActionTypes;

AccountTranslator = require('../utils/translators/account_translator');

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
      account = AccountTranslator.toImmutable(account);
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
    var account, defaultID, mailboxes;
    account = _accounts.get(accountID) || this.getDefault();
    mailboxes = account.get('mailboxes');
    defaultID = account.get('favorites')[0];
    if (defaultID) {
      return mailboxes.get(defaultID);
    } else {
      return mailboxes.first();
    }
  };

  AccountStore.prototype.getSelected = function() {
    return _selectedAccount;
  };

  AccountStore.prototype.getSelectedMailboxes = function(flatten) {
    var emptyMap, getFlattenMailboxes, rawMailboxesTree;
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
      emptyMap = Immutable.OrderedMap.empty();
      return (_selectedAccount != null ? _selectedAccount.get('mailboxes') : void 0) || emptyMap;
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
    var ids, mailboxes;
    mailboxes = this.getSelectedMailboxes(true);
    ids = _selectedAccount != null ? _selectedAccount.get('favorites') : void 0;
    return mailboxes.filter(function(box, key) {
      return __indexOf.call(ids.slice(1), key) >= 0;
    }).toOrderedMap();
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

;require.register("stores/layout_store", function(exports, require, module) {
var ActionTypes, LayoutStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/store');

ActionTypes = require('../constants/app_constants').ActionTypes;

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

;require.register("stores/message_store", function(exports, require, module) {
var AccountStore, ActionTypes, AppDispatcher, LayoutActionCreator, MessageStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Store = require('../libs/flux/store/store');

AppDispatcher = require('../app_dispatcher');

AccountStore = require('./account_store');

ActionTypes = require('../constants/app_constants').ActionTypes;

LayoutActionCreator = require('../actions/layout_action_creator');

MessageStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _counts, _messages, _unreadCounts;

  __extends(MessageStore, _super);

  function MessageStore() {
    return MessageStore.__super__.constructor.apply(this, arguments);
  }

  _messages = Immutable.Sequence().mapKeys(function(_, message) {
    return message.id;
  }).map(function(message) {
    return Immutable.fromJS(message);
  }).toOrderedMap();

  _counts = Immutable.Map();

  _unreadCounts = Immutable.Map();


  /*
      Defines here the action handlers.
   */

  MessageStore.prototype.__bindHandlers = function(handle) {
    var onReceiveRawMessage;
    handle(ActionTypes.RECEIVE_RAW_MESSAGE, onReceiveRawMessage = function(message, silent) {
      if (silent == null) {
        silent = false;
      }
      message.hasAttachments = Array.isArray(message.attachments) && message.attachments.length > 0;
      if (message.createdAt == null) {
        message.createdAt = message.date;
      }
      if (message.attachments == null) {
        message.attachments = [];
      }
      message.attachments = message.attachments.map(function(file) {
        file.messageId = message.id;
        return file;
      });
      if (message.flags == null) {
        message.flags = [];
      }
      message = Immutable.Map(message);
      message.getReplyToAddress = function() {
        var from, reply;
        reply = this.get('replyTo');
        from = this.get('from');
        reply = (reply == null) || reply.length === 0 ? from : reply;
        return reply;
      };
      _messages = _messages.set(message.get('id'), message);
      if (!silent) {
        return this.emit('change');
      }
    });
    handle(ActionTypes.RECEIVE_RAW_MESSAGES, function(messages) {
      var message, _i, _len;
      if ((messages.count != null) && (messages.mailboxID != null)) {
        _counts = _counts.set(messages.mailboxID, messages.count);
        _unreadCounts = _unreadCounts.set(messages.mailboxID, messages.unread);
        messages = messages.messages;
      }
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
    handle(ActionTypes.MESSAGE_SEND, function(message) {
      return this.emit('change');
    });
    handle(ActionTypes.MESSAGE_DELETE, function(message) {
      return this.emit('change');
    });
    handle(ActionTypes.MESSAGE_BOXES, function(message) {
      return this.emit('change');
    });
    return handle(ActionTypes.MESSAGE_FLAG, function(message) {
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

  MessageStore.prototype.getMessagesCounts = function() {
    return _counts;
  };

  MessageStore.prototype.getUnreadMessagesCounts = function() {
    return _unreadCounts;
  };

  MessageStore.prototype.getMessagesByConversation = function(messageID) {
    var conversation, idToLook, idsToLook, newIdsToLook, temp;
    idsToLook = [messageID];
    conversation = [];
    while (idToLook = idsToLook.pop()) {
      conversation.push(this.getByID(idToLook));
      temp = _messages.filter(function(message) {
        return message.get('inReplyTo') === idToLook;
      });
      newIdsToLook = temp.map(function(item) {
        return item.get('id');
      }).toArray();
      idsToLook = idsToLook.concat(newIdsToLook);
    }
    return conversation;
  };

  return MessageStore;

})(Store);

module.exports = new MessageStore();
});

;require.register("stores/search_store", function(exports, require, module) {
var ActionTypes, SearchStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/store');

ActionTypes = require('../constants/app_constants').ActionTypes;

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
      if (typeof rawResult !== "undefined" && rawResult !== null) {
        _results = _results.withMutations(function(map) {
          return rawResults.forEach(function(rawResult) {
            var message;
            message = Immutable.Map(rawResult);
            return map.set(message.get('id'), message);
          });
        });
      } else {
        _results = Immutable.OrderedMap.empty();
      }
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

;require.register("stores/settings_store", function(exports, require, module) {
var ActionTypes, SettingsStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/store');

ActionTypes = require('../constants/app_constants').ActionTypes;

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
    composeInHTML: true,
    messageDisplayHTML: true,
    messageDisplayImages: false
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

;require.register("stores/tasks_store", function(exports, require, module) {
var ActionTypes, Store, TasksStore,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/store');

ActionTypes = require('../constants/app_constants').ActionTypes;

TasksStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _tasks;

  __extends(TasksStore, _super);

  function TasksStore() {
    return TasksStore.__super__.constructor.apply(this, arguments);
  }

  _tasks = Immutable.Sequence(window.tasks).mapKeys(function(_, task) {
    return task.id;
  }).map(function(message) {
    return Immutable.fromJS(message);
  }).toOrderedMap();


  /*
      Defines here the action handlers.
   */

  TasksStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.RECEIVE_TASK_UPDATE, function(task) {
      task = Immutable.Map(task);
      _tasks = _tasks.set(task.get('id'), task);
      return this.emit('change');
    });
    return handle(ActionTypes.RECEIVE_TASK_DELETE, function(taskid) {
      _tasks = _tasks.remove(taskid);
      return this.emit('change');
    });
  };

  TasksStore.prototype.getTasks = function() {
    return _tasks.toOrderedMap();
  };

  return TasksStore;

})(Store);

module.exports = new TasksStore();
});

;require.register("utils/message_utils", function(exports, require, module) {
module.exports = {
  displayAddresses: function(addresses, full) {
    var item, res, _i, _len;
    if (full == null) {
      full = false;
    }
    if (addresses == null) {
      return "";
    }
    res = [];
    for (_i = 0, _len = addresses.length; _i < _len; _i++) {
      item = addresses[_i];
      if (item == null) {
        break;
      }
      if (full) {
        if ((item.name != null) && item.name !== "") {
          res.push("\"" + item.name + "\" <" + item.address + ">");
        } else {
          res.push("" + item.address);
        }
      } else {
        if ((item.name != null) && item.name !== "") {
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
  },
  getAttachmentType: function(type) {
    var sub;
    sub = type.split('/');
    switch (sub[0]) {
      case 'audio':
      case 'image':
      case 'text':
      case 'video':
        return sub[0];
      case "application":
        switch (sub[1]) {
          case "vnd.ms-excel":
          case "vnd.oasis.opendocument.spreadsheet":
          case "vnd.openxmlformats-officedocument.spreadsheetml.sheet":
            return "spreadsheet";
          case "msword":
          case "vnd.ms-word":
          case "vnd.oasis.opendocument.text":
          case "vnd.openxmlformats-officedocument.wordprocessingm" + "l.document":
            return "word";
          case "vns.ms-powerpoint":
          case "vnd.oasis.opendocument.presentation":
          case "vnd.openxmlformats-officedocument.presentationml." + "presentation":
            return "presentation";
          case "pdf":
            return sub[1];
          case "gzip":
          case "zip":
            return 'archive';
        }
    }
  },
  convertAttachments: function(file) {
    var name;
    name = file.generatedFileName;
    return {
      name: name,
      size: file.length,
      type: file.contentType,
      originalName: file.fileName,
      contentDisposition: file.contentDisposition,
      contentId: file.contentId,
      transferEncoding: file.transferEncoding,
      url: "/message/" + file.messageId + "/attachments/" + name
    };
  },
  formatDate: function(date) {
    var formatter, today;
    if (date == null) {
      return;
    }
    today = moment();
    date = moment(date);
    if (date.isBefore(today, 'year')) {
      formatter = 'DD/MM/YYYY';
    } else if (date.isBefore(today, 'day')) {
      formatter = 'DD MMMM';
    } else {
      formatter = 'hh:mm';
    }
    return date.format(formatter);
  }
};
});

;require.register("utils/plugin_utils", function(exports, require, module) {
var __hasProp = {}.hasOwnProperty;

module.exports = {
  init: function() {
    var config, observer, onMutation, pluginConf, pluginName, _ref;
    if (window.plugins == null) {
      window.plugins = {};
    }
    _ref = window.plugins;
    for (pluginName in _ref) {
      if (!__hasProp.call(_ref, pluginName)) continue;
      pluginConf = _ref[pluginName];
      if (pluginConf.active) {
        this.activate(pluginName);
      }
    }
    if (typeof MutationObserver !== "undefined" && MutationObserver !== null) {
      config = {
        attributes: false,
        childList: true,
        characterData: false,
        subtree: true
      };
      onMutation = function(mutations) {
        var check, checkNode, mutation, _i, _len, _results;
        checkNode = function(node, action) {
          var listener, _ref1, _results;
          if (node.nodeType !== Node.ELEMENT_NODE) {
            return;
          }
          _ref1 = window.plugins;
          _results = [];
          for (pluginName in _ref1) {
            if (!__hasProp.call(_ref1, pluginName)) continue;
            pluginConf = _ref1[pluginName];
            if (pluginConf.active) {
              if (action === 'add') {
                listener = pluginConf.onAdd;
              }
              if (action === 'delete') {
                listener = pluginConf.onDelete;
              }
              if ((listener != null) && listener.condition.bind(pluginConf)(node)) {
                _results.push(listener.action.bind(pluginConf)(node));
              } else {
                _results.push(void 0);
              }
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        };
        check = function(mutation) {
          var node, nodes, _i, _j, _len, _len1, _results;
          nodes = Array.prototype.slice.call(mutation.addedNodes);
          for (_i = 0, _len = nodes.length; _i < _len; _i++) {
            node = nodes[_i];
            checkNode(node, 'add');
          }
          nodes = Array.prototype.slice.call(mutation.removedNodes);
          _results = [];
          for (_j = 0, _len1 = nodes.length; _j < _len1; _j++) {
            node = nodes[_j];
            _results.push(checkNode(node, 'del'));
          }
          return _results;
        };
        _results = [];
        for (_i = 0, _len = mutations.length; _i < _len; _i++) {
          mutation = mutations[_i];
          _results.push(check(mutation));
        }
        return _results;
      };
      observer = new MutationObserver(onMutation);
      return observer.observe(document, config);
    } else {
      return setInterval(function() {
        var _ref1, _results;
        _ref1 = window.plugins;
        _results = [];
        for (pluginName in _ref1) {
          if (!__hasProp.call(_ref1, pluginName)) continue;
          pluginConf = _ref1[pluginName];
          if (pluginConf.active) {
            if (pluginConf.onAdd != null) {
              if (pluginConf.onAdd.condition(document.body)) {
                _results.push(pluginConf.onAdd.action(document.body));
              } else {
                _results.push(void 0);
              }
            } else {
              _results.push(void 0);
            }
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      }, 200);
    }
  },
  activate: function(key) {
    var event, listener, plugin, pluginConf, pluginName, type, _ref, _ref1, _results;
    plugin = window.plugins[key];
    type = plugin.type;
    plugin.active = true;
    if (plugin.listeners != null) {
      _ref = plugin.listeners;
      for (event in _ref) {
        if (!__hasProp.call(_ref, event)) continue;
        listener = _ref[event];
        window.addEventListener(event, listener.bind(plugin));
      }
    }
    if (plugin.onActivate) {
      plugin.onActivate();
    }
    if (type != null) {
      _ref1 = window.plugins;
      _results = [];
      for (pluginName in _ref1) {
        if (!__hasProp.call(_ref1, pluginName)) continue;
        pluginConf = _ref1[pluginName];
        if (pluginName === key) {
          continue;
        }
        if (pluginConf.type === type && pluginConf.active) {
          _results.push(this.deactivate(pluginName));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  },
  deactivate: function(key) {
    var event, listener, plugin, _ref;
    plugin = window.plugins[key];
    plugin.active = false;
    if (plugin.listeners != null) {
      _ref = plugin.listeners;
      for (event in _ref) {
        if (!__hasProp.call(_ref, event)) continue;
        listener = _ref[event];
        window.removeEventListener(event, listener);
      }
    }
    if (plugin.onDeactivate) {
      return plugin.onDeactivate();
    }
  }
};
});

;require.register("utils/socketio_utils", function(exports, require, module) {
var ActionTypes, AppDispatcher, TaskStore, dispatchTaskDelete, dispatchTaskUpdate, pathToSocketIO, socket, url;

TaskStore = require('../stores/tasks_store');

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

url = window.location.origin;

pathToSocketIO = "" + (window.location.pathname.substring(1)) + "socket.io";

socket = io.connect(url, {
  resource: pathToSocketIO
});

dispatchTaskUpdate = function(task) {
  return AppDispatcher.handleServerAction({
    type: ActionTypes.RECEIVE_TASK_UPDATE,
    value: task
  });
};

dispatchTaskDelete = function(taskid) {
  return AppDispatcher.handleServerAction({
    type: ActionTypes.RECEIVE_TASK_DELETE,
    value: taskid
  });
};

socket.on('task.create', dispatchTaskUpdate);

socket.on('task.update', dispatchTaskUpdate);

socket.on('task.delete', dispatchTaskDelete);

module.exports = {
  acknowledgeTask: function(taskid) {
    console.log(taskid);
    return socket.emit('mark_ack', taskid);
  }
};
});

;require.register("utils/translators/account_translator", function(exports, require, module) {
var toRawObject;

module.exports = {
  toImmutable: function(rawAccount) {
    var _createImmutableMailboxes;
    _createImmutableMailboxes = function(children) {
      return Immutable.Sequence(children).mapKeys(function(_, mailbox) {
        return mailbox.id;
      }).map(function(mailbox) {
        children = mailbox.children;
        mailbox.children = _createImmutableMailboxes(children);
        return Immutable.Map(mailbox);
      }).toOrderedMap();
    };
    rawAccount.mailboxes = _createImmutableMailboxes(rawAccount.mailboxes);
    return Immutable.Map(rawAccount);
  },
  toRawObject: toRawObject = function(account) {
    var mailboxes, _createRawObjectMailboxes;
    _createRawObjectMailboxes = function(children) {
      return children != null ? children.map(function(child) {
        children = child.get('children');
        return child.set('children', _createRawObjectMailboxes(children));
      }).toVector() : void 0;
    };
    mailboxes = account.get('mailboxes');
    account = account.set('mailboxes', _createRawObjectMailboxes(mailboxes));
    return account.toJS();
  }
};
});

;require.register("utils/xhr_utils", function(exports, require, module) {
var AccountTranslator, SettingsStore, request;

request = superagent;

AccountTranslator = require('./translators/account_translator');

SettingsStore = require('../stores/settings_store');

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
  messageDelete: function(messageId, callback) {
    return request.del("/message/" + messageId).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback("Something went wrong -- " + res.body);
      }
    });
  },
  messagePatch: function(messageId, patch, callback) {
    return request.patch("/message/" + messageId, patch).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback("Something went wrong -- " + res.body);
      }
    });
  },
  conversationDelete: function(conversationId, callback) {
    return request.del("/conversation/" + conversationId).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback("Something went wrong -- " + res.body);
      }
    });
  },
  conversationPatch: function(conversationId, patch, callback) {
    return request.patch("/conversation/" + conversationId, patch).set('Accept', 'application/json').end(function(res) {
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
  accountDiscover: function(domain, callback) {
    return request.get("provider/" + domain).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback(res.body, null);
      }
    });
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

;
//# sourceMappingURL=app.js.map