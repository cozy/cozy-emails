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
var AccountActionCreator, AccountStore, ActionTypes, AppDispatcher, LayoutActionCreator, XHRUtils;

XHRUtils = require('../utils/xhr_utils');

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

AccountStore = require('../stores/account_store');

LayoutActionCreator = null;

module.exports = AccountActionCreator = {
  create: function(inputValues, afterCreation) {
    AccountActionCreator._setNewAccountWaitingStatus(true);
    return XHRUtils.createAccount(inputValues, function(error, account) {
      if ((error != null) || (account == null)) {
        return AccountActionCreator._setNewAccountError(error);
      } else {
        AppDispatcher.handleViewAction({
          type: ActionTypes.ADD_ACCOUNT,
          value: account
        });
        return afterCreation(AccountStore.getByID(account.id));
      }
    });
  },
  edit: function(inputValues, accountID) {
    var account, newAccount;
    AccountActionCreator._setNewAccountWaitingStatus(true);
    account = AccountStore.getByID(accountID);
    newAccount = account.mergeDeep(inputValues);
    return XHRUtils.editAccount(newAccount, function(error, rawAccount) {
      if (error != null) {
        return AccountActionCreator._setNewAccountError(error);
      } else {
        AppDispatcher.handleViewAction({
          type: ActionTypes.EDIT_ACCOUNT,
          value: rawAccount
        });
        LayoutActionCreator = require('../actions/layout_action_creator');
        return LayoutActionCreator.notify(t('account updated'), {
          autoclose: true
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
  selectAccount: function(accountID, mailboxID) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SELECT_ACCOUNT,
      value: {
        accountID: accountID,
        mailboxID: mailboxID
      }
    });
  },
  discover: function(domain, callback) {
    return XHRUtils.accountDiscover(domain, function(err, infos) {
      if (infos == null) {
        infos = [];
      }
      return callback(err, infos);
    });
  },
  mailboxCreate: function(inputValues, callback) {
    return XHRUtils.mailboxCreate(inputValues, function(error, account) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.MAILBOX_CREATE,
          value: account
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  mailboxUpdate: function(inputValues, callback) {
    return XHRUtils.mailboxUpdate(inputValues, function(error, account) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.MAILBOX_UPDATE,
          value: account
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  mailboxDelete: function(inputValues, callback) {
    return XHRUtils.mailboxDelete(inputValues, function(error, account) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.MAILBOX_DELETE,
          value: account
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  }
};
});

;require.register("actions/contact_action_creator", function(exports, require, module) {
var ActionTypes, Activity, AppDispatcher, ContactActionCreator, LayoutActionCreator;

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

Activity = require('../utils/activity_utils');

LayoutActionCreator = require('../actions/layout_action_creator');

module.exports = ContactActionCreator = {
  searchContact: function(query) {
    var activity, options;
    options = {
      name: 'search',
      data: {
        type: 'contact',
        query: query
      }
    };
    activity = new Activity(options);
    activity.onsuccess = function() {
      return AppDispatcher.handleViewAction({
        type: ActionTypes.RECEIVE_RAW_CONTACT_RESULTS,
        value: this.result
      });
    };
    return activity.onerror = function() {
      return console.log("KO", this.error, this.name);
    };
  },
  searchContactLocal: function(query) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.CONTACT_LOCAL_SEARCH,
      value: query
    });
  },
  createContact: function(contact) {
    var activity, options;
    options = {
      name: 'create',
      data: {
        type: 'contact',
        contact: contact
      }
    };
    activity = new Activity(options);
    activity.onsuccess = function() {
      var msg;
      AppDispatcher.handleViewAction({
        type: ActionTypes.RECEIVE_RAW_CONTACT_RESULTS,
        value: this.result
      });
      msg = t('contact create success', {
        contact: contact.name || contact.address
      });
      return LayoutActionCreator.notify(msg, {
        autoclose: true
      });
    };
    return activity.onerror = function() {
      var msg;
      msg = t('contact create error', {
        error: this.name
      });
      return LayoutActionCreator.notify(msg, {
        autoclose: true
      });
    };
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
var AccountActionCreator, AccountStore, ActionTypes, AlertLevel, AppDispatcher, LayoutActionCreator, LayoutStore, MessageActionCreator, MessageStore, SearchActionCreator, SocketUtils, XHRUtils, _cachedQuery, _ref;

XHRUtils = require('../utils/xhr_utils');

SocketUtils = require('../utils/socketio_utils');

AccountStore = require('../stores/account_store');

LayoutStore = require('../stores/layout_store');

MessageStore = require('../stores/message_store');

AppDispatcher = require('../app_dispatcher');

_ref = require('../constants/app_constants'), ActionTypes = _ref.ActionTypes, AlertLevel = _ref.AlertLevel;

AccountActionCreator = require('./account_action_creator');

MessageActionCreator = require('./message_action_creator');

SearchActionCreator = require('./search_action_creator');

_cachedQuery = {};

module.exports = LayoutActionCreator = {
  setDisposition: function(type, value) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SET_DISPOSITION,
      value: {
        type: type,
        value: value
      }
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
  alertHide: function(level, message) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.HIDE_ALERT
    });
  },
  refresh: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.REFRESH,
      value: null
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
  notify: function(message, options) {
    var task;
    task = {
      id: Date.now(),
      finished: true,
      message: message
    };
    if (options != null) {
      task.autoclose = options.autoclose;
      task.errors = options.errors;
      task.finished = options.finished;
      task.actions = options.actions;
    }
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RECEIVE_TASK_UPDATE,
      value: task
    });
  },
  clearToasts: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.CLEAR_TOASTS,
      value: null
    });
  },
  filterMessages: function(filter) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.LIST_FILTER,
      value: filter
    });
  },
  quickFilterMessages: function(filter) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.LIST_QUICK_FILTER,
      value: filter
    });
  },
  sortMessages: function(sort) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.LIST_SORT,
      value: sort
    });
  },
  getDefaultRoute: function() {
    if (AccountStore.getAll().length === 0) {
      return 'account.new';
    } else {
      return 'account.mailbox.messages';
    }
  },
  showMessageList: function(panelInfo) {
    var accountID, cached, mailboxID, query, selectedAccount, selectedMailbox, _ref1;
    _ref1 = panelInfo.parameters, accountID = _ref1.accountID, mailboxID = _ref1.mailboxID;
    selectedAccount = AccountStore.getSelected();
    selectedMailbox = AccountStore.getSelectedMailbox();
    if ((selectedAccount == null) || selectedAccount.get('id') !== accountID || selectedMailbox.get('id') !== mailboxID) {
      AccountActionCreator.selectAccount(accountID, mailboxID);
    }
    cached = _cachedQuery.mailboxID === mailboxID;
    query = {};
    ['sort', 'after', 'before', 'flag', 'pageAfter'].forEach(function(param) {
      var value;
      value = panelInfo.parameters[param];
      if ((value != null) && value !== '') {
        query[param] = value;
        if (_cachedQuery[param] !== value) {
          _cachedQuery[param] = value;
          return cached = false;
        }
      }
    });
    _cachedQuery.mailboxID = mailboxID;
    if (!cached) {
      MessageActionCreator.setFetching(true);
      return XHRUtils.fetchMessagesByFolder(mailboxID, query, function(err, rawMessages) {
        MessageActionCreator.setFetching(false);
        if (err != null) {
          return LayoutActionCreator.alertError(err);
        } else {
          return MessageActionCreator.receiveRawMessages(rawMessages);
        }
      });
    }
  },
  showMessage: function(panelInfo, direction) {
    var message, messageID, onMessage;
    onMessage = function(msg) {
      var selectedAccount;
      selectedAccount = AccountStore.getSelected();
      if ((selectedAccount == null) && (msg != null ? msg.accountID : void 0)) {
        return AccountActionCreator.selectAccount(msg.accountID);
      }
    };
    messageID = panelInfo.parameters.messageID;
    message = MessageStore.getByID(messageID);
    if (message != null) {
      return onMessage(message);
    } else {
      return XHRUtils.fetchMessage(messageID, function(err, rawMessage) {
        if (err != null) {
          return LayoutActionCreator.alertError(err);
        } else {
          MessageActionCreator.receiveRawMessage(rawMessage);
          return onMessage(rawMessage);
        }
      });
    }
  },
  showConversation: function(panelInfo, direction) {
    var conversationID, message, messageID, onMessage;
    onMessage = function(msg) {
      var selectedAccount;
      selectedAccount = AccountStore.getSelected();
      if ((selectedAccount == null) && (msg != null ? msg.accountID : void 0)) {
        return AccountActionCreator.selectAccount(msg.accountID);
      }
    };
    messageID = panelInfo.parameters.messageID;
    message = MessageStore.getByID(messageID);
    if (message != null) {
      onMessage(message);
      conversationID = message.get('conversationID');
      return XHRUtils.fetchConversation(conversationID, function(err, rawMessages) {
        if (err != null) {
          return LayoutActionCreator.alertError(err);
        } else {
          MessageActionCreator.receiveRawMessages(rawMessages);
          return onMessage(rawMessages[0]);
        }
      });
    } else {
      return XHRUtils.fetchMessage(messageID, function(err, rawMessage) {
        if (err != null) {
          return LayoutActionCreator.alertError(err);
        } else {
          MessageActionCreator.receiveRawMessage(rawMessage);
          return onMessage(rawMessage);
        }
      });
    }
  },
  showComposeNewMessage: function(panelInfo, direction) {
    var defaultAccount, selectedAccount;
    selectedAccount = AccountStore.getSelected();
    if (selectedAccount == null) {
      defaultAccount = AccountStore.getDefault();
      return AccountActionCreator.selectAccount(defaultAccount.get('id'));
    }
  },
  showComposeMessage: function(panelInfo, direction) {
    var defaultAccount, selectedAccount;
    selectedAccount = AccountStore.getSelected();
    if (selectedAccount == null) {
      defaultAccount = AccountStore.getDefault();
      return AccountActionCreator.selectAccount(defaultAccount.get('id'));
    }
  },
  showCreateAccount: function(panelInfo, direction) {
    return AccountActionCreator.selectAccount(null);
  },
  showConfigAccount: function(panelInfo, direction) {
    return AccountActionCreator.selectAccount(panelInfo.parameters.accountID);
  },
  showSearch: function(panelInfo, direction) {
    var page, query, _ref1;
    AccountActionCreator.selectAccount(null);
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
  showSettings: function(panelInfo, direction) {},
  refreshMessages: function() {
    return XHRUtils.refresh(function(results) {
      if (results === "done") {
        MessageActionCreator.receiveRawMessages(null);
        return LayoutActionCreator.notify(t('account refreshed'), {
          autoclose: true
        });
      }
    });
  },
  toastsShow: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.TOASTS_SHOW
    });
  },
  toastsHide: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.TOASTS_HIDE
    });
  }
};
});

;require.register("actions/message_action_creator", function(exports, require, module) {
var AccountStore, ActionTypes, AppDispatcher, MessageStore, XHRUtils;

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

XHRUtils = require('../utils/xhr_utils');

AccountStore = require("../stores/account_store");

MessageStore = require('../stores/message_store');

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
  setFetching: function(fetching) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SET_FETCHING,
      value: fetching
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
        return callback(error, message);
      }
    });
  },
  "delete": function(message, callback) {
    var LayoutActionCreator, doDelete, mass;
    LayoutActionCreator = require('./layout_action_creator');
    doDelete = function(message) {
      var account, id, msg, observer, patches, trash;
      if (typeof message === "string") {
        message = MessageStore.getByID(message);
      }
      account = AccountStore.getByID(message.get('accountID'));
      if (account == null) {
        console.log("No account with id " + (message.get('accountID')) + " for message " + (message.get('id')));
        LayoutActionCreator.alertError(t('app error'));
        return;
      }
      trash = account.get('trashMailbox');
      if ((trash == null) || trash === '') {
        return LayoutActionCreator.alertError(t('message delete no trash'));
      } else {
        msg = message.toJSON();
        AppDispatcher.handleViewAction({
          type: ActionTypes.MESSAGE_ACTION,
          value: {
            id: message.get('id'),
            from: Object.keys(msg.mailboxIDs),
            to: trash
          }
        });
        observer = jsonpatch.observe(msg);
        for (id in msg.mailboxIDs) {
          delete msg.mailboxIDs[id];
        }
        msg.mailboxIDs[trash] = -1;
        patches = jsonpatch.generate(observer);
        return XHRUtils.messagePatch(message.get('id'), patches, (function(_this) {
          return function(err, message) {
            var options;
            if (err == null) {
              AppDispatcher.handleViewAction({
                type: ActionTypes.MESSAGE_DELETE,
                value: msg
              });
            } else {
              LayoutActionCreator.alertError("" + (t("message action delete ko")) + " " + err);
            }
            if (!mass) {
              options = {
                autoclose: true,
                actions: [
                  {
                    label: t('message undelete'),
                    onClick: function() {
                      return _this.undelete();
                    }
                  }
                ]
              };
              LayoutActionCreator.notify(t('message action delete ok', {
                subject: msg.subject
              }), options);
              if (callback != null) {
                return callback(err);
              }
            }
          };
        })(this));
      }
    };
    if (Array.isArray(message)) {
      mass = true;
      message.forEach(doDelete);
      if (callback != null) {
        return callback();
      }
    } else {
      mass = false;
      return doDelete(message);
    }
  },
  move: function(message, from, to, callback) {
    var msg, observer, patches;
    if (typeof message === "string") {
      message = MessageStore.getByID(message);
    }
    msg = message.toJSON();
    AppDispatcher.handleViewAction({
      type: ActionTypes.MESSAGE_ACTION,
      value: {
        id: message.get('id'),
        from: from,
        to: to
      }
    });
    observer = jsonpatch.observe(msg);
    delete msg.mailboxIDs[from];
    msg.mailboxIDs[to] = -1;
    patches = jsonpatch.generate(observer);
    return XHRUtils.messagePatch(message.get('id'), patches, function(error, message) {
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.RECEIVE_RAW_MESSAGE,
          value: msg
        });
      }
      if (callback != null) {
        return callback(error);
      }
    });
  },
  undelete: function() {
    var LayoutActionCreator, action, message;
    LayoutActionCreator = require('./layout_action_creator');
    action = MessageStore.getPrevAction();
    if (action != null) {
      message = MessageStore.getByID(action.id);
      return this.move(message, action.to, action.from, function(err) {
        if (err == null) {
          return LayoutActionCreator.notify(t('message undelete ok'));
        }
      });
    } else {
      return LayoutActionCreator.alertError(t('message undelete error'));
    }
  },
  updateFlag: function(message, flags, callback) {
    var msg, patches;
    msg = message.toJSON();
    patches = jsonpatch.compare({
      flags: msg.flags
    }, {
      flags: flags
    });
    XHRUtils.messagePatch(message.get('id'), patches, function(error, messageUpdated) {
      if (error == null) {
        if (!_.isEqual(flags, messageUpdated.flags)) {
          AppDispatcher.handleViewAction({
            type: ActionTypes.RECEIVE_RAW_MESSAGE,
            value: messageUpdated
          });
        }
      }
      if (callback != null) {
        return callback(error);
      }
    });
    return setTimeout(function() {
      var messageUpdated;
      messageUpdated = message.toJS();
      messageUpdated.flags = flags;
      return AppDispatcher.handleViewAction({
        type: ActionTypes.RECEIVE_RAW_MESSAGE,
        value: messageUpdated
      });
    }, 0);
  },
  setCurrent: function(messageID) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.MESSAGE_CURRENT,
      value: messageID
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
var ActionTypes, AppDispatcher, LayoutActionCreator, SettingsActionCreator, SettingsStore, XHRUtils;

XHRUtils = require('../utils/xhr_utils');

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

SettingsStore = require('../stores/settings_store');

LayoutActionCreator = require('./layout_action_creator');

module.exports = SettingsActionCreator = {
  edit: function(inputValues) {
    return XHRUtils.changeSettings(inputValues, function(err, values) {
      if (err) {
        return LayoutActionCreator.alertError(t('settings save error') + err);
      } else {
        return AppDispatcher.handleViewAction({
          type: ActionTypes.SETTINGS_UPDATED,
          value: values
        });
      }
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
var AccountActionCreator, LAC, MailboxItem, MailboxList, RouterMixin, a, button, classer, div, fieldset, form, h3, h4, i, input, label, legend, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, p = _ref.p, h3 = _ref.h3, h4 = _ref.h4, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, fieldset = _ref.fieldset, legend = _ref.legend;

classer = React.addons.classSet;

MailboxList = require('./mailbox-list');

AccountActionCreator = require('../actions/account_action_creator');

RouterMixin = require('../mixins/router_mixin');

LAC = require('../actions/layout_action_creator');

classer = React.addons.classSet;

module.exports = React.createClass({
  displayName: 'AccountConfig',
  _lastDiscovered: '',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  _accountFields: ['id', 'label', 'name', 'login', 'password', 'imapServer', 'imapPort', 'imapSSL', 'imapTLS', 'smtpServer', 'smtpPort', 'smtpSSL', 'smtpTLS', 'accountType', 'mailboxes', 'favoriteMailboxes', 'draftMailbox', 'sentMailbox', 'trashMailbox'],
  _accountSchema: {
    properties: {
      'label': {
        allowEmpty: false
      },
      'name': {
        allowEmpty: false
      },
      'login': {
        allowEmpty: false
      },
      'password': {
        allowEmpty: false
      },
      'imapServer': {
        allowEmpty: false
      },
      'imapPort': {
        allowEmpty: false
      },
      'imapSSL': {
        allowEmpty: true
      },
      'imapTLS': {
        allowEmpty: true
      },
      'smtpServer': {
        allowEmpty: false
      },
      'smtpPort': {
        allowEmpty: false
      },
      'smtpSSL': {
        allowEmpty: true
      },
      'smtpTLS': {
        allowEmpty: true
      },
      'draftMailbox': {
        allowEmpty: true
      },
      'sentMailbox': {
        allowEmpty: true
      },
      'trashMailbox': {
        allowEmpty: true
      },
      'accountType': {
        allowEmpty: true
      }
    }
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var tabAccountClass, tabAccountUrl, tabMailboxClass, tabMailboxUrl, titleLabel;
    if (this.state.id) {
      titleLabel = t("account edit");
    } else {
      titleLabel = t("account new");
    }
    tabAccountClass = tabMailboxClass = '';
    tabAccountUrl = tabMailboxUrl = null;
    if (!this.props.tab || this.props.tab === 'account') {
      tabAccountClass = 'active';
      tabMailboxUrl = this.buildUrl({
        direction: 'first',
        action: 'account.config',
        parameters: [this.state.id, 'mailboxes']
      });
    } else {
      tabMailboxClass = 'active';
      tabAccountUrl = this.buildUrl({
        direction: 'first',
        action: 'account.config',
        parameters: [this.state.id, 'account']
      });
    }
    return div({
      id: 'mailbox-config'
    }, h3({
      className: null
    }, titleLabel), this.props.tab != null ? ul({
      className: "nav nav-tabs",
      role: "tablist"
    }, li({
      className: tabAccountClass
    }, a({
      href: tabAccountUrl
    }, t("account tab account"))), li({
      className: tabMailboxClass
    }, a({
      href: tabMailboxUrl
    }, t("account tab mailboxes")))) : void 0, !this.props.tab || this.props.tab === 'account' ? this.renderMain() : this.renderMailboxes());
  },
  renderError: function() {
    var message;
    if (this.props.error && this.props.error.name === 'AccountConfigError') {
      message = t('config error ' + this.props.error.field);
      return div({
        className: 'alert alert-warning'
      }, message);
    } else if (this.props.error) {
      return div({
        className: 'alert alert-warning'
      }, this.props.error.message);
    } else if (Object.keys(this.state.errors).length !== 0) {
      return div({
        className: 'alert alert-warning'
      }, t('account errors'));
    }
  },
  renderMain: function() {
    var buttonLabel, cancelUrl, getError, hasError;
    if (this.props.isWaiting) {
      buttonLabel = 'Saving...';
    } else if (this.props.selectedAccount != null) {
      buttonLabel = t("account save");
    } else {
      buttonLabel = t("account add");
    }
    hasError = (function(_this) {
      return function(fields) {
        var errors;
        if (!Array.isArray(fields)) {
          fields = [fields];
        }
        errors = fields.some(function(field) {
          return _this.state.errors[field] != null;
        });
        if (errors) {
          return ' has-error';
        } else {
          return '';
        }
      };
    })(this);
    getError = (function(_this) {
      return function(field) {
        if (_this.state.errors[field] != null) {
          return div({
            className: 'col-sm-5 col-sm-offset-2 control-label'
          }, _this.state.errors[field]);
        }
      };
    })(this);
    cancelUrl = this.buildUrl({
      direction: 'first',
      action: 'default',
      fullWidth: true
    });
    return form({
      className: 'form-horizontal'
    }, this.renderError(), fieldset(null, legend(null, t('account identifiers'))), div({
      className: 'form-group' + hasError('label')
    }, label({
      htmlFor: 'mailbox-label',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("account label")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-label',
      name: 'mailbox-label',
      valueLink: this.linkState('label'),
      type: 'text',
      className: 'form-control',
      placeholder: t("account name short"),
      onBlur: this.validateForm
    })), getError('label')), div({
      className: 'form-group' + hasError('name')
    }, label({
      htmlFor: 'mailbox-name',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("account user name")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-name',
      name: 'mailbox-name',
      valueLink: this.linkState('name'),
      type: 'text',
      className: 'form-control',
      placeholder: t("account user fullname"),
      onBlur: this.validateForm
    })), getError('name')), div({
      className: 'form-group' + hasError(['login', 'auth'])
    }, label({
      htmlFor: 'mailbox-email-address',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("account address")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-email-address',
      name: 'mailbox-email-address',
      valueLink: this.linkState('login'),
      ref: 'login',
      onBlur: this.discover,
      type: 'email',
      className: 'form-control',
      placeholder: t("account address placeholder")
    })), getError('login')), div({
      className: 'form-group' + hasError(['password', 'auth'])
    }, label({
      htmlFor: 'mailbox-password',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account password')), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-password',
      name: 'mailbox-password',
      valueLink: this.linkState('password'),
      type: 'password',
      className: 'form-control',
      onBlur: this.validateForm
    })), getError('password')), this.state.displayGMAILSecurity ? fieldset(null, legend(null, t('gmail security tile')), p(null, t('gmail security body', {
      login: this.state.login
    })), p(null, a({
      target: '_blank',
      href: "https://www.google.com/settings/security/lesssecureapps"
    }, t('gmail security link')))) : void 0, fieldset(null, legend(null, t('account sending server')), div({
      className: 'form-group' + hasError(['smtp', 'smtpServer', 'smtpPort'])
    }, label({
      htmlFor: 'mailbox-smtp-server',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("account sending server")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-smtp-server',
      name: 'mailbox-smtp-server',
      valueLink: this.linkState('smtpServer'),
      type: 'text',
      className: 'form-control',
      placeholder: 'smtp.provider.tld',
      onBlur: this.validateForm
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-smtp-port',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account port')), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-smtp-port',
      name: 'mailbox-smtp-port',
      valueLink: this.linkState('smtpPort'),
      type: 'text',
      className: 'form-control',
      onBlur: this._onSMTPPort,
      onInput: (function(_this) {
        return function() {
          return _this.setState({
            smtpManualPort: true
          });
        };
      })(this)
    })), getError('smtpServer'), getError('smtpPort')), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-smtp-ssl',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account SSL')), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-smtp-ssl',
      name: 'mailbox-smtp-ssl',
      checkedLink: this.linkState('smtpSSL'),
      type: 'checkbox',
      onClick: (function(_this) {
        return function(ev) {
          return _this._onServerParam(ev.target, 'smtp', 'ssl');
        };
      })(this)
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-smtp-tls',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account TLS')), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-smtp-tls',
      name: 'mailbox-smtp-tls',
      checkedLink: this.linkState('smtpTLS'),
      type: 'checkbox',
      onClick: (function(_this) {
        return function(ev) {
          return _this._onServerParam(ev.target, 'smtp', 'tls');
        };
      })(this)
    })))), div({
      className: 'hidden'
    }, label({
      htmlFor: 'account-type',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account type')), div({
      className: 'col-sm-3'
    }, input({
      id: 'account-type',
      name: 'account-type',
      ref: 'type',
      valueLink: this.linkState('accountType'),
      type: 'text',
      className: 'form-control'
    })), getError('password')), fieldset(null, legend(null, t('account receiving server')), div({
      className: 'form-group' + hasError(['imap', 'imapServer', 'imapPort'])
    }, label({
      htmlFor: 'mailbox-imap-server',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t("account receiving server")), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-imap-server',
      name: 'mailbox-imap-server',
      valueLink: this.linkState('imapServer'),
      type: 'text',
      className: 'form-control',
      placeholder: 'imap.provider.tld',
      onBlur: this.validateForm
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-imap-port',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, 'Port'), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-imap-port',
      name: 'mailbox-imap-port',
      valueLink: this.linkState('imapPort'),
      type: 'text',
      className: 'form-control',
      onBlur: this._onIMAPPort,
      onInput: (function(_this) {
        return function() {
          return _this.setState({
            imapManualPort: true
          });
        };
      })(this)
    })), getError('imapServer'), getError('imapPort')), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-imap-ssl',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account SSL')), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-imap-ssl',
      name: 'mailbox-imap-ssl',
      checkedLink: this.linkState('imapSSL'),
      type: 'checkbox',
      onClick: (function(_this) {
        return function(ev) {
          return _this._onServerParam(ev.target, 'imap', 'ssl');
        };
      })(this)
    }))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'mailbox-imap-tls',
      className: 'col-sm-2 col-sm-offset-2 control-label'
    }, t('account TLS')), div({
      className: 'col-sm-3'
    }, input({
      id: 'mailbox-imap-tls',
      name: 'mailbox-imap-tls',
      checkedLink: this.linkState('imapTLS'),
      type: 'checkbox',
      onClick: (function(_this) {
        return function(ev) {
          return _this._onServerParam(ev.target, 'imap', 'tls');
        };
      })(this)
    })))), fieldset(null, legend(null, t('account actions'))), div({
      className: ''
    }, div({
      className: 'col-sm-offset-4'
    }, button({
      className: 'btn btn-cozy',
      onClick: this.onSubmit
    }, buttonLabel)), this.state.id != null ? fieldset(null, legend(null, t('account danger zone')), div({
      className: 'col-sm-offset-4'
    }, button({
      className: 'btn btn-default btn-danger btn-remove',
      onClick: this.onRemove
    }, t("account remove")))) : void 0));
  },
  renderMailboxes: function() {
    var favorites, mailboxes;
    favorites = this.state.favoriteMailboxes;
    if ((this.state.mailboxes != null) && (favorites != null)) {
      mailboxes = this.state.mailboxes.map((function(_this) {
        return function(mailbox, key) {
          var error, favorite;
          try {
            favorite = favorites.get(mailbox.get('id')) != null;
            return MailboxItem({
              accountID: _this.state.id,
              mailbox: mailbox,
              favorite: favorite
            });
          } catch (_error) {
            error = _error;
            return console.log(error, favorites);
          }
        };
      })(this)).toJS();
    }
    return form({
      className: 'form-horizontal'
    }, this.renderError(), this._renderMailboxChoice(t('account draft mailbox'), "draftMailbox"), this._renderMailboxChoice(t('account sent mailbox'), "sentMailbox"), this._renderMailboxChoice(t('account trash mailbox'), "trashMailbox"), h4({
      className: 'config-title'
    }, t("account tab mailboxes")), ul({
      className: "folder-list list-unstyled boxes container"
    }, mailboxes != null ? li({
      className: 'row box title',
      key: 'title'
    }, span({
      className: "col-xs-1"
    }, ''), span({
      className: "col-xs-1"
    }, ''), span({
      className: "col-xs-6"
    }, ''), span({
      className: "col-xs-1"
    }, ''), span({
      className: "col-xs-1 text-center"
    }, t('mailbox title total')), span({
      className: "col-xs-1 text-center"
    }, t('mailbox title unread')), span({
      className: "col-xs-1 text-center"
    }, t('mailbox title new'))) : void 0, mailboxes, li({
      className: "row box new",
      key: 'new'
    }, span({
      className: "col-xs-1 box-action add",
      onClick: this.addMailbox,
      title: t("mailbox title add")
    }, i({
      className: 'fa fa-plus'
    })), span({
      className: "col-xs-1 box-action cancel",
      onClick: this.undoMailbox,
      title: t("mailbox title add cancel")
    }, i({
      className: 'fa fa-undo'
    })), div({
      className: 'col-xs-6'
    }, input({
      id: 'newmailbox',
      ref: 'newmailbox',
      type: 'text',
      className: 'form-control',
      placeholder: t("account newmailbox placeholder"),
      onKeyDown: this.onKeyDown
    })), label({
      className: 'col-xs-2 text-center control-label'
    }, t("account newmailbox parent")), div({
      className: 'col-xs-2 text-center'
    }, MailboxList({
      allowUndefined: true,
      mailboxes: this.state.mailboxes,
      selectedMailbox: this.state.newMailboxParent,
      onChange: (function(_this) {
        return function(mailbox) {
          return _this.setState({
            newMailboxParent: mailbox
          });
        };
      })(this)
    })))));
  },
  onKeyDown: function(evt) {
    switch (evt.key) {
      case "Enter":
        return this.addMailbox();
    }
  },
  _renderMailboxChoice: function(labelText, box) {
    if (this.state.id != null) {
      return div({
        className: "form-group " + box
      }, label({
        className: 'col-sm-2 col-sm-offset-2 control-label'
      }, labelText), div({
        className: 'col-sm-3'
      }, MailboxList({
        allowUndefined: true,
        mailboxes: this.state.mailboxes,
        selectedMailbox: this.state[box],
        onChange: (function(_this) {
          return function(mailbox) {
            var newState;
            newState = {};
            newState[box] = mailbox;
            return _this.setState(newState, function() {
              return _this.onSubmit();
            });
          };
        })(this)
      })));
    }
  },
  _afterMount: function() {
    var node;
    node = document.querySelector("#mailbox-config .alert");
    if (node != null) {
      return node.scrollIntoView();
    }
  },
  componentDidMount: function() {
    return this._afterMount();
  },
  componentDidUpdate: function() {
    return this._afterMount();
  },
  doValidate: function() {
    var accountValue, field, init, valid, validOptions, _i, _len, _ref1;
    accountValue = {};
    init = (function(_this) {
      return function(field) {
        return accountValue[field] = _this.state[field];
      };
    })(this);
    _ref1 = this._accountFields;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      field = _ref1[_i];
      init(field);
    }
    validOptions = {
      additionalProperties: true
    };
    valid = validate(accountValue, this._accountSchema, validOptions);
    return {
      accountValue: accountValue,
      valid: valid
    };
  },
  validateForm: function(event) {
    var accountValue, error, errors, setError, valid, _i, _len, _ref1, _ref2;
    if (event != null) {
      event.preventDefault();
    }
    if (Object.keys(this.state.errors).length !== 0) {
      _ref1 = this.doValidate(), accountValue = _ref1.accountValue, valid = _ref1.valid;
      if (valid.valid) {
        return this.setState({
          errors: {}
        });
      } else {
        errors = {};
        setError = function(error) {
          return errors[error.property] = t("validate " + error.message);
        };
        _ref2 = valid.errors;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          error = _ref2[_i];
          setError(error);
        }
        return this.setState({
          errors: errors
        });
      }
    }
  },
  onSubmit: function(event) {
    var accountValue, error, errors, setError, valid, _i, _len, _ref1, _ref2;
    if (event != null) {
      event.preventDefault();
    }
    _ref1 = this.doValidate(), accountValue = _ref1.accountValue, valid = _ref1.valid;
    if (valid.valid) {
      if (this.state.id != null) {
        return AccountActionCreator.edit(accountValue, this.state.id);
      } else {
        return AccountActionCreator.create(accountValue, (function(_this) {
          return function(account) {
            LAC.notify(t("account creation ok"));
            return _this.redirect({
              direction: 'first',
              action: 'account.config',
              parameters: [account.get('id'), 'mailboxes'],
              fullWidth: true
            });
          };
        })(this));
      }
    } else {
      errors = {};
      setError = function(error) {
        return errors[error.property] = t("validate " + error.message);
      };
      _ref2 = valid.errors;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        error = _ref2[_i];
        setError(error);
      }
      return this.setState({
        errors: errors
      });
    }
  },
  onRemove: function(event) {
    event.preventDefault();
    if (window.confirm(t('account remove confirm'))) {
      return AccountActionCreator.remove(this.state.id);
    }
  },
  addMailbox: function(event) {
    var mailbox;
    if (event != null) {
      event.preventDefault();
    }
    mailbox = {
      label: this.refs.newmailbox.getDOMNode().value.trim(),
      accountID: this.state.id,
      parentID: this.state.newMailboxParent
    };
    return AccountActionCreator.mailboxCreate(mailbox, function(error) {
      if (error != null) {
        return LAC.alertError("" + (t("mailbox create ko")) + " " + error);
      } else {
        return LAC.notify(t("mailbox create ok"));
      }
    });
  },
  undoMailbox: function(event) {
    event.preventDefault();
    this.refs.newmailbox.getDOMNode().value = '';
    return this.setState({
      newMailboxParent: null
    });
  },
  discover: function(event) {
    var login;
    this.validateForm(event);
    login = this.state.login;
    if (login !== this._lastDiscovered) {
      AccountActionCreator.discover(login.split('@')[1], (function(_this) {
        return function(err, provider) {
          var getInfos, infos, isGmail, server, _i, _len;
          if (err == null) {
            infos = {};
            getInfos = function(server) {
              if (server.type === 'imap' && (infos.imapServer == null)) {
                infos.imapServer = server.hostname;
                infos.imapPort = server.port;
                if (server.socketType === 'SSL') {
                  infos.imapSSL = true;
                  infos.imapTLS = false;
                } else if (server.socketType === 'STARTTLS') {
                  infos.imapSSL = false;
                  infos.imapTLS = true;
                } else if (server.socketType === 'plain') {
                  infos.imapSSL = false;
                  infos.imapTLS = false;
                }
              }
              if (server.type === 'smtp' && (infos.smtpServer == null)) {
                infos.smtpServer = server.hostname;
                infos.smtpPort = server.port;
                if (server.socketType === 'SSL') {
                  infos.smtpSSL = true;
                  return infos.smtpTLS = false;
                } else if (server.socketType === 'STARTTLS') {
                  infos.smtpSSL = false;
                  return infos.smtpTLS = true;
                } else if (server.socketType === 'plain') {
                  infos.smtpSSL = false;
                  return infos.smtpTLS = false;
                }
              }
            };
            for (_i = 0, _len = provider.length; _i < _len; _i++) {
              server = provider[_i];
              getInfos(server);
            }
            if (infos.imapServer == null) {
              infos.imapServer = '';
              infos.imapPort = '993';
            }
            if (infos.smtpServer == null) {
              infos.smtpServer = '';
              infos.smtpPort = '465';
            }
            if (!infos.imapSSL) {
              switch (infos.imapPort) {
                case '993':
                  infos.imapSSL = true;
                  infos.imapTLS = false;
                  break;
                default:
                  infos.imapSSL = false;
                  infos.imapTLS = false;
              }
            }
            if (!infos.smtpSSL) {
              switch (infos.smtpPort) {
                case '465':
                  infos.smtpSSL = true;
                  infos.smtpTLS = false;
                  break;
                case '587':
                  infos.smtpSSL = false;
                  infos.smtpTLS = true;
                  break;
                default:
                  infos.smtpSSL = false;
                  infos.smtpTLS = false;
              }
            }
            isGmail = infos.imapServer === 'imap.googlemail.com';
            infos.displayGMAILSecurity = isGmail;
            _this.setState(infos);
            return _this.validateForm();
          }
        };
      })(this));
      return this._lastDiscovered = login;
    }
  },
  _onServerParam: function(target, server, type) {
    if ((server === 'imap' && this.state.imapManualPort) || (server === 'smtp' && this.state.smtpManualPort)) {
      return;
    }
    if (server === 'smtp') {
      if (type === 'ssl' && target.checked) {
        return this.setState({
          smtpPort: 465
        });
      } else if (type === 'tls' && target.checked) {
        return this.setState({
          smtpPort: 587
        });
      }
    } else {
      if (target.checked) {
        return this.setState({
          imapPort: 993
        });
      } else {
        return this.setState({
          imapPort: 143
        });
      }
    }
  },
  _onIMAPPort: function(ev) {
    var infos, port;
    port = ev.target.value.trim();
    infos = {
      imapPort: port
    };
    switch (port) {
      case '993':
        infos.imapSSL = true;
        infos.imapTLS = false;
        break;
      default:
        infos.imapSSL = false;
        infos.imapTLS = false;
    }
    return this.setState(infos);
  },
  _onSMTPPort: function(ev) {
    var infos, port;
    port = ev.target.value.trim();
    infos = {};
    switch (port) {
      case '465':
        infos.smtpSSL = true;
        infos.smtpTLS = false;
        break;
      case '587':
        infos.smtpSSL = false;
        infos.smtpTLS = true;
        break;
      default:
        infos.smtpSSL = false;
        infos.smtpTLS = false;
    }
    return this.setState(infos);
  },
  componentWillReceiveProps: function(props) {
    var errors, field;
    if (props.selectedAccount && !props.isWaiting) {
      return this.setState(this._accountToState(props));
    } else {
      if (props.error != null) {
        if (props.error.name === 'AccountConfigError') {
          errors = {};
          field = props.error.field;
          if (field === 'auth') {
            errors['login'] = t('config error auth');
            errors['password'] = t('config error auth');
          } else {
            errors[field] = t('config error ' + field);
          }
          return this.setState({
            errors: errors
          });
        }
      }
    }
  },
  getInitialState: function() {
    return this._accountToState(null);
  },
  _accountToState: function(props) {
    var account, field, init, state, _i, _j, _len, _len1, _ref1, _ref2;
    state = {
      errors: {}
    };
    if (props != null) {
      account = props.selectedAccount;
      if (props.error != null) {
        if (props.error.name === 'AccountConfigError') {
          field = props.error.field;
          if (field === 'auth') {
            state.errors['login'] = t('config error auth');
            state.errors['password'] = t('config error auth');
          } else {
            state.errors[field] = t('config error ' + field);
          }
        }
      }
    }
    if (account != null) {
      _ref1 = this._accountFields;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        field = _ref1[_i];
        state[field] = account.get(field);
      }
      state.newMailboxParent = null;
      state.mailboxes = props.mailboxes;
      state.favoriteMailboxes = props.favoriteMailboxes;
      if (state.mailboxes.length === 0) {
        this.redirect({
          direction: 'first',
          action: 'account.config',
          parameters: [this.state.id, 'mailboxes']
        });
      }
    } else if (Object.keys(state.errors).length === 0) {
      init = function(field) {
        return state[field] = '';
      };
      _ref2 = this._accountFields;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        field = _ref2[_j];
        init(field);
      }
      state.id = null;
      state.smtpPort = 465;
      state.smtpSSL = true;
      state.smtpTLS = false;
      state.imapPort = 993;
      state.imapSSL = true;
      state.imapTLS = false;
      state.accountType = 'IMAP';
      state.newMailboxParent = null;
      state.favoriteMailboxes = null;
    }
    return state;
  }
});

MailboxItem = React.createClass({
  displayName: 'MailboxItem',
  propTypes: {
    mailbox: React.PropTypes.object
  },
  componentWillReceiveProps: function(props) {
    return this.setState({
      edited: false
    });
  },
  getInitialState: function() {
    return {
      edited: false,
      favorite: this.props.favorite
    };
  },
  render: function() {
    var classItem, favoriteClass, favoriteTitle, j, key, nbRecent, nbTotal, nbUnread, pusher, _i, _ref1;
    pusher = "";
    for (j = _i = 1, _ref1 = this.props.mailbox.get('depth'); _i <= _ref1; j = _i += 1) {
      pusher += "    ";
    }
    key = this.props.mailbox.get('id');
    if (this.state.favorite) {
      favoriteClass = "fa fa-eye mailbox-visi-yes";
      favoriteTitle = t("mailbox title favorite");
    } else {
      favoriteClass = "fa fa-eye-slash mailbox-visi-no";
      favoriteTitle = t("mailbox title not favorite");
    }
    nbTotal = this.props.mailbox.get('nbTotal') || 0;
    nbUnread = this.props.mailbox.get('nbUnread') || 0;
    nbRecent = this.props.mailbox.get('nbRecent') || 0;
    classItem = classer({
      'row': true,
      'box': true,
      'box-item': true,
      edited: this.state.edited
    });
    if (this.state.edited) {
      return li({
        className: classItem,
        key: key
      }, span({
        className: "col-xs-1 box-action save",
        onClick: this.updateMailbox,
        title: t("mailbox title edit save")
      }, i({
        className: 'fa fa-check'
      })), span({
        className: "col-xs-1 box-action cancel",
        onClick: this.undoMailbox,
        title: t("mailbox title edit cancel")
      }, i({
        className: 'fa fa-undo'
      })), input({
        className: "col-xs-6 box-label",
        ref: 'label',
        defaultValue: this.props.mailbox.get('label'),
        type: 'text',
        onKeyDown: this.onKeyDown
      }));
    } else {
      return li({
        className: classItem,
        key: key
      }, span({
        className: "col-xs-1 box-action edit",
        onClick: this.editMailbox,
        title: t("mailbox title edit")
      }, i({
        className: 'fa fa-pencil'
      })), span({
        className: "col-xs-1 box-action delete",
        onClick: this.deleteMailbox,
        title: t("mailbox title delete")
      }, i({
        className: 'fa fa-trash-o'
      })), span({
        className: "col-xs-6 box-label",
        onClick: this.editMailbox
      }, "" + pusher + (this.props.mailbox.get('label'))), span({
        className: "col-xs-1 box-action favorite",
        title: favoriteTitle,
        onClick: this.toggleFavorite
      }, i({
        className: favoriteClass
      })), span({
        className: "col-xs-1 text-center box-count box-total"
      }, nbTotal), span({
        className: "col-xs-1 text-center box-count box-unread"
      }, nbUnread), span({
        className: "col-xs-1 text-center box-count box-new"
      }, nbRecent));
    }
  },
  onKeyDown: function(evt) {
    switch (evt.key) {
      case "Enter":
        return this.updateMailbox();
    }
  },
  editMailbox: function(e) {
    e.preventDefault();
    return this.setState({
      edited: true
    });
  },
  undoMailbox: function(e) {
    e.preventDefault();
    return this.setState({
      edited: false
    });
  },
  updateMailbox: function(e) {
    var mailbox;
    if (e != null) {
      e.preventDefault();
    }
    mailbox = {
      label: this.refs.label.getDOMNode().value.trim(),
      mailboxID: this.props.mailbox.get('id'),
      accountID: this.props.accountID
    };
    return AccountActionCreator.mailboxUpdate(mailbox, function(error) {
      if (error != null) {
        return LAC.alertError("" + (t("mailbox update ko")) + " " + error);
      } else {
        return LAC.notify(t("mailbox update ok"));
      }
    });
  },
  toggleFavorite: function(e) {
    var mailbox;
    mailbox = {
      favorite: !this.state.favorite,
      mailboxID: this.props.mailbox.get('id'),
      accountID: this.props.accountID
    };
    AccountActionCreator.mailboxUpdate(mailbox, function(error) {
      if (error != null) {
        return LAC.alertError("" + (t("mailbox update ko")) + " " + error);
      } else {
        return LAC.notify(t("mailbox update ok"));
      }
    });
    return this.setState({
      favorite: !this.state.favorite
    });
  },
  deleteMailbox: function(e) {
    var mailbox;
    e.preventDefault();
    if (window.confirm(t('account confirm delbox'))) {
      mailbox = {
        mailboxID: this.props.mailbox.get('id'),
        accountID: this.props.accountID
      };
      return AccountActionCreator.mailboxDelete(mailbox, function(error) {
        if (error != null) {
          return LAC.alertError("" + (t("mailbox delete ko")) + " " + error);
        } else {
          return LAC.notify(t("mailbox delete ok"));
        }
      });
    }
  }
});
});

;require.register("components/account_picker", function(exports, require, module) {
var RouterMixin, a, button, div, input, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, p = _ref.p, span = _ref.span, a = _ref.a, button = _ref.button, input = _ref.input;

RouterMixin = require('../mixins/router_mixin');

module.exports = React.createClass({
  displayName: 'AccountPicker',
  render: function() {
    if (accounts.length === 1) {
      return this.renderNoChoice();
    } else {
      return this.renderPicker();
    }
  },
  onChange: function(_arg) {
    var accountID;
    accountID = _arg.target.dataset.value;
    return this.props.valueLink.requestChange(accountID);
  },
  renderNoChoice: function() {
    var account, label;
    account = this.props.accounts.get(this.props.valueLink.value);
    if (this.props.type === 'address') {
      label = "\"" + (account.get('name') || account.get('label')) + "\" <" + (account.get('login')) + ">";
    } else {
      label = account.get('label');
    }
    return p({
      className: 'form-control-static col-sm-6'
    }, label);
  },
  renderPicker: function() {
    var account, accounts, key, label, value;
    accounts = this.props.accounts;
    account = accounts.get(this.props.valueLink.value);
    value = this.props.valueLink.value;
    if (this.props.type === 'address') {
      label = "\"" + (account.get('name') || account.get('label')) + "\" <" + (account.get('login')) + ">";
    } else {
      label = account.get('label');
    }
    return div(null, span({
      className: 'compose-from dropdown-toggle',
      'data-toggle': 'dropdown'
    }, span({
      ref: 'account'
    }, label), span({
      className: 'caret'
    })), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, (function() {
      var _ref1, _results;
      _ref1 = accounts.toJS();
      _results = [];
      for (key in _ref1) {
        account = _ref1[key];
        if (key !== value) {
          _results.push(this.renderAccount(key, account));
        }
      }
      return _results;
    }).call(this)));
  },
  renderAccount: function(key, account) {
    var label;
    if (this.props.type === 'address') {
      label = "\"" + (account.name || account.label) + "\" <" + account.login + ">";
    } else {
      label = account.label;
    }
    return li({
      role: 'presentation',
      key: key
    }, a({
      role: 'menuitem',
      onClick: this.onChange,
      'data-value': key
    }, label));
  }
});
});

;require.register("components/alert", function(exports, require, module) {
var AlertLevel, LayoutActionCreator, button, div, span, strong, _ref;

_ref = React.DOM, div = _ref.div, button = _ref.button, span = _ref.span, strong = _ref.strong;

AlertLevel = require('../constants/app_constants').AlertLevel;

LayoutActionCreator = require('../actions/layout_action_creator');

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
      ref: 'alert',
      className: "alert " + levels[alert.level] + " alert-dismissible",
      role: "alert"
    }, button({
      type: "button",
      className: "close",
      onClick: this.hide
    }, span({
      'aria-hidden': "true"
    }, "×"), span({
      className: "sr-only"
    }, t("app alert close"))), strong(null, alert.message)) : void 0);
  },
  hide: function() {
    return LayoutActionCreator.alertHide();
  },
  autohide: function() {
    if (false && this.props.alert.level === AlertLevel.SUCCESS) {
      setTimeout((function(_this) {
        return function() {
          return _this.refs.alert.getDOMNode().classList.add('autoclose');
        };
      })(this), 1000);
      return setTimeout(this.hide, 10000);
    }
  },
  componentDidMount: function() {
    return this.autohide();
  },
  componentDidUpdate: function() {
    return this.autohide();
  }
});
});

;require.register("components/application", function(exports, require, module) {
var AccountConfig, AccountStore, Alert, Application, Compose, ContactStore, Conversation, Dispositions, LayoutActionCreator, LayoutStore, Menu, MessageFilter, MessageList, MessageStore, ReactCSSTransitionGroup, RefreshesStore, RouterMixin, SearchForm, SearchStore, Settings, SettingsStore, StoreWatchMixin, ToastContainer, Topbar, a, body, button, classer, div, form, i, input, p, span, strong, _ref, _ref1;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span, a = _ref.a, button = _ref.button, strong = _ref.strong;

AccountConfig = require('./account-config');

Alert = require('./alert');

Topbar = require('./topbar');

ToastContainer = require('./toast').Container;

Compose = require('./compose');

Conversation = require('./conversation');

Menu = require('./menu');

MessageList = require('./message-list');

Settings = require('./settings');

SearchForm = require('./search-form');

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

StoreWatchMixin = require('../mixins/store_watch_mixin');

AccountStore = require('../stores/account_store');

ContactStore = require('../stores/contact_store');

MessageStore = require('../stores/message_store');

LayoutStore = require('../stores/layout_store');

SettingsStore = require('../stores/settings_store');

SearchStore = require('../stores/search_store');

RefreshesStore = require('../stores/refreshes_store');

LayoutActionCreator = require('../actions/layout_action_creator');

_ref1 = require('../constants/app_constants'), MessageFilter = _ref1.MessageFilter, Dispositions = _ref1.Dispositions;


/*
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly

    About routing: it uses Backbone.Router as a source of truth for the layout.
    (based on:
        https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592)
 */

module.exports = Application = React.createClass({
  displayName: 'Application',
  mixins: [StoreWatchMixin([AccountStore, ContactStore, MessageStore, LayoutStore, SettingsStore, SearchStore, RefreshesStore]), RouterMixin],
  render: function() {
    var alert, disposition, firstPanelLayoutMode, getUrl, isFullWidth, keyFirst, keySecond, layout, panelClasses, panelsClasses, responsiveClasses;
    layout = this.props.router.current;
    if (layout == null) {
      return div(null, t("app loading"));
    }
    isFullWidth = layout.secondPanel == null;
    firstPanelLayoutMode = isFullWidth ? 'full' : 'first';
    disposition = LayoutStore.getDisposition();
    panelsClasses = classer({
      row: true,
      horizontal: disposition.type === Dispositions.HORIZONTAL
    });
    panelClasses = this.getPanelClasses(isFullWidth);
    responsiveClasses = classer({
      'col-xs-12': true,
      'col-md-9': disposition.type === Dispositions.THREE,
      'col-md-11': disposition.type !== Dispositions.THREE,
      'pushed': this.state.isResponsiveMenuShown
    });
    alert = this.state.alertMessage;
    getUrl = (function(_this) {
      return function(mailbox) {
        var _ref2;
        return _this.buildUrl({
          direction: 'first',
          action: 'account.mailbox.messages',
          parameters: [(_ref2 = _this.state.selectedAccount) != null ? _ref2.get('id') : void 0, mailbox.get('id')]
        });
      };
    })(this);
    keyFirst = 'left-panel-' + layout.firstPanel.action.split('.')[0];
    if (layout.secondPanel != null) {
      keySecond = 'right-panel-' + layout.secondPanel.action.split('.')[0];
    }
    return div({
      className: 'container-fluid'
    }, div({
      className: 'row'
    }, Menu({
      accounts: this.state.accounts,
      refreshes: this.state.refreshes,
      selectedAccount: this.state.selectedAccount,
      selectedMailboxID: this.state.selectedMailboxID,
      isResponsiveMenuShown: this.state.isResponsiveMenuShown,
      layout: this.props.router.current,
      mailboxes: this.state.mailboxesSorted,
      favorites: this.state.favoriteSorted,
      disposition: disposition,
      toggleMenu: this.toggleMenu
    }), div({
      id: 'page-content',
      className: responsiveClasses
    }, Alert({
      alert: alert
    }), ToastContainer(), a({
      onClick: this.toggleMenu,
      className: 'responsive-handler hidden-md hidden-lg'
    }, i({
      className: 'fa fa-bars pull-left'
    }), t("app menu")), div({
      id: 'panels',
      className: panelsClasses
    }, div({
      className: panelClasses.firstPanel,
      key: keyFirst
    }, this.getPanelComponent(layout.firstPanel, firstPanelLayoutMode)), !isFullWidth && (layout.secondPanel != null) ? div({
      className: panelClasses.secondPanel,
      key: keySecond
    }, this.getPanelComponent(layout.secondPanel, 'second')) : void 0))));
  },
  getPanelClasses: function(isFullWidth) {
    var classes, disposition, first, layout, previous, second, wasFullWidth;
    previous = this.props.router.previous;
    layout = this.props.router.current;
    first = layout.firstPanel;
    second = layout.secondPanel;
    if (isFullWidth) {
      classes = {
        firstPanel: 'panel col-xs-12 col-md-12 row-10'
      };
      if ((previous != null) && previous.secondPanel) {
        if (previous.secondPanel.action === layout.firstPanel.action && _.difference(previous.secondPanel.parameters, layout.firstPanel.parameters).length === 0) {
          classes.firstPanel += ' expandFromRight';
        }
      } else if (previous != null) {
        classes.firstPanel += ' moveFromLeft';
      }
    } else {
      disposition = LayoutStore.getDisposition();
      if (disposition.type === Dispositions.HORIZONTAL) {
        classes = {
          firstPanel: "panel col-xs-12 col-md-12 hidden-xs hidden-sm row-" + disposition.height,
          secondPanel: "panel col-xs-12 col-md-12 row-" + (10 - disposition.height) + " row-offset-" + disposition.height
        };
      } else {
        classes = {
          firstPanel: "panel col-xs-12 col-md-" + disposition.width + " hidden-xs hidden-sm row-10",
          secondPanel: "panel col-xs-12 col-md-" + (12 - disposition.width) + " col-offset-" + disposition.width + " row-10"
        };
      }
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
    var account, accountID, conversation, conversationID, conversationLength, conversationLengths, counterMessage, direction, emptyListMessage, error, favoriteMailboxes, fetching, isWaiting, lengths, mailbox, mailboxID, mailboxes, message, messageID, messages, messagesCount, query, selectedAccount, selectedMailboxID, settings, tab;
    if (panelInfo.action === 'account.mailbox.messages' || panelInfo.action === 'account.mailbox.messages.full' || panelInfo.action === 'search') {
      if (panelInfo.action === 'search') {
        accountID = null;
        mailboxID = null;
        messages = SearchStore.getResults();
        messagesCount = messages.count();
        emptyListMessage = t('list search empty', {
          query: this.state.searchQuery
        });
        counterMessage = t('list search count', messagesCount);
      } else {
        accountID = panelInfo.parameters.accountID;
        mailboxID = panelInfo.parameters.mailboxID;
        account = AccountStore.getByID(accountID);
        if (account != null) {
          mailbox = account.get('mailboxes').get(mailboxID);
          messages = MessageStore.getMessagesByMailbox(mailboxID, this.state.settings.get('displayConversation'));
          messagesCount = (mailbox != null ? mailbox.get('nbTotal') : void 0) || 0;
          emptyListMessage = (function() {
            switch (MessageStore.getCurrentFilter()) {
              case MessageFilter.FLAGGED:
                return t('no flagged message');
              case MessageFilter.UNSEEN:
                return t('no unseen message');
              case MessageFilter.ALL:
                return t('list empty');
              default:
                return t('no filter message');
            }
          })();
          counterMessage = t('list count', messagesCount);
        } else {
          this.redirect({
            direction: "first",
            action: "default"
          });
          return;
        }
      }
      messageID = MessageStore.getCurrentID();
      direction = layout === 'first' ? 'secondPanel' : 'firstPanel';
      fetching = MessageStore.isFetching();
      if (this.state.settings.get('displayConversation')) {
        conversationLengths = MessageStore.getConversationsLength();
      }
      query = MessageStore.getParams();
      query.accountID = accountID;
      query.mailboxID = mailboxID;
      return MessageList({
        messages: messages,
        messagesCount: messagesCount,
        accountID: accountID,
        mailboxID: mailboxID,
        messageID: messageID,
        mailboxes: this.state.mailboxes,
        settings: this.state.settings,
        fetching: fetching,
        query: query,
        conversationLengths: conversationLengths,
        emptyListMessage: emptyListMessage,
        counterMessage: counterMessage
      });
    } else if (panelInfo.action === 'account.config') {
      selectedAccount = AccountStore.getSelected();
      error = AccountStore.getError();
      isWaiting = AccountStore.isWaiting();
      mailboxes = AccountStore.getSelectedMailboxes();
      favoriteMailboxes = this.state.favoriteMailboxes;
      tab = panelInfo.parameters.tab;
      if (selectedAccount && !error && mailboxes.length === 0) {
        error = {
          name: 'AccountConfigError',
          field: 'nomailboxes'
        };
      }
      return AccountConfig({
        error: error,
        isWaiting: isWaiting,
        selectedAccount: selectedAccount,
        mailboxes: mailboxes,
        favoriteMailboxes: favoriteMailboxes,
        tab: tab
      });
    } else if (panelInfo.action === 'account.new') {
      return AccountConfig({
        error: AccountStore.getError(),
        isWaiting: AccountStore.isWaiting()
      });
    } else if (panelInfo.action === 'message' || panelInfo.action === 'conversation') {
      messageID = panelInfo.parameters.messageID;
      message = MessageStore.getByID(messageID);
      selectedMailboxID = this.state.selectedMailboxID;
      if (message != null) {
        conversationID = message.get('conversationID');
        lengths = MessageStore.getConversationsLength();
        conversationLength = lengths.get(conversationID);
        conversation = MessageStore.getConversation(conversationID);
        MessageStore.setCurrentID(message.get('id'));
        if (selectedMailboxID == null) {
          selectedMailboxID = Object.keys(message.get('mailboxIDs'))[0];
        }
      }
      return Conversation({
        key: 'conversation-' + conversationID,
        layout: layout,
        settings: this.state.settings,
        accounts: this.state.accounts,
        mailboxes: this.state.mailboxes,
        selectedAccount: this.state.selectedAccount,
        selectedMailboxID: selectedMailboxID,
        message: message,
        conversation: conversation,
        conversationLength: conversationLength,
        prevID: MessageStore.getPreviousMessage(),
        nextID: MessageStore.getNextMessage()
      });
    } else if (panelInfo.action === 'compose') {
      return Compose({
        layout: layout,
        action: null,
        inReplyTo: null,
        settings: this.state.settings,
        accounts: this.state.accounts,
        selectedAccount: this.state.selectedAccount,
        message: null
      });
    } else if (panelInfo.action === 'edit') {
      messageID = panelInfo.parameters.messageID;
      message = MessageStore.getByID(messageID);
      return Compose({
        layout: layout,
        action: null,
        inReplyTo: null,
        settings: this.state.settings,
        accounts: this.state.accounts,
        selectedAccount: this.state.selectedAccount,
        message: message
      });
    } else if (panelInfo.action === 'settings') {
      settings = this.state.settings;
      return Settings({
        settings: settings
      });
    } else {
      return div(null, 'Unknown component');
    }
  },
  getStateFromStores: function() {
    var firstPanelInfo, selectedAccount, selectedAccountID, selectedMailboxID, _ref2;
    selectedAccount = AccountStore.getSelected();
    if (selectedAccount == null) {
      selectedAccount = AccountStore.getDefault();
    }
    selectedAccountID = (selectedAccount != null ? selectedAccount.get('id') : void 0) || null;
    firstPanelInfo = (_ref2 = this.props.router.current) != null ? _ref2.firstPanel : void 0;
    if ((firstPanelInfo != null ? firstPanelInfo.action : void 0) === 'account.mailbox.messages' || (firstPanelInfo != null ? firstPanelInfo.action : void 0) === 'account.mailbox.messages.full') {
      selectedMailboxID = firstPanelInfo.parameters.mailboxID;
    } else {
      selectedMailboxID = null;
    }
    return {
      accounts: AccountStore.getAll(),
      selectedAccount: selectedAccount,
      isResponsiveMenuShown: false,
      alertMessage: LayoutStore.getAlert(),
      mailboxes: AccountStore.getSelectedMailboxes(),
      mailboxesSorted: AccountStore.getSelectedMailboxes(true),
      selectedMailboxID: selectedMailboxID,
      selectedMailbox: AccountStore.getSelectedMailbox(selectedMailboxID),
      favoriteMailboxes: AccountStore.getSelectedFavorites(),
      favoriteSorted: AccountStore.getSelectedFavorites(true),
      searchQuery: SearchStore.getQuery(),
      refreshes: RefreshesStore.getRefreshing(),
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
  toggleMenu: function(event) {
    return this.setState({
      isResponsiveMenuShown: !this.state.isResponsiveMenuShown
    });
  }
});
});

;require.register("components/compose", function(exports, require, module) {
var AccountPicker, Compose, ComposeActions, ComposeEditor, FilePicker, LayoutActionCreator, MailsInput, MessageActionCreator, MessageUtils, RouterMixin, a, button, classer, div, form, h3, i, input, label, li, span, textarea, ul, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, a = _ref.a, i = _ref.i, textarea = _ref.textarea, form = _ref.form, label = _ref.label, button = _ref.button, span = _ref.span, ul = _ref.ul, li = _ref.li, input = _ref.input;

classer = React.addons.classSet;

FilePicker = require('./file_picker');

MailsInput = require('./mails_input');

AccountPicker = require('./account_picker');

ComposeActions = require('../constants/app_constants').ComposeActions;

MessageUtils = require('../utils/message_utils');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

RouterMixin = require('../mixins/router_mixin');

module.exports = Compose = React.createClass({
  displayName: 'Compose',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  propTypes: {
    selectedAccount: React.PropTypes.object.isRequired,
    layout: React.PropTypes.string.isRequired,
    accounts: React.PropTypes.object.isRequired,
    message: React.PropTypes.object,
    action: React.PropTypes.string,
    callback: React.PropTypes.func,
    onCancel: React.PropTypes.func,
    settings: React.PropTypes.object.isRequired
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var classBcc, classCc, classInput, classLabel, closeUrl, collapseUrl, expandUrl, focusEditor, labelSend, onCancel;
    if (!this.props.accounts) {
      return;
    }
    expandUrl = this.buildUrl({
      direction: 'first',
      action: 'compose',
      fullWidth: true
    });
    collapseUrl = this.buildUrl({
      firstPanel: {
        action: 'account.mailbox.messages',
        parameters: this.state.accountID
      },
      secondPanel: {
        action: 'compose'
      }
    });
    onCancel = (function(_this) {
      return function() {
        if (_this.props.onCancel != null) {
          return _this.props.onCancel();
        } else {
          return _this.redirect(_this.buildUrl({
            direction: 'first',
            action: 'default',
            fullWidth: true
          }));
        }
      };
    })(this);
    closeUrl = this.buildClosePanelUrl(this.props.layout);
    classLabel = 'compose-label';
    classInput = 'compose-input';
    classCc = this.state.cc.length === 0 ? '' : ' shown';
    classBcc = this.state.bcc.length === 0 ? '' : ' shown';
    labelSend = this.state.sending ? t('compose action sending') : t('compose action send');
    focusEditor = Array.isArray(this.state.to) && this.state.to.length > 0 && this.state.subject !== '';
    return div({
      id: 'email-compose'
    }, this.props.layout !== 'full' ? a({
      href: expandUrl,
      className: 'expand pull-right'
    }, i({
      className: 'fa fa-arrows-h'
    })) : a({
      href: collapseUrl,
      className: 'close-email pull-right'
    }, i({
      className: 'fa fa-compress'
    })), h3(null, t('compose')), form({
      className: ''
    }, div({
      className: 'form-group'
    }, label({
      htmlFor: 'compose-from',
      className: classLabel
    }, t("compose from")), div({
      className: classInput
    }, div({
      className: 'btn-toolbar compose-toggle',
      role: 'toolbar'
    }, div(null), a({
      className: 'compose-toggle-cc',
      onClick: this.onToggleCc
    }, t('compose toggle cc')), a({
      className: 'compose-toggle-bcc',
      onClick: this.onToggleBcc
    }, t('compose toggle bcc'))), AccountPicker({
      accounts: this.props.accounts,
      valueLink: this.linkState('accountID'),
      type: 'address'
    }))), div({
      className: 'clearfix'
    }, null), MailsInput({
      id: 'compose-to',
      valueLink: this.linkState('to'),
      label: t('compose to'),
      ref: 'to'
    }), MailsInput({
      id: 'compose-cc',
      className: 'compose-cc' + classCc,
      valueLink: this.linkState('cc'),
      label: t('compose cc'),
      placeholder: t('compose cc help')
    }), MailsInput({
      id: 'compose-bcc',
      className: 'compose-bcc' + classBcc,
      valueLink: this.linkState('bcc'),
      label: t('compose bcc'),
      placeholder: t('compose bcc help')
    }), div({
      className: 'form-group'
    }, label({
      htmlFor: 'compose-subject',
      className: classLabel
    }, t("compose subject")), div({
      className: classInput
    }, input({
      id: 'compose-subject',
      name: 'compose-subject',
      ref: 'subject',
      valueLink: this.linkState('subject'),
      type: 'text',
      className: 'form-control',
      placeholder: t("compose subject help")
    }))), div({
      className: ''
    }, label({
      htmlFor: 'compose-subject',
      className: classLabel
    }, t("compose content")), ComposeEditor({
      html: this.linkState('html'),
      text: this.linkState('text'),
      settings: this.props.settings,
      onSend: this.onSend,
      composeInHTML: this.state.composeInHTML,
      focus: focusEditor
    })), div({
      className: 'attachements'
    }, FilePicker({
      className: '',
      editable: true,
      valueLink: this.linkState('attachments')
    })), div({
      className: 'composeToolbox'
    }, div({
      className: 'btn-toolbar',
      role: 'toolbar'
    }, div({
      className: ''
    }, button({
      className: 'btn btn-cozy',
      type: 'button',
      disable: this.state.sending ? true : null,
      onClick: this.onSend
    }, this.state.sending ? span({
      className: 'fa fa-refresh fa-spin'
    }) : span({
      className: 'fa fa-send'
    }), span(null, labelSend)), button({
      className: 'btn btn-cozy',
      disable: this.state.saving ? true : null,
      type: 'button',
      onClick: this.onDraft
    }, this.state.saving ? span({
      className: 'fa fa-refresh fa-spin'
    }) : span({
      className: 'fa fa-save'
    }), span(null, t('compose action draft'))), this.props.message != null ? button({
      className: 'btn btn-cozy-non-default',
      type: 'button',
      onClick: this.onDelete
    }, span({
      className: 'fa fa-trash-o'
    }), span(null, t('compose action delete'))) : void 0, button({
      onClick: onCancel,
      className: 'btn btn-cozy-non-default'
    }, t('app cancel'))))), div({
      className: 'clearfix'
    }, null)));
  },
  _initCompose: function() {
    if (this._saveInterval) {
      window.clearInterval(this._saveInterval);
    }
    this._saveInterval = window.setInterval(this._autosave, 30000);
    this.getDOMNode().scrollIntoView();
    if (!Array.isArray(this.state.to) || this.state.to.length === 0) {
      return setTimeout(function() {
        return document.getElementById('compose-to').focus();
      }, 0);
    }
  },
  componentDidMount: function() {
    return this._initCompose();
  },
  componentWillUnmount: function() {
    if (this._saveInterval) {
      return window.clearInterval(this._saveInterval);
    }
  },
  getInitialState: function(forceDefault) {
    var key, message, state, value, _ref1;
    if (message = this.props.message) {
      state = {
        composeInHTML: this.props.settings.get('composeInHTML')
      };
      if ((message.get('html') == null) && message.get('text')) {
        state.conposeInHTML = false;
      }
      _ref1 = message.toJS();
      for (key in _ref1) {
        value = _ref1[key];
        state[key] = value;
      }
      state.attachments = message.get('attachments');
    } else {
      state = MessageUtils.makeReplyMessage(this.props.inReplyTo, this.props.action, this.props.settings.get('composeInHTML'));
      if (state.accountID == null) {
        state.accountID = this.props.selectedAccount.get('id');
      }
    }
    state.sending = false;
    state.saving = false;
    return state;
  },
  componentWillReceiveProps: function(nextProps) {
    if (nextProps.message !== this.props.message) {
      this.props.message = nextProps.message;
      return this.setState(this.getInitialState());
    }
  },
  onDraft: function(args) {
    return this._doSend(true);
  },
  onSend: function(args) {
    return this._doSend(false);
  },
  _doSend: function(isDraft) {
    var account, from, message, valid;
    account = this.props.accounts.get(this.state.accountID);
    from = {
      name: (account != null ? account.get('name') : void 0) || void 0,
      address: account.get('login')
    };
    if (!~from.address.indexOf('@')) {
      from.address += '@' + account.get('imapServer');
    }
    message = {
      id: this.state.id,
      accountID: this.state.accountID,
      mailboxIDs: this.state.mailboxIDs,
      from: [from],
      to: this.state.to,
      cc: this.state.cc,
      bcc: this.state.bcc,
      subject: this.state.subject,
      isDraft: isDraft,
      attachments: this.state.attachments
    };
    valid = true;
    if (!isDraft) {
      if (this.state.to.length === 0 && this.state.cc.length === 0 && this.state.bcc.length === 0) {
        valid = false;
        LayoutActionCreator.alertError(t("compose error no dest"));
        setTimeout(function() {
          return document.getElementById('compose-to').focus();
        }, 0);
      } else if (this.state.subject === '') {
        valid = false;
        LayoutActionCreator.alertError(t("compose error no subject"));
        setTimeout(function() {
          return this.refs.subject.getDOMNode().focus();
        }, 0);
      }
    }
    if (valid) {
      if (this.state.composeInHTML) {
        message.html = this.state.html;
        try {
          message.text = toMarkdown(message.html);
        } catch (_error) {
          message.text = typeof message.html === "function" ? message.html(replace(/<[^>]*>/gi, '')) : void 0;
        }
      } else {
        message.text = this.state.text.trim();
      }
      if (!isDraft && this._saveInterval) {
        window.clearInterval(this._saveInterval);
      }
      if (isDraft) {
        this.setState({
          saving: true
        });
      } else {
        this.setState({
          sending: true
        });
      }
      return MessageActionCreator.send(message, (function(_this) {
        return function(error, message) {
          var msgKo, msgOk;
          if (isDraft) {
            _this.setState({
              saving: false
            });
          } else {
            _this.setState({
              sending: false
            });
          }
          if (isDraft) {
            msgKo = t("message action draft ko");
            msgOk = t("message action draft ok");
          } else {
            msgKo = t("message action sent ko");
            msgOk = t("message action sent ok");
          }
          if (error != null) {
            return LayoutActionCreator.alertError("" + msgKo + " :  error");
          } else {
            LayoutActionCreator.notify(msgOk);
            _this.setState(message);
            if (!isDraft) {
              if (_this.props.callback != null) {
                return _this.props.callback(error);
              } else {
                return _this.redirect(_this.buildClosePanelUrl(_this.props.layout));
              }
            }
          }
        };
      })(this));
    }
  },
  _autosave: function() {
    return this._doSend(true);
  },
  onDelete: function(args) {
    if (window.confirm(t('mail confirm delete', {
      subject: this.props.message.get('subject')
    }))) {
      return MessageActionCreator["delete"](this.props.message, (function(_this) {
        return function(error) {
          if (error != null) {
            return LayoutActionCreator.alertError("" + (t("message action delete ko")) + " " + error);
          } else {
            if (_this.props.callback) {
              return _this.props.callback();
            } else {
              return _this.redirect({
                direction: 'first',
                action: 'account.mailbox.messages',
                parameters: [_this.props.selectedAccount.get('id'), _this.props.selectedMailboxID, 1],
                fullWidth: true
              });
            }
          }
        };
      })(this));
    }
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

ComposeEditor = React.createClass({
  displayName: 'ComposeEditor',
  mixins: [React.addons.LinkedStateMixin],
  getInitialState: function() {
    return {
      html: this.props.html,
      text: this.props.text
    };
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var onHTMLChange, onTextChange;
    onHTMLChange = (function(_this) {
      return function(event) {
        return _this.props.html.requestChange(_this.refs.html.getDOMNode().innerHTML);
      };
    })(this);
    onTextChange = (function(_this) {
      return function(event) {
        return _this.props.text.requestChange(_this.refs.content.getDOMNode().value);
      };
    })(this);
    if (this.props.composeInHTML) {
      return div({
        className: 'rt-editor form-control',
        ref: 'html',
        contentEditable: true,
        onKeyDown: this.onKeyDown,
        onInput: onHTMLChange,
        dangerouslySetInnerHTML: {
          __html: this.state.html.value
        }
      });
    } else {
      return textarea({
        className: 'editor',
        ref: 'content',
        onKeyDown: this.onKeyDown,
        onChange: onTextChange,
        defaultValue: this.state.text.value
      });
    }
  },
  _initCompose: function() {
    var node, r, range, rect, s, _ref1;
    if (this.props.composeInHTML) {
      if (this.props.focus) {
        node = (_ref1 = this.refs.html) != null ? _ref1.getDOMNode() : void 0;
        if (node == null) {
          return;
        }
        setTimeout(function() {
          return jQuery(node).focus();
        }, 0);
        if (!this.props.settings.get('composeOnTop')) {
          node.innerHTML += "<p><br /></p>";
          node = node.lastChild;
          if (node != null) {
            node.scrollIntoView(false);
            node.innerHTML = "<br \>";
            s = window.getSelection();
            r = document.createRange();
            r.selectNodeContents(node);
            s.removeAllRanges();
            s.addRange(r);
            document.execCommand('delete', false, null);
          }
        }
      }
      return jQuery('#email-compose .rt-editor').on('keypress', function(e) {
        if (e.keyCode === 13) {
          return setTimeout(function() {
            var after, before, inserted, matchesSelector, parent, process, rangeAfter, rangeBefore, sel, target;
            matchesSelector = document.documentElement.matches || document.documentElement.matchesSelector || document.documentElement.webkitMatchesSelector || document.documentElement.mozMatchesSelector || document.documentElement.oMatchesSelector || document.documentElement.msMatchesSelector;
            target = document.getSelection().anchorNode;
            if (target == null) {
              return;
            }
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
            setTimeout(function() {
              return inserted.focus();
            }, 0);
            sel = window.getSelection();
            return sel.collapse(inserted, 0);
          }, 0);
        }
      });
    } else {
      if (this.props.focus) {
        node = this.refs.content.getDOMNode();
        if (!this.props.settings.get('composeOnTop')) {
          rect = node.getBoundingClientRect();
          node.scrollTop = node.scrollHeight - rect.height;
          if (typeof node.selectionStart === "number") {
            node.selectionStart = node.selectionEnd = node.value.length;
          } else if (typeof node.createTextRange !== "undefined") {
            setTimeout(function() {
              return node.focus();
            }, 0);
            range = node.createTextRange();
            range.collapse(false);
            range.select();
          }
        }
        return setTimeout(function() {
          return node.focus();
        }, 0);
      }
    }
  },
  componentDidMount: function() {
    return this._initCompose();
  },
  onKeyDown: function(evt) {
    if (evt.ctrlKey && evt.key === 'Enter') {
      return this.props.onSend();
    }
  }
});
});

;require.register("components/contact-form", function(exports, require, module) {
var ContactActionCreator, ContactStore, RouterMixin, StoreWatchMixin, a, classer, div, form, i, img, input, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, form = _ref.form, input = _ref.input, span = _ref.span, ul = _ref.ul, li = _ref.li, a = _ref.a, img = _ref.img, i = _ref.i;

classer = React.addons.classSet;

ContactActionCreator = require('../actions/contact_action_creator');

ContactStore = require('../stores/contact_store');

StoreWatchMixin = require('../mixins/store_watch_mixin');

RouterMixin = require('../mixins/router_mixin');

module.exports = React.createClass({
  displayName: 'ContactForm',
  mixins: [StoreWatchMixin([ContactStore]), RouterMixin],
  getStateFromStores: function() {
    var query, _ref1;
    query = (_ref1 = this.refs.contactInput) != null ? _ref1.getDOMNode().value.trim() : void 0;
    return {
      contacts: (query != null ? query.length : void 0) > 2 ? ContactStore.getResults() : null,
      selected: 0
    };
  },
  componentWillMount: function() {
    return this.setState({
      contacts: null
    });
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var current, listClass, _ref1;
    listClass = ((_ref1 = this.state.contacts) != null ? _ref1.length : void 0) > 0 ? 'open' : '';
    current = 0;
    return form({
      className: "contact-form"
    }, div(null, div({
      className: 'input-group'
    }, input({
      className: 'form-control search-input',
      type: 'text',
      placeholder: t('contact form placeholder'),
      onKeyDown: this.onKeyDown,
      ref: 'contactInput',
      defaultValue: this.props.query
    }), div({
      className: 'input-group-addon btn btn-cozy search-btn',
      onClick: this.onSubmit
    }, span({
      className: 'fa fa-search'
    })))), this.state.contacts != null ? div({
      className: listClass
    }, ul({
      className: "contact-list"
    }, this.state.contacts.map((function(_this) {
      return function(contact, key) {
        var selected;
        selected = current === _this.state.selected;
        current++;
        return _this.renderContact(contact, selected);
      };
    })(this)).toJS())) : void 0);
  },
  renderContact: function(contact, selected) {
    var avatar, classes, selectContact;
    selectContact = (function(_this) {
      return function() {
        return _this.props.onContact(contact);
      };
    })(this);
    avatar = contact.get('avatar');
    classes = classer({
      selected: selected
    });
    return li({
      className: classes,
      onClick: selectContact
    }, a(null, avatar != null ? img({
      className: 'avatar',
      src: avatar
    }) : i({
      className: 'avatar fa fa-user'
    }), "" + (contact.get('fn')) + " <" + (contact.get('address')) + ">"));
  },
  onSubmit: function() {
    var query;
    query = this.refs.contactInput.getDOMNode().value.trim();
    if (query.length > 2) {
      return ContactActionCreator.searchContactLocal(query);
    }
  },
  onKeyDown: function(evt) {
    var contact, _ref1;
    switch (evt.key) {
      case "Tab":
        this.onSubmit();
        evt.preventDefault();
        return false;
      case "Enter":
        if (((_ref1 = this.state.contacts) != null ? _ref1.count() : void 0) > 0) {
          this.props.onContact;
          contact = this.state.contacts.slice(this.state.selected).first();
          this.props.onContact(contact);
        } else {
          this.onSubmit();
        }
        evt.preventDefault();
        return false;
      case "ArrowUp":
        return this.setState({
          selected: this.state.selected === 0 ? this.state.contacts.count() - 1 : this.state.selected - 1
        });
      case "ArrowDown":
        return this.setState({
          selected: this.state.selected === (this.state.contacts.count() - 1) ? 0 : this.state.selected + 1
        });
    }
  }
});
});

;require.register("components/conversation", function(exports, require, module) {
var Message, MessageFlags, RouterMixin, a, classer, div, h3, i, li, p, span, ul, _ref,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a;

Message = require('./message');

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

MessageFlags = require('../constants/app_constants').MessageFlags;

module.exports = React.createClass({
  displayName: 'Conversation',
  mixins: [RouterMixin],
  propTypes: {
    message: React.PropTypes.object,
    conversation: React.PropTypes.object,
    selectedAccount: React.PropTypes.object.isRequired,
    layout: React.PropTypes.string.isRequired,
    selectedMailboxID: React.PropTypes.string,
    mailboxes: React.PropTypes.object.isRequired,
    settings: React.PropTypes.object.isRequired,
    accounts: React.PropTypes.object.isRequired
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  getInitialState: function() {
    return {
      expanded: false
    };
  },
  expand: function() {
    return this.setState({
      expanded: true
    });
  },
  renderMessage: function(key, message, active) {
    return Message({
      accounts: this.props.accounts,
      active: active,
      inConversation: this.props.conversation.length > 1,
      key: key,
      mailboxes: this.props.mailboxes,
      message: message,
      nextID: this.props.nextID,
      prevID: this.props.prevID,
      selectedAccount: this.props.selectedAccount,
      selectedMailboxID: this.props.selectedMailboxID,
      settings: this.props.settings
    });
  },
  render: function() {
    var activeMessages, closeIcon, closeUrl, collapseUrl, expandUrl, key, message, otherMessages, selectedAccountID;
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
        selectedAccountID = this.props.conversation.get(0).mailbox;
      }
    } else {
      selectedAccountID = this.props.conversation.get(0).mailbox;
    }
    collapseUrl = this.buildUrl({
      firstPanel: {
        action: 'account.mailbox.messages',
        parameters: selectedAccountID
      },
      secondPanel: {
        action: 'message',
        parameters: this.props.conversation.get(0).get('id')
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
    otherMessages = {};
    activeMessages = {};
    this.props.conversation.map((function(_this) {
      return function(message, key) {
        var _ref1;
        if (_this.props.message.get('id') === message.get('id') || (_ref1 = MessageFlags.SEEN, __indexOf.call(message.get('flags'), _ref1) < 0)) {
          return activeMessages[key] = message;
        } else {
          return otherMessages[key] = message;
        }
      };
    })(this)).toJS();
    return div({
      className: 'conversation'
    }, this.props.layout !== 'full' ? a({
      href: expandUrl,
      className: 'expand hidden-xs hidden-sm'
    }, i({
      className: 'fa fa-arrows-h'
    })) : a({
      href: collapseUrl,
      className: 'compress'
    }, i({
      className: 'fa fa-compress'
    })), h3({
      className: 'message-title'
    }, this.props.message.get('subject')), ul({
      className: 'thread list-unstyled'
    }, (function() {
      var _results;
      if (this.state.expanded) {
        _results = [];
        for (key in otherMessages) {
          message = otherMessages[key];
          _results.push(this.renderMessage(key, message, false));
        }
        return _results;
      } else if (this.props.conversationLength > 1) {
        return li({
          className: 'conversation-length-msg'
        }, a({
          onClick: this.expand
        }, t('mail conversation length', {
          smart_count: this.props.conversationLength
        })));
      }
    }).call(this), (function() {
      var _results;
      _results = [];
      for (key in activeMessages) {
        message = activeMessages[key];
        _results.push(this.renderMessage(key, message, true));
      }
      return _results;
    }).call(this)));
  }
});
});

;require.register("components/file_picker", function(exports, require, module) {
var FileItem, FilePicker, FileShape, MessageUtils, a, div, form, i, input, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, form = _ref.form, input = _ref.input, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, a = _ref.a;

MessageUtils = require('../utils/message_utils');

FileShape = React.PropTypes.shape({
  fileName: React.PropTypes.string,
  length: React.PropTypes.number,
  contentType: React.PropTypes.string,
  generatedFileName: React.PropTypes.string,
  contentDisposition: React.PropTypes.string,
  contentId: React.PropTypes.string,
  transferEncoding: React.PropTypes.string,
  rawFileObject: React.PropTypes.object,
  url: React.PropTypes.string
});


/*
 * File picker
 *
 * Available props
 * - editable: boolean (false)
 * - files: array
 * - form: boolean (true) embed component inside a form element
 * - valueLink: a ReactLink for files
 */

FilePicker = React.createClass({
  displayName: 'FilePicker',
  propTypes: {
    editable: React.PropTypes.bool,
    display: React.PropTypes.func,
    value: React.PropTypes.instanceOf(Immutable.Vector),
    valueLink: React.PropTypes.shape({
      value: React.PropTypes.instanceOf(Immutable.Vector),
      requestChange: React.PropTypes.func
    })
  },
  getDefaultProps: function() {
    return {
      editable: false,
      valueLink: {
        value: Immutable.Vector.empty(),
        requestChange: function() {}
      }
    };
  },
  getInitialState: function() {
    return {
      files: this.props.value || this.props.valueLink.value
    };
  },
  componentWillReceiveProps: function(props) {
    return this.setState({
      files: props.value || props.valueLink.value
    });
  },
  addFiles: function(files) {
    files = this.state.files.concat(files).toVector();
    return this.props.valueLink.requestChange(files);
  },
  deleteFile: function(file) {
    var files;
    files = this.state.files.filter(function(f) {
      return f.get('generatedFileName') !== file.generatedFileName;
    }).toVector();
    return this.props.valueLink.requestChange(files);
  },
  displayFile: function(file) {
    if (file.url) {
      return window.open(file.url);
    } else if (file.rawFileObject) {
      return window.open(URL.createObjectURL(file.rawFileObject));
    } else {
      return console.log("broken file : ", file);
    }
  },
  render: function() {
    var className;
    className = 'file-picker';
    if (this.props.className) {
      className += " " + this.props.className;
    }
    return div({
      className: className
    }, ul({
      className: 'files list-unstyled'
    }, this.state.files.toJS().map((function(_this) {
      return function(file) {
        return FileItem({
          key: file.generatedFileName,
          file: file,
          editable: _this.props.editable,
          "delete": function() {
            return _this.deleteFile(file);
          },
          display: function() {
            return _this.displayFile(file);
          }
        });
      };
    })(this))), this.props.editable ? div(null, span({
      className: "file-wrapper"
    }, input({
      type: "file",
      multiple: "multiple",
      ref: "file",
      onChange: this.handleFiles
    })), div({
      className: "dropzone",
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
    var file, files;
    e.preventDefault();
    files = e.target.files || e.dataTransfer.files;
    return this.addFiles((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        _results.push(this._fromDOM(file));
      }
      return _results;
    }).call(this));
  },
  _fromDOM: function(file) {
    var dotpos, idx, name;
    idx = this.state.files.filter(function(f) {
      return f.get('fileName') === file.name;
    }).count();
    name = file.name;
    if (idx > 0) {
      dotpos = file.name.indexOf('.');
      name = name.substring(0, dotpos) + '-' + (idx + 1) + name.substring(dotpos);
    }
    return Immutable.Map({
      fileName: file.name,
      length: file.size,
      contentType: file.type,
      rawFileObject: file,
      generatedFileName: name,
      contentDisposition: null,
      contentId: null,
      transferEncoding: null,
      content: null,
      url: null
    });
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
      fileName: React.PropTypes.string,
      contentType: React.PropTypes.string,
      length: React.PropTypes.number
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
    var file, iconClass, icons, type;
    file = this.props.file;
    type = MessageUtils.getAttachmentType(file.contentType);
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
    return li({
      className: "file-item",
      key: file.name
    }, i({
      className: "mime " + type + " fa " + iconClass
    }), this.props.editable ? i({
      className: "fa fa-times delete",
      onClick: this.doDelete
    }) : void 0, a({
      className: 'file-name',
      target: '_blank',
      onClick: this.doDisplay,
      href: file.url,
      'data-file-url': file.url
    }, file.generatedFileName), div({
      className: 'file-detail'
    }, span(null, "" + ((file.length / 1000).toFixed(2)) + "Ko")));
  },
  doDisplay: function(e) {
    e.preventDefault();
    e.stopPropagation();
    return this.props.display();
  },
  doDelete: function(e) {
    e.preventDefault();
    e.stopPropagation();
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
    if (selectedId != null) {
      selected = this.props.mailboxes.get(selectedId);
    }
    if (this.props.mailboxes.length > 0) {
      return div({
        className: 'btn-group btn-group-sm dropdown pull-left'
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

;require.register("components/mails_input", function(exports, require, module) {
var ContactActionCreator, ContactForm, ContactStore, MailsInput, MessageUtils, Modal, StoreWatchMixin, a, classer, div, i, img, input, label, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, label = _ref.label, input = _ref.input, span = _ref.span, ul = _ref.ul, li = _ref.li, a = _ref.a, img = _ref.img, i = _ref.i;

MessageUtils = require('../utils/message_utils');

ContactForm = require('./contact-form');

Modal = require('./modal');

StoreWatchMixin = require('../mixins/store_watch_mixin');

ContactStore = require('../stores/contact_store');

ContactActionCreator = require('../actions/contact_action_creator');

classer = React.addons.classSet;

module.exports = MailsInput = React.createClass({
  displayName: 'MailsInput',
  mixins: [React.addons.LinkedStateMixin, StoreWatchMixin([ContactStore])],
  getStateFromStores: function() {
    var query, _ref1;
    query = (_ref1 = this.refs.contactInput) != null ? _ref1.getDOMNode().value.trim() : void 0;
    return {
      contacts: (query != null ? query.length : void 0) > 0 ? ContactStore.getResults() : null,
      selected: 0,
      open: false
    };
  },
  componentWillMount: function() {
    return this.setState({
      contacts: null,
      open: false
    });
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  proxyValueLink: function() {
    return {
      value: MessageUtils.displayAddresses(this.props.valueLink.value, true),
      requestChange: (function(_this) {
        return function(newValue) {
          var result;
          result = newValue.split(',').map(function(tupple) {
            var match;
            if (match = tupple.match(/"(.*)" <(.*)>/)) {
              return {
                name: match[1],
                address: match[2]
              };
            } else {
              return {
                address: tupple.trim()
              };
            }
          });
          return _this.props.valueLink.requestChange(result);
        };
      })(this)
    };
  },
  render: function() {
    var classLabel, className, current, listClass, _ref1;
    className = (this.props.className || '') + ' form-group';
    classLabel = 'compose-label control-label';
    listClass = classer({
      'contact-form': true,
      open: this.state.open && ((_ref1 = this.state.contacts) != null ? _ref1.length : void 0) > 0
    });
    current = 0;
    return div({
      className: className
    }, label({
      htmlFor: this.props.id,
      className: classLabel
    }, this.props.label), div({
      className: 'contact-group dropdown ' + listClass
    }, input({
      id: this.props.id,
      name: this.props.id,
      className: 'form-control compose-input',
      onKeyDown: this.onKeyDown,
      onBlur: this.onBlur,
      ref: 'contactInput',
      valueLink: this.proxyValueLink(),
      type: 'text',
      placeholder: this.props.placeholder
    }), div({
      className: 'input-group-addon btn btn-cozy contact',
      onClick: this.onQuery
    }, span({
      className: 'fa fa-search'
    })), this.state.contacts != null ? ul({
      className: "dropdown-menu contact-list"
    }, this.state.contacts.map((function(_this) {
      return function(contact, key) {
        var selected;
        selected = current === _this.state.selected;
        current++;
        return _this.renderContact(contact, selected);
      };
    })(this)).toJS()) : void 0));
  },
  renderContact: function(contact, selected) {
    var avatar, classes, selectContact;
    selectContact = (function(_this) {
      return function() {
        return _this.onContact(contact);
      };
    })(this);
    avatar = contact.get('avatar');
    classes = classer({
      selected: selected
    });
    return li({
      className: classes,
      onClick: selectContact
    }, a(null, avatar != null ? img({
      className: 'avatar',
      src: avatar
    }) : i({
      className: 'avatar fa fa-user'
    }), "" + (contact.get('fn')) + " <" + (contact.get('address')) + ">"));
  },
  onQuery: function(char) {
    var query;
    query = this.refs.contactInput.getDOMNode().value.split(',').pop().trim();
    if (char != null) {
      query += char;
    }
    if (query.length > 0) {
      ContactActionCreator.searchContactLocal(query);
      this.setState({
        open: true
      });
      return true;
    } else {
      if (this.state.open) {
        this.setState({
          contacts: null,
          open: false
        });
      }
      return false;
    }
  },
  onKeyDown: function(evt) {
    var contact, node, _ref1;
    switch (evt.key) {
      case "Enter":
        if (((_ref1 = this.state.contacts) != null ? _ref1.count() : void 0) > 0) {
          this.onContact;
          contact = this.state.contacts.slice(this.state.selected).first();
          this.onContact(contact);
        } else {
          this.onQuery();
        }
        evt.preventDefault();
        return false;
      case "ArrowUp":
        return this.setState({
          selected: this.state.selected === 0 ? this.state.contacts.count() - 1 : this.state.selected - 1
        });
      case "ArrowDown":
        return this.setState({
          selected: this.state.selected === (this.state.contacts.count() - 1) ? 0 : this.state.selected + 1
        });
      case "Backspace":
        node = this.refs.contactInput.getDOMNode();
        node.value = node.value.trim();
        if (node.value.length < 2) {
          return this.setState({
            open: false
          });
        }
        break;
      case "Escape":
        return this.setState({
          contacts: null,
          open: false
        });
      default:
        if ((evt.key != null) || evt.key.toString().length === 1) {
          this.onQuery(String.fromCharCode(evt.which));
          return true;
        }
    }
  },
  onBlur: function() {
    return this.setState({
      open: false
    });
  },
  onContact: function(contact) {
    var address, current, name, val;
    val = this.proxyValueLink();
    if (this.props.valueLink.value.length > 0) {
      current = val.value.split(',').slice(0, -1).join(',');
    } else {
      current = "";
    }
    if (current.trim() !== '') {
      current += ',';
    }
    name = contact.get('fn');
    address = contact.get('address');
    val.requestChange("" + current + name + " <" + address + ">,");
    return this.setState({
      contacts: null,
      open: false
    });
  }
});
});

;require.register("components/menu", function(exports, require, module) {
var AccountStore, Dispositions, LayoutActionCreator, Menu, MenuMailboxItem, MessageActionCreator, Modal, RouterMixin, SpecialBoxIcons, ThinProgress, a, classer, div, i, li, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

AccountStore = require('../stores/account_store');

Modal = require('./modal');

ThinProgress = require('./thin_progress');

_ref1 = require('../constants/app_constants'), Dispositions = _ref1.Dispositions, SpecialBoxIcons = _ref1.SpecialBoxIcons;

module.exports = Menu = React.createClass({
  displayName: 'Menu',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  getInitialState: function() {
    return {
      displayActiveAccount: true,
      modalErrors: null,
      onlyFavorites: true
    };
  },
  componentWillReceiveProps: function(props) {
    if (!Immutable.is(props.selectedAccount, this.props.selectedAccount)) {
      return this.setState({
        displayActiveAccount: true
      });
    }
  },
  displayErrors: function(refreshee) {
    return this.setState({
      modalErrors: refreshee.get('errors')
    });
  },
  hideErrors: function() {
    return this.setState({
      modalErrors: null
    });
  },
  render: function() {
    var classes, closeLabel, closeModal, composeClass, composeUrl, content, modal, modalErrors, newMailboxClass, newMailboxUrl, selectedAccountUrl, settingsClass, settingsUrl, subtitle, title, _ref2, _ref3, _ref4;
    if (this.props.accounts.length) {
      selectedAccountUrl = this.buildUrl({
        direction: 'first',
        action: 'account.mailbox.messages',
        parameters: (_ref2 = this.props.selectedAccount) != null ? _ref2.get('id') : void 0,
        fullWidth: true
      });
    } else {
      selectedAccountUrl = this.buildUrl({
        direction: 'first',
        action: 'account.new',
        fullWidth: true
      });
    }
    if (this.props.layout.firstPanel.action === 'compose' || ((_ref3 = this.props.layout.secondPanel) != null ? _ref3.action : void 0) === 'compose') {
      composeClass = 'active';
      composeUrl = selectedAccountUrl;
    } else {
      composeClass = '';
      composeUrl = this.buildUrl({
        direction: 'first',
        action: 'compose',
        parameters: null,
        fullWidth: true
      });
    }
    if (this.props.layout.firstPanel.action === 'account.new') {
      newMailboxClass = 'active';
      newMailboxUrl = selectedAccountUrl;
    } else {
      newMailboxClass = '';
      newMailboxUrl = this.buildUrl({
        direction: 'first',
        action: 'account.new',
        fullWidth: true
      });
    }
    if (this.props.layout.firstPanel.action === 'settings' || ((_ref4 = this.props.layout.secondPanel) != null ? _ref4.action : void 0) === 'settings') {
      settingsClass = 'active';
      settingsUrl = selectedAccountUrl;
    } else {
      settingsClass = '';
      settingsUrl = this.buildUrl({
        direction: 'first',
        action: 'settings',
        fullWidth: true
      });
    }
    if (this.state.modalErrors) {
      title = t('modal please contribute');
      subtitle = t('modal please report');
      modalErrors = this.state.modalErrors;
      closeModal = this.hideErrors;
      closeLabel = t('app alert close');
      content = React.DOM.pre({
        style: {
          "max-height": "300px",
          "word-wrap": "normal"
        }
      }, this.state.modalErrors.join("\n\n"));
      modal = Modal({
        title: title,
        subtitle: subtitle,
        content: content,
        closeModal: closeModal,
        closeLabel: closeLabel
      });
    } else {
      modal = null;
    }
    classes = classer({
      'hidden-xs hidden-sm': !this.props.isResponsiveMenuShown,
      'col-xs-4': true,
      'col-md-1': this.props.disposition.type !== Dispositions.THREE,
      'col-md-3': this.props.disposition.type === Dispositions.THREE,
      'three': this.props.disposition.type === Dispositions.THREE
    });
    return div({
      id: 'menu',
      className: classes
    }, modal, this.props.accounts.length !== 0 ? a({
      href: composeUrl,
      onClick: this._hideMenu,
      className: 'menu-item compose-action ' + composeClass
    }, i({
      className: 'fa fa-edit'
    }), span({
      className: 'item-label'
    }, t('menu compose'))) : void 0, this.props.accounts.length !== 0 ? ul({
      id: 'account-list',
      className: 'list-unstyled'
    }, this.props.accounts.map((function(_this) {
      return function(account, key) {
        return _this.getAccountRender(account, key);
      };
    })(this)).toJS()) : void 0, a({
      href: newMailboxUrl,
      onClick: this._hideMenu,
      className: 'menu-item new-account-action ' + newMailboxClass
    }, i({
      className: 'fa fa-inbox'
    }), span({
      className: 'item-label'
    }, t('menu account new'))), a({
      href: settingsUrl,
      onClick: this._hideMenu,
      className: 'menu-item settings-action ' + settingsClass
    }, i({
      className: 'fa fa-cog'
    }), span({
      className: 'item-label'
    }, t('menu settings'))));
  },
  getAccountRender: function(account, key) {
    var accountClasses, accountID, defaultMailbox, icon, isSelected, mailboxes, progress, refreshes, toggleActive, toggleDisplay, toggleFavorites, toggleFavoritesLabel, url, _ref2;
    isSelected = ((this.props.selectedAccount == null) && key === 0) || ((_ref2 = this.props.selectedAccount) != null ? _ref2.get('id') : void 0) === account.get('id');
    accountID = account.get('id');
    defaultMailbox = AccountStore.getDefaultMailbox(accountID);
    refreshes = this.props.refreshes;
    if (defaultMailbox != null) {
      url = this.buildUrl({
        direction: 'first',
        action: 'account.mailbox.messages',
        parameters: [accountID, defaultMailbox != null ? defaultMailbox.get('id') : void 0],
        fullWidth: true
      });
    } else {
      url = this.buildUrl({
        direction: 'first',
        action: 'account.config',
        parameters: [accountID, 'account'],
        fullWidth: true
      });
    }
    toggleActive = (function(_this) {
      return function() {
        if (!_this.state.displayActiveAccount) {
          _this.setState({
            displayActiveAccount: true
          });
        }
        return _this._hideMenu();
      };
    })(this);
    toggleDisplay = (function(_this) {
      return function() {
        if (isSelected) {
          return _this.setState({
            displayActiveAccount: !_this.state.displayActiveAccount
          });
        } else {
          return _this.setState({
            displayActiveAccount: true
          });
        }
      };
    })(this);
    toggleFavorites = (function(_this) {
      return function() {
        return _this.setState({
          onlyFavorites: !_this.state.onlyFavorites
        });
      };
    })(this);
    accountClasses = classer({
      active: isSelected && this.state.displayActiveAccount
    });
    if (this.state.onlyFavorites) {
      mailboxes = this.props.favorites;
      icon = 'fa-toggle-down';
      toggleFavoritesLabel = t('menu favorites off');
    } else {
      mailboxes = this.props.mailboxes;
      icon = 'fa-toggle-up';
      toggleFavoritesLabel = t('menu favorites on');
    }
    return li({
      className: accountClasses,
      key: key
    }, a({
      href: url,
      className: 'menu-item account ' + accountClasses,
      onClick: toggleActive,
      onDoubleClick: toggleDisplay,
      'data-toggle': 'tooltip',
      'data-delay': '10000',
      'data-placement': 'right'
    }, i({
      className: 'fa fa-inbox'
    }), span({
      'data-account-id': key,
      className: 'item-label'
    }, account.get('label')), (progress = refreshes.get(accountID)) ? (progress.get('errors').length ? span({
      className: 'refresh-error'
    }, i({
      className: 'fa warning',
      onClick: this.displayErrors.bind(null, progress)
    })) : void 0, ThinProgress({
      done: progress.get('done'),
      total: progress.get('total')
    })) : void 0), isSelected ? ul({
      className: 'list-unstyled submenu mailbox-list'
    }, mailboxes != null ? mailboxes.map((function(_this) {
      return function(mailbox, key) {
        var selectedMailboxID;
        selectedMailboxID = _this.props.selectedMailboxID;
        return MenuMailboxItem({
          account: account,
          mailbox: mailbox,
          key: key,
          selectedMailboxID: selectedMailboxID,
          refreshes: refreshes,
          displayErrors: _this.displayErrors,
          hideMenu: _this._hideMenu
        });
      };
    })(this)).toJS() : void 0, li(null, a({
      className: 'menu-item',
      tabIndex: 0,
      onClick: toggleFavorites,
      key: 'toggle'
    }, i({
      className: 'fa ' + icon
    }), span({
      className: 'item-label'
    }, toggleFavoritesLabel)))) : void 0);
  },
  _hideMenu: function() {
    if (this.props.isResponsiveMenuShown) {
      return this.props.toggleMenu();
    }
  },
  _initTooltips: function() {},
  componentDidMount: function() {
    return this._initTooltips();
  },
  componentDidUpdate: function() {
    return this._initTooltips();
  }
});

MenuMailboxItem = React.createClass({
  displayName: 'MenuMailboxItem',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  getInitialState: function() {
    return {
      target: false
    };
  },
  render: function() {
    var attrib, classesChild, classesParent, displayError, icon, j, mailboxID, mailboxIcon, mailboxUrl, nbRecent, nbTotal, nbUnread, progress, pusher, title, _i, _ref2;
    mailboxID = this.props.mailbox.get('id');
    mailboxUrl = this.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: [this.props.account.get('id'), mailboxID]
    });
    nbTotal = this.props.mailbox.get('nbTotal') || 0;
    nbUnread = this.props.mailbox.get('nbUnread') || 0;
    nbRecent = this.props.mailbox.get('nbRecent') || 0;
    title = t("menu mailbox total", nbTotal);
    if (nbUnread > 0) {
      title += t("menu mailbox unread", nbUnread);
    }
    if (nbRecent > 0) {
      title += t("menu mailbox new", nbRecent);
    }
    classesParent = classer({
      active: mailboxID === this.props.selectedMailboxID,
      target: this.state.target
    });
    classesChild = classer({
      'menu-item': true,
      target: this.state.target,
      news: nbRecent > 0
    });
    mailboxIcon = 'fa-folder';
    for (attrib in SpecialBoxIcons) {
      icon = SpecialBoxIcons[attrib];
      if (this.props.account.get(attrib) === mailboxID) {
        mailboxIcon = icon;
      }
    }
    progress = this.props.refreshes.get(mailboxID);
    displayError = this.props.displayErrors.bind(null, progress);
    pusher = "";
    for (j = _i = 1, _ref2 = this.props.mailbox.get('depth'); _i <= _ref2; j = _i += 1) {
      pusher += "   ";
    }
    return li({
      className: classesParent
    }, a({
      href: mailboxUrl,
      onClick: this.props.hideMenu,
      className: classesChild,
      'data-mailbox-id': mailboxID,
      onDragEnter: this.onDragEnter,
      onDragLeave: this.onDragLeave,
      onDragOver: this.onDragOver,
      onDrop: this.onDrop,
      title: title,
      'data-toggle': 'tooltip',
      'data-placement': 'right',
      key: this.props.key
    }, i({
      className: 'fa ' + mailboxIcon
    }), !progress && nbUnread && nbUnread > 0 ? span({
      className: 'badge'
    }, nbUnread) : void 0, span({
      className: 'item-label'
    }, "" + pusher + (this.props.mailbox.get('label'))), progress ? ThinProgress({
      done: progress.get('done'),
      total: progress.get('total')
    }) : void 0, (progress != null ? progress.get('errors').length : void 0) ? span({
      className: 'refresh-error',
      onClick: displayError
    }, i({
      className: 'fa fa-warning'
    }, null)) : void 0));
  },
  onDragEnter: function(e) {
    if (!this.state.target) {
      return this.setState({
        target: true
      });
    }
  },
  onDragLeave: function(e) {
    if (this.state.target) {
      return this.setState({
        target: false
      });
    }
  },
  onDragOver: function(e) {
    return e.preventDefault();
  },
  onDrop: function(event) {
    var mailboxID, messageID, newID, _ref2;
    _ref2 = JSON.parse(event.dataTransfer.getData('text')), messageID = _ref2.messageID, mailboxID = _ref2.mailboxID;
    newID = event.currentTarget.dataset.mailboxId;
    this.setState({
      target: false
    });
    return MessageActionCreator.move(messageID, mailboxID, newID, function(error) {
      if (error != null) {
        return LayoutActionCreator.alertError("" + (t("message action move ko")) + " " + error);
      } else {
        return LayoutActionCreator.notify(t("message action move ok"));
      }
    });
  }
});
});

;require.register("components/message-list", function(exports, require, module) {
var ContactActionCreator, ConversationActionCreator, FlagsConstants, LayoutActionCreator, MailboxList, MessageActionCreator, MessageFilter, MessageFlags, MessageItem, MessageList, MessageStore, MessageUtils, MessagesFilter, MessagesQuickFilter, MessagesSort, Participants, RouterMixin, SocketUtils, ToolboxActions, ToolboxMove, a, alertError, button, classer, div, i, img, input, li, p, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, p = _ref.p, button = _ref.button, input = _ref.input, img = _ref.img;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

MessageUtils = require('../utils/message_utils');

SocketUtils = require('../utils/socketio_utils');

_ref1 = require('../constants/app_constants'), MessageFlags = _ref1.MessageFlags, MessageFilter = _ref1.MessageFilter, FlagsConstants = _ref1.FlagsConstants;

LayoutActionCreator = require('../actions/layout_action_creator');

ContactActionCreator = require('../actions/contact_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

MessageStore = require('../stores/message_store');

MailboxList = require('./mailbox-list');

Participants = require('./participant');

ToolboxActions = require('./toolbox_actions');

ToolboxMove = require('./toolbox_move');

alertError = LayoutActionCreator.alertError;

MessageList = React.createClass({
  displayName: 'MessageList',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  getInitialState: function() {
    return {
      edited: false,
      filterFlag: false,
      filterUnsead: false,
      selected: {},
      allSelected: false
    };
  },
  componentWillReceiveProps: function(props) {
    var selected;
    if (props.mailboxID !== this.props.mailboxID) {
      return this.setState({
        allSelected: false,
        edited: false,
        selected: {}
      });
    } else {
      selected = this.state.selected;
      Object.keys(selected).forEach(function(id) {
        if (!props.messages.get(id)) {
          return delete selected[id];
        }
      });
      this.setState({
        selected: selected
      });
      if (Object.keys(selected).length === 0) {
        return this.setState({
          allSelected: false,
          edited: false
        });
      }
    }
  },
  render: function() {
    var advanced, classCompact, classEdited, classList, compact, configMailboxUrl, filterParams, getMailboxUrl, messages, nbMessages, nbSelected, nextPage, toggleFilterFlag, toggleFilterUnseen;
    compact = this.props.settings.get('listStyle') === 'compact';
    messages = this.props.messages.map((function(_this) {
      return function(message, key) {
        var cid, id, isActive, _ref2;
        id = message.get('id');
        cid = message.get('conversationID');
        isActive = _this.props.messageID === id;
        return MessageItem({
          message: message,
          conversationLength: (_ref2 = _this.props.conversationLengths) != null ? _ref2.get(cid) : void 0,
          key: key,
          isActive: isActive,
          edited: _this.state.edited,
          settings: _this.props.settings,
          selected: _this.state.selected[id] != null,
          onSelect: function(val) {
            var selected;
            selected = _.clone(_this.state.selected);
            if (val) {
              selected[id] = val;
            } else {
              delete selected[id];
            }
            if (Object.keys(selected).length > 0) {
              return _this.setState({
                edited: true,
                selected: selected
              });
            } else {
              return _this.setState({
                allSelected: false,
                edited: false,
                selected: {}
              });
            }
          }
        });
      };
    })(this)).toJS();
    nbMessages = parseInt(this.props.counterMessage, 10);
    filterParams = {
      accountID: this.props.accountID,
      mailboxID: this.props.mailboxID,
      query: this.props.query
    };
    nextPage = (function(_this) {
      return function() {
        return LayoutActionCreator.showMessageList({
          parameters: _this.props.query
        });
      };
    })(this);
    getMailboxUrl = (function(_this) {
      return function(mailbox) {
        return _this.buildUrl({
          direction: 'first',
          action: 'account.mailbox.messages',
          parameters: [_this.props.accountID, mailbox.get('id')]
        });
      };
    })(this);
    configMailboxUrl = this.buildUrl({
      direction: 'first',
      action: 'account.config',
      parameters: [this.props.accountID, 'account'],
      fullWidth: true
    });
    advanced = this.props.settings.get('advanced');
    nbSelected = Object.keys(this.state.selected).length > 0 ? null : true;
    toggleFilterFlag = (function(_this) {
      return function() {
        var filter, params;
        filter = _this.state.filterFlag ? MessageFilter.ALL : MessageFilter.FLAGGED;
        LayoutActionCreator.filterMessages(filter);
        params = MessageStore.getParams();
        params.accountID = _this.props.accountID;
        params.mailboxID = _this.props.mailboxID;
        LayoutActionCreator.showMessageList({
          parameters: params
        });
        return _this.setState({
          filterFlag: !_this.state.filterFlag,
          filterUnseen: false
        });
      };
    })(this);
    toggleFilterUnseen = (function(_this) {
      return function() {
        var filter, params;
        filter = _this.state.filterUnseen ? MessageFilter.ALL : MessageFilter.UNSEEN;
        LayoutActionCreator.filterMessages(filter);
        params = MessageStore.getParams();
        params.accountID = _this.props.accountID;
        params.mailboxID = _this.props.mailboxID;
        LayoutActionCreator.showMessageList({
          parameters: params
        });
        return _this.setState({
          filterUnseen: !_this.state.filterUnseen,
          filterFlag: false
        });
      };
    })(this);
    classList = classer({
      compact: compact,
      edited: this.state.edited
    });
    classCompact = classer({
      active: compact
    });
    classEdited = classer({
      active: this.state.edited
    });
    return div({
      className: 'message-list ' + classList,
      ref: 'list'
    }, div({
      className: 'message-list-actions'
    }, div({
      className: 'btn-toolbar',
      role: 'toolbar'
    }, div({
      className: 'btn-group'
    }, advanced ? div({
      className: 'btn-group btn-group-sm message-list-option'
    }, button({
      type: "button",
      className: "btn btn-default " + classEdited,
      onClick: this.toggleEdited
    }, i({
      className: 'fa fa-square-o'
    }))) : void 0, advanced && !this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option'
    }, MailboxList({
      getUrl: getMailboxUrl,
      mailboxes: this.props.mailboxes,
      selectedMailbox: this.props.mailboxID
    })) : void 0, !advanced && !this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option '
    }, button({
      onClick: toggleFilterUnseen,
      title: t('list filter unseen title'),
      className: 'btn btn-default ' + (this.state.filterUnseen ? ' shown ' : '')
    }, span({
      className: 'fa fa-envelope'
    }))) : void 0, !advanced && !this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option '
    }, button({
      onClick: toggleFilterFlag,
      title: t('list filter flagged title'),
      className: 'btn btn-default ' + (this.state.filterFlag ? ' shown ' : '')
    }, span({
      className: 'fa fa-star'
    }))) : void 0, advanced && !this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option'
    }, MessagesFilter(filterParams)) : void 0, advanced && !this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option'
    }, MessagesSort(filterParams)) : void 0, !this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option'
    }, button({
      className: 'btn btn-default trash',
      type: 'button',
      disabled: null,
      onClick: this.refresh
    }, span({
      className: 'fa fa-refresh'
    }))) : void 0, !this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option'
    }, a({
      href: configMailboxUrl,
      className: 'btn btn-default'
    }, i({
      className: 'fa fa-cog'
    }))) : void 0, this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option'
    }, button({
      type: "button",
      className: "btn btn-default " + classEdited,
      onClick: this.toggleAll
    }, i({
      className: 'fa fa-square-o'
    }))) : void 0, this.state.edited ? div({
      className: 'btn-group btn-group-sm message-list-option'
    }, button({
      className: 'btn btn-default trash',
      type: 'button',
      disabled: nbSelected,
      onClick: this.onDelete
    }, span({
      className: 'fa fa-trash-o'
    }))) : void 0, this.state.edited ? ToolboxMove({
      mailboxes: this.props.mailboxes,
      onMove: this.onMove,
      direction: 'left'
    }) : void 0, this.state.edited ? ToolboxActions({
      mailboxes: this.props.mailboxes,
      onMark: this.onMark,
      onConversation: this.onConversation,
      onHeaders: this.onHeaders,
      direction: 'left'
    }) : void 0))), this.props.messages.count() === 0 ? this.props.fetching ? p(null, t('list fetching')) : p(null, this.props.emptyListMessage) : div(null, ul({
      className: 'list-unstyled'
    }, messages), this.props.messages.count() < nbMessages && (this.props.query.pageAfter != null) ? p({
      className: 'text-center'
    }, this.props.fetching ? i({
      className: "fa fa-refresh fa-spin"
    }) : a({
      className: 'more-messages',
      onClick: nextPage,
      ref: 'nextPage'
    }, t('list next page'))) : p({
      ref: 'listEnd'
    }, t('list end'))));
  },
  refresh: function(event) {
    event.preventDefault();
    return LayoutActionCreator.refreshMessages();
  },
  toggleEdited: function() {
    if (this.state.edited) {
      return this.setState({
        allSelected: false,
        edited: false,
        selected: {}
      });
    } else {
      return this.setState({
        edited: true
      });
    }
  },
  toggleAll: function() {
    var selected;
    if (this.state.allSelected) {
      return this.setState({
        allSelected: false,
        edited: false,
        selected: {}
      });
    } else {
      selected = {};
      this.props.messages.map(function(message, key) {
        return selected[key] = true;
      }).toJS();
      return this.setState({
        allSelected: true,
        edited: true,
        selected: selected
      });
    }
  },
  onDelete: function() {
    var selected;
    selected = Object.keys(this.state.selected);
    if (selected.length === 0) {
      return alertError(t('list mass no message'));
    } else {
      if (window.confirm(t('list delete confirm', {
        nb: selected.length
      }))) {
        return MessageActionCreator["delete"](selected);

        /*
        selected.forEach (id) ->
            MessageActionCreator.delete id, (error) ->
                if error?
                    alertError "#{t("message action delete ko")} #{error}"
                else
                    window.cozyMails.messageNavigate()
         */
      }
    }
  },
  onMove: function(args) {
    var newbox, selected;
    selected = Object.keys(this.state.selected);
    if (selected.length === 0) {
      return alertError(t('list mass no message'));
    } else {
      newbox = args.target.dataset.value;
      if (args.target.dataset.conversation != null) {
        return selected.forEach((function(_this) {
          return function(id) {
            var conversationID, message;
            message = _this.props.messages.get(id);
            conversationID = message.get('conversationID');
            return ConversationActionCreator.move(conversationID, newbox, function(error) {
              if (error != null) {
                return alertError("" + (t("conversation move ko")) + " " + error);
              } else {
                return window.cozyMails.messageNavigate();
              }
            });
          };
        })(this));
      } else {
        return selected.forEach((function(_this) {
          return function(id) {
            var message;
            message = _this.props.messages.get(id);
            return MessageActionCreator.move(message, _this.props.mailboxID, newbox, function(error) {
              if (error != null) {
                return alertError("" + (t("message action move ko")) + " " + error);
              } else {
                return window.cozyMails.messageNavigate();
              }
            });
          };
        })(this));
      }
    }
  },
  onMark: function(args) {
    var flag, selected;
    selected = Object.keys(this.state.selected);
    if (selected.length === 0) {
      return alertError(t('list mass no message'));
    } else {
      flag = args.target.dataset.value;
      return selected.forEach((function(_this) {
        return function(id) {
          var flags, message;
          message = _this.props.messages.get(id);
          flags = message.get('flags').slice();
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
          return MessageActionCreator.updateFlag(message, flags, function(error) {
            if (error != null) {
              return alertError("" + (t("message action mark ko")) + " " + error);
            }
          });
        };
      })(this));
    }
  },
  onConversation: function(args) {
    var selected;
    selected = Object.keys(this.state.selected);
    if (selected.length === 0) {
      return alertError(t('list mass no message'));
    } else {
      return selected.forEach((function(_this) {
        return function(id) {
          var action, conversationID, message;
          message = _this.props.messages.get(id);
          conversationID = message.get('conversationID');
          action = args.target.dataset.action;
          switch (action) {
            case 'delete':
              return ConversationActionCreator["delete"](conversationID, function(error) {
                if (error != null) {
                  return alertError("" + (t("conversation delete ko")) + " " + error);
                }
              });
            case 'seen':
              return ConversationActionCreator.seen(conversationID, function(error) {
                if (error != null) {
                  return alertError("" + (t("conversation seen ok ")) + " " + error);
                }
              });
            case 'unseen':
              return ConversationActionCreator.unseen(conversationID, function(error) {
                if (error != null) {
                  return alertError("" + (t("conversation unseen ok")) + " " + error);
                }
              });
          }
        };
      })(this));
    }
  },
  _isVisible: function(node, before) {
    var height, margin, rect, width;
    margin = before ? 40 : 0;
    rect = node.getBoundingClientRect();
    height = window.innerHeight || document.documentElement.clientHeight;
    width = window.innerWidth || document.documentElement.clientWidth;
    return rect.bottom <= (height + 0) && rect.top >= 0;
  },
  _loadNext: function() {
    if ((this.refs.nextPage != null) && this._isVisible(this.refs.nextPage.getDOMNode(), true)) {
      return LayoutActionCreator.showMessageList({
        parameters: this.props.query
      });
    }
  },
  _handleRealtimeGrowth: function() {
    var lastdate, nbMessages;
    nbMessages = parseInt(this.props.counterMessage, 10);
    if (nbMessages < this.props.messages.count() && (this.refs.listEnd != null) && !this._isVisible(this.refs.listEnd.getDOMNode(), true)) {
      lastdate = this.props.messages.last().get('date');
      return SocketUtils.changeRealtimeScope(this.props.mailboxID, lastdate);
    }
  },
  _initScroll: function() {
    var active, scrollable;
    if (this.refs.nextPage == null) {
      return;
    }
    if (this.state.messageID !== this.props.messageID) {
      active = document.querySelector("[data-message-id='" + this.props.messageID + "']");
      if ((active != null) && !this._isVisible(active)) {
        active.scrollIntoView();
      }
      this.setState({
        messageID: this.props.messageID
      });
    }
    scrollable = this.refs.list.getDOMNode().parentNode;
    return setTimeout((function(_this) {
      return function() {
        scrollable.removeEventListener('scroll', _this._loadNext);
        return scrollable.addEventListener('scroll', _this._loadNext);
      };
    })(this), 0);
  },
  componentDidMount: function() {
    return this._initScroll();
  },
  componentDidUpdate: function() {
    this._initScroll();
    return this._handleRealtimeGrowth();
  },
  componentWillUnmount: function() {
    var scrollable;
    scrollable = this.refs.list.getDOMNode().parentNode;
    return scrollable.removeEventListener('scroll', this._loadNext);
  }
});

module.exports = MessageList;

MessageItem = React.createClass({
  displayName: 'MessagesItem',
  mixins: [RouterMixin],
  render: function() {
    var action, avatar, classes, compact, conversationID, date, flags, id, isDraft, message, tag, url, _ref2;
    message = this.props.message;
    flags = message.get('flags');
    classes = classer({
      message: true,
      read: message.get('isRead'),
      active: this.props.isActive,
      edited: this.props.edited,
      'unseen': flags.indexOf(MessageFlags.SEEN) === -1,
      'has-attachments': message.get('hasAttachments'),
      'is-fav': flags.indexOf(MessageFlags.FLAGGED) !== -1
    });
    isDraft = message.get('flags').indexOf(MessageFlags.DRAFT) !== -1;
    if (isDraft) {
      action = 'edit';
      id = message.get('id');
    } else {
      conversationID = message.get('conversationID');
      if (conversationID && this.props.settings.get('displayConversation')) {
        action = 'conversation';
        id = message.get('id');
      } else {
        action = 'message';
        id = message.get('id');
      }
    }
    if (!this.props.edited) {
      url = this.buildUrl({
        direction: 'second',
        action: action,
        parameters: id
      });
      tag = a;
    } else {
      tag = span;
    }
    compact = this.props.settings.get('listStyle') === 'compact';
    date = MessageUtils.formatDate(message.get('createdAt'), compact);
    avatar = MessageUtils.getAvatar(message);
    return li({
      className: classes,
      key: this.props.key,
      'data-message-id': message.get('id'),
      draggable: !this.props.edited,
      onClick: this.onMessageClick,
      onDragStart: this.onDragStart
    }, tag({
      href: url,
      className: 'wrapper',
      'data-message-id': message.get('id'),
      onClick: this.onMessageClick,
      onDoubleClick: this.onMessageDblClick
    }, div({
      className: 'avatar-wrapper'
    }, input({
      ref: 'select',
      className: 'select',
      type: 'checkbox',
      checked: this.props.selected,
      onChange: this.onSelect
    }), avatar != null ? img({
      className: 'avatar',
      src: avatar
    }) : i({
      className: 'fa fa-user'
    })), span({
      className: 'participants'
    }, this.getParticipants(message)), div({
      className: 'preview'
    }, this.props.conversationLength > 1 ? span({
      className: 'badge conversation-length'
    }, this.props.conversationLength) : void 0, span({
      className: 'title'
    }, message.get('subject')), p(null, ((_ref2 = message.get('text')) != null ? _ref2.substr(0, 100) : void 0) + "…")), span({
      className: 'hour'
    }, date), span({
      className: "flags"
    }, i({
      className: 'attach fa fa-paperclip'
    }), i({
      className: 'fav fa fa-star'
    }))));
  },
  _doCheck: function() {
    if (this.props.selected) {
      return setTimeout((function(_this) {
        return function() {
          var _ref2;
          return (_ref2 = _this.refs.select) != null ? _ref2.getDOMNode().checked = true : void 0;
        };
      })(this), 50);
    } else {
      return setTimeout((function(_this) {
        return function() {
          var _ref2;
          return (_ref2 = _this.refs.select) != null ? _ref2.getDOMNode().checked = false : void 0;
        };
      })(this), 50);
    }
  },
  componentDidMount: function() {
    return this._doCheck();
  },
  componentDidUpdate: function() {
    return this._doCheck();
  },
  onSelect: function(e) {
    this.props.onSelect(!this.props.selected);
    e.preventDefault();
    return e.stopPropagation();
  },
  onMessageClick: function(event) {
    if (this.props.edited) {
      this.props.onSelect(!this.props.selected);
      event.preventDefault();
      return event.stopPropagation();
    } else {
      if (!this.props.settings.get('displayPreview')) {
        event.preventDefault();
        return MessageActionCreator.setCurrent(event.currentTarget.dataset.messageId);
      }
    }
  },
  onMessageDblClick: function(event) {
    var url;
    if (!this.props.edited) {
      url = event.currentTarget.href.split('#')[1];
      return window.router.navigate(url, {
        trigger: true
      });
    }
  },
  onDragStart: function(event) {
    var data;
    event.stopPropagation();
    data = {
      messageID: event.currentTarget.dataset.messageId,
      mailboxID: this.props.mailboxID
    };
    event.dataTransfer.setData('text', JSON.stringify(data));
    event.dataTransfer.effectAllowed = 'move';
    return event.dataTransfer.dropEffect = 'move';
  },
  getParticipants: function(message) {
    var from, to;
    from = message.get('from');
    to = message.get('to').concat(message.get('cc'));
    return span(null, Participants({
      participants: from,
      onAdd: this.addAddress
    }), span(null, ', '), Participants({
      participants: to,
      onAdd: this.addAddress
    }));
  },
  addAddress: function(address) {
    return ContactActionCreator.createContact(address);
  }
});

MessagesQuickFilter = React.createClass({
  displayName: 'MessagesQuickFilter',
  render: function() {
    return div({
      className: "form-group message-list-action"
    }, input({
      className: "form-control",
      type: "text",
      onBlur: this.onQuick
    }));
  },
  onQuick: function(ev) {
    return LayoutActionCreator.quickFilterMessages(ev.target.value.trim());
  }
});

MessagesFilter = React.createClass({
  displayName: 'MessagesFilter',
  mixins: [RouterMixin],
  render: function() {
    var filter, title;
    filter = this.props.query.flag;
    if ((filter == null) || filter === '-') {
      title = i({
        className: 'fa fa-filter'
      });
    } else {
      title = t('list filter ' + filter);
    }
    return div({
      className: 'btn-group btn-group-sm dropdown filter-dropdown'
    }, button({
      className: 'btn btn-default dropdown-toggle message-list-action',
      type: 'button',
      'data-toggle': 'dropdown'
    }, title, span({
      className: 'caret'
    })), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, li({
      role: 'presentation'
    }, a({
      onClick: this.onFilter,
      'data-filter': MessageFilter.ALL
    }, t('list filter all'))), li({
      role: 'presentation'
    }, a({
      onClick: this.onFilter,
      'data-filter': MessageFilter.UNSEEN
    }, t('list filter unseen'))), li({
      role: 'presentation'
    }, a({
      onClick: this.onFilter,
      'data-filter': MessageFilter.FLAGGED
    }, t('list filter flagged')))));
  },
  onFilter: function(ev) {
    var params;
    LayoutActionCreator.filterMessages(ev.target.dataset.filter);
    params = MessageStore.getParams();
    params.accountID = this.props.accountID;
    params.mailboxID = this.props.mailboxID;
    return LayoutActionCreator.showMessageList({
      parameters: params
    });
  }
});

MessagesSort = React.createClass({
  displayName: 'MessagesSort',
  mixins: [RouterMixin],
  render: function() {
    var sort, title;
    sort = this.props.query.sort;
    if ((sort == null) || sort === '-') {
      title = t('list sort');
    } else {
      sort = sort.substr(1);
      title = t('list sort ' + sort);
    }
    return div({
      className: 'btn-group btn-group-sm dropdown sort-dropdown'
    }, button({
      className: 'btn btn-default dropdown-toggle message-list-action',
      type: 'button',
      'data-toggle': 'dropdown'
    }, title, span({
      className: 'caret'
    })), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, li({
      role: 'presentation'
    }, a({
      onClick: this.onSort,
      'data-sort': 'date'
    }, t('list sort date'))), li({
      role: 'presentation'
    }, a({
      onClick: this.onSort,
      'data-sort': 'subject'
    }, t('list sort subject')))));
  },
  onSort: function(ev) {
    var field, params;
    field = ev.target.dataset.sort;
    LayoutActionCreator.sortMessages({
      field: field
    });
    params = MessageStore.getParams();
    params.accountID = this.props.accountID;
    params.mailboxID = this.props.mailboxID;
    return LayoutActionCreator.showMessageList({
      parameters: params
    });
  }
});
});

;require.register("components/message", function(exports, require, module) {
var AttachmentPreview, Compose, ComposeActions, ContactActionCreator, ConversationActionCreator, FilePicker, FlagsConstants, LayoutActionCreator, MessageActionCreator, MessageContent, MessageFlags, MessageUtils, Participants, RouterMixin, ToolboxActions, ToolboxMove, a, alertError, alertSuccess, button, classer, div, h4, i, iframe, img, li, p, pre, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, a = _ref.a, button = _ref.button, pre = _ref.pre, iframe = _ref.iframe, img = _ref.img, h4 = _ref.h4;

Compose = require('./compose');

FilePicker = require('./file_picker');

ToolboxActions = require('./toolbox_actions');

ToolboxMove = require('./toolbox_move');

MessageUtils = require('../utils/message_utils');

_ref1 = require('../constants/app_constants'), ComposeActions = _ref1.ComposeActions, MessageFlags = _ref1.MessageFlags, FlagsConstants = _ref1.FlagsConstants;

LayoutActionCreator = require('../actions/layout_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

ContactActionCreator = require('../actions/contact_action_creator');

RouterMixin = require('../mixins/router_mixin');

Participants = require('./participant');

classer = React.addons.classSet;

alertError = LayoutActionCreator.alertError;

alertSuccess = LayoutActionCreator.notify;

module.exports = React.createClass({
  displayName: 'Message',
  mixins: [RouterMixin],
  getInitialState: function() {
    return {
      active: this.props.active,
      composing: false,
      composeAction: '',
      headers: false,
      messageDisplayHTML: this.props.settings.get('messageDisplayHTML'),
      messageDisplayImages: this.props.settings.get('messageDisplayImages')
    };
  },
  propTypes: {
    accounts: React.PropTypes.object.isRequired,
    active: React.PropTypes.bool,
    inConversation: React.PropTypes.bool,
    key: React.PropTypes.string.isRequired,
    mailboxes: React.PropTypes.object.isRequired,
    message: React.PropTypes.object.isRequired,
    nextID: React.PropTypes.string,
    prevID: React.PropTypes.string,
    selectedAccount: React.PropTypes.object.isRequired,
    selectedMailboxID: React.PropTypes.string.isRequired,
    settings: React.PropTypes.object.isRequired
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  _prepareMessage: function() {
    var e, fullHeaders, html, key, message, rich, text, urls, value, _ref2;
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
    urls = /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/gim;
    if (text && !html && this.state.messageDisplayHTML) {
      try {
        html = markdown.toHTML(text);
      } catch (_error) {
        e = _error;
        console.log("Error converting text message to Markdown: " + e);
        html = "<div class='text'>" + text + "</div>";
      }
    }
    if (html && !text && !this.state.messageDisplayHTML) {
      text = toMarkdown(html);
    }
    if (text) {
      rich = text.replace(urls, '<a href="$1" target="_blank">$1</a>', 'gim');
      rich = rich.replace(/^>>>>>[^>]?.*$/gim, '<span class="quote5">$&</span>');
      rich = rich.replace(/^>>>>[^>]?.*$/gim, '<span class="quote4">$&</span>');
      rich = rich.replace(/^>>>[^>]?.*$/gim, '<span class="quote3">$&</span>');
      rich = rich.replace(/^>>[^>]?.*$/gim, '<span class="quote2">$&</span>');
      rich = rich.replace(/^>[^>]?.*$/gim, '<span class="quote1">$&</span>', 'gim');
    }
    return {
      id: message.get('id'),
      attachments: message.get('attachments'),
      flags: message.get('flags') || [],
      from: message.get('from'),
      to: message.get('to'),
      cc: message.get('cc'),
      fullHeaders: fullHeaders,
      text: text,
      rich: rich,
      html: html,
      date: MessageUtils.formatDate(message.get('createdAt'))
    };
  },
  componentWillMount: function() {
    return this._markRead(this.props.message);
  },
  componentWillReceiveProps: function(props) {
    var state;
    state = {
      active: props.active,
      composing: false
    };
    if (props.message.get('id') !== this.props.message.get('id')) {
      this._markRead(this.props.message);
      state.messageDisplayHTML = props.settings.get('messageDisplayHTML');
      state.messageDisplayImages = props.settings.get('messageDisplayImages');
    }
    return this.setState(state);
  },
  _markRead: function(message) {
    var flags;
    if (this._currentMessageId === message.get('id')) {
      return;
    }
    this._currentMessageId = message.get('id');
    flags = message.get('flags').slice();
    if (flags.indexOf(MessageFlags.SEEN) === -1) {
      flags.push(MessageFlags.SEEN);
      return MessageActionCreator.updateFlag(message, flags);
    }
  },
  prepareHTML: function(prepared) {
    var doc, hideImage, html, image, images, link, messageDisplayHTML, parser, _i, _j, _len, _len1, _ref2;
    messageDisplayHTML = true;
    parser = new DOMParser();
    html = "<html><head>\n    <link rel=\"stylesheet\" href=\"./mail_stylesheet.css\" />\n    <style>body { visibility: hidden; }</style>\n</head><body>" + prepared.html + "</body></html>";
    doc = parser.parseFromString(html, "text/html");
    images = [];
    if (!doc) {
      doc = document.implementation.createHTMLDocument("");
      doc.documentElement.innerHTML = html;
    }
    if (!doc) {
      console.log("Unable to parse HTML content of message");
      messageDisplayHTML = false;
    }
    if (doc && !this.state.messageDisplayImages) {
      hideImage = function(image) {
        image.dataset.src = image.getAttribute('src');
        return image.removeAttribute('src');
      };
      images = doc.querySelectorAll('IMG[src]');
      for (_i = 0, _len = images.length; _i < _len; _i++) {
        image = images[_i];
        hideImage(image);
      }
    }
    _ref2 = doc.querySelectorAll('a[href]');
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      link = _ref2[_j];
      link.target = '_blank';
    }
    if (doc != null) {
      this._htmlContent = doc.documentElement.innerHTML;
    } else {
      this._htmlContent = prepared.html;
    }
    return {
      messageDisplayHTML: messageDisplayHTML,
      images: images
    };
  },
  render: function() {
    var classes, images, imagesWarning, message, messageDisplayHTML, prepared, _ref2;
    message = this.props.message;
    prepared = this._prepareMessage();
    if (this.state.messageDisplayHTML && prepared.html) {
      _ref2 = this.prepareHTML(prepared), messageDisplayHTML = _ref2.messageDisplayHTML, images = _ref2.images;
      imagesWarning = images.length > 0 && !this.state.messageDisplayImages;
    } else {
      messageDisplayHTML = false;
      imagesWarning = false;
    }
    classes = classer({
      message: true,
      active: this.state.active
    });
    if (this.state.active) {
      return li({
        className: classes,
        key: this.props.key,
        'data-id': message.get('id')
      }, this.renderHeaders(prepared), div({
        className: 'full-headers'
      }, pre(null, prepared.fullHeaders.join("\n"))), this.renderToolbox(message.get('id'), prepared), this.renderCompose(), MessageContent({
        message: message,
        messageDisplayHTML: messageDisplayHTML,
        html: this._htmlContent,
        text: prepared.text,
        rich: prepared.rich,
        imagesWarning: imagesWarning,
        composing: this.state.composing,
        displayImages: this.displayImages,
        displayHTML: this.displayHTML
      }), this.renderAttachments(prepared.attachments.toJS()), div({
        className: 'clearfix'
      }));
    } else {
      return li({
        className: classes,
        key: this.props.key,
        'data-id': message.get('id')
      }, this.renderHeaders(prepared));
    }
  },
  getParticipants: function(prepared) {
    var from, to;
    from = prepared.from;
    to = prepared.to.concat(prepared.cc);
    return span(null, Participants({
      participants: from,
      onAdd: this.addAddress
    }), span(null, ', '), Participants({
      participants: to,
      onAdd: this.addAddress
    }));
  },
  renderHeaders: function(prepared) {
    var avatar, classes, flags, hasAttachments, leftClass, _base;
    hasAttachments = prepared.attachments.length;
    leftClass = hasAttachments ? 'col-md-8' : 'col-md-12';
    flags = prepared.flags;
    avatar = MessageUtils.getAvatar(this.props.message);
    classes = classer({
      'header': true,
      'row': true,
      'full': this.state.headers,
      'compact': !this.state.headers,
      'has-attachments': hasAttachments,
      'is-fav': flags.indexOf(MessageFlags.FLAGGED) !== -1
    });
    if (this.state.headers) {
      return div({
        className: classes,
        onClick: this.toggleActive
      }, div({
        className: leftClass
      }, avatar ? img({
        className: 'sender-avatar',
        src: avatar
      }) : i({
        className: 'sender-avatar fa fa-user'
      }), div({
        className: 'participants col-md-9'
      }, p({
        className: 'sender'
      }, this.renderAddress('from'), i({
        className: 'toggle-headers fa fa-toggle-up',
        onClick: this.toggleHeaders
      })), p({
        className: 'receivers'
      }, span(null, t("mail receivers")), this.renderAddress('to')), (typeof (_base = this.props.message.get('cc')) === "function" ? _base(length > 0) : void 0) ? p({
        className: 'receivers'
      }, span(null, t("mail receivers cc")), this.renderAddress('cc')) : void 0, hasAttachments ? span({
        className: 'hour'
      }, prepared.date) : void 0), !hasAttachments ? span({
        className: 'hour'
      }, prepared.date) : void 0), hasAttachments ? div({
        className: 'col-md-4'
      }, FilePicker({
        editable: false,
        value: prepared.attachments
      })) : void 0);
    } else {
      return div({
        className: classes,
        onClick: this.toggleActive
      }, avatar ? img({
        className: 'sender-avatar',
        src: avatar
      }) : i({
        className: 'sender-avatar fa fa-user'
      }), span({
        className: 'participants'
      }, this.getParticipants(prepared)), this.state.active ? i({
        className: 'toggle-headers fa fa-toggle-down',
        onClick: this.toggleHeaders
      }) : void 0, span({
        className: 'hour'
      }, prepared.date), span({
        className: "flags"
      }, i({
        className: 'attach fa fa-paperclip'
      }), i({
        className: 'fav fa fa-star'
      })));
    }
  },
  renderAddress: function(field) {
    var addresses;
    addresses = this.props.message.get(field);
    if (addresses == null) {
      return;
    }
    return Participants({
      participants: addresses,
      onAdd: this.addAddress
    });
  },
  renderCompose: function() {
    if (this.state.composing) {
      return Compose({
        inReplyTo: this.props.message,
        accounts: this.props.accounts,
        settings: this.props.settings,
        selectedAccount: this.props.selectedAccount,
        action: this.state.composeAction,
        layout: 'second',
        callback: (function(_this) {
          return function(error) {
            if (error == null) {
              return _this.setState({
                composing: false
              });
            }
          };
        })(this),
        onCancel: (function(_this) {
          return function() {
            return _this.setState({
              composing: false
            });
          };
        })(this)
      });
    }
  },
  renderToolbox: function(id, prepared) {
    var conversationID, displayNext, displayPrev, getParams, isFlagged, isSeen, next, nextUrl, params, prev, prevUrl;
    if (this.state.composing) {
      return;
    }
    isFlagged = prepared.flags.indexOf(FlagsConstants.FLAGGED) === -1;
    isSeen = prepared.flags.indexOf(FlagsConstants.SEEN) === -1;
    conversationID = this.props.message.get('conversationID');
    getParams = (function(_this) {
      return function(id) {
        if (conversationID && _this.props.settings.get('displayConversation')) {
          return {
            action: 'conversation',
            id: id
          };
        } else {
          return {
            action: 'message',
            id: id
          };
        }
      };
    })(this);
    if (this.props.prevID != null) {
      params = getParams(this.props.prevID);
      prev = {
        direction: 'second',
        action: params.action,
        parameters: params.id
      };
      prevUrl = this.buildUrl(prev);
      displayPrev = (function(_this) {
        return function() {
          return _this.redirect(prev);
        };
      })(this);
    }
    if (this.props.nextID != null) {
      params = getParams(this.props.nextID);
      next = {
        direction: 'second',
        action: params.action,
        parameters: params.id
      };
      nextUrl = this.buildUrl(next);
      displayNext = (function(_this) {
        return function() {
          return _this.redirect(next);
        };
      })(this);
    }
    return div({
      className: 'messageToolbox row'
    }, div({
      className: 'btn-toolbar',
      role: 'toolbar'
    }, div({
      className: 'btn-group btn-group-sm btn-group-justified'
    }, prevUrl != null ? div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default prev',
      type: 'button',
      onClick: displayPrev
    }, a({
      href: prevUrl
    }, span({
      className: 'fa fa-long-arrow-left'
    })))) : void 0, div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default reply',
      type: 'button',
      onClick: this.onReply
    }, span({
      className: 'fa fa-reply'
    }), span({
      className: 'tool-long'
    }, t('mail action reply')))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default reply-all',
      type: 'button',
      onClick: this.onReplyAll
    }, span({
      className: 'fa fa-reply-all'
    }), span({
      className: 'tool-long'
    }, t('mail action reply all')))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default forward',
      type: 'button',
      onClick: this.onForward
    }, span({
      className: 'fa fa-mail-forward'
    }), span({
      className: 'tool-long'
    }, t('mail action forward')))), div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default trash',
      type: 'button',
      onClick: this.onDelete
    }, span({
      className: 'fa fa-trash-o'
    }), span({
      className: 'tool-long'
    }, t('mail action delete')))), ToolboxMove({
      mailboxes: this.props.mailboxes,
      onMove: this.onMove,
      direction: 'right'
    }), ToolboxActions({
      mailboxes: this.props.mailboxes,
      isSeen: isSeen,
      isFlagged: isFlagged,
      messageID: id,
      onMark: this.onMark,
      onConversation: this.onConversation,
      onHeaders: this.onHeaders,
      direction: 'right'
    }), nextUrl != null ? div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default',
      type: 'button',
      onClick: displayNext
    }, a({
      href: nextUrl
    }, span({
      className: 'fa fa-long-arrow-right'
    })))) : void 0)));
  },
  renderAttachments: function(attachments) {
    var files;
    files = attachments.filter(function(file) {
      return MessageUtils.getAttachmentType(file.contentType) === 'image';
    });
    if (files.length === 0) {
      return;
    }
    return div({
      className: 'att-previews'
    }, h4(null, t('message preview title')), files.map(function(file) {
      return AttachmentPreview({
        file: file,
        key: file.checksum
      });
    }));
  },
  toggleHeaders: function(e) {
    var state;
    e.preventDefault();
    e.stopPropagation();
    state = {
      headers: !this.state.headers
    };
    if (this.props.inConversation && !this.state.active) {
      state.active = true;
    }
    return this.setState(state);
  },
  toggleActive: function(e) {
    if (this.props.inConversation) {
      e.preventDefault();
      e.stopPropagation();
      if (this.state.active) {
        return this.setState({
          active: false,
          headers: false
        });
      } else {
        return this.setState({
          active: true,
          headers: false
        });
      }
    }
  },
  displayNextMessage: function(next) {
    if (next == null) {
      if (this.props.nextID != null) {
        next = this.props.nextID;
      } else {
        next = this.props.prevID;
      }
    }
    if (next != null) {
      return this.redirect({
        direction: 'second',
        action: 'message',
        parameters: next
      });
    } else {
      return this.redirect({
        direction: 'first',
        action: 'account.mailbox.messages',
        parameters: {
          accountID: this.props.message.get('accountID'),
          mailboxID: this.props.selectedMailboxID
        },
        fullWidth: true
      });
    }
  },
  onReply: function(args) {
    return this.setState({
      composing: true,
      composeAction: ComposeActions.REPLY
    });
  },
  onReplyAll: function(args) {
    return this.setState({
      composing: true,
      composeAction: ComposeActions.REPLY_ALL
    });
  },
  onForward: function(args) {
    return this.setState({
      composing: true,
      composeAction: ComposeActions.FORWARD
    });
  },
  onDelete: function(args) {
    var message, next;
    message = this.props.message;
    if (this.props.nextID != null) {
      next = this.props.nextID;
    } else {
      next = this.props.prevID;
    }
    if ((!this.props.settings.get('messageConfirmDelete')) || window.confirm(t('mail confirm delete', {
      subject: message.get('subject')
    }))) {
      this.displayNextMessage(next);
      return MessageActionCreator["delete"](message, function(error) {
        if (error != null) {
          return alertError("" + (t("message action delete ko")) + " " + error);
        }
      });
    }
  },
  onCopy: function(args) {
    return LayoutActionCreator.alertWarning(t("app unimplemented"));
  },
  onMove: function(args) {
    var conversationID, newbox, next, oldbox;
    newbox = args.target.dataset.value;
    if (this.props.nextID != null) {
      next = this.props.nextID;
    } else {
      next = this.props.prevID;
    }
    if (args.target.dataset.conversation != null) {
      conversationID = this.props.message.get('conversationID');
      return ConversationActionCreator.move(conversationID, newbox, (function(_this) {
        return function(error) {
          if (error != null) {
            return alertError("" + (t("conversation move ko")) + " " + error);
          } else {
            alertSuccess(t("conversation move ok"));
            return _this.displayNextMessage(next);
          }
        };
      })(this));
    } else {
      oldbox = this.props.selectedMailboxID;
      return MessageActionCreator.move(this.props.message, oldbox, newbox, (function(_this) {
        return function(error) {
          if (error != null) {
            return alertError("" + (t("message action move ko")) + " " + error);
          } else {
            alertSuccess(t("message action move ok"));
            return _this.displayNextMessage(next);
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
        return alertError("" + (t("message action mark ko")) + " " + error);
      } else {
        return alertSuccess(t("message action mark ok"));
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
            return alertError("" + (t("conversation delete ko")) + " " + error);
          } else {
            return alertSuccess(t("conversation delete ok"));
          }
        });
      case 'seen':
        return ConversationActionCreator.seen(id, function(error) {
          if (error != null) {
            return alertError("" + (t("conversation seen ko")) + " " + error);
          } else {
            return alertSuccess(t("conversation seen ok"));
          }
        });
      case 'unseen':
        return ConversationActionCreator.unseen(id, function(error) {
          if (error != null) {
            return alertError("" + (t("conversation unseen ko")) + " " + error);
          } else {
            return alertSuccess(t("conversation unseen ok"));
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
  addAddress: function(address) {
    return ContactActionCreator.createContact(address);
  },
  displayImages: function(event) {
    event.preventDefault();
    return this.setState({
      messageDisplayImages: true
    });
  },
  displayHTML: function(value) {
    if (value == null) {
      value = true;
    }
    return this.setState({
      messageDisplayHTML: value
    });
  }
});

MessageContent = React.createClass({
  displayName: 'MessageContent',
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var displayHTML;
    displayHTML = (function(_this) {
      return function() {
        return _this.props.displayHTML(true);
      };
    })(this);
    if (this.props.messageDisplayHTML && this.props.html) {
      return div({
        className: 'row'
      }, this.props.imagesWarning ? div({
        className: "imagesWarning content-action",
        ref: "imagesWarning"
      }, span(null, t('message images warning')), button({
        className: 'btn btn-default',
        type: "button",
        ref: 'imagesDisplay',
        onClick: this.props.displayImages
      }, t('message images display'))) : void 0, iframe({
        'data-message-id': this.props.message.get('id'),
        className: 'content',
        ref: 'content',
        allowTransparency: true,
        sandbox: 'allow-same-origin allow-popups',
        frameBorder: 0
      }));
    } else {
      return div({
        className: 'row'
      }, div({
        className: 'preview'
      }, p({
        dangerouslySetInnerHTML: {
          __html: this.props.rich
        }
      })));
    }
  },
  _initFrame: function(type) {
    var doc, frame, loadContent, panel, step, _ref2;
    panel = document.querySelector("#panels > .panel:nth-of-type(2)");
    if ((panel != null) && !this.props.composing) {
      panel.scrollTop = 0;
    }
    if (this.props.messageDisplayHTML && this.refs.content) {
      frame = this.refs.content.getDOMNode();
      doc = frame.contentDocument || ((_ref2 = frame.contentWindow) != null ? _ref2.document : void 0);
      step = 0;
      loadContent = (function(_this) {
        return function(e) {
          var updateHeight, _ref3;
          step = 0;
          doc = frame.contentDocument || ((_ref3 = frame.contentWindow) != null ? _ref3.document : void 0);
          if (doc != null) {
            doc.documentElement.innerHTML = _this.props.html;
            updateHeight = function(e) {
              var height, _ref4;
              height = doc.body.getBoundingClientRect().height;
              frame.style.height = "" + (height + 60) + "px";
              step++;
              if (step > 10) {
                doc.body.removeEventListener('load', loadContent);
                return (_ref4 = frame.contentWindow) != null ? _ref4.removeEventListener('resize') : void 0;
              }
            };
            frame.style.height = "32px";
            updateHeight();
            setTimeout(updateHeight, 1000);
            return doc.body.onload = updateHeight;
          } else {
            return _this.props.displayHTML(false);
          }
        };
      })(this);
      if (type === 'mount' && doc.readyState !== 'complete') {
        return frame.addEventListener('load', loadContent);
      } else {
        return loadContent();
      }
    }
  },
  componentDidMount: function() {
    return this._initFrame('mount');
  },
  componentDidUpdate: function() {
    return this._initFrame('update');
  }
});

AttachmentPreview = React.createClass({
  displayName: 'AttachmentPreview',
  getInitialState: function() {
    return {
      displayed: false
    };
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var toggleDisplay;
    toggleDisplay = (function(_this) {
      return function() {
        return _this.setState({
          displayed: !_this.state.displayed
        });
      };
    })(this);
    return span({
      className: 'att-preview',
      key: this.props.key
    }, this.state.displayed ? img({
      onClick: toggleDisplay,
      src: this.props.file.url
    }) : button({
      className: 'btn btn-default btn-lg',
      onClick: toggleDisplay
    }, this.props.file.fileName));
  }
});
});

;require.register("components/modal", function(exports, require, module) {
var Modal;

module.exports = Modal = React.createClass({
  displayName: 'Modal',
  render: function() {
    return React.DOM.div({
      className: "modal fade in",
      role: "dialog",
      style: {
        display: 'block'
      }
    }, React.DOM.div({
      className: "modal-dialog"
    }, React.DOM.div({
      className: "modal-content"
    }, this.props.title != null ? React.DOM.div({
      className: "modal-header"
    }, this.props.closeLabel != null ? React.DOM.button({
      type: 'button',
      className: 'close',
      onClick: this.props.closeModal
    }, React.DOM.i({
      className: 'fa fa-times'
    })) : void 0, React.DOM.h4({
      className: "modal-title"
    }, this.props.title)) : void 0, React.DOM.div({
      className: "modal-body"
    }, this.props.subtitle != null ? React.DOM.span(null, this.props.subtitle) : void 0, this.props.content), this.props.closeLabel != null ? React.DOM.div({
      className: "modal-footer"
    }, React.DOM.button({
      type: 'button',
      className: 'btn',
      onClick: this.props.closeModal
    }, this.props.closeLabel)) : void 0)));
  }
});
});

;require.register("components/participant", function(exports, require, module) {
var ContactStore, MessageUtils, Participant, Participants, a, i, span, _ref;

_ref = React.DOM, span = _ref.span, a = _ref.a, i = _ref.i;

MessageUtils = require('../utils/message_utils');

ContactStore = require('../stores/contact_store');

Participant = React.createClass({
  displayName: 'Participant',
  render: function() {
    if (this.props.address == null) {
      return span(null);
    } else {
      return span({
        className: 'address-item',
        'data-toggle': "tooltip",
        ref: 'participant',
        title: this.props.address.address,
        key: this.props.key
      }, MessageUtils.displayAddress(this.props.address));
    }
  },
  tooltip: function() {
    var addTooltip, delay, node, onAdd, removeTooltip;
    if (this.refs.participant != null) {
      node = this.refs.participant.getDOMNode();
      delay = null;
      onAdd = (function(_this) {
        return function(e) {
          e.preventDefault();
          e.stopPropagation();
          return _this.props.onAdd(_this.props.address);
        };
      })(this);
      addTooltip = (function(_this) {
        return function(e) {
          var add, addNode, avatar, contact, image, mask, options, rect, template, tooltipNode;
          if (node.dataset.tooltip) {
            return;
          }
          node.dataset.tooltip = true;
          contact = ContactStore.getByAddress(_this.props.address.address);
          avatar = contact != null ? contact.get('avatar') : void 0;
          if (avatar != null) {
            image = "<img class='avatar' src=" + avatar + ">";
          } else {
            image = "<i class='avatar fa fa-user' />";
          }
          if (contact != null) {
            image = "<a href=\"#apps/contacts/contact/" + (contact.get('id')) + "\" target=\"blank\">\n    " + image + "\n</a>";
          }
          if (_this.props.onAdd != null) {
            add = "<a class='address-add'>\n    <i class='fa fa-plus' />\n</a>";
          } else {
            add = '';
          }
          template = "<div class=\"tooltip\" role=\"tooltip\">\n    <div class=\"tooltip-arrow\"></div>\n    <div>\n        " + image + "\n        " + _this.props.address.address + "\n        " + add + "\n    </div>\n</div>'";
          options = {
            template: template,
            trigger: 'manual',
            container: "[data-reactid='" + node.dataset.reactid + "']"
          };
          jQuery(node).tooltip(options).tooltip('show');
          tooltipNode = jQuery(node).data('bs.tooltip').tip()[0];
          if (parseInt(tooltipNode.style.left, 10) < 0) {
            tooltipNode.style.left = 0;
          }
          rect = tooltipNode.getBoundingClientRect();
          mask = document.createElement('div');
          mask.classList.add('tooltip-mask');
          mask.style.top = (rect.top - 2) + 'px';
          mask.style.left = (rect.left - 2) + 'px';
          mask.style.height = (rect.height + 16) + 'px';
          mask.style.width = (rect.width + 4) + 'px';
          document.body.appendChild(mask);
          mask.addEventListener('mouseout', function(e) {
            var _ref1, _ref2;
            if (!((rect.left < (_ref1 = e.pageX) && _ref1 < rect.right)) || !((rect.top < (_ref2 = e.pageY) && _ref2 < rect.bottom))) {
              mask.parentNode.removeChild(mask);
              return removeTooltip();
            }
          });
          if (_this.props.onAdd != null) {
            addNode = tooltipNode.querySelector('.address-add');
            addNode.addEventListener('mouseover', function() {});
            return addNode.addEventListener('click', onAdd);
          }
        };
      })(this);
      removeTooltip = function() {
        var addNode;
        addNode = node.querySelector('.address-add');
        if (addNode != null) {
          addNode.removeEventListener('click', onAdd);
        }
        delete node.dataset.tooltip;
        return jQuery(node).tooltip('destroy');
      };
      node.addEventListener('mouseover', function() {
        return delay = setTimeout(function() {
          return addTooltip();
        }, 1000);
      });
      return node.addEventListener('mouseout', function() {
        return clearTimeout(delay);
      });
    }
  },
  componentDidMount: function() {
    return this.tooltip();
  },
  componentDidUpdate: function() {
    return this.tooltip();
  }
});

Participants = React.createClass({
  displayName: 'Participants',
  render: function() {
    var address, key;
    return span({
      className: 'address-list'
    }, (function() {
      var _i, _len, _ref1, _results;
      if (this.props.participants) {
        _ref1 = this.props.participants;
        _results = [];
        for (key = _i = 0, _len = _ref1.length; _i < _len; key = ++_i) {
          address = _ref1[key];
          _results.push(span({
            key: key,
            className: null
          }, Participant({
            key: key,
            address: address,
            onAdd: this.props.onAdd
          }), key < (this.props.participants.length - 1) ? span(null, ', ') : void 0));
        }
        return _results;
      }
    }).call(this));
  }
});

module.exports = Participants;
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
var ApiUtils, PluginUtils, SettingsActionCreator, a, button, classer, div, fieldset, form, h3, input, label, legend, li, ul, _ref,
  __hasProp = {}.hasOwnProperty;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button, fieldset = _ref.fieldset, legend = _ref.legend, ul = _ref.ul, li = _ref.li, a = _ref.a;

classer = React.addons.classSet;

SettingsActionCreator = require('../actions/settings_action_creator');

PluginUtils = require('../utils/plugin_utils');

ApiUtils = require('../utils/api_utils');

module.exports = React.createClass({
  displayName: 'Settings',
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
    }, t("settings label listStyle")), div({
      className: 'col-sm-3'
    }, div({
      className: "dropdown"
    }, button({
      className: "btn btn-default dropdown-toggle",
      type: "button",
      "data-toggle": "dropdown"
    }, t("settings label listStyle " + (this.state.settings.listStyle || 'default'))), ul({
      className: "dropdown-menu",
      role: "menu"
    }, li({
      role: "presentation",
      'data-target': 'listStyle',
      'data-style': 'default',
      onClick: this.handleChange
    }, a({
      role: "menuitem"
    }, t("settings label listStyle default"))), li({
      role: "presentation",
      'data-target': 'listStyle',
      'data-style': 'compact',
      onClick: this.handleChange
    }, a({
      role: "menuitem"
    }, t("settings label listStyle compact")))))))), this._renderOption('displayConversation'), this._renderOption('composeInHTML'), this._renderOption('composeOnTop'), this._renderOption('messageDisplayHTML'), this._renderOption('messageDisplayImages'), this._renderOption('messageConfirmDelete'), this._renderOption('displayPreview'), fieldset(null, legend(null, t('settings plugins')), (function() {
      var _ref1, _results;
      _ref1 = this.state.settings.plugins;
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
          className: classLabel,
          htmlFor: 'settings-plugin-' + pluginName
        }, pluginConf.name), div({
          className: 'col-sm-3'
        }, input({
          id: 'settings-plugin-' + pluginName,
          checked: pluginConf.active,
          onChange: this.handleChange,
          'data-target': 'plugin',
          'data-plugin': pluginName,
          type: 'checkbox'
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
      type: 'checkbox'
    }))));
  },
  handleChange: function(event) {
    var name, pluginConf, pluginName, settings, target, _ref1;
    event.preventDefault();
    target = event.currentTarget;
    switch (target.dataset.target) {
      case 'composeInHTML':
      case 'composeOnTop':
      case 'displayConversation':
      case 'messageDisplayHTML':
      case 'messageDisplayImages':
      case 'messageConfirmDelete':
      case 'displayPreview':
        settings = this.state.settings;
        settings[target.dataset.target] = target.checked;
        this.setState({
          settings: settings
        });
        return SettingsActionCreator.edit(settings);
      case 'listStyle':
        settings = this.state.settings;
        settings.listStyle = target.dataset.style;
        this.setState({
          settings: settings
        });
        return SettingsActionCreator.edit(settings);
      case 'plugin':
        name = target.dataset.plugin;
        settings = this.state.settings;
        if (target.checked) {
          PluginUtils.activate(name);
        } else {
          PluginUtils.deactivate(name);
        }
        _ref1 = settings.plugins;
        for (pluginName in _ref1) {
          if (!__hasProp.call(_ref1, pluginName)) continue;
          pluginConf = _ref1[pluginName];
          settings.plugins[pluginName].active = window.plugins[pluginName].active;
        }
        this.setState({
          settings: settings
        });
        return SettingsActionCreator.edit(settings);
    }
  },
  getInitialState: function(forceDefault) {
    var settings;
    settings = this.props.settings.toObject();
    return {
      settings: this.props.settings.toObject()
    };
  }
});
});

;require.register("components/thin_progress", function(exports, require, module) {
var ThinProgress, div;

div = React.DOM.div;

module.exports = ThinProgress = React.createClass({
  displayName: 'ThinProgress',
  render: function() {
    var percent;
    percent = 100 * (this.props.done / this.props.total) + '%';
    return div({
      className: "progress progress-thin"
    }, div({
      className: 'progress-bar',
      style: {
        width: percent
      }
    }));
  }
});
});

;require.register("components/toast", function(exports, require, module) {
var ActionTypes, AppDispatcher, CSSTransitionGroup, LayoutActionCreator, LayoutStore, Modal, SocketUtils, StoreWatchMixin, Toast, ToastContainer, a, button, classer, div, h4, i, pre, span, strong, _ref;

_ref = React.DOM, a = _ref.a, h4 = _ref.h4, pre = _ref.pre, div = _ref.div, button = _ref.button, span = _ref.span, strong = _ref.strong, i = _ref.i;

SocketUtils = require('../utils/socketio_utils');

AppDispatcher = require('../app_dispatcher');

Modal = require('./modal');

StoreWatchMixin = require('../mixins/store_watch_mixin');

LayoutStore = require('../stores/layout_store');

LayoutActionCreator = require('../actions/layout_action_creator');

ActionTypes = require('../constants/app_constants').ActionTypes;

CSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

module.exports = Toast = React.createClass({
  displayName: 'Toast',
  getInitialState: function() {
    return {
      modalErrors: false
    };
  },
  closeModal: function() {
    return this.setState({
      modalErrors: false
    });
  },
  showModal: function(errors) {
    return this.setState({
      modalErrors: errors
    });
  },
  acknowledge: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RECEIVE_TASK_DELETE,
      value: this.props.toast.get('id')
    });
  },
  renderModal: function() {
    var closeLabel, closeModal, content, modalErrors, subtitle, title;
    title = t('modal please contribute');
    subtitle = t('modal please report');
    modalErrors = this.state.modalErrors;
    closeModal = this.closeModal;
    closeLabel = t('app alert close');
    content = React.DOM.pre({
      style: {
        "max-height": "300px",
        "word-wrap": "normal"
      }
    }, this.state.modalErrors.join("\n\n"));
    return Modal({
      title: title,
      subtitle: subtitle,
      content: content,
      closeModal: closeModal,
      closeLabel: closeLabel
    });
  },
  render: function() {
    var classes, hasErrors, percent, showModal, toast;
    toast = this.props.toast.toJS();
    hasErrors = (toast.errors != null) && toast.errors.length;
    classes = classer({
      toast: true,
      'alert-dismissible': toast.finished,
      'alert-info': !hasErrors,
      'alert-warning': hasErrors
    });
    if ((toast.done != null) && (toast.total != null)) {
      percent = parseInt(100 * toast.done / toast.total) + '%';
    }
    if (hasErrors) {
      showModal = this.showModal.bind(this, toast.errors);
    }
    return div({
      className: classes,
      role: "alert"
    }, this.state.modalErrors ? renderModal() : void 0, percent != null ? div({
      className: "progress"
    }, div({
      className: 'progress-bar',
      style: {
        width: percent
      }
    }), div({
      className: 'progress-bar-label start',
      style: {
        width: percent
      }
    }, "" + (t("task " + toast.code, toast)) + " : " + percent), div({
      className: 'progress-bar-label end'
    }, "" + (t("task " + toast.code, toast)) + " : " + percent)) : void 0, toast.message ? div({
      className: "message"
    }, toast.message) : void 0, toast.finished ? button({
      type: "button",
      className: "close",
      onClick: this.acknowledge
    }, span({
      'aria-hidden': "true"
    }, "×"), span({
      className: "sr-only"
    }, t("app alert close"))) : void 0, toast.actions != null ? div({
      className: 'toast-actions'
    }, toast.actions.map(function(action, id) {
      return button({
        className: "btn btn-default btn-xs",
        type: "button",
        key: id,
        onClick: action.onClick
      }, action.label);
    })) : void 0);
  }
});

module.exports.Container = ToastContainer = React.createClass({
  displayName: 'ToastContainer',
  mixins: [StoreWatchMixin([LayoutStore])],
  getStateFromStores: function() {
    return {
      toasts: LayoutStore.getToasts(),
      hidden: !LayoutStore.isShown()
    };
  },
  render: function() {
    var classes, toasts;
    toasts = this.state.toasts.map(function(toast, id) {
      return Toast({
        toast: toast,
        key: id
      });
    }).toVector().toJS();
    classes = classer({
      'toasts-container': true,
      'action-hidden': this.state.hidden,
      'has-toasts': toasts.length !== 0
    });
    return div({
      className: classes
    }, CSSTransitionGroup({
      transitionName: "toast"
    }, toasts), div({
      className: 'alert alert-success toast toasts-actions'
    }, span({
      className: "toast-action hide-action",
      title: t('toast hide'),
      onClick: this.toggleHidden
    }, i({
      className: 'fa fa-eye-slash'
    })), span({
      className: "toast-action show-action",
      title: t('toast show'),
      onClick: this.toggleHidden
    }, i({
      className: 'fa fa-eye'
    })), span({
      className: "toast-action close-action",
      title: t('toast close all'),
      onClick: this.closeAll
    }, i({
      className: 'fa fa-times'
    }))));
  },
  toggleHidden: function() {
    if (this.state.hidden) {
      return LayoutActionCreator.toastsShow();
    } else {
      return LayoutActionCreator.toastsHide();
    }
  },
  closeAll: function() {
    return LayoutActionCreator.clearToasts();
  }
});
});

;require.register("components/toolbox_actions", function(exports, require, module) {
var FlagsConstants, MessageFlags, ToolboxActions, a, button, div, i, li, p, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, a = _ref.a, button = _ref.button;

_ref1 = require('../constants/app_constants'), MessageFlags = _ref1.MessageFlags, FlagsConstants = _ref1.FlagsConstants;

module.exports = ToolboxActions = React.createClass({
  displayName: 'ToolboxActions',
  render: function() {
    var direction;
    direction = this.props.direction === 'right' ? 'right' : 'left';
    return div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default dropdown-toggle more',
      type: 'button',
      'data-toggle': 'dropdown'
    }, t('mail action more', span({
      className: 'caret'
    }))), ul({
      className: 'dropdown-menu dropdown-menu-' + direction,
      role: 'menu'
    }, li({
      role: 'presentation'
    }, t('mail action mark')), (this.props.isSeen == null) || this.props.isSeen === true ? li(null, a({
      role: 'menuitem',
      onClick: this.props.onMark,
      'data-value': FlagsConstants.SEEN
    }, t('mail mark read'))) : void 0, (this.props.isSeen == null) || this.props.isSeen === false ? li(null, a({
      role: 'menuitem',
      onClick: this.props.onMark,
      'data-value': FlagsConstants.UNSEEN
    }, t('mail mark unread'))) : void 0, (this.props.isFlagged == null) || this.props.isFlagged === true ? li(null, a({
      role: 'menuitem',
      onClick: this.props.onMark,
      'data-value': FlagsConstants.FLAGGED
    }, t('mail mark fav'))) : void 0, (this.props.isFlagged == null) || this.props.isFlagged === false ? li(null, a({
      role: 'menuitem',
      onClick: this.props.onMark,
      'data-value': FlagsConstants.NOFLAG
    }, t('mail mark nofav'))) : void 0, li({
      role: 'presentation',
      className: 'divider'
    }), this.props.messageID != null ? li({
      role: 'presentation'
    }, a({
      onClick: this.props.onHeaders,
      'data-message-id': this.props.messageID
    }, t('mail action headers'))) : void 0, li({
      role: 'presentation'
    }, a({
      onClick: this.props.onConversation,
      'data-action': 'delete'
    }, t('mail action conversation delete'))), li({
      role: 'presentation'
    }, a({
      onClick: this.props.onConversation,
      'data-action': 'seen'
    }, t('mail action conversation seen'))), li({
      role: 'presentation'
    }, a({
      onClick: this.props.onConversation,
      'data-action': 'unseen'
    }, t('mail action conversation unseen'))), li({
      role: 'presentation',
      className: 'divider'
    }), li({
      role: 'presentation'
    }, t('mail action conversation move')), this.props.mailboxes.map((function(_this) {
      return function(mailbox, key) {
        return _this.renderMailboxes(mailbox, key, true);
      };
    })(this)).toJS(), li({
      role: 'presentation',
      className: 'divider'
    })));
  },
  renderMailboxes: function(mailbox, key, conversation) {
    var j, pusher, _i, _ref2;
    if (mailbox.get('id') === this.props.selectedMailboxID) {
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
  }
});
});

;require.register("components/toolbox_move", function(exports, require, module) {
var ConversationActionCreator, LayoutActionCreator, ToolboxMove, a, button, div, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, a = _ref.a, button = _ref.button;

LayoutActionCreator = require('../actions/layout_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

module.exports = ToolboxMove = React.createClass({
  displayName: 'ToolboxMove',
  render: function() {
    var direction;
    direction = this.props.direction === 'right' ? 'right' : 'left';
    return div({
      className: 'btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default dropdown-toggle move',
      type: 'button',
      'data-toggle': 'dropdown'
    }, t('mail action move', span({
      className: 'caret'
    }))), ul({
      className: 'dropdown-menu dropdown-menu-' + direction,
      role: 'menu'
    }, this.props.mailboxes.map((function(_this) {
      return function(mailbox, key) {
        return _this.renderMailboxes(mailbox, key);
      };
    })(this)).toJS()));
  },
  renderMailboxes: function(mailbox, key, conversation) {
    var j, pusher, _i, _ref1;
    if (mailbox.get('id') === this.props.selectedMailboxID) {
      return;
    }
    pusher = "";
    for (j = _i = 1, _ref1 = mailbox.get('depth'); _i <= _ref1; j = _i += 1) {
      pusher += "--";
    }
    return li({
      role: 'presentation',
      key: key
    }, a({
      role: 'menuitem',
      onClick: this.props.onMove,
      'data-value': key,
      'data-conversation': conversation
    }, "" + pusher + (mailbox.get('label'))));
  }
});
});

;require.register("components/topbar", function(exports, require, module) {
var LayoutActionCreator, MailboxList, ReactCSSTransitionGroup, RouterMixin, SearchForm, Topbar, a, body, button, div, form, i, input, p, span, strong, _ref;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span, a = _ref.a, button = _ref.button, strong = _ref.strong;

MailboxList = require('./mailbox-list');

SearchForm = require('./search-form');

RouterMixin = require('../mixins/router_mixin');

LayoutActionCreator = require('../actions/layout_action_creator');

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup;

module.exports = Topbar = React.createClass({
  displayName: 'Topbar',
  mixins: [RouterMixin],
  refresh: function(event) {
    event.preventDefault();
    return LayoutActionCreator.refreshMessages();
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var configMailboxUrl, getUrl, layout, mailboxes, responsiveBackUrl, searchQuery, selectedAccount, selectedMailboxID, _ref1;
    _ref1 = this.props, layout = _ref1.layout, selectedAccount = _ref1.selectedAccount, selectedMailboxID = _ref1.selectedMailboxID, mailboxes = _ref1.mailboxes, searchQuery = _ref1.searchQuery;
    responsiveBackUrl = this.buildUrl({
      firstPanel: layout.firstPanel,
      fullWidth: true
    });
    getUrl = (function(_this) {
      return function(mailbox) {
        return _this.buildUrl({
          direction: 'first',
          action: 'account.mailbox.messages',
          parameters: [selectedAccount != null ? selectedAccount.get('id') : void 0, mailbox.get('id')]
        });
      };
    })(this);
    if (selectedAccount && layout.firstPanel.action !== 'account.new') {
      if (layout.firstPanel.action === 'account.config') {
        configMailboxUrl = this.buildUrl({
          direction: 'first',
          action: 'account.mailbox.messages',
          parameters: selectedAccount.get('id'),
          fullWidth: true
        });
      } else {
        configMailboxUrl = this.buildUrl({
          direction: 'first',
          action: 'account.config',
          parameters: [selectedAccount.get('id'), 'account'],
          fullWidth: true
        });
      }
    }
    return div({
      id: 'quick-actions',
      className: 'row'
    }, layout.secondPanel ? a({
      href: responsiveBackUrl,
      className: 'responsive-handler hidden-md hidden-lg'
    }, i({
      className: 'fa fa-chevron-left hidden-md hidden-lg pull-left'
    }), t("app back")) : void 0, layout.firstPanel.action === 'account.mailbox.messages' || layout.firstPanel.action === 'account.mailbox.messages' ? div({
      className: 'col-md-6 hidden-xs hidden-sm pull-left'
    }, form({
      className: 'form-inline col-md-12'
    }, MailboxList({
      getUrl: getUrl,
      mailboxes: mailboxes,
      selectedMailbox: selectedMailboxID
    }), SearchForm({
      query: searchQuery
    }))) : void 0, layout.firstPanel.action === 'account.mailbox.messages' || layout.firstPanel.action === 'account.mailbox.messages' ? div({
      id: 'contextual-actions',
      className: 'col-md-6 hidden-xs hidden-sm pull-left text-right'
    }, a({
      onClick: this.refresh,
      className: 'btn btn-cozy-contrast'
    }, i({
      className: 'fa fa-refresh'
    })), ReactCSSTransitionGroup({
      transitionName: 'fade'
    }, configMailboxUrl ? a({
      href: configMailboxUrl,
      className: 'btn btn-cozy mailbox-config'
    }, i({
      className: 'fa fa-cog'
    })) : void 0)) : void 0);
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
    'MAILBOX_ADD': 'MAILBOX_ADD',
    'MAILBOX_CREATE': 'MAILBOX_CREATE',
    'MAILBOX_UPDATE': 'MAILBOX_UPDATE',
    'MAILBOX_DELETE': 'MAILBOX_DELETE',
    'RECEIVE_RAW_MESSAGE': 'RECEIVE_RAW_MESSAGE',
    'RECEIVE_RAW_MESSAGES': 'RECEIVE_RAW_MESSAGES',
    'MESSAGE_SEND': 'MESSAGE_SEND',
    'MESSAGE_DELETE': 'MESSAGE_DELETE',
    'MESSAGE_BOXES': 'MESSAGE_BOXES',
    'MESSAGE_FLAG': 'MESSAGE_FLAG',
    'MESSAGE_ACTION': 'MESSAGE_ACTION',
    'MESSAGE_CURRENT': 'MESSAGE_CURRENT',
    'RECEIVE_MESSAGE_DELETE': 'RECEIVE_MESSAGE_DELETE',
    'SET_FETCHING': 'SET_FETCHING',
    'SET_SEARCH_QUERY': 'SET_SEARCH_QUERY',
    'RECEIVE_RAW_SEARCH_RESULTS': 'RECEIVE_RAW_SEARCH_RESULTS',
    'CLEAR_SEARCH_RESULTS': 'CLEAR_SEARCH_RESULTS',
    'SET_CONTACT_QUERY': 'SET_CONTACT_QUERY',
    'RECEIVE_RAW_CONTACT_RESULTS': 'RECEIVE_RAW_CONTACT_RESULTS',
    'CLEAR_CONTACT_RESULTS': 'CLEAR_CONTACT_RESULTS',
    'CONTACT_LOCAL_SEARCH': 'CONTACT_LOCAL_SEARCH',
    'SET_DISPOSITION': 'SET_DISPOSITION',
    'DISPLAY_ALERT': 'DISPLAY_ALERT',
    'HIDE_ALERT': 'HIDE_ALERT',
    'REFRESH': 'REFRESH',
    'RECEIVE_RAW_MAILBOXES': 'RECEIVE_RAW_MAILBOXES',
    'SETTINGS_UPDATED': 'SETTINGS_UPDATED',
    'RECEIVE_TASK_UPDATE': 'RECEIVE_TASK_UPDATE',
    'RECEIVE_TASK_DELETE': 'RECEIVE_TASK_DELETE',
    'CLEAR_TOASTS': 'CLEAR_TOASTS',
    'RECEIVE_REFRESH_UPDATE': 'RECEIVE_REFRESH_UPDATE',
    'RECEIVE_REFRESH_STATUS': 'RECEIVE_REFRESH_STATUS',
    'RECEIVE_REFRESH_DELETE': 'RECEIVE_REFRESH_DELETE',
    'LIST_FILTER': 'LIST_FILTER',
    'LIST_QUICK_FILTER': 'LIST_QUICK_FILTER',
    'LIST_SORT': 'LIST_SORT',
    'TOASTS_SHOW': 'TOASTS_SHOW',
    'TOASTS_HIDE': 'TOASTS_HIDE'
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
  },
  MessageFilter: {
    'ALL': 'all',
    'FLAGGED': 'flagged',
    'UNSEEN': 'unseen'
  },
  MailboxFlags: {
    'DRAFT': '\\Drafts',
    'SENT': '\\Sent',
    'TRASH': '\\Trash',
    'ALL': '\\All',
    'SPAM': '\\Junk',
    'FLAGGED': '\\Flagged'
  },
  FlagsConstants: {
    SEEN: '\\Seen',
    UNSEEN: 'Unseen',
    FLAGGED: '\\Flagged',
    NOFLAG: 'Noflag'
  },
  Dispositions: {
    HORIZONTAL: 'horizontal',
    VERTICAL: 'vertical',
    THREE: 'three'
  },
  SpecialBoxIcons: {
    inboxMailbox: 'fa-inbox',
    draftMailbox: 'fa-edit',
    sentMailbox: 'fa-share-square-o',
    trashMailbox: 'fa-trash-o',
    junkMailbox: 'fa-exclamation',
    allMailbox: 'fa-archive'
  }
};
});

;require.register("initialize", function(exports, require, module) {
window.onerror = function(msg, url, line, col, error) {
  var data, exception, xhr;
  console.error(msg, url, line, col, error);
  exception = (error != null ? error.toString() : void 0) || msg;
  if (exception !== window.lastError) {
    data = {
      data: {
        type: 'error',
        error: {
          msg: msg,
          full: error.toString(),
          stack: error.stack
        },
        url: url,
        line: line,
        col: col,
        href: window.location.href
      }
    };
    xhr = new XMLHttpRequest();
    xhr.open('POST', 'activity', true);
    xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    xhr.send(JSON.stringify(data));
    return window.lastError = exception;
  }
};

window.onload = function() {
  var AccountStore, Application, ContactStore, LayoutStore, MessageStore, PluginUtils, Router, SearchStore, SettingsActionCreator, SettingsStore, application, data, e, exception, locale, xhr;
  try {
    window.__DEV__ = window.location.hostname === 'localhost';
    window.cozyMails = require('./utils/api_utils');
    if (window.settings == null) {
      window.settings = {};
    }
    locale = window.locale || window.navigator.language || "en";
    window.cozyMails.setLocale(locale);
    PluginUtils = require("./utils/plugin_utils");
    if (window.settings.plugins == null) {
      window.settings.plugins = {};
    }
    PluginUtils.merge(window.settings.plugins);
    PluginUtils.init();
    window.cozyMails.setSetting('plugins', window.settings.plugins);
    AccountStore = require('./stores/account_store');
    ContactStore = require('./stores/contact_store');
    LayoutStore = require('./stores/layout_store');
    MessageStore = require('./stores/message_store');
    SearchStore = require('./stores/search_store');
    SettingsStore = require('./stores/settings_store');
    Router = require('./router');
    this.router = new Router();
    window.router = this.router;
    Application = require('./components/application');
    application = Application({
      router: this.router
    });
    React.renderComponent(application, document.body);
    SettingsActionCreator = require('./actions/settings_action_creator/');
    Backbone.history.start();
    return require('./utils/socketio_utils');
  } catch (_error) {
    e = _error;
    console.error(e);
    exception = e.toString();
    if (exception !== window.lastError) {
      data = {
        data: {
          type: 'error',
          exception: exception
        }
      };
      xhr = new XMLHttpRequest();
      xhr.open('POST', 'activity', true);
      xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
      xhr.send(JSON.stringify(data));
      return window.lastError = exception;
    }
  }
};
});

;require.register("libs/flux/dispatcher/Dispatcher", function(exports, require, module) {

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

;require.register("libs/flux/store/Store", function(exports, require, module) {
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
        if (name === 'default') {
          name = LayoutActionCreator.getDefaultRoute();
          args = [null];
        }
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
  "app cancel": "Cancel",
  "app menu": "Menu",
  "app search": "Search…",
  "app alert close": "Close",
  "app unimplemented": "Not implemented yet",
  "app error": "Argh, I'm unable to perform this action, please try again",
  "compose": "Compose new email",
  "compose default": 'Hello, how are you doing today?',
  "compose from": "From",
  "compose to": "To",
  "compose to help": "Recipients list",
  "compose cc": "Cc",
  "compose cc help": "Copy list",
  "compose bcc": "Bcc",
  "compose bcc help": "Hidden copy list",
  "compose subject": "Subject",
  "compose content": "Content",
  "compose subject help": "Message subject",
  "compose reply prefix": "Re: ",
  "compose reply separator": "\n\nOn %{date}, %{sender} wrote \n",
  "compose forward prefix": "Fwd: ",
  "compose forward separator": "\n\nOn %{date}, %{sender} wrote \n",
  "compose action draft": "Save draft",
  "compose action send": "Send",
  "compose action delete": "Delete draft",
  "compose action sending": "Sending",
  "compose toggle cc": "Cc",
  "compose toggle bcc": "Bcc",
  "compose error no dest": "You can not send a message to nobody",
  "compose error no subject": "Please set a subject",
  "compose confirm keep draft": "Message not sent, keep the draft?",
  "compose draft deleted": "Draft deleted",
  "menu compose": "Compose",
  "menu account new": "New Mailbox",
  "menu settings": "Parameters",
  "menu mailbox total": "%{smart_count} message|||| %{smart_count} messages",
  "menu mailbox unread": ", %{smart_count} unread message ||||, %{smart_count} unread messages ",
  "menu mailbox new": " and %{smart_count} new message|||| and %{smart_count} new messages ",
  "menu favorites on": "Favorites",
  "menu favorites off": "All",
  "list empty": "No email in this box.",
  "no flagged message": "No Important email in this box.",
  "no unseen message": "All emails have been read in this box",
  "no filter message": "No email for this filter.",
  "list fetching": "Loading…",
  "list search empty": "No result found for the query \"%{query}\".",
  "list count": "%{smart_count} message in this box |||| %{smart_count} messages in this box",
  "list search count": "%{smart_count} result found. |||| %{smart_count} results found.",
  "list filter": "Filter",
  "list filter all": "All",
  "list filter unseen": "Unseen",
  "list filter unseen title": "Show only unread messages",
  "list filter flagged": "Important",
  "list filter flagged title": "Show only Important messages",
  "list sort": "Sort",
  "list sort date": "Date",
  "list sort subject": "Subject",
  "list option compact": "Compact",
  "list next page": "More messages",
  "list end": "This is the end of the road",
  "list mass no message": "No message selected",
  "list delete confirm": "Do you really want to delete %{nb} messages?",
  "mail receivers": "To: ",
  "mail receivers cc": "Cc: ",
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
  "mail mark unread": "Unread",
  "mail confirm delete": "Do you really want to delete message “%{subject}”?",
  "mail action conversation delete": "Delete conversation",
  "mail action conversation move": "Move conversation",
  "mail action conversation seen": "Mark conversation as read",
  "mail action conversation unseen": "Mark conversation as unread",
  "mail conversation length": "%{smart_count} message dans cette conversation. ||||\n%{smart_count} messages dans cette conversation.",
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
  "account port": "Port",
  "account SSL": "Use SSL",
  "account TLS": "Use STARTTLS",
  "account remove": "Remove this account",
  "account remove confirm": "Do you really want to remove this account?",
  "account draft mailbox": "Draft box",
  "account sent mailbox": "Sent box",
  "account trash mailbox": "Trash",
  "account mailboxes": "Folders",
  "account newmailbox label": "New Folder",
  "account newmailbox placeholder": "Name",
  "account newmailbox parent": "Parent:",
  "account confirm delbox": "Do you really want to delete this box and everything in it?",
  "account tab account": "Account",
  "account tab mailboxes": "Folders",
  "account errors": "Some data are missing or invalid",
  "account type": "Account type",
  "account updated": "Account updated",
  "account creation ok": "Yeah! The account has been successfully created. Now select the mailboxes you want to see in the menu",
  "account refreshed": "Account refreshed",
  "account identifiers": "Identification",
  "account actions": "Actions",
  "account danger zone": "Danger Zone",
  "mailbox create ok": "Folder created",
  "mailbox create ko": "Error creating folder",
  "mailbox update ok": "Folder updated",
  "mailbox update ko": "Error updating folder",
  "mailbox delete ok": "Folder deleted",
  "mailbox delete ko": "Error deleting folder",
  "mailbox title edit": "Rename folder",
  "mailbox title delete": "Delete folder",
  "mailbox title edit save": "Save",
  "mailbox title edit cancel": "Cancel",
  "mailbox title add": "Add new folder",
  "mailbox title add cancel": "Cancel",
  "mailbox title favorite": "Folder is displayed",
  "mailbox title not favorite": "Folder not displayed",
  "mailbox title total": "Total",
  "mailbox title unread": "Unread",
  "mailbox title new": "New",
  "config error auth": "Wrong connection parameters",
  "config error imapPort": "Wrong IMAP port",
  "config error imapServer": "Wrong IMAP server",
  "config error imapTLS": "Wrong IMAP TLS",
  "config error smtpPort": "Wrong SMTP Port",
  "config error smtpServer": "Wrong SMTP Server",
  "config error nomailboxes": "No folder in this account, please create one",
  "message action sent ok": "Message sent",
  "message action sent ko": "Error sending message: ",
  "message action draft ok": "Message saved",
  "message action draft ko": "Error saving message: ",
  "message action delete ok": "Message “%{subject}” deleted",
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
  "message undelete": "Undo message deletion",
  "message undelete ok": "Message undeleted",
  "message undelete error": "Undo not available",
  "message preview title": "View attachments",
  "settings title": "Settings",
  "settings button save": "Save",
  "settings plugins": "Add ons",
  "settings label composeInHTML": "Rich message editor",
  "settings label composeOnTop": "Reply on top of message",
  "settings label displayConversation": "Display conversations",
  "settings label displayPreview": "Display message preview",
  "settings label messageDisplayHTML": "Display message in HTML",
  "settings label messageDisplayImages": "Display images inside messages",
  "settings label messageConfirmDelete": "Confirm before deleting a message",
  "settings label listStyle": "Message list style",
  "settings label listStyle default": "Normal",
  "settings label listStyle compact": "Compact",
  "settings lang": "Language",
  "settings lang en": "English",
  "settings lang fr": "Français",
  "settings save error": "Unable to save settings, please try again",
  "picker drop here": "Drop files here",
  "mailbox pick one": "Pick one",
  "mailbox pick null": "No box for this",
  "task account-fetch": 'Refreshing %{account}',
  "task box-fetch": 'Refreshing %{box}',
  "task apply-diff-fetch": 'Fetching mails from %{box} of %{account}',
  "task apply-diff-remove": 'Deleting mails from %{box} of %{account}',
  "task recover-uidvalidity": 'Analysing',
  "there were errors": '%{smart_count} error. |||| %{smart_count} errors.',
  "modal please report": "Please transmit this information to cozy.",
  "modal please contribute": "Please contribute",
  "validate must not be empty": "Mandatory field",
  "toast hide": "Hide alerts",
  "toast show": "Display alerts",
  "toast close all": "Close all alerts",
  "contact form": "Select contacts",
  "contact form placeholder": "contact name",
  "contact create success": "%{contact} has been added to your contacts",
  "contact create error": "Error adding to your contacts : {error}",
  "gmail security tile": "About Gmail security",
  "gmail security body": "Gmail considers connection using username and password not safe.\nPlease click on the following link, make sure\nyou are connected with your %{login} account and enable access for\nless secure apps.",
  "gmail security link": "Enable access for less secure apps."
};
});

;require.register("locales/fr", function(exports, require, module) {
module.exports = {
  "app loading": "Chargement…",
  "app back": "Retour",
  "app cancel": "Annuler",
  "app menu": "Menu",
  "app search": "Rechercher…",
  "app alert close": "Fermer",
  "app unimplemented": "Non implémenté",
  "app error": "Oups, une erreur est survenue, veuillez réessayer",
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
  "compose content": "Contenu",
  "compose subject help": "Objet du message",
  "compose reply prefix": "Re: ",
  "compose reply separator": "\n\nLe %{date}, %{sender} a écrit \n",
  "compose forward prefix": "Fwd: ",
  "compose forward separator": "\n\nLe %{date}, %{sender} a écrit \n",
  "compose action draft": "Enregistrer le brouillon",
  "compose action send": "Envoyer",
  "compose action sending": "Envoi…",
  "compose action delete": "Supprimer le brouillon",
  "compose toggle cc": "Copie à",
  "compose toggle bcc": "Copie cachée à",
  "compose error no dest": "Vous n'avez pas saisi de destinataires",
  "compose error no subject": "Vous n'avez pas saisi de sujet",
  "compose confirm keep draft": "Vous n'avez pas envoyé le message, voulez-vous conserver le brouillon ?",
  "compose draft deleted": "Brouillon supprimé",
  "menu compose": "Nouveau",
  "menu account new": "Ajouter un compte",
  "menu settings": "Paramètres",
  "menu mailbox total": "%{smart_count} message |||| %{smart_count} messages ",
  "menu mailbox unread": " dont %{smart_count} non lu |||| dont %{smart_count} non lus ",
  "menu mailbox new": " et %{smart_count} nouveaux |||| et %{smart_count} nouveaux ",
  "menu favorites on": "Favorites",
  "menu favorites off": "Toutes",
  "list empty": "Pas d'email dans cette boîte..",
  "no flagged message": "Pas d'email important dans cette boîte.",
  "no unseen message": "Pas d'email non-lu dans cette boîte.",
  "no filter message": "Pas d'email pour ce filtre.",
  "list fetching": "Chargement…",
  "list search empty": "Aucun résultat trouvé pour la requête \"%{query}\".",
  "list count": "%{smart_count} message dans cette boite |||| %{smart_count} messages dans cette boite",
  "list search count": "%{smart_count} résultat trouvé. |||| %{smart_count} résultats trouvés.",
  "list filter": "Filtrer",
  "list filter all": "Tous",
  "list filter unseen": "Non lus",
  "list filter unseen title": "N'afficher que les messages non lus",
  "list filter flagged": "Importants",
  "list filter flagged title": "N'afficher que les messages importants",
  "list sort": "Trier",
  "list sort date": "Date",
  "list sort subject": "Sujet",
  "list option compact": "Compact",
  "list next page": "Davantage de messages",
  "list end": "FIN",
  "list mass no message": "Aucun message sélectionné",
  "list delete confirm": "Voulez-vous vraiment supprimer %{nb} messages ?",
  "mail receivers": "À ",
  "mail receivers cc": "Copie ",
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
  "mail confirm delete": "Voulez-vous vraiment supprimer le message « %{subject} » ?",
  "mail action conversation delete": "Supprimer la conversation",
  "mail action conversation move": "Déplacer la conversation",
  "mail action conversation seen": "Marquer la conversation comme lue",
  "mail action conversation unseen": "Marquer la conversation comme non lue",
  "mail conversation length": "%{smart_count} message dans cette conversation. ||||\n%{smart_count} messages dans cette conversation.",
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
  "account port": "Port",
  "account SSL": "Utiliser SSL",
  "account TLS": "Utiliser STARTTLS",
  "account remove": "Supprimer ce compte",
  "account remove confirm": "Voulez-vous vraiment supprimer ce compte ?",
  "account draft mailbox": "Enregistrer les brouillons dans",
  "account sent mailbox": "Enregistrer les messages envoyés dans",
  "account trash mailbox": "Corbeille",
  "account mailboxes": "Dossiers",
  "account newmailbox label": "Nouveaux dossier",
  "account newmailbox placeholder": "Nom",
  "account newmailbox parent": "Créer sous",
  "account confirm delbox": "Voulez-vous vraiment supprimer ce dossier et tout son contenu ?",
  "account tab account": "Compte",
  "account tab mailboxes": "Dossiers",
  "account errors": "Certaines informations manquent ou sont incorrectes",
  "account type": "Type de compte",
  "account updated": "Modification enregistrée",
  "account refreshed": "Actualisé",
  "account creation ok": "Youpi, le compte a été créé ! Sélectionnez à présent les dossiers que vous voulez voir apparaitre dans le menu",
  "account identifiers": "Identification",
  "account danger zone": "Zone dangereuse",
  "account actions": "Actions",
  "mailbox create ok": "Dossier créé",
  "mailbox create ko": "Erreur de création du dossier",
  "mailbox update ok": "Dossier mis à jour",
  "mailbox update ko": "Erreur de mise à jour",
  "mailbox delete ok": "Dossier supprimé",
  "mailbox delete ko": "Erreur de suppression du dossier",
  "mailbox title edit": "Renommer le dossier",
  "mailbox title delete": "Supprimer le dossier",
  "mailbox title edit save": "Enregistrer",
  "mailbox title edit cancel": "Annuler",
  "mailbox title add": "Créer un dossier",
  "mailbox title add cancel": "Annuler",
  "mailbox title favorite": "Dossier affiché",
  "mailbox title not favorite": "Dossier non affiché",
  "mailbox title total": "Total",
  "mailbox title unread": "Non lus",
  "mailbox title new": "Nouveaux",
  "config error auth": "Impossible de se connecter avec ces paramètres",
  "config error imapPort": "Port du serveur IMAP invalide",
  "config error imapServer": "Serveur IMAP invalide",
  "config error imapTLS": "Erreur IMAP TLS",
  "config error smtpPort": "Port du serveur d'envoi invalide",
  "config error smtpServer": "Serveur d'envoi invalide",
  "config error nomailboxes": "Ce compte n'a pas encore de dossier, commencez par en créer",
  "message action sent ok": "Message envoyé !",
  "message action sent ko": "Une erreur est survenue : ",
  "message action draft ok": "Message sauvegardé !",
  "message action draft ko": "Une erreur est survenue : ",
  "message action delete ok": "Message « %{subject} » supprimé",
  "message action delete ko": "Impossible de supprimer le message : ",
  "message action move ok": "Message déplacé",
  "message action move ko": "Le déplacement a échoué",
  "message action mark ok": "Le message a été mis à jour",
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
  "message undelete": "Annuler la suppression",
  "message undelete ok": "Message restauré",
  "message undelete error": "Impossible d'annuler l'action",
  "message preview title": "Voir les pièces-jointes",
  "settings title": "Paramètres",
  "settings button save": "Enregistrer",
  "settings plugins": "Modules complémentaires",
  "settings label composeInHTML": "Éditeur riche",
  "settings label composeOnTop": "Répondre au dessus du message",
  "settings label displayConversation": "Afficher les conversations",
  "settings label displayPreview": "Prévisualiser les messages",
  "settings label messageDisplayHTML": "Afficher les messages en HTML",
  "settings label messageDisplayImages": "Afficher les images",
  "settings label messageConfirmDelete": "Demander confirmation avant de supprimer un message",
  "settings label listStyle": "Affichage de la liste des messages",
  "settings label listStyle default": "Normal",
  "settings label listStyle compact": "Compact",
  "settings lang": "Langue",
  "settings lang en": "English",
  "settings lang fr": "Français",
  "settings save error": "Erreur d'enregistrement des paramètres, veuillez ré-essayer",
  "picker drop here": "Déposer les fichiers ici",
  "mailbox pick one": "Choisissez une boite",
  "mailbox pick null": "Pas de boite pour ça",
  "task account-fetch": 'Rafraichissement %{account}',
  "task box-fetch": 'Rafraichissement %{box}',
  "task apply-diff-fetch": 'Téléchargement des messages du dossier %{box} de %{account}',
  "task apply-diff-remove": 'Suppression des messages du dossier %{box} de %{account}',
  "task recover-uidvalidity": 'Analyse du compte',
  "there were errors": '%{smart_count} erreur. |||| %{smart_count} erreurs.',
  "modal please report": "Merci de bien vouloir transmettre ces informations à cozy.",
  "modal please contribute": "Merci de contribuer",
  "validate must not be empty": "Ce champ doit être renseigné",
  "toast hide": "Masquer les alertes",
  "toast show": "Afficher les alertes",
  "toast close all": "Fermer toutes les alertes",
  "contact form": "Sélectionnez des contacts",
  "contact form placeholder": "Nom",
  "contact create success": "%{contact} a été ajouté(e) à vos contacts",
  "contact create error": "L'ajout à votre carnet d'adresse a échoué : {error}",
  "gmail security tile": "Sécurité Gmail",
  "gmail security body": "Gmail considère les connection par nom d'utilisateur et mot de passe\nnon sécurisées. Veuillez cliquer sur le lien ci-dessous, assurez\nvous d'être connecté avec le compte %{login} et activer l'accès\npour les applications moins sécurisées.",
  "gmail security link": "Activer l'accès pour les applications moins sécurisées"
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
var AccountStore, MessageStore, PanelRouter, Router,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

PanelRouter = require('./libs/panel_router');

AccountStore = require('./stores/account_store');

MessageStore = require('./stores/message_store');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.patterns = {
    'account.config': {
      pattern: 'account/:accountID/config/:tab',
      fluxAction: 'showConfigAccount'
    },
    'account.new': {
      pattern: 'account/new',
      fluxAction: 'showCreateAccount'
    },
    'account.mailbox.messages.full': {
      pattern: 'account/:accountID/box/:mailboxID/sort/:sort/' + 'flag/:flag/before/:before/after/:after/' + 'page/:pageAfter',
      fluxAction: 'showMessageList'
    },
    'account.mailbox.messages': {
      pattern: 'account/:accountID/mailbox/:mailboxID',
      fluxAction: 'showMessageList'
    },
    'search': {
      pattern: 'search/:query/page/:page',
      fluxAction: 'showSearch'
    },
    'message': {
      pattern: 'message/:messageID',
      fluxAction: 'showMessage'
    },
    'conversation': {
      pattern: 'conversation/:messageID',
      fluxAction: 'showConversation'
    },
    'compose': {
      pattern: 'compose',
      fluxAction: 'showComposeNewMessage'
    },
    'edit': {
      pattern: 'edit/:messageID',
      fluxAction: 'showComposeMessage'
    },
    'settings': {
      pattern: 'settings',
      fluxAction: 'showSettings'
    },
    'default': {
      pattern: '',
      fluxAction: ''
    }
  };

  Router.prototype.routes = {
    '': 'default'
  };

  Router.prototype._getDefaultParameters = function(action) {
    var defaultAccount, defaultAccountID, defaultMailboxID, defaultParameters, _ref, _ref1;
    switch (action) {
      case 'account.mailbox.messages':
      case 'account.mailbox.messages.full':
        defaultAccountID = (_ref = AccountStore.getDefault()) != null ? _ref.get('id') : void 0;
        defaultMailboxID = AccountStore.getDefaultMailbox(defaultAccountID).get('id');
        defaultParameters = MessageStore.getParams();
        defaultParameters.accountID = defaultAccountID;
        defaultParameters.mailboxID = defaultMailboxID;
        defaultParameters.sort = '-';
        break;
      case 'account.config':
        defaultAccount = (_ref1 = AccountStore.getDefault()) != null ? _ref1.get('id') : void 0;
        defaultParameters = {
          accountID: defaultAccount,
          tab: 'account'
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
  var setMailbox, _accounts, _mailboxSort, _newAccountError, _newAccountWaiting, _refreshSelected, _selectedAccount, _selectedMailbox;

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

  _selectedMailbox = null;

  _newAccountWaiting = false;

  _newAccountError = null;

  _refreshSelected = function() {
    var selectedAccountID, selectedMailboxID, _ref;
    if (selectedAccountID = _selectedAccount != null ? _selectedAccount.get('id') : void 0) {
      _selectedAccount = _accounts.get(selectedAccountID);
      if (selectedMailboxID = _selectedMailbox != null ? _selectedMailbox.get('id') : void 0) {
        return _selectedMailbox = _selectedAccount != null ? (_ref = _selectedAccount.get('mailboxes')) != null ? _ref.get(selectedMailboxID) : void 0 : void 0;
      }
    }
  };

  setMailbox = function(accountID, boxID, boxData) {
    var account, mailboxes;
    account = _accounts.get(accountID);
    mailboxes = account.get('mailboxes');
    mailboxes = mailboxes.map(function(box) {
      if (box.get('id') === boxID) {
        boxData.weight = box.get('weight');
        return AccountTranslator.mailboxToImmutable(boxData);
      } else {
        return box;
      }
    }).toOrderedMap();
    account = account.set('mailboxes', mailboxes);
    _accounts = _accounts.set(accountID, account);
    return _refreshSelected();
  };

  _mailboxSort = function(mb1, mb2) {
    var w1, w2;
    w1 = mb1.get('weight');
    w2 = mb2.get('weight');
    if (w1 < w2) {
      return 1;
    } else if (w1 > w2) {
      return -1;
    } else {
      if (mb1.get('label' < mb2.get('label'))) {
        return 1;
      } else if (mb1.get('label' > mb2.get('label'))) {
        return 1;
      } else {
        return 0;
      }
    }
  };

  AccountStore.prototype._applyMailboxDiff = function(accountID, diff) {
    var account, mailboxes, updated;
    account = _accounts.get(accountID);
    mailboxes = account.get('mailboxes');
    updated = mailboxes.withMutations(function(map) {
      var box, boxid, deltas, _results;
      _results = [];
      for (boxid in diff) {
        deltas = diff[boxid];
        if (!(deltas.nbTotal + deltas.nbUnread)) {
          continue;
        }
        box = map.get(boxid);
        if (box != null) {
          box = box.merge({
            nbTotal: box.get('nbTotal') + deltas.nbTotal,
            nbUnread: box.get('nbUnread') + deltas.nbUnread
          });
          _results.push(map.set(boxid, box));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    });
    if (updated !== mailboxes) {
      account = account.set('mailboxes', updated);
      _accounts = _accounts.set(accountID, account);
      _refreshSelected();
      return this.emit('change');
    }
  };

  AccountStore.prototype._setCurrentAccount = function(account) {
    return _selectedAccount = account;
  };


  /*
      Defines here the action handlers.
   */

  AccountStore.prototype.__bindHandlers = function(handle) {
    var onUpdate;
    onUpdate = (function(_this) {
      return function(rawAccount) {
        var account;
        account = AccountTranslator.toImmutable(rawAccount);
        _accounts = _accounts.set(account.get('id'), account);
        _this._setCurrentAccount(account);
        _newAccountWaiting = false;
        _newAccountError = null;
        return _this.emit('change');
      };
    })(this);
    handle(ActionTypes.ADD_ACCOUNT, function(rawAccount) {
      return onUpdate(rawAccount);
    });
    handle(ActionTypes.SELECT_ACCOUNT, function(value) {
      var _ref;
      if (value.accountID != null) {
        this._setCurrentAccount(_accounts.get(value.accountID) || null);
      } else {
        this._setCurrentAccount(null);
      }
      if (value.mailboxID != null) {
        _selectedMailbox = (_selectedAccount != null ? (_ref = _selectedAccount.get('mailboxes')) != null ? _ref.get(value.mailboxID) : void 0 : void 0) || null;
      } else {
        _selectedMailbox = null;
      }
      return this.emit('change');
    });
    handle(ActionTypes.NEW_ACCOUNT_WAITING, function(payload) {
      _newAccountWaiting = payload;
      return this.emit('change');
    });
    handle(ActionTypes.NEW_ACCOUNT_ERROR, function(error) {
      _newAccountWaiting = false;
      _newAccountError = error;
      return this.emit('change');
    });
    handle(ActionTypes.EDIT_ACCOUNT, function(rawAccount) {
      return onUpdate(rawAccount);
    });
    handle(ActionTypes.MAILBOX_CREATE, function(rawAccount) {
      return onUpdate(rawAccount);
    });
    handle(ActionTypes.MAILBOX_UPDATE, function(rawAccount) {
      return onUpdate(rawAccount);
    });
    handle(ActionTypes.MAILBOX_DELETE, function(rawAccount) {
      return onUpdate(rawAccount);
    });
    handle(ActionTypes.REMOVE_ACCOUNT, function(accountID) {
      _accounts = _accounts["delete"](accountID);
      this._setCurrentAccount(this.getDefault());
      return this.emit('change');
    });
    return handle(ActionTypes.RECEIVE_MAILBOX_UPDATE, function(boxData) {
      setMailbox(boxData.accountID, boxData.id, boxData);
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

  AccountStore.prototype.getByLabel = function(label) {
    return _accounts.find(function(account) {
      return account.get('label') === label;
    });
  };

  AccountStore.prototype.getDefault = function() {
    return _accounts.first() || null;
  };

  AccountStore.prototype.getDefaultMailbox = function(accountID) {
    var account, defaultID, favorites, mailbox, mailboxes;
    account = _accounts.get(accountID) || this.getDefault();
    if (!account) {
      return null;
    }
    mailboxes = account.get('mailboxes');
    mailbox = mailboxes.filter(function(mailbox) {
      return mailbox.get('label').toLowerCase() === 'inbox';
    });
    if (mailbox.count() !== 0) {
      return mailbox.first();
    } else {
      favorites = account.get('favorites');
      defaultID = favorites != null ? favorites[0] : void 0;
      if (defaultID) {
        return mailboxes.get(defaultID);
      } else {
        return mailboxes.first();
      }
    }
  };

  AccountStore.prototype.getSelected = function() {
    return _selectedAccount;
  };

  AccountStore.prototype.getSelectedMailboxes = function(sorted) {
    var mailboxes, result;
    if (_selectedAccount == null) {
      return Immutable.OrderedMap.empty();
    }
    result = Immutable.OrderedMap();
    mailboxes = _selectedAccount.get('mailboxes');
    if (sorted) {
      mailboxes = mailboxes.sort(_mailboxSort);
    }
    mailboxes.forEach(function(data) {
      var mailbox;
      mailbox = Immutable.Map(data);
      result = result.set(mailbox.get('id'), mailbox);
      return true;
    });
    return result;
  };

  AccountStore.prototype.getSelectedMailbox = function(selectedID) {
    var mailboxes;
    mailboxes = this.getSelectedMailboxes();
    if (selectedID != null) {
      return mailboxes.get(selectedID);
    } else if (_selectedMailbox != null) {
      return _selectedMailbox;
    } else {
      return mailboxes.first();
    }
  };

  AccountStore.prototype.getSelectedFavorites = function(sorted) {
    var ids, mailboxes, mb;
    mailboxes = this.getSelectedMailboxes();
    ids = _selectedAccount != null ? _selectedAccount.get('favorites') : void 0;
    if (ids != null) {
      mb = mailboxes.filter(function(box, key) {
        return __indexOf.call(ids, key) >= 0;
      }).toOrderedMap();
    } else {
      mb = mailboxes.toOrderedMap();
    }
    if (sorted) {
      mb = mb.sort(_mailboxSort);
    }
    return mb;
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

;require.register("stores/contact_store", function(exports, require, module) {
var ActionTypes, ContactStore, Store,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/store');

ActionTypes = require('../constants/app_constants').ActionTypes;

ContactStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _contacts, _import, _query, _results;

  __extends(ContactStore, _super);

  function ContactStore() {
    return ContactStore.__super__.constructor.apply(this, arguments);
  }

  _query = "";

  _contacts = Immutable.OrderedMap.empty();

  _results = Immutable.OrderedMap.empty();

  _import = function(rawResults) {
    var convert;
    _results = Immutable.OrderedMap.empty();
    if (rawResults != null) {
      if (!Array.isArray(rawResults)) {
        rawResults = [rawResults];
      }
      convert = function(map) {
        return rawResults.forEach(function(rawResult) {
          var addresses;
          addresses = [];
          rawResult.datapoints.forEach(function(point) {
            if (point.name === 'email') {
              addresses.push(point.value);
            }
            if (point.name === 'avatar') {
              return rawResult.avatar = point.value;
            }
          });
          delete rawResult.docType;
          return addresses.forEach(function(address) {
            var contact;
            rawResult.address = address;
            contact = Immutable.Map(rawResult);
            return map.set(address, contact);
          });
        });
      };
      _results = _results.withMutations(convert);
      return _contacts = _contacts.withMutations(convert);
    }
  };

  _import(window.contacts);


  /*
      Defines here the action handlers.
   */

  ContactStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.RECEIVE_RAW_CONTACT_RESULTS, (function(_this) {
      return function(rawResults) {
        _import(rawResults);
        return _this.emit('change');
      };
    })(this));
    return handle(ActionTypes.CONTACT_LOCAL_SEARCH, (function(_this) {
      return function(query) {
        var re;
        query = query.toLowerCase();
        re = new RegExp(query, 'i');
        _results = _contacts.filter(function(contact) {
          var full, obj;
          obj = contact.toObject();
          full = '';
          ['address', 'fn'].forEach(function(key) {
            if (typeof obj[key] === 'string') {
              return full += obj[key];
            }
          });
          return re.test(full);
        }).toOrderedMap();
        return _this.emit('change');
      };
    })(this));
  };


  /*
      Public API
   */

  ContactStore.prototype.getResults = function() {
    return _results;
  };

  ContactStore.prototype.getQuery = function() {
    return _query;
  };

  ContactStore.prototype.getByAddress = function(address) {
    return _contacts.get(address);
  };

  ContactStore.prototype.getAvatar = function(address) {
    var _ref;
    return (_ref = _contacts.get(address)) != null ? _ref.get('avatar') : void 0;
  };

  return ContactStore;

})(Store);

module.exports = new ContactStore();
});

;require.register("stores/layout_store", function(exports, require, module) {
var ActionTypes, Dispositions, LayoutStore, Store, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/store');

_ref = require('../constants/app_constants'), ActionTypes = _ref.ActionTypes, Dispositions = _ref.Dispositions;

LayoutStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _alert, _disposition, _shown, _tasks;

  __extends(LayoutStore, _super);

  function LayoutStore() {
    return LayoutStore.__super__.constructor.apply(this, arguments);
  }

  _disposition = {
    type: Dispositions.VERTICAL,
    height: 5,
    width: 6
  };

  _alert = {
    level: null,
    message: null
  };

  _tasks = Immutable.OrderedMap();

  _shown = true;


  /*
      Defines here the action handlers.
   */

  LayoutStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.SET_DISPOSITION, function(disposition) {
      _disposition.type = disposition.type;
      if (_disposition.type === Dispositions.VERTICAL) {
        _disposition.height = 5;
        _disposition.width = disposition.value || _disposition.width;
      } else if (_disposition.type === Dispositions.HORIZONTAL) {
        _disposition.height = disposition.value || _disposition.height;
        _disposition.width = 6;
      }
      return this.emit('change');
    });
    handle(ActionTypes.DISPLAY_ALERT, function(value) {
      _alert.level = value.level;
      _alert.message = value.message;
      return this.emit('change');
    });
    handle(ActionTypes.HIDE_ALERT, function(value) {
      _alert.level = null;
      _alert.message = null;
      return this.emit('change');
    });
    handle(ActionTypes.SELECT_ACCOUNT, function(value) {
      _alert.level = null;
      _alert.message = null;
      return this.emit('change');
    });
    handle(ActionTypes.REFRESH, function() {
      return this.emit('change');
    });
    handle(ActionTypes.CLEAR_TOASTS, function() {
      _tasks = Immutable.OrderedMap();
      return this.emit('change');
    });
    handle(ActionTypes.RECEIVE_TASK_UPDATE, (function(_this) {
      return function(task) {
        var id, remove;
        task = Immutable.Map(task);
        id = task.get('id');
        _tasks = _tasks.set(id, task);
        if (task.get('autoclose')) {
          remove = function() {
            _tasks = _tasks.remove(id);
            return _this.emit('change');
          };
          setTimeout(remove, 3000);
        }
        return _this.emit('change');
      };
    })(this));
    handle(ActionTypes.RECEIVE_TASK_DELETE, function(taskid) {
      _tasks = _tasks.remove(taskid);
      return this.emit('change');
    });
    handle(ActionTypes.TOASTS_SHOW, function() {
      _shown = true;
      return this.emit('change');
    });
    return handle(ActionTypes.TOASTS_HIDE, function() {
      _shown = false;
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  LayoutStore.prototype.getDisposition = function() {
    return _disposition;
  };

  LayoutStore.prototype.getAlert = function() {
    return _alert;
  };

  LayoutStore.prototype.getToasts = function() {
    return _tasks;
  };

  LayoutStore.prototype.isShown = function() {
    return _shown;
  };

  return LayoutStore;

})(Store);

module.exports = new LayoutStore();
});

;require.register("stores/message_store", function(exports, require, module) {
var AccountStore, ActionTypes, AppDispatcher, ContactStore, MessageFilter, MessageFlags, MessageStore, SocketUtils, Store, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Store = require('../libs/flux/store/store');

ContactStore = require('./contact_store');

AppDispatcher = require('../app_dispatcher');

AccountStore = require('./account_store');

SocketUtils = require('../utils/socketio_utils');

_ref = require('../constants/app_constants'), ActionTypes = _ref.ActionTypes, MessageFlags = _ref.MessageFlags, MessageFilter = _ref.MessageFilter;

MessageStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var computeMailboxDiff, onReceiveRawMessage, reverseDateSort, __getSortFunction, __sortFunction, _conversationLengths, _conversationMemoize, _conversationMemoizeId, _currentID, _currentMessages, _fetching, _filter, _messages, _params, _prevAction, _sortField, _sortOrder;

  __extends(MessageStore, _super);

  function MessageStore() {
    return MessageStore.__super__.constructor.apply(this, arguments);
  }

  _sortField = 'date';

  _sortOrder = 1;

  __getSortFunction = function(criteria, order) {
    var sortFunction;
    return sortFunction = function(message1, message2) {
      var val1, val2;
      if (typeof message1.get === 'function') {
        val1 = message1.get(criteria);
        val2 = message2.get(criteria);
      } else {
        val1 = message1[criteria];
        val2 = message2[criteria];
      }
      if (val1 > val2) {
        return -1 * order;
      } else if (val1 < val2) {
        return 1 * order;
      } else {
        return 0;
      }
    };
  };

  __sortFunction = __getSortFunction('date', 1);

  reverseDateSort = __getSortFunction('date', -1);

  _messages = Immutable.Sequence().sort(__sortFunction).mapKeys(function(_, message) {
    return message.id;
  }).map(function(message) {
    return Immutable.fromJS(message);
  }).toOrderedMap();

  _filter = '-';

  _params = {
    sort: '-date'
  };

  _fetching = false;

  _currentMessages = Immutable.Sequence();

  _conversationLengths = Immutable.Map();

  _conversationMemoize = null;

  _conversationMemoizeId = null;

  _currentID = null;

  _prevAction = null;

  computeMailboxDiff = function(oldmsg, newmsg) {
    var added, changed, deltaUnread, isRead, newboxes, oldboxes, out, removed, stayed, wasRead, _ref1, _ref2;
    if (!oldmsg) {
      return {};
    }
    changed = false;
    wasRead = (_ref1 = MessageFlags.SEEN, __indexOf.call(oldmsg.get('flags'), _ref1) >= 0);
    isRead = (_ref2 = MessageFlags.SEEN, __indexOf.call(newmsg.get('flags'), _ref2) >= 0);
    oldboxes = Object.keys(oldmsg.get('mailboxIDs'));
    newboxes = Object.keys(newmsg.get('mailboxIDs'));
    out = {};
    added = _.difference(newboxes, oldboxes);
    added.forEach(function(boxid) {
      changed = true;
      return out[boxid] = {
        nbTotal: +1,
        nbUnread: isRead ? +1 : 0
      };
    });
    removed = _.difference(oldboxes, newboxes);
    removed.forEach(function(boxid) {
      changed = true;
      return out[boxid] = {
        nbTotal: -1,
        nbUnread: wasRead ? -1 : 0
      };
    });
    stayed = _.intersection(oldboxes, newboxes);
    deltaUnread = wasRead && !isRead ? +1 : !wasRead && isRead ? -1 : 0;
    stayed.forEach(function(boxid) {
      if (deltaUnread !== 0) {
        changed = true;
      }
      return out[boxid] = {
        nbTotal: 0,
        nbUnread: deltaUnread
      };
    });
    if (changed) {
      return out;
    } else {
      return false;
    }
  };

  onReceiveRawMessage = function(message) {
    var diff, oldmsg;
    if (message.attachments == null) {
      message.attachments = [];
    }
    if (message.date == null) {
      message.date = new Date().toISOString();
    }
    if (message.createdAt == null) {
      message.createdAt = message.date;
    }
    message.hasAttachments = message.attachments.length > 0;
    message.attachments = message.attachments.map(function(file) {
      return Immutable.Map(file);
    });
    message.attachments = Immutable.Vector.from(message.attachments);
    if (message.flags == null) {
      message.flags = [];
    }
    delete message.docType;
    message = Immutable.Map(message);
    oldmsg = _messages.get(message.get('id'));
    _messages = _messages.set(message.get('id'), message);
    if (diff = computeMailboxDiff(oldmsg, message)) {
      return AccountStore._applyMailboxDiff(message.get('accountID'), diff);
    }
  };


  /*
      Defines here the action handlers.
   */

  MessageStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.RECEIVE_RAW_MESSAGE, function(message) {
      onReceiveRawMessage(message);
      return this.emit('change');
    });
    handle(ActionTypes.RECEIVE_RAW_MESSAGES, function(messages) {
      var lengths, message, next, url, _i, _len;
      if (messages.mailboxID) {
        SocketUtils.changeRealtimeScope(messages.mailboxID);
      }
      _params = {};
      if (messages.links != null) {
        if (messages.links.next != null) {
          next = decodeURIComponent(messages.links.next);
          url = 'http://localhost' + next;
          url.split('?')[1].split('&').forEach(function(p) {
            var key, value, _ref1;
            _ref1 = p.split('='), key = _ref1[0], value = _ref1[1];
            if (value === '') {
              value = '-';
            }
            return _params[key] = value;
          });
        }
        SocketUtils.changeRealtimeScope(messages.mailboxID, _params.pageAfter);
      }
      if (lengths = messages.conversationLengths) {
        _conversationLengths = _conversationLengths.merge(lengths);
      }
      if ((messages.count != null) && (messages.mailboxID != null)) {
        messages = messages.messages.sort(__sortFunction);
      }
      for (_i = 0, _len = messages.length; _i < _len; _i++) {
        message = messages[_i];
        onReceiveRawMessage(message);
      }
      return this.emit('change');
    });
    handle(ActionTypes.REMOVE_ACCOUNT, function(accountID) {
      AppDispatcher.waitFor([AccountStore.dispatchToken]);
      _messages = _messages.filter(function(message) {
        return message.get('accountID') !== accountID;
      });
      return this.emit('change');
    });
    handle(ActionTypes.MESSAGE_SEND, function(message) {
      return onReceiveRawMessage(message);
    });
    handle(ActionTypes.MESSAGE_DELETE, function(message) {
      return onReceiveRawMessage(message);
    });
    handle(ActionTypes.MESSAGE_BOXES, function(message) {
      return onReceiveRawMessage(message);
    });
    handle(ActionTypes.MESSAGE_FLAG, function(message) {
      return onReceiveRawMessage(message);
    });
    handle(ActionTypes.LIST_FILTER, function(filter) {
      _messages = _messages.clear();
      if (_filter === filter) {
        _filter = '-';
      } else {
        _filter = filter;
      }
      return _params = {
        after: '-',
        flag: _filter,
        before: '-',
        pageAfter: '-',
        sort: _params.sort
      };
    });
    handle(ActionTypes.LIST_SORT, function(sort) {
      var currentField, currentOrder, newOrder;
      _messages = _messages.clear();
      _sortField = sort.field;
      currentField = _params.sort.substr(1);
      currentOrder = _params.sort.substr(0, 1);
      if (currentField === sort.field) {
        newOrder = currentOrder === '+' ? '-' : '+';
        _sortOrder = -1 * _sortOrder;
      } else {
        _sortOrder = -1;
        if (sort.field === 'date') {
          newOrder = '-';
        } else {
          newOrder = '+';
        }
      }
      return _params = {
        after: '-',
        flag: _params.flag,
        before: '-',
        pageAfter: '-',
        sort: newOrder + sort.field
      };
    });
    handle(ActionTypes.MESSAGE_ACTION, function(action) {
      return _prevAction = action;
    });
    handle(ActionTypes.MESSAGE_CURRENT, function(messageID) {
      this.setCurrentID(messageID);
      return this.emit('change');
    });
    handle(ActionTypes.SELECT_ACCOUNT, function(value) {
      this.setCurrentID(null);
      _params.after = '-';
      _params.before = '-';
      return _params.pageAfter = '-';
    });
    handle(ActionTypes.RECEIVE_MESSAGE_DELETE, function(id) {
      _messages = _messages.remove(id);
      return this.emit('change');
    });
    return handle(ActionTypes.SET_FETCHING, function(fetching) {
      _fetching = fetching;
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
  * Get messages from mailbox, with optional pagination
  *
  * @param {String}  mailboxID
  * @param {Boolean} conversation
  *
  * @return {Array}
   */

  MessageStore.prototype.getMessagesByMailbox = function(mailboxID, useConversations) {
    var conversationIDs, sequence, _ref1;
    conversationIDs = [];
    sequence = _messages.filter(function(message) {
      var conversationID, mailboxes;
      mailboxes = Object.keys(message.get('mailboxIDs'));
      if (__indexOf.call(mailboxes, mailboxID) < 0) {
        return false;
      }
      if (useConversations) {
        conversationID = message.get('conversationID');
        if (__indexOf.call(conversationIDs, conversationID) >= 0) {
          return false;
        } else {
          conversationIDs.push(conversationID);
          return true;
        }
      } else {
        return true;
      }
    }).sort(__getSortFunction(_sortField, _sortOrder));
    _currentMessages = sequence.toOrderedMap();
    if (_currentID == null) {
      this.setCurrentID((_ref1 = _currentMessages.first()) != null ? _ref1.get('id') : void 0);
    }
    return _currentMessages;
  };

  MessageStore.prototype.getCurrentID = function(messageID) {
    return _currentID;
  };

  MessageStore.prototype.setCurrentID = function(messageID) {
    return _currentID = messageID;
  };

  MessageStore.prototype.getPreviousMessage = function() {
    var idx, keys;
    keys = Object.keys(_currentMessages.toJS());
    idx = keys.indexOf(_currentID);
    if (idx === -1) {
      return null;
    } else {
      return keys[idx - 1];
    }
  };

  MessageStore.prototype.getNextMessage = function() {
    var idx, keys;
    keys = Object.keys(_currentMessages.toJS());
    idx = keys.indexOf(_currentID);
    if (idx === -1 || idx === (keys.length - 1)) {
      return null;
    } else {
      return keys[idx + 1];
    }
  };

  MessageStore.prototype.getConversation = function(conversationID) {
    if (conversationID !== _conversationMemoizeId) {
      _conversationMemoize = _messages.filter(function(message) {
        return message.get('conversationID') === conversationID;
      }).sort(reverseDateSort).toVector();
    }
    return _conversationMemoize;
  };

  MessageStore.prototype.getConversationsLength = function() {
    return _conversationLengths;
  };

  MessageStore.prototype.getParams = function() {
    return _params;
  };

  MessageStore.prototype.getCurrentFilter = function() {
    return _filter;
  };

  MessageStore.prototype.getPrevAction = function() {
    return _prevAction;
  };

  MessageStore.prototype.isFetching = function() {
    return _fetching;
  };

  return MessageStore;

})(Store);

module.exports = new MessageStore();
});

;require.register("stores/refreshes_store", function(exports, require, module) {
var ActionTypes, RefreshesStore, Store, refreshesToImmutable,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/store');

ActionTypes = require('../constants/app_constants').ActionTypes;

refreshesToImmutable = function(refreshes) {
  return Immutable.Sequence(refreshes).mapKeys(function(_, refresh) {
    return refresh.objectID;
  }).map(function(refresh) {
    return Immutable.fromJS(refresh);
  }).toOrderedMap();
};

RefreshesStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var _refreshes;

  __extends(RefreshesStore, _super);

  function RefreshesStore() {
    return RefreshesStore.__super__.constructor.apply(this, arguments);
  }

  _refreshes = refreshesToImmutable(window.refreshes || []);


  /*
      Defines here the action handlers.
   */

  RefreshesStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.RECEIVE_REFRESH_STATUS, function(refreshes) {
      return _refreshes = refreshesToImmutable(refreshes);
    });
    handle(ActionTypes.RECEIVE_REFRESH_UPDATE, function(refresh) {
      var id;
      refresh = Immutable.Map(refresh);
      id = refresh.get('objectID');
      _refreshes = _refreshes.set(id, refresh).toOrderedMap();
      return this.emit('change');
    });
    return handle(ActionTypes.RECEIVE_REFRESH_DELETE, function(refreshID) {
      _refreshes = _refreshes.filter(function(refresh) {
        return refresh.get('id') !== refreshID;
      }).toOrderedMap();
      return this.emit('change');
    });
  };

  RefreshesStore.prototype.getRefreshing = function() {
    return _refreshes;
  };

  return RefreshesStore;

})(Store);

module.exports = new RefreshesStore();
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

  _settings = Immutable.Map(window.settings);


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

;require.register("utils/activity_utils", function(exports, require, module) {
var ActivityUtils, XHRUtils;

XHRUtils = require('../utils/xhr_utils');

ActivityUtils = function(options) {
  var activity;
  activity = {};
  XHRUtils.activityCreate(options, function(error, res) {
    if (error) {
      return activity.onerror.call(error);
    } else {
      return activity.onsuccess.call(res);
    }
  });
  return activity;
};

module.exports = ActivityUtils;
});

;require.register("utils/api_utils", function(exports, require, module) {
var AccountStore, LayoutActionCreator, MessageStore, SettingsStore, onMessageList,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

AccountStore = require('../stores/account_store');

MessageStore = require('../stores/message_store');

SettingsStore = require('../stores/settings_store');

LayoutActionCreator = require('../actions/layout_action_creator');

onMessageList = function() {
  var actions, _ref, _ref1;
  actions = ["account.mailbox.messages", "account.mailbox.messages.full"];
  return _ref = (_ref1 = router.current.firstPanel) != null ? _ref1.action : void 0, __indexOf.call(actions, _ref) >= 0;
};

module.exports = {
  getCurrentAccount: function() {
    return AccountStore.getSelected();
  },
  getCurrentMailbox: function() {
    return AccountStore.getSelectedMailboxes();
  },
  getCurrentActions: function() {
    var res;
    res = [];
    Object.keys(router.current).forEach(function(panel) {
      if (router.current[panel] != null) {
        return res.push(router.current[panel].action);
      }
    });
    return res;
  },
  messageNew: function() {
    return router.navigate('compose/', {
      trigger: true
    });
  },
  setLocale: function(lang, refresh) {
    var err, locales, polyglot;
    window.moment.locale(lang);
    locales = {};
    try {
      locales = require("../locales/" + lang);
    } catch (_error) {
      err = _error;
      console.log(err);
      locales = require("../locales/en");
    }
    polyglot = new Polyglot();
    polyglot.extend(locales);
    window.t = polyglot.t.bind(polyglot);
    if (refresh) {
      return LayoutActionCreator.refresh();
    }
  },
  getAccountByLabel: function(label) {
    return AccountStore.getByLabel(label);
  },
  getSetting: function(key) {
    return SettingsStore.get().toJS()[key];
  },
  setSetting: function(key, value) {
    var ActionTypes, AppDispatcher, settings;
    AppDispatcher = require('../app_dispatcher');
    ActionTypes = require('../constants/app_constants').ActionTypes;
    settings = SettingsStore.get().toJS();
    settings[key] = value;
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SETTINGS_UPDATED,
      value: settings
    });
  },
  messageNavigate: function(direction, nextID) {
    var MessageActionCreator;
    if (!onMessageList()) {
      return;
    }
    if (nextID == null) {
      if (direction === 'prev') {
        nextID = MessageStore.getPreviousMessage();
      } else {
        nextID = MessageStore.getNextMessage();
      }
    }
    if (nextID == null) {
      return;
    }
    MessageActionCreator = require('../actions/message_action_creator');
    MessageActionCreator.setCurrent(nextID);
    if (SettingsStore.get('displayPreview')) {
      return this.messageDisplay(nextID);
    }
  },
  messageDisplay: function(messageID) {
    var action, conversationID, message, url;
    if (!messageID) {
      messageID = MessageStore.getCurrentID();
    }
    action = 'message';
    if (SettingsStore.get('displayConversation')) {
      message = MessageStore.getByID(messageID);
      if (message == null) {
        return;
      }
      conversationID = message.get('conversationID');
      if (conversationID) {
        action = 'conversation';
      }
    }
    url = window.router.buildUrl({
      direction: 'second',
      action: action,
      parameters: messageID
    });
    return window.router.navigate(url, {
      trigger: true
    });
  },
  messageClose: function() {
    var closeUrl;
    closeUrl = window.router.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: AccountStore.getSelected().get('id'),
      fullWidth: true
    });
    return window.router.navigate(closeUrl, {
      trigger: true
    });
  },
  messageDeleteCurrent: function() {
    var MessageActionCreator, alertError, message, nextID;
    if (!onMessageList()) {
      return;
    }
    MessageActionCreator = require('../actions/message_action_creator');
    alertError = LayoutActionCreator.alertError;
    message = MessageStore.getByID(MessageStore.getCurrentID());
    if (message == null) {
      return;
    }
    if ((!SettingsStore.get('messageConfirmDelete')) || window.confirm(t('mail confirm delete', {
      subject: message.get('subject')
    }))) {
      nextID = MessageStore.getNextMessage();
      this.messageNavigate(null, nextID);
      return MessageActionCreator["delete"](message, function(error) {
        if (error != null) {
          return alertError("" + (t("message action delete ko")) + " " + error);
        }
      });
    }
  },
  messageUndo: function() {
    var MessageActionCreator;
    MessageActionCreator = require('../actions/message_action_creator');
    return MessageActionCreator.undelete();
  }
};
});

;require.register("utils/message_utils", function(exports, require, module) {
var ComposeActions, ContactStore, MessageUtils;

ComposeActions = require('../constants/app_constants').ComposeActions;

ContactStore = require('../stores/contact_store');

module.exports = MessageUtils = {
  displayAddress: function(address, full) {
    if (full == null) {
      full = false;
    }
    if (full) {
      if ((address.name != null) && address.name !== "") {
        return "\"" + address.name + "\" <" + address.address + ">";
      } else {
        return "" + address.address;
      }
    } else {
      if ((address.name != null) && address.name !== "") {
        return address.name;
      } else {
        return address.address.split('@')[0];
      }
    }
  },
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
      res.push(MessageUtils.displayAddress(item, full));
    }
    return res.join(", ");
  },
  getReplyToAddress: function(message) {
    var from, reply;
    reply = message.get('replyTo');
    from = message.get('from');
    if ((reply != null ? reply.length : void 0) !== 0) {
      return reply;
    } else {
      return from;
    }
  },
  makeReplyMessage: function(inReplyTo, action, inHTML) {
    var dateHuman, html, message, sender, text;
    message = {
      composeInHTML: inHTML,
      attachments: Immutable.Vector.empty()
    };
    if (inReplyTo) {
      message.accountID = inReplyTo.get('accountID');
      dateHuman = this.formatDate(inReplyTo.get('createdAt'));
      sender = this.displayAddresses(inReplyTo.get('from'));
      text = inReplyTo.get('text');
      html = inReplyTo.get('html');
      if (text && !html && inHTML) {
        html = markdown.toHTML(text);
      }
      if (html && !text && !inHTML) {
        text = toMarkdown(html);
      }
      message.inReplyTo = inReplyTo.get('id');
      message.references = inReplyTo.get('references') || [];
      message.references = message.references.concat(message.inReplyTo);
    }
    switch (action) {
      case ComposeActions.REPLY:
        message.to = this.getReplyToAddress(inReplyTo);
        message.cc = [];
        message.bcc = [];
        message.subject = "" + (t('compose reply prefix')) + (inReplyTo.get('subject'));
        message.text = t('compose reply separator', {
          date: dateHuman,
          sender: sender
        }) + this.generateReplyText(text) + "\n";
        message.html = "<p><br /></p>\n<p>" + (t('compose reply separator', {
          date: dateHuman,
          sender: sender
        })) + "</p>\n<blockquote>" + html + "</blockquote>\n<p><br /></p>";
        break;
      case ComposeActions.REPLY_ALL:
        message.to = this.getReplyToAddress(inReplyTo);
        message.cc = [].concat(inReplyTo.get('to'), inReplyTo.get('cc'));
        message.bcc = [];
        message.subject = "" + (t('compose reply prefix')) + (inReplyTo.get('subject'));
        message.text = t('compose reply separator', {
          date: dateHuman,
          sender: sender
        }) + this.generateReplyText(text) + "\n";
        message.html = "<p><br /></p>\n<p>" + (t('compose reply separator', {
          date: dateHuman,
          sender: sender
        })) + "</p>\n<blockquote>" + html + "</blockquote>\n<p><br /></p>";
        break;
      case ComposeActions.FORWARD:
        message.to = [];
        message.cc = [];
        message.bcc = [];
        message.subject = "" + (t('compose forward prefix')) + (inReplyTo.get('subject'));
        message.text = t('compose forward separator', {
          date: dateHuman,
          sender: sender
        }) + text;
        message.html = ("<p>" + (t('compose forward separator', {
          date: dateHuman,
          sender: sender
        })) + "</p>") + html;
        message.attachments = inReplyTo.get('attachments');
        break;
      case null:
        message.to = [];
        message.cc = [];
        message.bcc = [];
        message.subject = '';
        message.text = t('compose default');
    }
    return message;
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
    if (!type) {
      return null;
    }
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
  formatDate: function(date, compact) {
    var formatter, today;
    if (date == null) {
      return;
    }
    today = moment();
    date = moment(date);
    if (date.isBefore(today, 'year')) {
      formatter = 'DD/MM/YYYY';
    } else if (date.isBefore(today, 'day')) {
      if ((compact != null) && compact) {
        formatter = 'L';
      } else {
        formatter = 'MMM DD';
      }
    } else {
      formatter = 'HH:mm';
    }
    return date.format(formatter);
  },
  getAvatar: function(message) {
    if (message.get('from')[0] != null) {
      return ContactStore.getAvatar(message.get('from')[0].address);
    } else {
      return null;
    }
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
              if (pluginConf.onAdd.condition.bind(pluginConf)(document.body)) {
                pluginConf.onAdd.action.bind(pluginConf)(document.body);
              }
            }
            if (pluginConf.onDelete != null) {
              if (pluginConf.onDelete.condition.bind(pluginConf)(document.body)) {
                _results.push(pluginConf.onDelete.action.bind(pluginConf)(document.body));
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
  },
  merge: function(remote) {
    var local, pluginConf, pluginName, _ref, _results;
    for (pluginName in remote) {
      if (!__hasProp.call(remote, pluginName)) continue;
      pluginConf = remote[pluginName];
      local = window.plugins[pluginName];
      if (local != null) {
        local.active = pluginConf.active;
      } else {
        delete remote[pluginName];
      }
    }
    _ref = window.plugins;
    _results = [];
    for (pluginName in _ref) {
      if (!__hasProp.call(_ref, pluginName)) continue;
      pluginConf = _ref[pluginName];
      if (remote[pluginName] == null) {
        _results.push(remote[pluginName] = {
          name: pluginConf.name,
          active: pluginConf.active
        });
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  }
};
});

;require.register("utils/socketio_utils", function(exports, require, module) {
var ActionTypes, AppDispatcher, dispatchAs, pathToSocketIO, scope, setServerScope, socket, url;

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

url = window.location.origin;

pathToSocketIO = "" + window.location.pathname + "socket.io";

socket = io.connect(url, {
  path: pathToSocketIO
});

dispatchAs = function(action) {
  return function(content) {
    return AppDispatcher.handleServerAction({
      type: action,
      value: content
    });
  };
};

scope = {};

setServerScope = function() {
  return socket.emit('change_scope', scope);
};

socket.on('refresh.status', dispatchAs(ActionTypes.RECEIVE_REFRESH_STATUS));

socket.on('refresh.create', dispatchAs(ActionTypes.RECEIVE_REFRESH_UPDATE));

socket.on('refresh.update', dispatchAs(ActionTypes.RECEIVE_REFRESH_UPDATE));

socket.on('refresh.delete', dispatchAs(ActionTypes.RECEIVE_REFRESH_DELETE));

socket.on('message.create', dispatchAs(ActionTypes.RECEIVE_RAW_MESSAGE));

socket.on('message.update', dispatchAs(ActionTypes.RECEIVE_RAW_MESSAGE));

socket.on('message.delete', dispatchAs(ActionTypes.RECEIVE_MESSAGE_DELETE));

socket.on('mailbox.update', dispatchAs(ActionTypes.RECEIVE_MAILBOX_UPDATE));

socket.on('connect', function() {
  return setServerScope();
});

socket.on('reconnect', function() {
  return setServerScope();
});

exports.acknowledgeRefresh = function(taskid) {
  return socket.emit('mark_ack', taskid);
};

exports.changeRealtimeScope = function(boxid, date) {
  scope = {
    mailboxID: boxid,
    before: date
  };
  return setServerScope();
};
});

;require.register("utils/translators/account_translator", function(exports, require, module) {
var AccountTranslator, MailboxFlags,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

MailboxFlags = require('../../constants/app_constants').MailboxFlags;

module.exports = AccountTranslator = {
  mailboxToImmutable: function(raw) {
    var box;
    raw.depth = raw.tree.length - 1;
    return box = Immutable.Map(raw);
  },
  toImmutable: function(raw) {
    var last, mailboxes, weight1, weight2;
    last = {};
    weight1 = 900;
    weight2 = 400;
    mailboxes = Immutable.Sequence(raw.mailboxes).mapKeys(function(_, box) {
      return box.id;
    }).map(function(box) {
      var label, _ref, _ref1, _ref2;
      if ((raw.draftMailbox == null) && (_ref = MailboxFlags.DRAFT, __indexOf.call(box.attribs, _ref) >= 0)) {
        raw.draftMailbox = mailboxes.draft;
      }
      if ((raw.sentMailbox == null) && (_ref1 = MailboxFlags.SENT, __indexOf.call(box.attribs, _ref1) >= 0)) {
        raw.sentMailbox = mailboxes.sent;
      }
      if ((raw.trashMailbox == null) && (_ref2 = MailboxFlags.TRASH, __indexOf.call(box.attribs, _ref2) >= 0)) {
        raw.trashMailbox = mailboxes.trash;
      }
      box.depth = box.tree.length - 1;
      if (box.depth === 0) {
        label = box.label.toLowerCase();
        if (label === 'inbox') {
          box.weight = 1000;
        } else if (box.attribs.length > 0 || /draft/.test(label) || /sent/.test(label) || /trash/.test(label)) {
          box.weight = weight1;
          weight1 -= 5;
        } else {
          box.weight = weight2;
          weight2 -= 5;
        }
        last[box.depth] = box.weight;
      } else {
        box.weight = last[box.depth - 1] - 0.1;
      }
      return AccountTranslator.mailboxToImmutable(box);
    }).toOrderedMap();
    raw.mailboxes = mailboxes;
    return Immutable.Map(raw);
  }
};
});

;require.register("utils/xhr_utils", function(exports, require, module) {
var AccountTranslator, SettingsStore, request,
  __hasProp = {}.hasOwnProperty;

request = superagent;

AccountTranslator = require('./translators/account_translator');

SettingsStore = require('../stores/settings_store');

module.exports = {
  changeSettings: function(settings, callback) {
    return request.put("settings").set('Accept', 'application/json').send(settings).end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in changeSettings", settings, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  fetchMessage: function(emailID, callback) {
    return request.get("message/" + emailID).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in fetchMessage", emailID, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  fetchConversation: function(emailID, callback) {
    return request.get("conversation/" + emailID).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in fetchConversation", emailID, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  fetchMessagesByFolder: function(mailboxID, query, callback) {
    var key, val;
    for (key in query) {
      if (!__hasProp.call(query, key)) continue;
      val = query[key];
      if (val === '-' || val === 'all') {
        delete query[key];
      }
    }
    return request.get("mailbox/" + mailboxID).set('Accept', 'application/json').query(query).end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in fetchMessagesByFolder", (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  mailboxCreate: function(mailbox, callback) {
    return request.post("mailbox").send(mailbox).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in mailboxCreate", mailbox, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  mailboxUpdate: function(data, callback) {
    return request.put("mailbox/" + data.mailboxID).send(data).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in mailboxUpdate", data, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  mailboxDelete: function(data, callback) {
    return request.del("mailbox/" + data.mailboxID).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in mailboxDelete", data, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  messageSend: function(message, callback) {
    var blob, files, name, req;
    req = request.post("message").set('Accept', 'application/json');
    files = {};
    message.attachments = message.attachments.map(function(file) {
      files[file.get('generatedFileName')] = file.get('rawFileObject');
      return file.remove('rawFileObject');
    }).toJS();
    req.field('body', JSON.stringify(message));
    for (name in files) {
      blob = files[name];
      if (blob != null) {
        req.attach(name, blob);
      }
    }
    return req.end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in messageSend", message, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  messagePatch: function(messageId, patch, callback) {
    return request.patch("message/" + messageId, patch).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in messagePatch", messageId, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  conversationDelete: function(conversationId, callback) {
    return request.del("conversation/" + conversationId).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in conversationDelete", conversationId, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  conversationPatch: function(conversationId, patch, callback) {
    return request.patch("conversation/" + conversationId, patch).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in conversationPatch", conversationId, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  createAccount: function(account, callback) {
    return request.post('account').send(account).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in createAccount", account, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(res.body, null);
      }
    });
  },
  editAccount: function(account, callback) {
    var rawAccount;
    rawAccount = account.toJS();
    return request.put("account/" + rawAccount.id).send(rawAccount).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in editAccount", account, (_ref = res.body) != null ? _ref.error : void 0);
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
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in search", (_ref = res.body) != null ? _ref.error : void 0);
        return callback(res.body, null);
      }
    });
  },
  refresh: function(hard, callback) {
    var url;
    url = hard ? "refresh?all=true" : "refresh";
    return request.get(url).end(function(res) {
      return typeof callback === "function" ? callback(res.text) : void 0;
    });
  },
  activityCreate: function(options, callback) {
    return request.post("activity").send(options).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in activityCreate", options, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(res.body, null);
      }
    });
  }
};
});

;
//# sourceMappingURL=app.js.map