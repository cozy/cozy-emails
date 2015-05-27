(function() {
  'use strict';

  var globals = typeof window === 'undefined' ? global : window;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};
  var has = ({}).hasOwnProperty;

  var aliases = {};

  var endsWith = function(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
  };

  var unalias = function(alias, loaderPath) {
    var start = 0;
    if (loaderPath) {
      if (loaderPath.indexOf('components/' === 0)) {
        start = 'components/'.length;
      }
      if (loaderPath.indexOf('/', start) > 0) {
        loaderPath = loaderPath.substring(start, loaderPath.indexOf('/', start));
      }
    }
    var result = aliases[alias + '/index.js'] || aliases[loaderPath + '/deps/' + alias + '/index.js'];
    if (result) {
      return 'components/' + result.substring(0, result.length - '.js'.length);
    }
    return alias;
  };

  var expand = (function() {
    var reg = /^\.\.?(\/|$)/;
    return function(root, name) {
      var results = [], parts, part;
      parts = (reg.test(name) ? root + '/' + name : name).split('/');
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
  })();
  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var absolute = expand(dirname(path), name);
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
    path = unalias(name, loaderPath);

    if (has.call(cache, path)) return cache[path].exports;
    if (has.call(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has.call(cache, dirIndex)) return cache[dirIndex].exports;
    if (has.call(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
  };

  require.alias = function(from, to) {
    aliases[to] = from;
  };

  require.register = require.define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has.call(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  require.list = function() {
    var result = [];
    for (var item in modules) {
      if (has.call(modules, item)) {
        result.push(item);
      }
    }
    return result;
  };

  require.brunch = true;
  globals.require = require;
})();
require.register("actions/account_action_creator", function(exports, require, module) {
var AccountActionCreator, AccountStore, ActionTypes, AppDispatcher, LayoutActionCreator, XHRUtils, alertError;

XHRUtils = require('../utils/xhr_utils');

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

AccountStore = require('../stores/account_store');

LayoutActionCreator = null;

alertError = function(error) {
  var message;
  LayoutActionCreator = require('../actions/layout_action_creator');
  if (error.name === 'AccountConfigError') {
    message = t("config error " + error.field);
    return LayoutActionCreator.alertError(message);
  } else {
    message = error.message || error.name || error;
    return LayoutActionCreator.alertError(message);
  }
};

module.exports = AccountActionCreator = {
  create: function(inputValues, afterCreation) {
    AccountActionCreator._setNewAccountWaitingStatus(true);
    return XHRUtils.createAccount(inputValues, function(error, account) {
      if ((error != null) || (account == null)) {
        AccountActionCreator._setNewAccountError(error);
        if (error != null) {
          return alertError(error);
        }
      } else {
        AppDispatcher.handleViewAction({
          type: ActionTypes.ADD_ACCOUNT,
          value: account
        });
        return afterCreation(AccountStore.getByID(account.id));
      }
    });
  },
  edit: function(inputValues, accountID, callback) {
    var account, newAccount;
    AccountActionCreator._setNewAccountWaitingStatus(true);
    account = AccountStore.getByID(accountID);
    newAccount = account.mergeDeep(inputValues);
    return XHRUtils.editAccount(newAccount, function(error, rawAccount) {
      if (error != null) {
        AccountActionCreator._setNewAccountError(error);
        return alertError(error);
      } else {
        AppDispatcher.handleViewAction({
          type: ActionTypes.EDIT_ACCOUNT,
          value: rawAccount
        });
        LayoutActionCreator = require('../actions/layout_action_creator');
        LayoutActionCreator.notify(t('account updated'), {
          autoclose: true
        });
        return typeof callback === "function" ? callback() : void 0;
      }
    });
  },
  check: function(inputValues, accountID, cb) {
    var account, newAccount;
    if (accountID != null) {
      account = AccountStore.getByID(accountID);
      newAccount = account.mergeDeep(inputValues).toJS();
    } else {
      newAccount = inputValues;
    }
    return XHRUtils.checkAccount(newAccount, function(error, rawAccount) {
      if (error != null) {
        AccountActionCreator._setNewAccountError(error);
        alertError(error);
      } else {
        LayoutActionCreator = require('../actions/layout_action_creator');
        LayoutActionCreator.notify(t('account checked'), {
          autoclose: true
        });
      }
      if (cb != null) {
        return cb(error, rawAccount);
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
  },
  mailboxExpunge: function(inputValues, callback) {
    AppDispatcher.handleViewAction({
      type: ActionTypes.MAILBOX_EXPUNGE,
      value: inputValues.mailboxID
    });
    return XHRUtils.mailboxExpunge(inputValues, function(error, account) {
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
    activity.onsuccess = function(err, res) {
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
      console.log(this.name);
      msg = t('contact create error', {
        error: this.name
      });
      return LayoutActionCreator.alertError(msg, {
        autoclose: true
      });
    };
  }
};
});

;require.register("actions/layout_action_creator", function(exports, require, module) {
var AccountActionCreator, AccountStore, ActionTypes, AlertLevel, AppDispatcher, LayoutActionCreator, LayoutStore, MessageActionCreator, MessageFlags, MessageStore, SearchActionCreator, SocketUtils, XHRUtils, _cachedQuery, _ref;

XHRUtils = require('../utils/xhr_utils');

SocketUtils = require('../utils/socketio_utils');

LayoutStore = require('../stores/layout_store');

AccountStore = require('../stores/account_store');

MessageStore = require('../stores/message_store');

AppDispatcher = require('../app_dispatcher');

_ref = require('../constants/app_constants'), ActionTypes = _ref.ActionTypes, AlertLevel = _ref.AlertLevel, MessageFlags = _ref.MessageFlags;

AccountActionCreator = require('./account_action_creator');

SearchActionCreator = require('./search_action_creator');

_cachedQuery = {};

module.exports = LayoutActionCreator = {
  setDisposition: function(type) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SET_DISPOSITION,
      value: type
    });
  },
  increasePreviewPanel: function(factor) {
    if (factor == null) {
      factor = 1;
    }
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RESIZE_PREVIEW_PANE,
      value: Math.abs(factor)
    });
  },
  decreasePreviewPanel: function(factor) {
    if (factor == null) {
      factor = 1;
    }
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RESIZE_PREVIEW_PANE,
      value: -1 * Math.abs(factor)
    });
  },
  resetPreviewPanel: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RESIZE_PREVIEW_PANE,
      value: null
    });
  },
  toggleFullscreen: function() {
    var type;
    type = LayoutStore.isPreviewFullscreen() ? ActionTypes.MINIMIZE_PREVIEW_PANE : ActionTypes.MAXIMIZE_PREVIEW_PANE;
    return AppDispatcher.handleViewAction({
      type: type
    });
  },
  minimizePreview: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.MINIMIZE_PREVIEW_PANE
    });
  },
  refresh: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.REFRESH,
      value: null
    });
  },
  alert: function(message) {
    return LayoutActionCreator.notify(message, {
      level: AlertLevel.INFO,
      autoclose: true
    });
  },
  alertSuccess: function(message) {
    return LayoutActionCreator.notify(message, {
      level: AlertLevel.SUCCESS,
      autoclose: true
    });
  },
  alertWarning: function(message) {
    return LayoutActionCreator.notify(message, {
      level: AlertLevel.WARNING,
      autoclose: true
    });
  },
  alertError: function(message) {
    return LayoutActionCreator.notify(message, {
      level: AlertLevel.ERROR,
      autoclose: true
    });
  },
  notify: function(message, options) {
    var task;
    if ((message == null) || message.toString().trim() === '') {
      throw new Error('Empty notification');
    } else {
      task = {
        id: Date.now(),
        finished: true,
        message: message.toString()
      };
      if (options != null) {
        task.autoclose = options.autoclose;
        task.errors = options.errors;
        task.finished = options.finished;
        task.actions = options.actions;
        task.level = options.level;
      }
      return AppDispatcher.handleViewAction({
        type: ActionTypes.RECEIVE_TASK_UPDATE,
        value: task
      });
    }
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
    var accountID, cached, mailboxID, query, selectedAccount, selectedMailbox, updated, _ref1;
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
      updated = Date.now();
      return XHRUtils.fetchMessagesByFolder(mailboxID, query, function(err, rawMsg) {
        MessageActionCreator.setFetching(false);
        if (err != null) {
          return LayoutActionCreator.alertError(err);
        } else {
          rawMsg.messages.forEach(function(msg) {
            return msg.updated = updated;
          });
          return MessageActionCreator.receiveRawMessages(rawMsg);
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
    var conversationID, message, messageID, onMessage, updated;
    onMessage = function(msg) {
      var selectedAccount;
      selectedAccount = AccountStore.getSelected();
      if ((selectedAccount == null) && (msg != null ? msg.accountID : void 0)) {
        return AccountActionCreator.selectAccount(msg.accountID);
      }
    };
    messageID = panelInfo.parameters.messageID;
    conversationID = panelInfo.parameters.conversationID;
    message = MessageStore.getByID(messageID);
    if (message != null) {
      onMessage(message);
    }
    updated = Date.now();
    return XHRUtils.fetchConversation(conversationID, function(err, rawMessages) {
      if (err != null) {
        return LayoutActionCreator.alertError(err);
      } else {
        rawMessages.forEach(function(msg) {
          return msg.updated = updated;
        });
        MessageActionCreator.receiveRawMessages(rawMessages);
        return onMessage(rawMessages[0]);
      }
    });
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
  refreshMessages: function(callback) {
    return XHRUtils.refresh(true, function(err, results) {
      if (err != null) {
        console.log(err);
        LayoutActionCreator.notify(t('account refresh error'), {
          autoclose: false,
          finished: true,
          errors: [JSON.stringify(err)]
        });
      } else {
        if (results === "done") {
          MessageActionCreator.receiveRawMessages(null);
          LayoutActionCreator.notify(t('account refreshed'), {
            autoclose: true
          });
        }
      }
      if (callback != null) {
        return callback();
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
  },
  intentAvailability: function(availability) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.INTENT_AVAILABLE,
      value: availability
    });
  },
  drawerShow: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.DRAWER_SHOW
    });
  },
  drawerHide: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.DRAWER_HIDE
    });
  },
  drawerToggle: function() {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.DRAWER_TOGGLE
    });
  }
};

MessageActionCreator = require('./message_action_creator');
});

;require.register("actions/message_action_creator", function(exports, require, module) {
var AccountStore, ActionTypes, AppDispatcher, Constants, FlagsConstants, LAC, MessageActionCreator, MessageFlags, MessageStore, XHRUtils, _convertFlagToOp, _fixCurrentMessage, _getNotification, _isDraft, _localDelete, _localMark, _localMove,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

AppDispatcher = require('../app_dispatcher');

Constants = require('../constants/app_constants');

ActionTypes = Constants.ActionTypes, MessageFlags = Constants.MessageFlags, FlagsConstants = Constants.FlagsConstants;

XHRUtils = require('../utils/xhr_utils');

AccountStore = require("../stores/account_store");

MessageStore = require('../stores/message_store');

LAC = void 0;

module.exports = MessageActionCreator = {
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
      return typeof callback === "function" ? callback(error, message) : void 0;
    });
  },
  setCurrent: function(messageID, conv) {
    if (typeof messageID !== 'string') {
      messageID = messageID.get('id');
    }
    return AppDispatcher.handleViewAction({
      type: ActionTypes.MESSAGE_CURRENT,
      value: {
        messageID: messageID,
        conv: conv
      }
    });
  },
  fetchConversation: function(conversationID) {
    return XHRUtils.fetchConversation(conversationID, function(err, rawMessages) {
      if (err == null) {
        return MessageActionCreator.receiveRawMessages(rawMessages);
      }
    });
  },
  refresh: function(target) {
    return XHRUtils.batchFetch(target, function(err, messages) {
      if (err) {
        return LAC.alertError(err);
      } else {
        return MessageActionCreator.receiveRawMessages(messages);
      }
    });
  },
  "delete": function(target, callback) {
    var messages;
    messages = _localDelete(target);
    return XHRUtils.batchDelete(target, function(err, updated) {
      var alertMsg;
      alertMsg = _getNotification(target, messages, 'delete', err);
      if (err) {
        MessageActionCreator.refresh(target);
        LAC.alertError(alertMsg);
      } else {
        if (target.silent !== true) {
          MessageActionCreator.receiveRawMessages(updated);
          LAC.notify(alertMsg, {
            autoclose: true,
            actions: [
              {
                label: t('undo last action'),
                onClick: function() {
                  return MessageActionCreator.undo();
                }
              }
            ]
          });
        }
      }
      return typeof callback === "function" ? callback(err, updated) : void 0;
    });
  },
  move: function(target, from, to, callback) {
    var messages;
    messages = _localMove(target, from, to);
    return XHRUtils.batchMove(target, from, to, function(err, updated) {
      var alertMsg;
      alertMsg = _getNotification(target, messages, 'move', err);
      if (err) {
        MessageActionCreator.refresh(target);
        LAC.alertError(alertMsg);
      } else {
        MessageActionCreator.receiveRawMessages(updated);
        if (!target.undeleting) {
          LAC.notify(alertMsg, {
            autoclose: true,
            actions: [
              {
                label: t('undo last action'),
                onClick: function() {
                  return MessageActionCreator.undo();
                }
              }
            ]
          });
        }
      }
      return typeof callback === "function" ? callback(err, updated) : void 0;
    });
  },
  mark: function(target, flag, callback) {
    var afterUpdate, op, _ref;
    _ref = _convertFlagToOp(flag), op = _ref.op, flag = _ref.flag;
    _localMark(target, op, flag);
    afterUpdate = function(err, updated) {
      if (err) {
        MessageActionCreator.refresh(target);
        LAC.alertError(err);
      } else {
        MessageActionCreator.receiveRawMessages(updated);
      }
      return typeof callback === "function" ? callback(err, updated) : void 0;
    };
    if (op === 'add') {
      return XHRUtils.batchAddFlag(target, flag, afterUpdate);
    } else if (op === 'remove') {
      return XHRUtils.batchRemoveFlag(target, flag, afterUpdate);
    } else {
      throw new Error("Wrong usage : unrecognized FlagsConstants");
    }
  },
  undo: function() {
    var action, done, lastBatch, options, _i, _len, _ref, _results;
    lastBatch = MessageStore.getPrevAction();
    if (lastBatch) {
      done = 0;
      _ref = lastBatch.actions;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        action = _ref[_i];
        options = {
          messageID: action.id,
          undeleting: true
        };
        done++;
        _results.push(this.move(options, action.to, action.from, function(err) {
          if (err) {
            return LAC.notify(t('undo ko'));
          } else if (--done === 0) {
            return LAC.notify(t('undo ok'), {
              autoclose: true
            });
          }
        }));
      }
      return _results;
    } else {
      return LAC.notify(t('undo unavailable'));
    }
  }
};

LAC = require('./layout_action_creator');

_getNotification = function(target, messages, action, err) {
  var errMsg, first, ok, smart_count, subject, type;
  first = messages[0];
  subject = (first != null ? typeof first.get === "function" ? first.get('subject') : void 0 : void 0) || (first != null ? first.subject : void 0);
  if (target.messageID) {
    type = 'message';
    if (target.isDraft) {
      type = 'draft';
    }
  } else if (target.conversationID) {
    type = 'conversation';
  } else if (target.conversationIDs) {
    type = 'conversations';
    smart_count = target.conversationIDs.length;
  } else if (target.messageIDs) {
    type = 'messages';
    smart_count = target.messageIDs.length;
  } else {
    throw new Error('Wrong Usage : unrecognized target MAC.getNotif');
  }
  if (err) {
    ok = 'ko';
    errMsg = ': ' + err.message || err;
  } else {
    ok = 'ok';
    errMsg = '';
  }
  return t("" + type + " " + action + " " + ok, {
    error: errMsg,
    subject: subject || '',
    smart_count: smart_count
  });
};

_convertFlagToOp = function(flag) {
  var op;
  if (flag === FlagsConstants.SEEN || flag === FlagsConstants.FLAGGED) {
    op = 'add';
  } else if (flag === FlagsConstants.NOFLAG) {
    op = 'remove';
    flag = FlagsConstants.FLAGGED;
  } else if (flag === FlagsConstants.UNSEEN) {
    op = 'remove';
    flag = FlagsConstants.SEEN;
  }
  return {
    op: op,
    flag: flag
  };
};

_fixCurrentMessage = function(target) {
  var conversationIDs, currentConversation, currentMessage, isConv, messageIDs, next;
  messageIDs = target.messageIDs || [target.messageID];
  currentMessage = MessageStore.getCurrentID() || 'not-null';
  conversationIDs = target.conversationIDs || [target.conversationID];
  currentConversation = MessageStore.getCurrentConversationID() || 'not-null';
  isConv = __indexOf.call(messageIDs, currentMessage) < 0;
  isConv = true;
  next = MessageStore.getNextOrPrevious(isConv);
  if (next != null) {
    return window.cozyMails.messageDisplay(next, false);
  }
};

_localMark = function(target, op, flag) {
  var flags, message, messages, updated, _i, _len;
  messages = MessageStore.getMixed(target);
  target.accountID = messages[0].get('accountID');
  updated = [];
  for (_i = 0, _len = messages.length; _i < _len; _i++) {
    message = messages[_i];
    flags = message.get('flags');
    if (op === 'add' && __indexOf.call(flags, flag) < 0) {
      flags = flags.concat([flag]);
    } else if (op === 'remove' && __indexOf.call(flags, flag) >= 0) {
      flags = _.without(flags, flag);
    } else {
      continue;
    }
    updated.push(message.set('flags', flags).toJS());
  }
  AppDispatcher.handleViewAction({
    type: ActionTypes.RECEIVE_RAW_MESSAGES,
    value: updated
  });
  return updated;
};

_isDraft = function(message, draftMailbox) {
  var mailboxIDs, _ref;
  mailboxIDs = message.get('mailboxIDs');
  return mailboxIDs[draftMailbox] || (_ref = MessageFlags.DRAFT, __indexOf.call(message.get('flags'), _ref) >= 0);
};

_localMove = function(target, from, to) {
  var actions, key, mailboxIDs, message, messages, newMailboxIds, updated, value, _i, _len;
  messages = MessageStore.getMixed(target);
  target.accountID = messages[0].get('accountID');
  actions = [];
  updated = [];
  for (_i = 0, _len = messages.length; _i < _len; _i++) {
    message = messages[_i];
    mailboxIDs = message.get('mailboxIDs');
    if (mailboxIDs[from]) {
      actions.push({
        id: message.get('id'),
        to: to,
        from: [from]
      });
      newMailboxIds = {};
      for (key in mailboxIDs) {
        value = mailboxIDs[key];
        newMailboxIds[key] = value;
      }
      delete newMailboxIds[from];
      newMailboxIds[to] = -1;
      updated.push(message.set('mailboxIDs', newMailboxIds).toJS());
    }
  }
  _fixCurrentMessage(target);
  AppDispatcher.handleViewAction({
    type: ActionTypes.RECEIVE_RAW_MESSAGES,
    value: updated
  });
  AppDispatcher.handleViewAction({
    type: ActionTypes.LAST_ACTION,
    value: {
      actions: actions
    }
  });
  return updated;
};

_localDelete = function(target) {
  var account, accountID, actions, draftMailbox, mailboxIDs, message, messages, newMailboxIds, trashMailbox, updated, _i, _len;
  messages = MessageStore.getMixed(target);
  accountID = messages[0].get('accountID');
  account = AccountStore.getByID(accountID);
  if (!account) {
    throw new Error('Wrong State : no account');
  }
  trashMailbox = account.get('trashMailbox');
  if (!trashMailbox) {
    throw new Error('Wrong State : no trashMailbox');
  }
  draftMailbox = account.get('draftMailbox');
  target.accountID = accountID;
  actions = [];
  updated = [];
  for (_i = 0, _len = messages.length; _i < _len; _i++) {
    message = messages[_i];
    if (accountID !== message.get('accountID')) {
      throw new Error("Wrong Usage : delete message from various accounts");
    }
    mailboxIDs = message.get('mailboxIDs');
    if (mailboxIDs[trashMailbox]) {
      continue;
    } else if (_isDraft(message, draftMailbox)) {
      AppDispatcher.handleViewAction({
        type: ActionTypes.RECEIVE_MESSAGE_DELETE,
        value: message.get('id')
      });
    }
    if (!mailboxIDs[trashMailbox]) {
      actions.push({
        id: message.get('id'),
        to: trashMailbox,
        from: Object.keys(mailboxIDs)
      });
      newMailboxIds = {};
      newMailboxIds[trashMailbox] = -1;
      updated.push(message.set('mailboxIDs', newMailboxIds).toJS());
    }
  }
  if (target.inReplyTo == null) {
    _fixCurrentMessage(target);
  }
  AppDispatcher.handleViewAction({
    type: ActionTypes.RECEIVE_RAW_MESSAGES,
    value: updated
  });
  AppDispatcher.handleViewAction({
    type: ActionTypes.LAST_ACTION,
    value: {
      actions: actions
    }
  });
  return updated;
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
    var payload;
    payload = {
      source: PayloadSources.VIEW_ACTION,
      action: action
    };
    this.dispatch(payload);
    return window.cozyMails.customEvent(PayloadSources.VIEW_ACTION, action);
  };

  AppDispatcher.prototype.handleServerAction = function(action) {
    var payload;
    payload = {
      source: PayloadSources.SERVER_ACTION,
      action: action
    };
    this.dispatch(payload);
    return window.cozyMails.customEvent(PayloadSources.SERVER_ACTION, action);
  };

  return AppDispatcher;

})(Dispatcher);

module.exports = new AppDispatcher();
});

;require.register("components/account_config", function(exports, require, module) {
var AccountActionCreator, AccountConfigMailboxes, AccountConfigMain, AccountConfigSignature, Container, LayoutActions, RouterMixin, Tabs, Title, _ref;

AccountActionCreator = require('../actions/account_action_creator');

LayoutActions = require('../actions/layout_action_creator');

RouterMixin = require('../mixins/router_mixin');

_ref = require('./basic_components'), Container = _ref.Container, Title = _ref.Title, Tabs = _ref.Tabs;

AccountConfigMain = require('./account_config_main');

AccountConfigMailboxes = require('./account_config_mailboxes');

AccountConfigSignature = require('./account_config_signature');

module.exports = React.createClass({
  displayName: 'AccountConfig',
  _lastDiscovered: '',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  _accountFields: ['id', 'label', 'name', 'login', 'password', 'imapServer', 'imapPort', 'imapSSL', 'imapTLS', 'imapLogin', 'smtpServer', 'smtpPort', 'smtpSSL', 'smtpTLS', 'smtpLogin', 'smtpPassword', 'smtpMethod', 'accountType'],
  _mailboxesFields: ['id', 'mailboxes', 'favoriteMailboxes', 'draftMailbox', 'sentMailbox', 'trashMailbox'],
  _accountSchema: {
    properties: {
      label: {
        allowEmpty: false
      },
      name: {
        allowEmpty: false
      },
      login: {
        allowEmpty: false
      },
      password: {
        allowEmpty: false
      },
      imapServer: {
        allowEmpty: false
      },
      imapPort: {
        allowEmpty: false
      },
      imapSSL: {
        allowEmpty: true
      },
      imapTLS: {
        allowEmpty: true
      },
      imapLogin: {
        allowEmpty: true
      },
      smtpServer: {
        allowEmpty: false
      },
      smtpPort: {
        allowEmpty: false
      },
      smtpSSL: {
        allowEmpty: true
      },
      smtpTLS: {
        allowEmpty: true
      },
      smtpLogin: {
        allowEmpty: true
      },
      smtpMethod: {
        allowEmpty: true
      },
      smtpPassword: {
        allowEmpty: true
      },
      draftMailbox: {
        allowEmpty: true
      },
      sentMailbox: {
        allowEmpty: true
      },
      trashMailbox: {
        allowEmpty: true
      },
      accountType: {
        allowEmpty: true
      }
    }
  },
  getInitialState: function() {
    return this.accountToState(null);
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    var isNextProps, isNextState;
    isNextState = _.isEqual(nextState, this.state);
    isNextProps = _.isEqual(nextProps, this.props);
    return !(isNextState && isNextProps);
  },
  componentWillReceiveProps: function(props) {
    var errors, field;
    if ((props.selectedAccount != null) && !props.isWaiting) {
      return this.setState(this.accountToState(props));
    } else {
      if (props.error != null) {
        if (props.error.name === 'AccountConfigError') {
          errors = {};
          field = props.error.field;
          if (field === 'auth') {
            errors.login = t('config error auth');
            errors.password = t('config error auth');
          } else {
            errors[field] = t('config error ' + field);
          }
          return this.setState({
            errors: errors
          });
        }
      } else {
        if (!props.isWaiting && !_.isEqual(props, this.props)) {
          return this.setState(this.accountToState(null));
        }
      }
    }
  },
  render: function() {
    var mailboxesOptions, mainOptions, tabParams, titleLabel, _ref1;
    mainOptions = this.buildMainOptions();
    mailboxesOptions = this.buildMailboxesOptions();
    titleLabel = this.buildTitleLabel();
    tabParams = this.buildTabParams();
    return Container({
      id: 'mailbox-config',
      key: "account-config-" + ((_ref1 = this.props.selectedAccount) != null ? _ref1.get('id') : void 0)
    }, Title({
      text: titleLabel
    }), this.props.tab != null ? Tabs({
      tabs: tabParams
    }) : void 0, !this.props.tab || this.props.tab === 'account' ? AccountConfigMain(mainOptions) : this.props.tab === 'signature' ? AccountConfigSignature({
      account: this.props.selectedAccount,
      editAccount: this.editAccount
    }) : AccountConfigMailboxes(mailboxesOptions));
  },
  buildMainOptions: function(options) {
    var field, _i, _len, _ref1;
    options = {
      isWaiting: this.props.isWaiting,
      selectedAccount: this.props.selectedAccount,
      validateForm: this.validateForm,
      onSubmit: this.onSubmit,
      onBlur: this.onFieldBlurred,
      errors: this.state.errors,
      checking: this.state.checking
    };
    _ref1 = this._accountFields;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      field = _ref1[_i];
      options[field] = this.linkState(field);
    }
    return options;
  },
  buildMailboxesOptions: function(options) {
    var field, _i, _len, _ref1;
    options = {
      error: this.props.error,
      errors: this.state.errors,
      onSubmit: this.onSubmit
    };
    _ref1 = this._mailboxesFields;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      field = _ref1[_i];
      options[field] = this.linkState(field);
    }
    return options;
  },
  buildTitleLabel: function() {
    var titleLabel;
    if (this.state.id) {
      titleLabel = t("account edit");
    } else {
      titleLabel = t("account new");
    }
    return titleLabel;
  },
  buildTabParams: function() {
    var tabAccountClass, tabMailboxClass, tabSignatureClass, tabs;
    tabAccountClass = tabMailboxClass = tabSignatureClass = '';
    if (!this.props.tab || this.props.tab === 'account') {
      tabAccountClass = 'active';
    } else if (this.props.tab === 'mailboxes') {
      tabMailboxClass = 'active';
    } else if (this.props.tab === 'signature') {
      tabSignatureClass = 'active';
    }
    tabs = [
      {
        "class": tabAccountClass,
        url: this.buildUrl({
          direction: 'first',
          action: 'account.config',
          parameters: [this.state.id, 'account']
        }),
        text: t("account tab account")
      }, {
        "class": tabMailboxClass,
        url: this.buildUrl({
          direction: 'first',
          action: 'account.config',
          parameters: [this.state.id, 'mailboxes']
        }),
        text: t("account tab mailboxes")
      }, {
        "class": tabSignatureClass,
        url: this.buildUrl({
          direction: 'first',
          action: 'account.config',
          parameters: [this.state.id, 'signature']
        }),
        text: t("account tab signature")
      }
    ];
    return tabs;
  },
  onFieldBlurred: function() {
    if (this.state.submitted) {
      return this.validateForm();
    }
  },
  onSubmit: function(event, check) {
    var accountValue, errors, valid, _ref1;
    if (event != null) {
      event.preventDefault();
    }
    _ref1 = this.validateForm(), accountValue = _ref1.accountValue, valid = _ref1.valid, errors = _ref1.errors;
    if (Object.keys(errors).length > 0) {
      LayoutActions.alertError(t('account errors'));
    }
    if (valid.valid) {
      if (check === true) {
        return this.checkAccount(accountValue);
      } else if (this.state.id != null) {
        return this.editAccount(accountValue);
      } else {
        return this.createAccount(accountValue);
      }
    }
  },
  validateForm: function(event) {
    var accountValue, error, errors, valid, _i, _len, _ref1, _ref2;
    if (event != null) {
      event.preventDefault();
    }
    this.setState({
      submitted: true
    });
    valid = {
      valid: null
    };
    accountValue = null;
    errors = {};
    _ref1 = this.doValidate(), accountValue = _ref1.accountValue, valid = _ref1.valid;
    if (valid.valid) {
      this.setState({
        errors: {}
      });
    } else {
      errors = {};
      _ref2 = valid.errors;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        error = _ref2[_i];
        errors[error.property] = t("validate " + error.message);
      }
      this.setState({
        errors: errors
      });
    }
    return {
      accountValue: accountValue,
      valid: valid,
      errors: errors
    };
  },
  doValidate: function() {
    var accountValue, field, valid, validOptions, _i, _j, _len, _len1, _ref1, _ref2;
    accountValue = {};
    _ref1 = this._accountFields;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      field = _ref1[_i];
      accountValue[field] = this.state[field];
    }
    _ref2 = this._mailboxesFields;
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      field = _ref2[_j];
      accountValue[field] = this.state[field];
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
  checkAccount: function(values) {
    this.setState({
      checking: true
    });
    return AccountActionCreator.check(values, this.state.id, (function(_this) {
      return function() {
        return _this.setState({
          checking: false
        });
      };
    })(this));
  },
  editAccount: function(values, callback) {
    return AccountActionCreator.edit(values, this.state.id, callback);
  },
  createAccount: function(values) {
    return AccountActionCreator.create(values, (function(_this) {
      return function(account) {
        var msg;
        msg = t("account creation ok");
        LayoutActions.notify(msg, {
          autoclose: true
        });
        return _this.redirect({
          direction: 'first',
          action: 'account.config',
          parameters: [account.get('id'), 'mailboxes'],
          fullWidth: true
        });
      };
    })(this));
  },
  accountToState: function(props) {
    var account, state;
    state = {
      errors: {}
    };
    if (props != null) {
      account = props.selectedAccount;
      this.buildErrorState(state, props);
    }
    if (account != null) {
      this.buildAccountState(state, props, account);
    } else if (Object.keys(state.errors).length === 0) {
      state = this.buildDefaultState(state);
    }
    return state;
  },
  buildErrorState: function(state, props) {
    var field;
    if (props.error != null) {
      if (props.error.name === 'AccountConfigError') {
        field = props.error.field;
        if (field === 'auth') {
          state.errors.login = t('config error auth');
          return state.errors.password = t('config error auth');
        } else {
          return state.errors[field] = t("config error " + field);
        }
      }
    }
  },
  buildAccountState: function(state, props, account) {
    var field, _i, _j, _len, _len1, _ref1, _ref2;
    if (this.state.id !== account.get('id')) {
      _ref1 = this._accountFields;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        field = _ref1[_i];
        state[field] = account.get(field);
      }
      if (state.smtpMethod == null) {
        state.smtpMethod = 'PLAIN';
      }
    }
    _ref2 = this._mailboxesFields;
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      field = _ref2[_j];
      state[field] = account.get(field);
    }
    state.newMailboxParent = null;
    state.mailboxes = props.mailboxes;
    state.favoriteMailboxes = props.favoriteMailboxes;
    if (state.mailboxes.length === 0) {
      return props.tab = 'mailboxes';
    }
  },
  buildDefaultState: function() {
    var field, state, _i, _j, _len, _len1, _ref1, _ref2;
    state = {
      errors: {}
    };
    _ref1 = this._accountFields;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      field = _ref1[_i];
      state[field] = '';
    }
    _ref2 = this._mailboxesFields;
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      field = _ref2[_j];
      state[field] = '';
    }
    state.id = null;
    state.smtpPort = 465;
    state.smtpSSL = true;
    state.smtpTLS = false;
    state.smtpMethod = 'PLAIN';
    state.imapPort = 993;
    state.imapSSL = true;
    state.imapTLS = false;
    state.accountType = 'IMAP';
    state.newMailboxParent = null;
    state.favoriteMailboxes = null;
    return state;
  }
});
});

;require.register("components/account_config_input", function(exports, require, module) {
var AccountInput, ErrorLine, RouterMixin, classer, div, input, label, textarea, _ref;

_ref = React.DOM, div = _ref.div, label = _ref.label, input = _ref.input, textarea = _ref.textarea;

ErrorLine = require('./basic_components').ErrorLine;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

module.exports = AccountInput = React.createClass({
  displayName: 'AccountInput',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  getInitialState: function() {
    return this.props;
  },
  componentWillReceiveProps: function(props) {
    return this.setState(props);
  },
  render: function() {
    var errorField, mainClasses, name, placeHolder, type;
    name = this.props.name;
    type = this.props.type || 'text';
    errorField = this.props.errorField || name;
    mainClasses = this.buildMainClasses(errorField);
    placeHolder = this.buildPlaceHolder(type, name);
    return div({
      key: "account-input-" + name,
      className: mainClasses
    }, label({
      htmlFor: "mailbox-" + name,
      className: "col-sm-2 col-sm-offset-2 control-label"
    }, t("account " + name)), div({
      className: 'col-sm-3'
    }, type === 'checkbox' ? input({
      id: "mailbox-" + name,
      name: "mailbox-" + name,
      checkedLink: this.linkState('value').value,
      type: type,
      onClick: this.props.onClick
    }) : type === 'textarea' ? textarea({
      id: "mailbox-" + name,
      name: "mailbox-" + name,
      valueLink: this.linkState('value').value,
      className: 'form-control',
      placeholder: placeHolder,
      onBlur: this.onBlur,
      onInput: this.props.onInput || null
    }) : input({
      id: "mailbox-" + name,
      name: "mailbox-" + name,
      valueLink: this.linkState('value').value,
      type: type,
      className: 'form-control',
      placeholder: placeHolder,
      onBlur: this.onBlur,
      onInput: this.props.onInput || null
    })), this.renderError(errorField, name));
  },
  onBlur: function() {
    var _base;
    return typeof (_base = this.props).onBlur === "function" ? _base.onBlur() : void 0;
  },
  renderError: function(errorField, name) {
    var error, result, _i, _len, _ref1, _ref2;
    result = [];
    if (Array.isArray(errorField)) {
      for (_i = 0, _len = errorField.length; _i < _len; _i++) {
        error = errorField[_i];
        if ((((_ref1 = this.state.errors) != null ? _ref1[error] : void 0) != null) && error === name) {
          result.push(ErrorLine({
            text: this.state.errors[error]
          }));
        }
      }
    } else {
      if (((_ref2 = this.state.errors) != null ? _ref2[errorField] : void 0) != null) {
        result.push(ErrorLine({
          text: this.state.errors[errorField]
        }));
      }
    }
    return result;
  },
  buildMainClasses: function(fields) {
    var errors, mainClasses;
    if (!Array.isArray(fields)) {
      fields = [fields];
    }
    errors = fields.some((function(_this) {
      return function(field) {
        return _this.state.errors[field] != null;
      };
    })(this));
    mainClasses = "form-group account-item-" + name + " ";
    if (errors) {
      mainClasses = "" + mainClasses + " has-error ";
    }
    if (this.props.className) {
      mainClasses = "" + mainClasses + " " + this.props.className + " ";
    }
    return mainClasses;
  },
  buildPlaceHolder: function(type, name) {
    var placeHolder;
    placeHolder = null;
    if ((type === 'text' || type === 'email') || name === 'signature') {
      placeHolder = t("account " + name + " short");
    }
    return placeHolder;
  }
});
});

;require.register("components/account_config_item", function(exports, require, module) {
var AccountActionCreator, LayoutActionCreator, MailboxItem, RouterMixin, classer, i, input, li, span, _ref;

_ref = React.DOM, li = _ref.li, span = _ref.span, i = _ref.i, input = _ref.input;

classer = React.addons.classSet;

AccountActionCreator = require('../actions/account_action_creator');

LayoutActionCreator = require('../actions/layout_action_creator');

RouterMixin = require('../mixins/router_mixin');

module.exports = MailboxItem = React.createClass({
  displayName: 'MailboxItem',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  propTypes: {
    mailbox: React.PropTypes.object
  },
  getInitialState: function() {
    return {
      edited: false,
      favorite: this.props.favorite
    };
  },
  render: function() {
    var classItem, favoriteClass, favoriteTitle, key, nbRecent, nbTotal, nbUnread, pusher, _ref1;
    pusher = this.buildIndentation();
    _ref1 = this.buildFavoriteValues(), favoriteClass = _ref1.favoriteClass, favoriteTitle = _ref1.favoriteTitle;
    nbTotal = this.props.mailbox.get('nbTotal') || 0;
    nbUnread = this.props.mailbox.get('nbUnread') || 0;
    nbRecent = this.props.mailbox.get('nbRecent') || 0;
    key = this.props.mailbox.get('id');
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
  buildIndentation: function() {
    var j;
    return ((function() {
      var _i, _ref1, _results;
      _results = [];
      for (j = _i = 1, _ref1 = this.props.mailbox.get('depth'); 1 <= _ref1 ? _i <= _ref1 : _i >= _ref1; j = 1 <= _ref1 ? ++_i : --_i) {
        _results.push("    ");
      }
      return _results;
    }).call(this)).join('');
  },
  buildFavoriteValues: function() {
    var favoriteClass, favoriteTitle;
    if (this.state.favorite) {
      favoriteClass = "fa fa-eye mailbox-visi-yes";
      favoriteTitle = t("mailbox title favorite");
    } else {
      favoriteClass = "fa fa-eye-slash mailbox-visi-no";
      favoriteTitle = t("mailbox title not favorite");
    }
    return {
      favoriteClass: favoriteClass,
      favoriteTitle: favoriteTitle
    };
  },
  onKeyDown: function(evt) {
    switch (evt.key) {
      case "Enter":
        return this.updateMailbox();
    }
  },
  editMailbox: function(event) {
    event.preventDefault();
    return this.setState({
      edited: true
    });
  },
  undoMailbox: function(event) {
    event.preventDefault();
    return this.setState({
      edited: false
    });
  },
  updateMailbox: function(event) {
    var mailbox;
    if (event != null) {
      event.preventDefault();
    }
    mailbox = {
      label: this.refs.label.getDOMNode().value.trim(),
      mailboxID: this.props.mailbox.get('id'),
      accountID: this.props.accountID
    };
    return AccountActionCreator.mailboxUpdate(mailbox, (function(_this) {
      return function(error) {
        var message;
        if (error != null) {
          message = "" + (t("mailbox update ko")) + " " + error;
          return LayoutActionCreator.alertError(message);
        } else {
          LayoutActionCreator.notify(t("mailbox update ok"), {
            autoclose: true
          });
          return _this.setState({
            edited: false
          });
        }
      };
    })(this));
  },
  toggleFavorite: function(event) {
    var mailbox;
    mailbox = {
      favorite: !this.state.favorite,
      mailboxID: this.props.mailbox.get('id'),
      accountID: this.props.accountID
    };
    AccountActionCreator.mailboxUpdate(mailbox, function(error) {
      var message;
      if (error != null) {
        message = "" + (t("mailbox update ko")) + " " + error;
        return LayoutActionCreator.alertError(message);
      } else {
        return LayoutActionCreator.notify(t("mailbox update ok"), {
          autoclose: true
        });
      }
    });
    return this.setState({
      favorite: !this.state.favorite
    });
  },
  deleteMailbox: function(event) {
    var mailbox;
    if (event != null) {
      event.preventDefault();
    }
    if (window.confirm(t('account confirm delbox'))) {
      mailbox = {
        mailboxID: this.props.mailbox.get('id'),
        accountID: this.props.accountID
      };
      return AccountActionCreator.mailboxDelete(mailbox, function(error) {
        var message;
        if (error != null) {
          message = "" + (t("mailbox delete ko")) + " " + error;
          return LayoutActionCreator.alertError(message);
        } else {
          return LayoutActionCreator.notify(t("mailbox delete ok"), {
            autoclose: true
          });
        }
      });
    }
  }
});
});

;require.register("components/account_config_mailboxes", function(exports, require, module) {
var AccountActionCreator, AccountConfigMailboxes, Form, LayoutActionCreator, MailboxItem, MailboxList, RouterMixin, SubTitle, classer, div, form, h4, i, input, label, li, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, h4 = _ref.h4, ul = _ref.ul, li = _ref.li, span = _ref.span, form = _ref.form, i = _ref.i, input = _ref.input, label = _ref.label;

classer = React.addons.classSet;

AccountActionCreator = require('../actions/account_action_creator');

LayoutActionCreator = require('../actions/layout_action_creator');

RouterMixin = require('../mixins/router_mixin');

MailboxList = require('./mailbox_list');

MailboxItem = require('./account_config_item');

_ref1 = require('./basic_components'), SubTitle = _ref1.SubTitle, Form = _ref1.Form;

module.exports = AccountConfigMailboxes = React.createClass({
  displayName: 'AccountConfigMailboxes',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    var isNextProps, isNextState;
    isNextState = _.isEqual(nextState, this.state);
    isNextProps = _.isEqual(nextProps, this.props);
    return !(isNextState && isNextProps);
  },
  getInitialState: function() {
    return this.propsToState(this.props);
  },
  componentWillReceiveProps: function(props) {
    return this.setState(this.propsToState(props));
  },
  propsToState: function(props) {
    var state;
    state = props;
    state.mailboxesFlat = {};
    if (state.mailboxes.value !== '') {
      state.mailboxes.value.map(function(mailbox, key) {
        var id;
        id = mailbox.get('id');
        state.mailboxesFlat[id] = {};
        return ['id', 'label', 'depth'].map(function(prop) {
          return state.mailboxesFlat[id][prop] = mailbox.get(prop);
        });
      }).toJS();
    }
    return state;
  },
  render: function() {
    var favorites, mailboxes;
    favorites = this.state.favoriteMailboxes.value;
    if (this.state.mailboxes.value !== '' && favorites !== '') {
      mailboxes = this.state.mailboxes.value.map((function(_this) {
        return function(mailbox, key) {
          var error, favorite;
          try {
            favorite = favorites.get(mailbox.get('id')) != null;
            return MailboxItem({
              accountID: _this.state.id.value,
              mailbox: mailbox,
              favorite: favorite
            });
          } catch (_error) {
            error = _error;
            return console.error(error, favorites);
          }
        };
      })(this)).toJS();
    }
    return Form({
      className: 'form-horizontal'
    }, this.renderError(), SubTitle({
      className: 'config-title',
      text: t("account special mailboxes")
    }), this.renderMailboxChoice(t('account draft mailbox'), "draftMailbox"), this.renderMailboxChoice(t('account sent mailbox'), "sentMailbox"), this.renderMailboxChoice(t('account trash mailbox'), "trashMailbox"), SubTitle({
      className: 'config-title'
    }, t("account mailboxes")), ul({
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
      mailboxes: this.state.mailboxesFlat,
      selectedMailboxID: this.state.newMailboxParent,
      onChange: (function(_this) {
        return function(mailbox) {
          return _this.setState({
            newMailboxParent: mailbox
          });
        };
      })(this)
    })))));
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
  renderMailboxChoice: function(labelText, box) {
    var errorClass;
    if ((this.state.id != null) && this.state.mailboxes.value !== '') {
      errorClass = this.state[box].value != null ? '' : 'has-error';
      return div({
        className: "form-group " + box + " " + errorClass
      }, label({
        className: 'col-sm-2 col-sm-offset-2 control-label'
      }, labelText), div({
        className: 'col-sm-3'
      }, MailboxList({
        allowUndefined: true,
        mailboxes: this.state.mailboxesFlat,
        selectedMailboxID: this.state[box].value,
        onChange: (function(_this) {
          return function(mailbox) {
            return _this.onMailboxChange(mailbox, box);
          };
        })(this)
      })));
    }
  },
  onMailboxChange: function(mailbox, box) {
    var newState;
    this.state[box].requestChange(mailbox);
    newState = {};
    newState[box] = mailbox;
    return this.setState(newState, (function(_this) {
      return function() {
        return _this.props.onSubmit();
      };
    })(this));
  },
  onKeyDown: function(evt) {
    switch (evt.key) {
      case "Enter":
        return this.addMailbox();
    }
  },
  addMailbox: function(event) {
    var mailbox;
    if (event != null) {
      event.preventDefault();
    }
    mailbox = {
      label: this.refs.newmailbox.getDOMNode().value.trim(),
      accountID: this.state.id.value,
      parentID: this.state.newMailboxParent
    };
    return AccountActionCreator.mailboxCreate(mailbox, (function(_this) {
      return function(error) {
        if (error != null) {
          return LayoutActionCreator.alertError("" + (t("mailbox create ko")) + " " + error);
        } else {
          LayoutActionCreator.notify(t("mailbox create ok"), {
            autoclose: true
          });
          return _this.refs.newmailbox.getDOMNode().value = '';
        }
      };
    })(this));
  },
  undoMailbox: function(event) {
    event.preventDefault();
    this.refs.newmailbox.getDOMNode().value = '';
    return this.setState({
      newMailboxParent: null
    });
  }
});
});

;require.register("components/account_config_main", function(exports, require, module) {
var AccountActionCreator, AccountConfigMain, AccountInput, FieldSet, Form, FormButtons, FormDropdown, LayoutActionCreator, RouterMixin, a, button, classer, div, fieldset, form, h3, h4, i, input, label, legend, li, p, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, p = _ref.p, h3 = _ref.h3, h4 = _ref.h4, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, fieldset = _ref.fieldset, legend = _ref.legend;

classer = React.addons.classSet;

AccountActionCreator = require('../actions/account_action_creator');

AccountInput = require('./account_config_input');

RouterMixin = require('../mixins/router_mixin');

LayoutActionCreator = require('../actions/layout_action_creator');

_ref1 = require('./basic_components'), Form = _ref1.Form, FieldSet = _ref1.FieldSet, FormButtons = _ref1.FormButtons, FormDropdown = _ref1.FormDropdown;

module.exports = AccountConfigMain = React.createClass({
  displayName: 'AccountConfigMain',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    var isNextProps, isNextState;
    isNextState = _.isEqual(nextState, this.state);
    isNextProps = _.isEqual(nextProps, this.props);
    return !(isNextState && isNextProps);
  },
  getInitialState: function() {
    var key, state, value, _ref2;
    state = {};
    _ref2 = this.props;
    for (key in _ref2) {
      value = _ref2[key];
      state[key] = value;
    }
    state.imapAdvanced = false;
    state.smtpAdvanced = false;
    return state;
  },
  componentWillReceiveProps: function(props) {
    var key, login, state, value, _ref2;
    state = {};
    for (key in props) {
      value = props[key];
      state[key] = value;
    }
    if (this._lastDiscovered == null) {
      login = state.login.value;
      if ((((_ref2 = state.id) != null ? _ref2.value : void 0) != null) && (login != null ? login.indexOf('@') : void 0) >= 0) {
        this._lastDiscovered = login.split('@')[1];
      }
    }
    return this.setState(state);
  },
  buildButtonLabel: function() {
    var buttonLabel;
    if (this.props.isWaiting) {
      buttonLabel = t('account saving');
    } else if (this.props.selectedAccount != null) {
      buttonLabel = t("account save");
    } else {
      buttonLabel = t("account add");
    }
    return buttonLabel;
  },
  render: function() {
    var buttonLabel, formClass, url;
    buttonLabel = this.buildButtonLabel();
    formClass = classer({
      'form-horizontal': true,
      'form-account': true,
      'waiting': this.props.isWaiting
    });
    return Form({
      className: formClass
    }, FieldSet({
      text: t('account identifiers')
    }), AccountInput({
      name: 'label',
      value: this.linkState('label').value,
      errors: this.state.errors,
      onBlur: this.props.onBlur
    }), AccountInput({
      name: 'name',
      value: this.linkState('name').value,
      errors: this.state.errors,
      onBlur: this.props.onBlur
    }), AccountInput({
      name: 'login',
      value: this.linkState('login').value,
      errors: this.state.errors,
      type: 'email',
      errorField: ['login', 'auth'],
      onBlur: this.discover
    }), AccountInput({
      name: 'password',
      value: this.linkState('password').value,
      errors: this.state.errors,
      type: 'password',
      errorField: ['password', 'auth'],
      onBlur: this.props.onBlur
    }), AccountInput({
      name: 'accountType',
      className: 'hidden',
      value: this.linkState('accountType').value,
      errors: this.state.errors
    }), this.state.displayGMAILSecurity ? (url = "https://www.google.com/settings/security/lesssecureapps", [
      FieldSet({
        text: t('gmail security tile')
      }), p(null, t('gmail security body', {
        login: this.state.login.value
      })), p(null, a({
        target: '_blank',
        href: url
      }, t('gmail security link')))
    ]) : void 0, FieldSet({
      text: t('account receiving server')
    }), AccountInput({
      name: 'imapServer',
      value: this.linkState('imapServer').value,
      errors: this.state.errors,
      errorField: ['imap', 'imapServer', 'imapPort'],
      onBlur: this.props.onBlur
    }), AccountInput({
      name: 'imapPort',
      value: this.linkState('imapPort').value,
      errors: this.state.errors,
      onBlur: (function(_this) {
        return function() {
          var _base;
          _this._onIMAPPort();
          return typeof (_base = _this.props).onBlur === "function" ? _base.onBlur() : void 0;
        };
      })(this),
      onInput: (function(_this) {
        return function() {
          return _this.setState({
            imapManualPort: true
          });
        };
      })(this)
    }), AccountInput({
      name: 'imapSSL',
      value: this.linkState('imapSSL').value,
      errors: this.state.errors,
      type: 'checkbox',
      onClick: (function(_this) {
        return function(event) {
          return _this._onServerParam(event.target, 'imap', 'ssl');
        };
      })(this)
    }), AccountInput({
      name: 'imapTLS',
      value: this.linkState('imapTLS').value,
      errors: this.state.errors,
      type: 'checkbox',
      onClick: (function(_this) {
        return function(event) {
          return _this._onServerParam(event.target, 'imap', 'tls');
        };
      })(this)
    }), div({
      className: "form-group"
    }, a({
      className: "col-sm-3 col-sm-offset-2 control-label clickable",
      onClick: this.toggleIMAPAdvanced
    }, t("account imap " + (this.state.imapAdvanced ? 'hide' : 'show') + " advanced"))), this.state.imapAdvanced ? AccountInput({
      name: 'imapLogin',
      value: this.linkState('imapLogin').value,
      errors: this.state.errors,
      errorField: ['imap', 'imapServer', 'imapPort', 'imapLogin']
    }) : void 0, FieldSet({
      text: t('account sending server')
    }), AccountInput({
      name: 'smtpServer',
      value: this.linkState('smtpServer').value,
      errors: this.state.errors,
      errorField: ['smtp', 'smtpServer', 'smtpPort', 'smtpLogin', 'smtpPassword'],
      onBlur: this.props.onBlur
    }), AccountInput({
      name: 'smtpPort',
      value: this.linkState('smtpPort').value,
      errors: this.state.errors,
      onBlur: (function(_this) {
        return function() {
          _this._onSMTPPort();
          return _this.props.onBlur();
        };
      })(this),
      onInput: (function(_this) {
        return function() {
          return _this.setState({
            smtpManualPort: true
          });
        };
      })(this)
    }), AccountInput({
      name: 'smtpSSL',
      value: this.linkState('smtpSSL').value,
      errors: this.state.errors,
      type: 'checkbox',
      onClick: (function(_this) {
        return function(ev) {
          return _this._onServerParam(ev.target, 'smtp', 'ssl');
        };
      })(this)
    }), AccountInput({
      name: 'smtpTLS',
      value: this.linkState('smtpTLS').value,
      errors: this.state.errors,
      type: 'checkbox',
      onClick: (function(_this) {
        return function(ev) {
          return _this._onServerParam(ev.target, 'smtp', 'tls');
        };
      })(this)
    }), div({
      className: "form-group"
    }, a({
      className: "col-sm-3 col-sm-offset-2 control-label clickable",
      onClick: this.toggleSMTPAdvanced
    }, t("account smtp " + (this.state.smtpAdvanced ? 'hide' : 'show') + " advanced"))), this.state.smtpAdvanced ? FormDropdown({
      prefix: 'mailbox',
      name: 'smtpMethod',
      labelText: t("account smtpMethod"),
      defaultText: t("account smtpMethod " + this.state.smtpMethod.value),
      values: ['NONE', 'CRAM-MD5', 'LOGIN', 'PLAIN'],
      onClick: this.onMethodChange,
      methodPrefix: "account smtpMethod"
    }) : void 0, this.state.smtpAdvanced ? AccountInput({
      name: 'smtpLogin',
      value: this.linkState('smtpLogin').value,
      errors: this.state.errors,
      errorField: ['smtp', 'smtpServer', 'smtpPort', 'smtpLogin', 'smtpPassword']
    }) : void 0, this.state.smtpAdvanced ? AccountInput({
      name: 'smtpPassword',
      value: this.linkState('smtpPassword').value,
      type: 'password',
      errors: this.state.errors,
      errorField: ['smtp', 'smtpServer', 'smtpPort', 'smtpLogin', 'smtpPassword']
    }) : void 0, FieldSet({
      text: t('account actions')
    }), FormButtons({
      buttons: [
        {
          "class": 'action-save',
          contrast: true,
          "default": false,
          danger: false,
          spinner: false,
          icon: 'save',
          onClick: this.onSubmit,
          text: buttonLabel
        }, {
          "class": 'action-check',
          contrast: false,
          "default": false,
          danger: false,
          spinner: this.props.checking,
          onClick: this.onCheck,
          icon: 'ellipsis-h',
          text: t('account check')
        }
      ]
    }), this.props.selectedAccount != null ? FieldSet({
      text: t('account danger zone')
    }) : void 0, this.props.selectedAccount != null ? FormButtons({
      buttons: [
        {
          "class": 'btn-remove',
          contrast: false,
          "default": true,
          danger: true,
          onClick: this.onRemove,
          spinner: false,
          icon: 'trash',
          text: t("account remove")
        }
      ]
    }) : void 0);
  },
  onSubmit: function(event) {
    return this.props.onSubmit(event, false);
  },
  onCheck: function(event) {
    return this.props.onSubmit(event, true);
  },
  onMethodChange: function(event) {
    console.log("blash");
    return this.state.smtpMethod.requestChange(event.target.dataset.value);
  },
  onRemove: function(event) {
    if (event != null) {
      event.preventDefault();
    }
    if (window.confirm(t('account remove confirm'))) {
      return AccountActionCreator.remove(this.props.selectedAccount.get('id'));
    }
  },
  toggleSMTPAdvanced: function() {
    return this.setState({
      smtpAdvanced: !this.state.smtpAdvanced
    });
  },
  toggleIMAPAdvanced: function() {
    return this.setState({
      imapAdvanced: !this.state.imapAdvanced
    });
  },
  discover: function(event) {
    var domain, login, _base;
    login = this.state.login.value;
    if (login != null ? login.indexOf('@' >= 0) : void 0) {
      domain = login.split('@')[1];
    }
    if (domain !== this._lastDiscovered) {
      this._lastDiscovered = domain;
      AccountActionCreator.discover(domain, (function(_this) {
        return function(err, provider) {
          if (err == null) {
            return _this.setDefaultValues(provider);
          }
        };
      })(this));
    }
    return typeof (_base = this.props).onBlur === "function" ? _base.onBlur() : void 0;
  },
  setDefaultValues: function(provider) {
    var infos, isGmail, key, server, val, _i, _len, _results;
    infos = {};
    for (_i = 0, _len = provider.length; _i < _len; _i++) {
      server = provider[_i];
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
          infos.smtpTLS = false;
        } else if (server.socketType === 'STARTTLS') {
          infos.smtpSSL = false;
          infos.smtpTLS = true;
        } else if (server.socketType === 'plain') {
          infos.smtpSSL = false;
          infos.smtpTLS = false;
        }
      }
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
    this.setState({
      displayGMAILSecurity: isGmail
    });
    _results = [];
    for (key in infos) {
      val = infos[key];
      _results.push(this.state[key].requestChange(val));
    }
    return _results;
  },
  _onServerParam: function(target, server, type) {
    if (!((server === 'imap' && this.state.imapManualPort) || (server === 'smtp' && this.state.smtpManualPort))) {
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
    }
  },
  _onIMAPPort: function(event) {
    var infos, port;
    port = event.target.value.trim();
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
  _onSMTPPort: function(event) {
    var infos, port;
    port = event.target.value.trim();
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
  }
});
});

;require.register("components/account_config_signature", function(exports, require, module) {
var AccountActionCreator, AccountInput, FieldSet, Form, FormButtons, LayoutActionCreator, RouterMixin, classer, div, form, h4, i, input, label, li, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, h4 = _ref.h4, ul = _ref.ul, li = _ref.li, span = _ref.span, form = _ref.form, i = _ref.i, input = _ref.input, label = _ref.label;

classer = React.addons.classSet;

AccountActionCreator = require('../actions/account_action_creator');

LayoutActionCreator = require('../actions/layout_action_creator');

RouterMixin = require('../mixins/router_mixin');

AccountInput = require('./account_config_input');

_ref1 = require('./basic_components'), Form = _ref1.Form, FieldSet = _ref1.FieldSet, FormButtons = _ref1.FormButtons;

module.exports = React.createClass({
  displayName: 'AccountConfigSignature',
  mixins: [React.addons.LinkedStateMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    var isNextProps, isNextState;
    isNextState = _.isEqual(nextState, this.state);
    isNextProps = _.isEqual(nextProps, this.props);
    return !(isNextState && isNextProps);
  },
  getInitialState: function() {
    return {
      account: this.props.account,
      saving: false,
      errors: {},
      signature: this.props.account.get('signature')
    };
  },
  render: function() {
    var formClass;
    console.log(this.state.account.get('signature'));
    formClass = classer({
      'form-horizontal': true,
      'form-account': true,
      'account-signature-form': true
    });
    return Form({
      className: formClass
    }, FieldSet({
      text: t('account signature')
    }), AccountInput({
      type: 'textarea',
      name: 'signature',
      value: this.linkState('signature'),
      errors: this.state.errors,
      onBlur: this.props.onBlur
    }), FieldSet({
      text: t('account actions')
    }), FormButtons({
      buttons: [
        {
          "class": 'signature-save',
          contrast: false,
          "default": false,
          danger: false,
          spinner: this.state.saving,
          icon: 'save',
          onClick: this.onSubmit,
          text: t('account signature save')
        }
      ]
    }));
  },
  onSubmit: function(event) {
    if (event != null) {
      event.preventDefault();
    }
    this.setState({
      saving: true
    });
    return this.props.editAccount({
      signature: this.state.signature
    }, (function(_this) {
      return function() {
        return _this.setState({
          saving: false
        });
      };
    })(this));
  }
});
});

;require.register("components/account_picker", function(exports, require, module) {
var RouterMixin, a, button, div, input, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, p = _ref.p, span = _ref.span, a = _ref.a, button = _ref.button, input = _ref.input;

RouterMixin = require('../mixins/router_mixin');

module.exports = React.createClass({
  displayName: 'AccountPicker',
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    if (Object.keys(accounts).length === 1) {
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
    account = this.props.accounts[this.props.valueLink.value];
    label = "\"" + (account.name || account.label) + "\" <" + account.login + ">";
    return p({
      className: 'form-control-static col-sm-6'
    }, label);
  },
  renderPicker: function() {
    var account, accounts, key, label, value;
    accounts = this.props.accounts;
    account = accounts[this.props.valueLink.value];
    value = this.props.valueLink.value;
    label = "\"" + (account.name || account.label) + "\" <" + account.login + ">";
    return div({
      className: 'account-picker'
    }, span({
      className: 'compose-from dropdown-toggle',
      'data-toggle': 'dropdown'
    }, span({
      ref: 'account',
      'data-value': value
    }, label), span({
      className: 'caret'
    })), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, (function() {
      var _results;
      _results = [];
      for (key in accounts) {
        account = accounts[key];
        if (key !== value) {
          _results.push(this.renderAccount(key, account));
        }
      }
      return _results;
    }).call(this)));
  },
  renderAccount: function(key, account) {
    var label;
    label = "\"" + (account.name || account.label) + "\" <" + account.login + ">";
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
      className: 'row row-alert'
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
var AccountConfig, AccountStore, Alert, Application, Compose, ContactStore, Conversation, Dispositions, LayoutActionCreator, LayoutStore, Menu, MessageFilter, MessageList, MessageStore, ReactCSSTransitionGroup, RefreshesStore, RouterMixin, SearchForm, SearchStore, Settings, SettingsStore, StoreWatchMixin, Stores, ToastContainer, TooltipRefesherMixin, Tooltips, Topbar, a, button, classer, div, form, i, input, main, p, section, span, strong, _ref, _ref1;

_ref = React.DOM, div = _ref.div, section = _ref.section, main = _ref.main, p = _ref.p, span = _ref.span, a = _ref.a, i = _ref.i, strong = _ref.strong, form = _ref.form, input = _ref.input, button = _ref.button;

AccountConfig = require('./account_config');

Alert = require('./alert');

Topbar = require('./topbar');

ToastContainer = require('./toast_container');

Compose = require('./compose');

Conversation = require('./conversation');

Menu = require('./menu');

MessageList = require('./message-list');

Settings = require('./settings');

SearchForm = require('./search-form');

Tooltips = require('./tooltips-manager');

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

StoreWatchMixin = require('../mixins/store_watch_mixin');

TooltipRefesherMixin = require('../mixins/tooltip_refresher_mixin');

AccountStore = require('../stores/account_store');

ContactStore = require('../stores/contact_store');

MessageStore = require('../stores/message_store');

LayoutStore = require('../stores/layout_store');

SettingsStore = require('../stores/settings_store');

SearchStore = require('../stores/search_store');

RefreshesStore = require('../stores/refreshes_store');

Stores = [AccountStore, ContactStore, MessageStore, LayoutStore, SettingsStore, SearchStore, RefreshesStore];

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
  mixins: [StoreWatchMixin(Stores), RouterMixin, TooltipRefesherMixin],
  render: function() {
    var alert, disposition, fullscreen, layout, layoutClasses;
    layout = this.props.router.current;
    if (layout == null) {
      return div(null, t("app loading"));
    }
    disposition = LayoutStore.getDisposition();
    fullscreen = LayoutStore.isPreviewFullscreen();
    alert = this.state.alertMessage;
    if ((layout.secondPanel != null) && (layout.secondPanel.parameters.messageID != null)) {
      MessageStore.setCurrentID(layout.secondPanel.parameters.messageID);
    } else {
      MessageStore.setCurrentID(null);
    }
    layoutClasses = ['layout', "layout-" + (LayoutStore.getDisposition()), fullscreen ? "layout-preview-fullscreen" : void 0, "layout-preview-" + (LayoutStore.getPreviewSize())].join(' ');
    return div({
      className: layoutClasses
    }, div({
      className: 'app'
    }, Menu({
      ref: 'menu',
      accounts: this.state.accounts,
      refreshes: this.state.refreshes,
      selectedAccount: this.state.selectedAccount,
      selectedMailboxID: this.state.selectedMailboxID,
      isResponsiveMenuShown: this.state.isResponsiveMenuShown,
      layout: this.props.router.current,
      mailboxes: this.state.mailboxesSorted,
      favorites: this.state.favoriteSorted,
      disposition: disposition
    }), main({
      className: layout.secondPanel != null ? null : 'full'
    }, this.getPanelComponent(layout.firstPanel), layout.secondPanel != null ? this.getPanelComponent(layout.secondPanel) : section({
      key: 'placeholder',
      'aria-expanded': false
    }))), Alert({
      alert: alert
    }), ToastContainer(), Tooltips());
  },
  getPanelComponent: function(panelInfo) {
    var account, accountID, conversation, conversationID, conversationLength, conversationLengths, counterMessage, displayConversations, emptyListMessage, error, favoriteMailboxes, fetching, isDraft, isTrash, isWaiting, lengths, mailbox, mailboxID, mailboxes, message, messageID, messages, messagesCount, nextMessage, prevMessage, query, ref, selectedAccount, selectedMailboxID, settings, tab, _ref2, _ref3, _ref4, _ref5;
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
      fetching = MessageStore.isFetching();
      if (this.state.settings.get('displayConversation')) {
        conversationID = MessageStore.getCurrentConversationID();
        if ((conversationID == null) && messages.length > 0) {
          conversationID = messages.first().get('conversationID');
        }
        conversationLengths = MessageStore.getConversationsLength();
      }
      query = _.clone(MessageStore.getParams());
      query.accountID = accountID;
      query.mailboxID = mailboxID;
      isDraft = ((_ref2 = this.state.selectedAccount) != null ? _ref2.get('draftMailbox') : void 0) === mailboxID;
      isTrash = ((_ref3 = this.state.selectedAccount) != null ? _ref3.get('trashMailbox') : void 0) === mailboxID;
      if (isDraft || isTrash) {
        displayConversations = false;
      } else {
        displayConversations = this.state.settings.get('displayConversation');
      }
      return MessageList({
        messages: messages,
        accountID: accountID,
        mailboxID: mailboxID,
        messageID: messageID,
        conversationID: conversationID,
        login: AccountStore.getByID(accountID).get('login'),
        mailboxes: this.state.mailboxesFlat,
        settings: this.state.settings,
        fetching: fetching,
        query: query,
        isTrash: isTrash,
        conversationLengths: conversationLengths,
        emptyListMessage: emptyListMessage,
        ref: 'messageList',
        displayConversations: displayConversations
      });
    } else if (panelInfo.action === 'account.config') {
      ref = "accountConfig";
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
        tab: tab,
        ref: ref
      });
    } else if (panelInfo.action === 'account.new') {
      return AccountConfig({
        ref: "accountConfig",
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
        if (selectedMailboxID == null) {
          selectedMailboxID = Object.keys(message.get('mailboxIDs'))[0];
        }
      }
      isDraft = ((_ref4 = this.state.selectedAccount) != null ? _ref4.get('draftMailbox') : void 0) === mailboxID;
      isTrash = ((_ref5 = this.state.selectedAccount) != null ? _ref5.get('trashMailbox') : void 0) === mailboxID;
      if (isDraft || isTrash) {
        displayConversations = false;
      } else {
        displayConversations = this.state.settings.get('displayConversation');
      }
      prevMessage = MessageStore.getPreviousMessage();
      nextMessage = MessageStore.getNextMessage();
      return Conversation({
        key: 'conversation-' + conversationID,
        settings: this.state.settings,
        accounts: this.state.accountsFlat,
        mailboxes: this.state.mailboxesFlat,
        selectedAccountID: this.state.selectedAccount.get('id'),
        selectedAccountLogin: this.state.selectedAccount.get('login'),
        selectedMailboxID: selectedMailboxID,
        message: message,
        conversation: conversation,
        conversationLength: conversationLength,
        prevMessageID: prevMessage != null ? prevMessage.get('id') : void 0,
        prevConversationID: prevMessage != null ? prevMessage.get('conversationID') : void 0,
        nextMessageID: nextMessage != null ? nextMessage.get('id') : void 0,
        nextConversationID: nextMessage != null ? nextMessage.get('conversationID') : void 0,
        ref: 'conversation',
        displayConversations: displayConversations,
        useIntents: LayoutStore.intentAvailable()
      });
    } else if (panelInfo.action === 'compose') {
      return Compose({
        layout: 'full',
        action: null,
        inReplyTo: null,
        settings: this.state.settings,
        accounts: this.state.accountsFlat,
        selectedAccountID: this.state.selectedAccount.get('id'),
        selectedAccountLogin: this.state.selectedAccount.get('login'),
        message: null,
        useIntents: LayoutStore.intentAvailable(),
        ref: 'compose'
      });
    } else if (panelInfo.action === 'edit') {
      messageID = panelInfo.parameters.messageID;
      message = MessageStore.getByID(messageID);
      return Compose({
        layout: 'full',
        action: null,
        inReplyTo: null,
        settings: this.state.settings,
        accounts: this.state.accountsFlat,
        selectedAccountID: this.state.selectedAccount.get('id'),
        selectedAccountLogin: this.state.selectedAccount.get('login'),
        selectedMailboxID: this.state.selectedMailboxID,
        message: message,
        useIntents: LayoutStore.intentAvailable(),
        ref: 'compose'
      });
    } else if (panelInfo.action === 'settings') {
      settings = this.state.settings;
      return Settings({
        ref: 'settings',
        settings: this.state.settings
      });
    } else {
      return div(null, 'Unknown component');
    }
  },
  getStateFromStores: function() {
    var accounts, accountsFlat, disposition, firstPanelInfo, mailboxes, mailboxesFlat, selectedAccount, selectedAccountID, selectedMailboxID, _ref2;
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
    accounts = AccountStore.getAll();
    mailboxes = AccountStore.getSelectedMailboxes();
    accountsFlat = {};
    accounts.map(function(account) {
      return accountsFlat[account.get('id')] = {
        name: account.get('name'),
        label: account.get('label'),
        login: account.get('login'),
        trashMailbox: account.get('trashMailbox'),
        signature: account.get('signature')
      };
    }).toJS();
    mailboxesFlat = {};
    mailboxes.map(function(mailbox) {
      var id;
      id = mailbox.get('id');
      mailboxesFlat[id] = {};
      return ['id', 'label', 'depth'].map(function(prop) {
        return mailboxesFlat[id][prop] = mailbox.get(prop);
      });
    }).toJS();
    disposition = LayoutStore.getDisposition();
    return {
      accounts: accounts,
      accountsFlat: accountsFlat,
      selectedAccount: selectedAccount,
      isResponsiveMenuShown: false,
      alertMessage: LayoutStore.getAlert(),
      mailboxes: mailboxes,
      mailboxesSorted: AccountStore.getSelectedMailboxes(true),
      mailboxesFlat: mailboxesFlat,
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
        var firstPanel, secondPanel;
        firstPanel = params.firstPanel, secondPanel = params.secondPanel;
        if (firstPanel != null) {
          _this.checkAccount(firstPanel.action);
        }
        if (secondPanel != null) {
          _this.checkAccount(secondPanel.action);
        }
        return _this.forceUpdate();
      };
    })(this);
    return this.props.router.on('fluxRoute', this.onRoute);
  },
  checkAccount: function(action) {
    var account, errorMsg;
    account = this.state.selectedAccount;
    if ((account != null)) {
      if ((account.get('draftMailbox') == null) || (account.get('sentMailbox') == null) || (account.get('trashMailbox') == null)) {
        if (action === 'account.mailbox.messages' || action === 'account.mailbox.messages.full' || action === 'search' || action === 'message' || action === 'conversation' || action === 'compose' || action === 'edit') {
          this.redirect({
            direction: 'first',
            action: 'account.config',
            parameters: [account.get('id'), 'mailboxes'],
            fullWidth: true
          });
          errorMsg = t('account no special mailboxes');
          return LayoutActionCreator.alertError(errorMsg);
        }
      }
    }
  },
  _notify: function(title, options) {
    return window.cozyMails.notify(title, options);
  },
  componentDidMount: function() {
    return Stores.forEach((function(_this) {
      return function(store) {
        return store.on('notify', _this._notify);
      };
    })(this));
  },
  componentWillUnmount: function() {
    Stores.forEach((function(_this) {
      return function(store) {
        return store.removeListener('notify', _this.notify);
      };
    })(this));
    return this.props.router.off('fluxRoute', this.onRoute);
  }
});
});

;require.register("components/attachement_preview", function(exports, require, module) {
var MessageUtils, Tooltips, a, i, img, li, _ref;

_ref = React.DOM, li = _ref.li, img = _ref.img, a = _ref.a, i = _ref.i;

MessageUtils = require('../utils/message_utils');

Tooltips = require('../constants/app_constants').Tooltips;

module.exports = React.createClass({
  displayName: 'AttachmentPreview',
  icons: {
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
  },
  render: function() {
    if (this.props.previewLink) {
      return li({
        key: this.props.key
      }, this.renderIcon(), a({
        target: '_blank',
        href: this.props.file.url,
        'aria-describedby': Tooltips.OPEN_ATTACHMENT,
        'data-tooltip-direction': 'top'
      }, this.props.preview ? img({
        width: 90,
        src: this.props.file.url
      }) : void 0, this.props.file.generatedFileName), ' - ', a({
        href: "" + this.props.file.url + "?download=1",
        'aria-describedby': Tooltips.DOWNLOAD_ATTACHMENT,
        'data-tooltip-direction': 'top'
      }, i({
        className: 'fa fa-download'
      }), this.displayFilesize(this.props.file.length)));
    } else {
      return li({
        key: this.props.key
      }, this.renderIcon(), a({
        href: "" + this.props.file.url + "?download=1",
        'aria-describedby': Tooltips.DOWNLOAD_ATTACHMENT,
        'data-tooltip-direction': 'left'
      }, "" + this.props.file.generatedFileName + "\n(" + (this.displayFilesize(this.props.file.length)) + ")"));
    }
  },
  renderIcon: function() {
    var type;
    type = MessageUtils.getAttachmentType(this.props.file.contentType);
    return i({
      className: "mime " + type + " fa " + (this.icons[type] || 'fa-file-o')
    });
  },
  displayFilesize: function(length) {
    if (length < 1024) {
      return "" + length + " " + (t('length bytes'));
    } else if (length < 1024 * 1024) {
      return "" + (0 | length / 1024) + " " + (t('length kbytes'));
    } else {
      return "" + (0 | length / (1024 * 1024)) + " " + (t('length mbytes'));
    }
  }
});
});

;require.register("components/basic_components", function(exports, require, module) {
var AddressLabel, Container, Dropdown, ErrorLine, FieldSet, Form, FormButton, FormButtons, FormDropdown, MenuDivider, MenuHeader, MenuItem, Spinner, SubTitle, Tabs, Title, a, button, div, fieldset, form, h3, h4, i, img, label, legend, li, section, span, ul, _ref;

_ref = React.DOM, div = _ref.div, section = _ref.section, h3 = _ref.h3, h4 = _ref.h4, ul = _ref.ul, li = _ref.li, a = _ref.a, i = _ref.i, button = _ref.button, span = _ref.span, fieldset = _ref.fieldset, legend = _ref.legend, label = _ref.label, img = _ref.img, form = _ref.form;

Container = React.createClass({
  render: function() {
    return section({
      id: this.props.id,
      key: this.props.key,
      className: 'panel'
    }, this.props.children);
  }
});

Title = React.createClass({
  render: function() {
    return h3({
      refs: this.props.ref,
      className: 'title'
    }, this.props.text);
  }
});

SubTitle = React.createClass({
  render: function() {
    return h4({
      refs: this.props.ref,
      className: 'subtitle ' + this.props.className
    }, this.props.text);
  }
});

Tabs = React.createClass({
  render: function() {
    var index, tab, url;
    return ul({
      className: "nav nav-tabs",
      role: "tablist"
    }, (function() {
      var _ref1, _ref2, _results;
      _ref1 = this.props.tabs;
      _results = [];
      for (index in _ref1) {
        tab = _ref1[index];
        if (((_ref2 = tab["class"]) != null ? _ref2.indexOf('active') : void 0) >= 0) {
          url = null;
        } else {
          url = tab.url;
        }
        _results.push(li({
          key: "tab-li-" + index,
          className: tab["class"]
        }, a({
          href: url,
          key: "tab-" + index
        }, tab.text)));
      }
      return _results;
    }).call(this));
  }
});

ErrorLine = React.createClass({
  render: function() {
    return div({
      className: 'col-sm-5 col-sm-offset-2 control-label'
    }, this.props.text);
  }
});

Form = React.createClass({
  render: function() {
    return form({
      id: this.props.id,
      className: this.props.className,
      method: 'POST'
    }, this.props.children);
  }
});

FieldSet = React.createClass({
  render: function() {
    return fieldset(null, legend(null, this.props.text), this.props.children);
  }
});

FormButton = React.createClass({
  render: function() {
    var className;
    className = 'btn ';
    if (this.props.contrast) {
      className += 'btn-cozy-contrast ';
    } else if (this.props["default"]) {
      className += 'btn-cozy-default ';
    } else {
      className += 'btn-cozy ';
    }
    if (this.props.danger) {
      className += 'btn-danger ';
    }
    if (this.props["class"] != null) {
      className += this.props["class"];
    }
    return button({
      className: className,
      onClick: this.props.onClick
    }, this.props.spinner ? span(null, Spinner({
      white: true
    })) : span({
      className: "fa fa-" + this.props.icon
    }), span(null, this.props.text));
  }
});

FormButtons = React.createClass({
  render: function() {
    var formButton, index;
    return div(null, div({
      className: 'col-sm-offset-4'
    }, (function() {
      var _i, _len, _ref1, _results;
      _ref1 = this.props.buttons;
      _results = [];
      for (index = _i = 0, _len = _ref1.length; _i < _len; index = ++_i) {
        formButton = _ref1[index];
        formButton.key = index;
        _results.push(FormButton(formButton));
      }
      return _results;
    }).call(this)));
  }
});

MenuItem = React.createClass({
  render: function() {
    var aOptions, liOptions;
    liOptions = {
      role: 'presentation'
    };
    if (this.props.key) {
      liOptions.key = this.props.key;
    }
    if (this.props.liClassName) {
      liOptions.className = this.props.liClassName;
    }
    aOptions = {
      role: 'menuitemu',
      onClick: this.props.onClick
    };
    if (this.props.className) {
      aOptions.className = this.props.className;
    }
    if (this.props.href) {
      aOptions.href = this.props.href;
    }
    if (this.props.target) {
      aOptions.target = this.props.href;
    }
    return li(liOptions, a(aOptions, this.props.children));
  }
});

MenuHeader = React.createClass({
  render: function() {
    var liOptions;
    liOptions = {
      role: 'presentation',
      className: 'dropdown-header'
    };
    if (this.props.key) {
      liOptions.key = this.props.key;
    }
    return li(liOptions, this.props.children);
  }
});

MenuDivider = React.createClass({
  render: function() {
    var liOptions;
    liOptions = {
      role: 'presentation',
      className: 'divider'
    };
    if (this.props.key) {
      liOptions.key = this.props.key;
    }
    return li(liOptions);
  }
});

FormDropdown = React.createClass({
  render: function() {
    return div({
      key: "account-input-" + this.props.name,
      className: "form-group account-item-" + this.props.name + " "
    }, label({
      htmlFor: "" + this.props.prefix + "-" + this.props.name,
      className: "col-sm-2 col-sm-offset-2 control-label"
    }, this.props.labelText), div({
      className: 'col-sm-3'
    }, div({
      className: "dropdown"
    }, button({
      id: "" + this.props.prefix + "-" + this.props.name,
      name: "" + this.props.prefix + "-" + this.props.name,
      className: "btn btn-default dropdown-toggle",
      type: "button",
      "data-toggle": "dropdown"
    }, this.props.defaultText), ul({
      className: "dropdown-menu",
      role: "menu"
    }, this.props.values.map((function(_this) {
      return function(method) {
        return li({
          role: "presentation"
        }, a({
          'data-value': method,
          role: "menuitem",
          onClick: _this.props.onClick
        }, t("" + _this.props.methodPrefix + " " + method)));
      };
    })(this))))));
  }
});

AddressLabel = React.createClass({
  render: function() {
    var key, meaninglessKey, result, _ref1, _ref2;
    meaninglessKey = 0;
    if (((_ref1 = this.props.contact.name) != null ? _ref1.length : void 0) > 0 && this.props.contact.address) {
      key = this.props.contact.address.replace(/\W/g, '');
      result = span(null, span(null, "" + this.props.contact.name + " "), span({
        className: 'contact-address',
        key: key
      }, i({
        className: 'fa fa-angle-left'
      }), this.props.contact.address, i({
        className: 'fa fa-angle-right'
      })));
    } else if (((_ref2 = this.props.contact.name) != null ? _ref2.length : void 0) > 0) {
      result = span({
        key: "label-" + (meaninglessKey++)
      }, this.props.contact.name);
    } else {
      result = span(null, this.props.contact.address);
    }
    return result;
  }
});

Dropdown = React.createClass({
  displayName: 'Dropdown',
  getInitialState: function() {
    var defaultKey, state;
    defaultKey = this.props.value != null ? this.props.value : Object.keys(this.props.values)[0];
    return state = {
      label: this.props.values[defaultKey]
    };
  },
  render: function() {
    var key, renderFilter, value;
    renderFilter = (function(_this) {
      return function(key, value) {
        var onChange;
        onChange = function() {
          _this.setState({
            label: value
          });
          return _this.props.onChange(key);
        };
        return li({
          role: 'presentation',
          onClick: onChange,
          key: key
        }, a({
          role: 'menuitem'
        }, value));
      };
    })(this);
    return div({
      className: 'dropdown'
    }, button({
      className: 'dropdown-toggle',
      type: 'button',
      'data-toggle': 'dropdown'
    }, "" + this.state.label + " ", span({
      className: 'caret'
    }, '')), ul({
      className: 'dropdown-menu',
      role: 'menu'
    }, (function() {
      var _ref1, _results;
      _ref1 = this.props.values;
      _results = [];
      for (key in _ref1) {
        value = _ref1[key];
        _results.push(renderFilter(key, t("list filter " + key)));
      }
      return _results;
    }).call(this)));
  }
});

Spinner = React.createClass({
  displayName: 'Spinner',
  protoTypes: {
    white: React.PropTypes.bool
  },
  render: function() {
    var suffix;
    suffix = this.props.white ? '-white' : '';
    return img({
      src: "images/spinner" + suffix + ".svg",
      alt: 'spinner',
      className: 'button-spinner'
    });
  }
});

module.exports = {
  AddressLabel: AddressLabel,
  Container: Container,
  Dropdown: Dropdown,
  ErrorLine: ErrorLine,
  Form: Form,
  FieldSet: FieldSet,
  FormButton: FormButton,
  FormButtons: FormButtons,
  FormDropdown: FormDropdown,
  MenuItem: MenuItem,
  MenuHeader: MenuHeader,
  MenuDivider: MenuDivider,
  Spinner: Spinner,
  SubTitle: SubTitle,
  Title: Title,
  Tabs: Tabs
};
});

;require.register("components/compose", function(exports, require, module) {
var AccountPicker, Compose, ComposeActions, ComposeEditor, FilePicker, FileUtils, LayoutActionCreator, MailsInput, MessageActionCreator, MessageUtils, RouterMixin, Spinner, Tooltips, a, button, classer, div, form, h3, i, input, label, li, section, span, textarea, ul, _ref, _ref1, _ref2;

_ref = React.DOM, div = _ref.div, section = _ref.section, h3 = _ref.h3, a = _ref.a, i = _ref.i, textarea = _ref.textarea, form = _ref.form, label = _ref.label, button = _ref.button;

_ref1 = React.DOM, span = _ref1.span, ul = _ref1.ul, li = _ref1.li, input = _ref1.input;

classer = React.addons.classSet;

FilePicker = require('./file_picker');

MailsInput = require('./mails_input');

Spinner = require('./basic_components').Spinner;

AccountPicker = require('./account_picker');

_ref2 = require('../constants/app_constants'), ComposeActions = _ref2.ComposeActions, Tooltips = _ref2.Tooltips;

FileUtils = require('../utils/file_utils');

MessageUtils = require('../utils/message_utils');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

RouterMixin = require('../mixins/router_mixin');

module.exports = Compose = React.createClass({
  displayName: 'Compose',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  propTypes: {
    selectedAccountID: React.PropTypes.string.isRequired,
    selectedAccountLogin: React.PropTypes.string.isRequired,
    layout: React.PropTypes.string,
    accounts: React.PropTypes.object.isRequired,
    message: React.PropTypes.object,
    action: React.PropTypes.string,
    callback: React.PropTypes.func,
    onCancel: React.PropTypes.func,
    settings: React.PropTypes.object.isRequired,
    useIntents: React.PropTypes.bool.isRequired
  },
  getDefaultProps: function() {
    return {
      layout: 'full'
    };
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var classBcc, classCc, classInput, classLabel, closeUrl, focusEditor, labelSend, onCancel, toggleFullscreen, _ref3, _ref4;
    if (!this.props.accounts) {
      return;
    }
    onCancel = (function(_this) {
      return function(e) {
        e.preventDefault();
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
    toggleFullscreen = function() {
      return LayoutActionCreator.toggleFullscreen();
    };
    closeUrl = this.buildClosePanelUrl(this.props.layout);
    classLabel = 'compose-label';
    classInput = 'compose-input';
    classCc = this.state.ccShown ? ' shown ' : '';
    classBcc = this.state.bccShown ? ' shown ' : '';
    if (this.state.sending) {
      labelSend = t('compose action sending');
    } else {
      labelSend = t('compose action send');
    }
    focusEditor = Array.isArray(this.state.to) && this.state.to.length > 0 && this.state.subject !== '';
    return section({
      className: classer({
        compose: true,
        panel: this.props.layout === 'full'
      }),
      'aria-expanded': true
    }, h3({
      'data-message-id': ((_ref3 = this.props.message) != null ? _ref3.get('id') : void 0) || ''
    }, this.state.subject || t('compose')), form({
      className: 'form-compose',
      method: 'POST'
    }, div({
      className: 'form-group account'
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
      valueLink: this.linkState('accountID')
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
      placeholder: t('compose cc help'),
      ref: 'cc'
    }), MailsInput({
      id: 'compose-bcc',
      className: 'compose-bcc' + classBcc,
      valueLink: this.linkState('bcc'),
      label: t('compose bcc'),
      placeholder: t('compose bcc help'),
      ref: 'bcc'
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
      messageID: (_ref4 = this.props.message) != null ? _ref4.get('id') : void 0,
      html: this.linkState('html'),
      text: this.linkState('text'),
      accounts: this.props.accounts,
      accountID: this.state.accountID,
      settings: this.props.settings,
      onSend: this.onSend,
      composeInHTML: this.state.composeInHTML,
      focus: focusEditor,
      ref: 'editor',
      getPicker: this.getPicker,
      useIntents: this.props.useIntents
    })), div({
      className: 'attachements'
    }, FilePicker({
      className: '',
      editable: true,
      valueLink: this.linkState('attachments'),
      ref: 'attachments'
    })), div({
      className: 'composeToolbox'
    }, div({
      className: 'btn-toolbar',
      role: 'toolbar'
    }, div({
      className: ''
    }, button({
      className: 'btn btn-cozy btn-send',
      type: 'button',
      disable: this.state.sending ? true : null,
      onClick: this.onSend
    }, this.state.sending ? span(null, Spinner({
      white: true
    })) : span({
      className: 'fa fa-send'
    }), span(null, labelSend)), button({
      className: 'btn btn-cozy btn-save',
      disable: this.state.saving ? true : null,
      type: 'button',
      onClick: this.onDraft
    }, this.state.saving ? span(null, Spinner({
      white: true
    })) : span({
      className: 'fa fa-save'
    }), span(null, t('compose action draft'))), this.props.message != null ? button({
      className: 'btn btn-cozy-non-default btn-delete',
      type: 'button',
      onClick: this.onDelete
    }, span({
      className: 'fa fa-trash-o'
    }), span(null, t('compose action delete'))) : void 0, button({
      onClick: onCancel,
      className: 'btn btn-cozy-non-default btn-cancel'
    }, t('app cancel'))))), div({
      className: 'clearfix'
    }, null)));
  },
  _initCompose: function() {
    if (this._saveInterval) {
      window.clearInterval(this._saveInterval);
    }
    this._saveInterval = window.setInterval(this._autosave, 30000);
    this._autosave();
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
  componentDidUpdate: function() {
    switch (this.state.focus) {
      case 'cc':
        setTimeout(function() {
          return document.getElementById('compose-cc').focus();
        }, 0);
        return this.setState({
          focus: ''
        });
      case 'bcc':
        setTimeout(function() {
          return document.getElementById('compose-bcc').focus();
        }, 0);
        return this.setState({
          focus: ''
        });
    }
  },
  componentWillUnmount: function() {
    var message, newContent, oldContent, silent, updated;
    if (this._saveInterval) {
      window.clearInterval(this._saveInterval);
    }
    if (this.state.isDraft && (this.state.id != null)) {
      if (this.state.composeInHTML) {
        newContent = MessageUtils.cleanReplyText(this.state.html).replace(/\s/gim, '');
        oldContent = MessageUtils.cleanReplyText(this.state.initHtml).replace(/\s/gim, '');
        updated = newContent !== oldContent;
      } else {
        updated = this.state.text !== this.state.initText;
      }
      silent = this.state.isNew && !updated;
      if (silent || !window.confirm(t('compose confirm keep draft'))) {
        return window.setTimeout((function(_this) {
          return function() {
            var messageID;
            messageID = _this.state.id;
            return MessageActionCreator["delete"]({
              messageID: messageID,
              silent: silent,
              isDraft: true,
              inReplyTo: _this.props.inReplyTo
            });
          };
        })(this), 0);
      } else {
        if (this.state.originalConversationID != null) {
          message = {
            id: this.state.id,
            accountID: this.state.accountID,
            mailboxIDs: this.state.mailboxIDs,
            from: this.state.from,
            to: this.state.to,
            cc: this.state.cc,
            bcc: this.state.bcc,
            subject: this.state.subject,
            isDraft: true,
            attachments: this.state.attachments,
            inReplyTo: this.state.inReplyTo,
            references: this.state.references,
            text: this.state.text,
            html: this.state.html,
            conversationID: this.state.originalConversationID
          };
          return MessageActionCreator.send(message, function(error, message) {
            var cid, msg;
            if (error != null) {
              msg = "" + (t("message action draft ko")) + " " + error;
              return LayoutActionCreator.alertError(msg);
            } else {
              msg = "" + (t("message action draft ok"));
              LayoutActionCreator.notify(msg, {
                autoclose: true
              });
              if (message.conversationID != null) {
                cid = message.conversationID;
                return MessageActionCreator.fetchConversation(cid);
              }
            }
          });
        }
      }
    }
  },
  getInitialState: function() {
    var account, key, message, state, value, _ref3;
    if (message = this.props.message) {
      state = {
        composeInHTML: this.props.settings.get('composeInHTML'),
        isNew: false
      };
      if ((message.get('html') == null) && message.get('text')) {
        state.conposeInHTML = false;
      }
      _ref3 = message.toJS();
      for (key in _ref3) {
        value = _ref3[key];
        state[key] = value;
      }
      state.attachments = message.get('attachments');
    } else {
      account = this.props.accounts[this.props.selectedAccountID];
      state = MessageUtils.makeReplyMessage(account.login, this.props.inReplyTo, this.props.action, this.props.settings.get('composeInHTML'), account.signature);
      state.isNew = true;
      if (state.accountID == null) {
        state.accountID = this.props.selectedAccountID;
      }
      state.originalConversationID = state.conversationID;
    }
    state.isDraft = true;
    state.sending = false;
    state.saving = false;
    state.ccShown = Array.isArray(state.cc) && state.cc.length > 0;
    state.bccShown = Array.isArray(state.bcc) && state.bcc.length > 0;
    state.initHtml = state.html;
    state.initText = state.text;
    return state;
  },
  componentWillReceiveProps: function(nextProps) {
    if (nextProps.message !== this.props.message) {
      this.props.message = nextProps.message;
      return this.setState(this.getInitialState());
    }
  },
  onDraft: function(e) {
    e.preventDefault();
    return this._doSend(true);
  },
  onSend: function(e) {
    if (e != null) {
      e.preventDefault();
    }
    return this._doSend(false);
  },
  _doSend: function(isDraft) {
    var account, from, message, valid;
    account = this.props.accounts[this.state.accountID];
    from = {
      name: account.name || void 0,
      address: account.login
    };
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
      attachments: this.state.attachments,
      inReplyTo: this.state.inReplyTo,
      references: this.state.references
    };
    if (!isDraft) {
      message.conversationID = this.state.originalConversationID;
    }
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
        setTimeout((function(_this) {
          return function() {
            return _this.refs.subject.getDOMNode().focus();
          };
        })(this), 0);
      }
    }
    if (valid) {
      if (this.state.composeInHTML) {
        message.html = this._cleanHTML(this.state.html);
        message.text = MessageUtils.cleanReplyText(message.html);
        message.html = MessageUtils.wrapReplyHtml(message.html);
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
          sending: true,
          isDraft: false
        });
      }
      return MessageActionCreator.send(message, (function(_this) {
        return function(error, message) {
          var cid, key, msgKo, msgOk, state, value;
          if ((error == null) && (_this.state.id == null)) {
            MessageActionCreator.setCurrent(message.id);
          }
          state = _.clone(_this.state);
          if (isDraft) {
            state.saving = false;
          } else {
            state.isDraft = false;
            state.sending = false;
          }
          for (key in message) {
            value = message[key];
            if (key !== 'attachments' && key !== 'html' && key !== 'text') {
              state[key] = value;
            }
          }
          if (_this.isMounted()) {
            _this.setState(state);
          }
          if (isDraft) {
            msgKo = t("message action draft ko");
          } else {
            msgKo = t("message action sent ko");
            msgOk = t("message action sent ok");
          }
          if (error != null) {
            return LayoutActionCreator.alertError("" + msgKo + " " + error);
          } else {
            if (!isDraft) {
              LayoutActionCreator.notify(msgOk, {
                autoclose: true
              });
            }
            if (_this.state.id == null) {
              MessageActionCreator.setCurrent(message.id);
            }
            if (!isDraft) {
              if (message.conversationID != null) {
                cid = message.conversationID;
                MessageActionCreator.fetchConversation(cid);
              }
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
    if (this.props.settings.get('autosaveDraft')) {
      return this._doSend(true);
    }
  },
  _cleanHTML: function(html) {
    var doc, image, imageSrc, images, parser, _i, _len;
    parser = new DOMParser();
    doc = parser.parseFromString(html, "text/html");
    if (!doc) {
      doc = document.implementation.createHTMLDocument("");
      doc.documentElement.innerHTML = html;
    }
    if (doc) {
      imageSrc = function(image) {
        return image.setAttribute('src', "cid:" + image.dataset.src);
      };
      images = doc.querySelectorAll('IMG[data-src]');
      for (_i = 0, _len = images.length; _i < _len; _i++) {
        image = images[_i];
        imageSrc(image);
      }
      return doc.documentElement.innerHTML;
    } else {
      console.error("Unable to parse HTML content of message");
      return html;
    }
  },
  onDelete: function(e) {
    var confirmMessage, messageID, params, subject;
    e.preventDefault();
    subject = this.props.message.get('subject');
    if ((subject != null) && subject !== '') {
      params = {
        subject: this.props.message.get('subject')
      };
      confirmMessage = t('mail confirm delete', params);
    } else {
      confirmMessage = t('mail confirm delete nosubject');
    }
    if (window.confirm(confirmMessage)) {
      messageID = this.props.message.get('id');
      return MessageActionCreator["delete"]({
        messageID: messageID
      }, (function(_this) {
        return function(error) {
          var parameters;
          if (error == null) {
            if (_this.props.callback) {
              return _this.props.callback();
            } else {
              parameters = [_this.props.selectedAccountID, _this.props.selectedMailboxID];
              return _this.redirect({
                direction: 'first',
                action: 'account.mailbox.messages',
                parameters: parameters,
                fullWidth: true
              });
            }
          }
        };
      })(this));
    }
  },
  onToggleCc: function(e) {
    var focus, toggle, _i, _len, _ref3;
    toggle = function(e) {
      return e.classList.toggle('shown');
    };
    _ref3 = this.getDOMNode().querySelectorAll('.compose-cc');
    for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
      e = _ref3[_i];
      toggle(e);
    }
    focus = !this.state.ccShown ? 'cc' : '';
    return this.setState({
      ccShown: !this.state.ccShown,
      focus: focus
    });
  },
  onToggleBcc: function(e) {
    var focus, toggle, _i, _len, _ref3;
    toggle = function(e) {
      return e.classList.toggle('shown');
    };
    _ref3 = this.getDOMNode().querySelectorAll('.compose-bcc');
    for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
      e = _ref3[_i];
      toggle(e);
    }
    focus = !this.state.bccShown ? 'bcc' : '';
    return this.setState({
      bccShown: !this.state.bccShown,
      focus: focus
    });
  },
  getPicker: function() {
    return this.refs.attachments;
  }
});

ComposeEditor = React.createClass({
  displayName: 'ComposeEditor',
  mixins: [React.addons.LinkedStateMixin],
  getInitialState: function() {
    return {
      html: this.props.html,
      text: this.props.text,
      target: false
    };
  },
  componentWillReceiveProps: function(nextProps) {
    if (nextProps.messageID !== this.props.messageID) {
      return this.setState({
        html: nextProps.html,
        text: nextProps.text
      });
    }
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  onHTMLChange: function(event) {
    return this.props.html.requestChange(this.refs.html.getDOMNode().innerHTML);
  },
  onTextChange: function(event) {
    return this.props.text.requestChange(this.refs.content.getDOMNode().value);
  },
  render: function() {
    var classFolded, classTarget;
    if (this.props.settings.get('composeOnTop')) {
      classFolded = 'folded';
    } else {
      classFolded = '';
    }
    classTarget = this.state.target ? 'target' : '';
    return div(null, this.props.useIntents ? div({
      className: "btn-group editor-actions"
    }, button({
      className: "btn btn-default",
      onClick: this.choosePhoto
    }, span({
      className: 'fa fa-image',
      'aria-describedby': Tooltips.COMPOSE_IMAGE,
      'data-tooltip-direction': 'top'
    }))) : void 0, this.props.composeInHTML ? div({
      className: "form-control rt-editor " + classFolded + " " + classTarget,
      ref: 'html',
      contentEditable: true,
      onKeyDown: this.onKeyDown,
      onInput: this.onHTMLChange,
      onDragOver: this.allowDrop,
      onDragEnter: this.onDragEnter,
      onDragLeave: this.onDragLeave,
      onDrop: this.handleFiles,
      onBlur: this.onHTMLChange,
      dangerouslySetInnerHTML: {
        __html: this.state.html.value
      }
    }) : textarea({
      className: "editor " + classTarget,
      ref: 'content',
      onKeyDown: this.onKeyDown,
      onChange: this.onTextChange,
      onBlur: this.onTextChange,
      defaultValue: this.state.text.value,
      onDragOver: this.allowDrop,
      onDragEnter: this.onDragEnter,
      onDragLeave: this.onDragLeave,
      onDrop: this.handleFiles
    }));
  },
  _initCompose: function() {
    var e, gecko, header, node, range, rect;
    if (this.props.composeInHTML) {
      this.setCursorPosition();
      gecko = document.queryCommandEnabled('insertBrOnReturn');
      jQuery('.rt-editor').on('keypress', function(e) {
        var quote;
        if (e.keyCode !== 13) {
          return;
        }
        quote = function() {
          var br, depth, getPath, isInsideQuote, node, range, selection, target, targetElement;
          isInsideQuote = function(node) {
            var matchesSelector;
            matchesSelector = document.documentElement.matches || document.documentElement.matchesSelector || document.documentElement.webkitMatchesSelector || document.documentElement.mozMatchesSelector || document.documentElement.oMatchesSelector || document.documentElement.msMatchesSelector;
            if (matchesSelector != null) {
              return matchesSelector.call(node, '.rt-editor blockquote, .rt-editor blockquote *');
            } else {
              while ((node != null) && node.tagName !== 'BLOCKQUOTE') {
                node = node.parentNode;
              }
              return node.tagName === 'BLOCKQUOTE';
            }
          };
          target = document.getSelection().anchorNode;
          if (target.lastChild != null) {
            target = target.lastChild;
            if (target.previousElementSibling != null) {
              target = target.previousElementSibling;
            }
          }
          targetElement = target;
          while (targetElement && !(targetElement instanceof Element)) {
            targetElement = targetElement.parentNode;
          }
          if (target == null) {
            return;
          }
          if (!isInsideQuote(targetElement)) {
            return;
          }
          if (gecko) {
            br = "\r\n<br>\r\n<br class='cozyInsertedBr'>\r\n";
          } else {
            br = "\r\n<div></div><div><br class='cozyInsertedBr'></div>\r\n";
          }
          document.execCommand('insertHTML', false, br);
          node = document.querySelector('.cozyInsertedBr');
          if (gecko) {
            node = node.previousElementSibling;
          }
          getPath = function(node) {
            var path;
            path = node.tagName;
            while ((node.parentNode != null) && node.contentEditable !== 'true') {
              node = node.parentNode;
              path = "" + node.tagName + " > " + path;
            }
            return path;
          };
          selection = window.getSelection();
          range = document.createRange();
          range.selectNode(node);
          selection.removeAllRanges();
          selection.addRange(range);
          depth = getPath(node).split('>').length;
          while (depth > 0) {
            document.execCommand('outdent', false, null);
            depth--;
          }
          node = document.querySelector('.cozyInsertedBr');
          if (node != null) {
            node.parentNode.removeChild(node);
          }
          document.execCommand('removeFormat', false, null);
        };
        return setTimeout(quote, 50);
      });
      if (document.querySelector('.rt-editor blockquote') && !document.querySelector('.rt-editor .originalToggle')) {
        try {
          header = jQuery('.rt-editor blockquote').eq(0).prev();
          header.text(header.text().replace('…', ''));
          header.append('<span class="originalToggle">…</>');
          return header.on('click', function() {
            return jQuery('.rt-editor').toggleClass('folded');
          });
        } catch (_error) {
          e = _error;
          return console.error(e);
        }
      } else {
        return jQuery('.rt-editor .originalToggle').on('click', function() {
          return jQuery('.rt-editor').toggleClass('folded');
        });
      }
    } else {
      if (this.props.focus) {
        node = this.refs.content.getDOMNode();
        if (!this.props.settings.get('composeOnTop')) {
          rect = node.getBoundingClientRect();
          node.scrollTop = node.scrollHeight - rect.height;
          if (typeof node.selectionStart === "number") {
            node.selectionStart = node.value.length;
            node.selectionEnd = node.value.length;
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
  setCursorPosition: function() {
    var account, node, range, selection, signatureNode, _ref3;
    if (this.props.focus) {
      node = (_ref3 = this.refs.html) != null ? _ref3.getDOMNode() : void 0;
      if (node != null) {
        document.querySelector(".rt-editor").focus();
        if (!this.props.settings.get('composeOnTop')) {
          account = this.props.accounts[this.props.accountID];
          signatureNode = document.getElementById("signature");
          if ((account.signature != null) && account.signature.length > 0 && (signatureNode != null)) {
            node = signatureNode;
            node.innerHTML = "<p><br /></p>\n" + node.innerHTML;
            node = node.firstChild;
          } else {
            node.innerHTML += "<p><br /></p><p><br /></p>";
            node = node.lastChild;
          }
          if (node != null) {
            node.scrollIntoView(false);
            node.innerHTML = "<br \>";
            selection = window.getSelection();
            range = document.createRange();
            range.selectNodeContents(node);
            selection.removeAllRanges();
            selection.addRange(range);
            document.execCommand('delete', false, null);
            return node.focus();
          }
        }
      }
    }
  },
  componentDidMount: function() {
    return this._initCompose();
  },
  componentDidUpdate: function(oldProps, oldState) {
    var node, oldSig, signature, signatureHtml, signatureNode;
    if (oldProps.messageID !== this.props.messageID) {
      this._initCompose();
    }
    if (oldProps.accountID !== this.props.accountID) {
      signature = this.props.accounts[this.props.accountID].signature;
      if (this.refs.html != null) {
        signatureNode = document.getElementById("signature");
        if ((signature != null) && signature.length > 0) {
          signatureHtml = signature.replace(/\n/g, '<br>');
          if (signatureNode != null) {
            signatureNode.innerHTML = "-- \n<br>" + signatureHtml + "</p>";
          } else {
            this.refs.html.getDOMNode().innerHTML += "<p><br></p><p id=\"signature\">-- \n<br>" + signatureHtml + "</p>";
          }
        } else {
          if (signatureNode != null) {
            signatureNode.parentNode.removeChild(signatureNode);
          }
        }
        return this.onHTMLChange();
      } else if (this.refs.content != null) {
        node = this.refs.content.getDOMNode();
        oldSig = this.props.accounts[oldProps.accountID].signature;
        if ((signature != null) && signature.length > 0) {
          if (oldSig && oldSig.length > 0) {
            node.textContent = node.textContent.replace(oldSig, signature);
          } else {
            node.textContent += "\n\n-- \n" + signature;
          }
        } else {
          if (oldSig && oldSig.length > 0) {
            oldSig = "-- \n" + signature;
            node.textContent = node.textContent.replace(oldSig, '');
          }
        }
        return this.onTextChange();
      }
    }
  },
  onKeyDown: function(evt) {
    if (evt.ctrlKey && evt.key === 'Enter') {
      return this.props.onSend();
    }
  },

  /*
   * Handle dropping of images inside editor
   */
  allowDrop: function(e) {
    return e.preventDefault();
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
  handleFiles: function(e) {
    var file, files, id, img, signature, _i, _len;
    e.preventDefault();
    files = e.target.files || e.dataTransfer.files;
    this.props.getPicker().addFiles(files);
    if (this.props.composeInHTML) {
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        if (file.type.split('/')[0] === 'image') {
          id = "editor-img-" + (new Date());
          img = "<img data-src='" + file.name + "' id='" + id + "'>";
          if (!document.activeElement.classList.contains('rt-editor')) {
            signature = document.getElementById('signature');
            if (signature != null) {
              signature.previousElementSibling.innerHTML += img;
            } else {
              document.querySelector('.rt-editor').innerHTML += img;
            }
          } else {
            document.execCommand('insertHTML', false, img);
          }
          FileUtils.fileToDataURI(file, (function(_this) {
            return function(result) {
              img = document.getElementById(id);
              if (img) {
                img.removeAttribute('id');
                img.src = result;
                return _this.onHTMLChange();
              }
            };
          })(this));
        }
      }
    }
    return this.setState({
      target: false
    });
  },
  choosePhoto: function(e) {
    var intent, timeout;
    e.preventDefault();
    intent = {
      type: 'pickObject',
      params: {
        objectType: 'singlePhoto',
        isCropped: false
      }
    };
    timeout = 30000;
    return window.intentManager.send('nameSpace', intent, timeout).then(this.choosePhoto_answer, function(error) {
      return console.log('response in error : ', error);
    });
  },
  choosePhoto_answer: function(message) {
    var answer, blob, data, editor, img, picker, signature;
    answer = message.data;
    if (answer.newPhotoChosen) {
      data = FileUtils.dataURItoBlob(answer.dataUrl);
      blob = new Blob([
        data.blob, {
          type: data.mime
        }
      ]);
      blob.name = answer.name;
      picker = this.props.getPicker();
      picker.addFiles([blob]);
      if (this.props.composeInHTML) {
        if (document.activeElement.classList.contains('rt-editor')) {
          document.execCommand('insertHTML', false, '<img src="' + answer.dataUrl + '" data-src="' + answer.name + '">');
        } else {
          img = document.createElement('img');
          img.src = answer.dataUrl;
          img.dataset.src = answer.name;
          signature = document.getElementById('signature');
          if (signature != null) {
            signature.parentNode.insertBefore(img, signature);
          } else {
            editor = document.querySelector('.rt-editor');
            if (editor != null) {
              editor.appendChild(img);
            }
          }
        }
        return this.onHTMLChange();
      }
    }
  }
});
});

;require.register("components/contact_label", function(exports, require, module) {
var AddressLabel, ContactActionCreator, ContactLabel, ContactStore, StoreWatchMixin, a, button, h3, header, i, li, messageUtils, p, section, span, ul, _ref;

_ref = React.DOM, section = _ref.section, header = _ref.header, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a, button = _ref.button;

messageUtils = require('../utils/message_utils');

ContactStore = require('../stores/contact_store');

StoreWatchMixin = require('../mixins/store_watch_mixin');

ContactActionCreator = require('../actions/contact_action_creator');

AddressLabel = require('./basic_components').AddressLabel;

module.exports = ContactLabel = React.createClass({
  mixins: [StoreWatchMixin([ContactStore])],
  getStateFromStores: function() {
    return {};
  },
  render: function() {
    var contactModel;
    if (this.props.contact != null) {
      contactModel = ContactStore.getByAddress(this.props.contact.address);
      if (contactModel != null) {
        return a({
          target: '_blank',
          href: "/#apps/contacts/contact/" + (contactModel.get('id')),
          onClick: function(event) {
            return event.stopPropagation();
          }
        }, AddressLabel({
          contact: this.props.contact
        }));
      } else {
        return span({
          className: 'participant',
          onClick: this.onContactClicked
        }, AddressLabel({
          contact: this.props.contact
        }));
      }
    } else {
      return span(null);
    }
  },
  onContactClicked: function(event) {
    var params;
    params = {
      contact: messageUtils.displayAddress(this.props.contact)
    };
    if (confirm(t('message contact creation', params))) {
      ContactActionCreator.createContact(this.props.contact);
    }
    return event.stopPropagation();
  }
});
});

;require.register("components/conversation", function(exports, require, module) {
var LayoutActionCreator, Message, MessageFlags, RouterMixin, Toolbar, a, button, classer, h3, header, i, li, p, section, span, ul, _ref,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ref = React.DOM, section = _ref.section, header = _ref.header, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a, button = _ref.button;

Message = require('./message');

Toolbar = require('./toolbar_conversation');

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

MessageFlags = require('../constants/app_constants').MessageFlags;

LayoutActionCreator = require('../actions/layout_action_creator');

module.exports = React.createClass({
  displayName: 'Conversation',
  mixins: [RouterMixin],
  propTypes: {
    message: React.PropTypes.object,
    conversation: React.PropTypes.object,
    selectedAccountID: React.PropTypes.string.isRequired,
    selectedAccountLogin: React.PropTypes.string.isRequired,
    selectedMailboxID: React.PropTypes.string,
    mailboxes: React.PropTypes.object.isRequired,
    settings: React.PropTypes.object.isRequired,
    accounts: React.PropTypes.object.isRequired,
    displayConversations: React.PropTypes.bool,
    useIntents: React.PropTypes.bool.isRequired
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  getInitialState: function() {
    return {
      expanded: []
    };
  },
  renderToolbar: function() {
    return Toolbar({
      readability: this.props.readability,
      nextMessageID: this.props.nextMessageID,
      nextConversationID: this.props.nextConversationID,
      prevMessageID: this.props.prevMessageID,
      prevConversationID: this.props.prevConversationID,
      settings: this.props.settings
    });
  },
  renderMessage: function(key, active) {
    var setActive;
    setActive = (function(_this) {
      return function(id) {
        return _this.props.conversation.map(function(message, key) {
          if (message.get('id') === id) {
            return _this._activeKey = key;
          }
        }).toJS();
      };
    })(this);
    return Message({
      ref: 'message',
      accounts: this.props.accounts,
      active: active,
      inConversation: this.props.conversation.length > 1,
      key: key.toString(),
      mailboxes: this.props.mailboxes,
      message: this.props.conversation.get(key),
      selectedAccountID: this.props.selectedAccountID,
      selectedAccountLogin: this.props.selectedAccountLogin,
      selectedMailboxID: this.props.selectedMailboxID,
      settings: this.props.settings,
      displayConversations: this.props.displayConversation,
      useIntents: this.props.useIntents,
      setActive: setActive
    });
  },
  renderGroup: function(messages, key) {
    var first, items, last;
    if (messages.length > 3 && __indexOf.call(this.state.expanded, key) < 0) {
      items = [];
      first = messages[0], last = messages[messages.length - 1];
      items.push(this.renderMessage(first, false));
      items.push(button({
        className: 'more',
        onClick: (function(_this) {
          return function() {
            var expanded;
            expanded = _this.state.expanded.slice(0);
            expanded.push(key);
            return _this.setState({
              expanded: expanded
            });
          };
        })(this)
      }, t('load more messages', messages.length - 2), i({
        className: 'fa fa-ellipsis-v'
      })));
      items.push(this.renderMessage(last, false));
    } else {
      items = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = messages.length; _i < _len; _i++) {
          key = messages[_i];
          _results.push(this.renderMessage(key, false));
        }
        return _results;
      }).call(this);
    }
    return items;
  },
  render: function() {
    var glob, index, lastMessageIndex, messages;
    if ((this.props.message == null) || !this.props.conversation) {
      return p(null, t("app loading"));
    }
    messages = [];
    lastMessageIndex = this.props.conversation.length - 1;
    this.props.conversation.map((function(_this) {
      return function(message, key) {
        var isSeen, last, _ref1;
        isSeen = (_ref1 = MessageFlags.SEEN, __indexOf.call(message.get('flags'), _ref1) >= 0);
        if (((_this._activeKey == null) && (!isSeen || key === lastMessageIndex)) || key === _this._activeKey) {
          messages.push(key);
          return _this._activeKey = key;
        } else {
          last = messages[messages.length - 1];
          if (!_.isArray(last)) {
            messages.push(last = []);
          }
          return last.push(key);
        }
      };
    })(this)).toJS();
    return section({
      key: 'conversation',
      className: 'conversation panel',
      'aria-expanded': true
    }, header(null, h3({
      className: 'conversation-title',
      'data-message-id': this.props.message.get('id')
    }, this.props.message.get('subject')), this.renderToolbar(), a({
      className: 'clickable btn btn-default fa fa-close',
      href: this.buildClosePanelUrl('second'),
      onClick: LayoutActionCreator.minimizePreview
    })), (function() {
      var _i, _len, _results;
      _results = [];
      for (index = _i = 0, _len = messages.length; _i < _len; index = ++_i) {
        glob = messages[index];
        if (_.isArray(glob)) {
          _results.push(this.renderGroup(glob, index));
        } else {
          _results.push(this.renderMessage(glob, true));
        }
      }
      return _results;
    }).call(this));
  }
});
});

;require.register("components/date_range_picker", function(exports, require, module) {
var DateRangePicker, Tooltips, button, datePickerFormat, div, i, input, li, momentFormat, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, button = _ref.button, input = _ref.input;

Tooltips = require('../constants/app_constants').Tooltips;

momentFormat = 'DD/MM/YYYY';

datePickerFormat = '%d/%m/%Y';

module.exports = DateRangePicker = React.createClass({
  displayName: 'DateRangePicker',
  propTypes: {
    active: React.PropTypes.bool,
    onDateFilter: React.PropTypes.func.isRequired
  },
  getInitialState: function() {
    return {
      isActive: this.props.active,
      label: t('daterangepicker placeholder'),
      startDate: '',
      endDate: ''
    };
  },
  componentWillReceiveProps: function(nextProps) {
    if (this.state.isActive && !nextProps.active) {
      return this.reset();
    }
  },
  onStartChange: function(obj) {
    var date;
    date = obj.target != null ? obj.target.value : "" + obj.dd + "/" + obj.mm + "/" + obj.yyyy;
    return this.setState({
      startDate: date
    }, this.filterize);
  },
  onEndChange: function(obj) {
    var date;
    date = obj.target ? obj.target.value : "" + obj.dd + "/" + obj.mm + "/" + obj.yyyy;
    return this.setState({
      endDate: date
    }, this.filterize);
  },
  filterize: function() {
    var d, end, m, start, y, _ref1, _ref2;
    if (!this.state.startDate ^ !this.state.endDate) {
      return;
    }
    start = this.state.startDate ? ((_ref1 = this.state.startDate.split('/'), d = _ref1[0], m = _ref1[1], y = _ref1[2], _ref1), "" + y + "-" + m + "-" + d + "T00:00:00.000Z") : void 0;
    end = this.state.endDate ? ((_ref2 = this.state.endDate.split('/'), d = _ref2[0], m = _ref2[1], y = _ref2[2], _ref2), "" + y + "-" + m + "-" + d + "T23:59:59.999Z") : void 0;
    this.setState({
      isActive: !!this.state.startDate && !!this.state.endDate
    });
    return this.props.onDateFilter(start, end);
  },
  reset: function() {
    return this.setState({
      isActive: false,
      startDate: '',
      endDate: ''
    }, this.filterize);
  },
  presetYesterday: function() {
    return this.setState({
      startDate: moment().subtract(1, 'day').format(momentFormat),
      endDate: moment().subtract(1, 'day').format(momentFormat)
    }, this.filterize);
  },
  presetLastWeek: function() {
    return this.setState({
      startDate: moment().subtract(1, 'week').format(momentFormat),
      endDate: moment().format(momentFormat)
    }, this.filterize);
  },
  presetLastMonth: function() {
    return this.setState({
      startDate: moment().subtract(1, 'month').format(momentFormat),
      endDate: moment().format(momentFormat)
    }, this.filterize);
  },
  render: function() {
    return div({
      className: 'dropdown date-range-picker',
      'aria-describedby': Tooltips.FILTER_DATE_RANGE,
      'data-tooltip-direction': 'bottom'
    }, button({
      className: 'dropdown-toggle',
      role: 'menuitem',
      'data-toggle': 'dropdown',
      'aria-selected': this.state.isActive
    }, i({
      className: 'fa fa-calendar'
    }), span({
      className: 'btn-label'
    }, "" + this.state.label + " "), span({
      className: 'caret'
    })), div({
      className: 'dropdown-menu'
    }, ul({
      className: 'presets list-unstyled'
    }, li({
      role: 'presentation'
    }, button({
      role: 'menuitem',
      onClick: this.presetYesterday
    }, t('daterangepicker presets yesterday'))), li({
      role: 'presentation'
    }, button({
      role: 'menuitem',
      onClick: this.presetLastWeek
    }, t('daterangepicker presets last week'))), li({
      role: 'presentation'
    }, button({
      role: 'menuitem',
      onClick: this.presetLastMonth
    }, t('daterangepicker presets last month'))), li({
      role: 'presentation'
    }, button({
      role: 'menuitem',
      onClick: this.reset
    }, t('daterangepicker clear')))), div({
      className: 'date-pickers'
    }, input({
      ref: "date-range-picker-start",
      id: "date-range-picker-start",
      type: 'text',
      name: "date-range-picker-start",
      value: this.state.startDate,
      onChange: this.onStartChange
    }), input({
      ref: "date-range-picker-end",
      id: "date-range-picker-end",
      type: 'text',
      name: "date-range-picker-end",
      value: this.state.endDate,
      onChange: this.onEndChange
    }))));
  },
  initDatepicker: function() {
    var options;
    options = {
      staticPos: true,
      fillGrid: true,
      hideInput: true
    };
    datePickerController.createDatePicker(_.extend({}, options, {
      formElements: {
        'date-range-picker-start': datePickerFormat
      },
      callbackFunctions: {
        datereturned: [this.onStartChange]
      }
    }));
    return datePickerController.createDatePicker(_.extend({}, options, {
      formElements: {
        'date-range-picker-end': datePickerFormat
      },
      callbackFunctions: {
        datereturned: [this.onEndChange]
      }
    }));
  },
  componentDidMount: function() {
    return this.initDatepicker();
  },
  componentDidUpdate: function() {
    datePickerController.setDateFromInput('date-range-picker-start');
    return datePickerController.setDateFromInput('date-range-picker-end');
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
 * - messageID: string
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
    }),
    messageID: React.PropTypes.string
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
      files: this.props.value || this.props.valueLink.value,
      target: false
    };
  },
  componentWillReceiveProps: function(props) {
    return this.setState({
      files: props.value || props.valueLink.value
    });
  },
  addFiles: function(files) {
    var file;
    files = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        _results.push(this._fromDOM(file));
      }
      return _results;
    }).call(this);
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
    var classMain, classZone;
    classMain = 'file-picker';
    if (this.props.className) {
      classMain += " " + this.props.className;
    }
    classZone = 'dropzone';
    if (this.state.target) {
      classZone += " target";
    }
    return div({
      className: classMain
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
          },
          messageID: _this.props.messageID
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
      className: classZone,
      ref: "dropzone",
      onDragOver: this.allowDrop,
      onDragEnter: this.onDragEnter,
      onDragLeave: this.onDragLeave,
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
  handleFiles: function(e) {
    var files;
    e.preventDefault();
    files = e.target.files || e.dataTransfer.files;
    this.addFiles(files);
    return this.setState({
      target: false
    });
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
      contentId: file.name,
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
 *  - (messageID): string
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
    "delete": React.PropTypes.func,
    messageID: React.PropTypes.string
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
    if (!(file.url != null) && !file.rawFileObject) {
      window.cozyMails.log(new Error("Wrong file " + (JSON.stringify(file))));
      file.url = "message/" + this.props.messageID + "/attachments/" + file.generatedFileName;
    }
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
      key: this.props.key
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
      'data-file-url': file.url,
      'data-file-name': file.generatedFileName,
      'data-file-type': file.contentType
    }, file.generatedFileName), div({
      className: 'file-detail'
    }, span(null, "" + ((file.length / 1000).toFixed(2)) + "Ko"), span({
      className: 'file-actions'
    }, a({
      className: "fa fa-download",
      href: "" + file.url + "?download=1"
    }))));
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

;require.register("components/mailbox_list", function(exports, require, module) {
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
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var key, mailbox, selected, selectedID;
    selectedID = this.props.selectedMailboxID;
    if ((this.props.mailboxes != null) && Object.keys(this.props.mailboxes).length > 0) {
      if (selectedID != null) {
        selected = this.props.mailboxes[selectedID];
      }
      return div({
        className: 'btn-group btn-group-sm dropdown pull-left'
      }, button({
        className: 'btn btn-default dropdown-toggle',
        type: 'button',
        'data-toggle': 'dropdown'
      }, (selected != null ? selected.label : void 0) || t('mailbox pick one'), span({
        className: 'caret'
      }, '')), ul({
        className: 'dropdown-menu',
        role: 'menu'
      }, this.props.allowUndefined && (selected != null) ? li({
        role: 'presentation',
        key: null,
        onClick: this.onChange.bind(this, null)
      }, a({
        role: 'menuitem'
      }, t('mailbox pick null'))) : void 0, (function() {
        var _ref1, _results;
        _ref1 = this.props.mailboxes;
        _results = [];
        for (key in _ref1) {
          mailbox = _ref1[key];
          if (key !== selectedID) {
            _results.push(this.getMailboxRender(mailbox, key));
          }
        }
        return _results;
      }).call(this)));
    } else {
      return div(null, "");
    }
  },
  getMailboxRender: function(mailbox, key) {
    var i, onChange, pusher, url, _base, _i, _ref1;
    url = typeof (_base = this.props).getUrl === "function" ? _base.getUrl(mailbox) : void 0;
    onChange = this.onChange.bind(this, key);
    pusher = "";
    for (i = _i = 1, _ref1 = mailbox.depth; _i <= _ref1; i = _i += 1) {
      pusher += "--";
    }
    return li({
      role: 'presentation',
      key: key,
      onClick: onChange
    }, url != null ? a({
      href: url,
      role: 'menuitem'
    }, "" + pusher + mailbox.label) : a({
      role: 'menuitem'
    }, "" + pusher + mailbox.label));
  }
});
});

;require.register("components/mails_input", function(exports, require, module) {
var ContactActionCreator, ContactStore, LayoutActionCreator, MailsInput, MessageUtils, Modal, a, classer, div, i, img, label, li, span, textarea, ul, _ref;

_ref = React.DOM, div = _ref.div, label = _ref.label, textarea = _ref.textarea, span = _ref.span, ul = _ref.ul, li = _ref.li, a = _ref.a, img = _ref.img, i = _ref.i;

MessageUtils = require('../utils/message_utils');

Modal = require('./modal');

ContactStore = require('../stores/contact_store');

ContactActionCreator = require('../actions/contact_action_creator');

LayoutActionCreator = require('../actions/layout_action_creator');

classer = React.addons.classSet;

module.exports = MailsInput = React.createClass({
  displayName: 'MailsInput',
  getStateFromStores: function() {
    return {
      contacts: ContactStore.getResults()
    };
  },
  componentWillMount: function() {
    return this.setState({
      contacts: null,
      open: false
    });
  },
  getInitialState: function() {
    var state;
    state = this.getStateFromStores();
    state.known = this.props.valueLink.value;
    state.unknown = '';
    state.selected = 0;
    state.open = false;
    return state;
  },
  componentWillReceiveProps: function(nextProps) {
    return this.setState({
      known: nextProps.valueLink.value
    });
  },
  componentDidMount: function() {
    ContactStore.on('change', this._setStateFromStores);
    return this.fixHeight();
  },
  componentWillUnmount: function() {
    return ContactStore.removeListener('change', this._setStateFromStores);
  },
  _setStateFromStores: function() {
    return this.setState(this.getStateFromStores());
  },
  componentDidUpdate: function() {
    return this.fixHeight();
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var cancelDragEvent, classLabel, className, current, knownContacts, listClass, onChange, renderTag, _ref1;
    renderTag = (function(_this) {
      return function(address, idx) {
        var display, onDragEnd, onDragStart, remove;
        remove = function() {
          var known;
          known = _this.state.known.filter(function(a) {
            return a.address !== address.address;
          });
          return _this.props.valueLink.requestChange(known);
        };
        onDragStart = function(event) {
          var data;
          event.stopPropagation();
          if (address != null) {
            data = {
              name: address.name,
              address: address.address
            };
            event.dataTransfer.setData('address', JSON.stringify(data));
            event.dataTransfer.effectAllowed = 'all';
            return event.dataTransfer.setData(_this.props.id, true);
          }
        };
        onDragEnd = function(event) {
          if (event.dataTransfer.dropEffect === 'move') {
            return remove();
          }
        };
        if ((address.name != null) && address.name.trim() !== '') {
          display = address.name;
        } else {
          display = address.address;
        }
        return span({
          className: 'address-tag',
          draggable: true,
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
          key: "" + _this.props.id + "-" + address.address + "-" + idx,
          title: address.address
        }, display, a({
          className: 'clickable',
          onClick: remove
        }, i({
          className: 'fa fa-times'
        })));
      };
    })(this);
    knownContacts = this.state.known.map(renderTag);
    onChange = (function(_this) {
      return function(event) {
        var known, value;
        value = event.target.value.split(',');
        if (value.length === 2) {
          known = _.clone(_this.state.known);
          known.push(MessageUtils.parseAddress(value[0]));
          _this.props.valueLink.requestChange(known);
          return _this.setState({
            unknown: value[1].trim()
          });
        } else {
          return _this.setState({
            unknown: event.target.value
          });
        }
      };
    })(this);
    className = (this.props.className || '') + (" form-group " + this.props.id);
    classLabel = 'compose-label control-label';
    listClass = classer({
      'contact-form': true,
      open: this.state.open && ((_ref1 = this.state.contacts) != null ? _ref1.length : void 0) > 0
    });
    current = 0;
    cancelDragEvent = (function(_this) {
      return function(event) {
        var types;
        event.preventDefault();
        types = Array.prototype.slice.call(event.dataTransfer.types);
        if (types.indexOf(_this.props.id) === -1) {
          return event.dataTransfer.dropEffect = 'move';
        } else {
          return event.dataTransfer.dropEffect = 'none';
        }
      };
    })(this);
    return div({
      className: className,
      onDrop: this.onDrop,
      onDragEnter: cancelDragEvent,
      onDragLeave: cancelDragEvent,
      onDragOver: cancelDragEvent
    }, label({
      htmlFor: this.props.id,
      className: classLabel
    }, this.props.label), knownContacts, div({
      className: 'contact-group dropdown ' + listClass
    }, textarea({
      id: this.props.id,
      name: this.props.id,
      className: 'form-control compose-input',
      onKeyDown: this.onKeyDown,
      onBlur: this.onBlur,
      onDrop: this.onDrop,
      onDragEnter: cancelDragEvent,
      onDragLeave: cancelDragEvent,
      onDragOver: cancelDragEvent,
      ref: 'contactInput',
      rows: 1,
      value: this.state.unknown,
      onChange: onChange,
      placeholder: this.props.placeholder,
      'autoComplete': 'off',
      'spellCheck': 'off'
    }), this.state.contacts != null ? ul({
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
    var force, query;
    query = this.refs.contactInput.getDOMNode().value.split(',').pop().replace(/^\s*/, '');
    if ((char != null) && typeof char === 'string') {
      query += char;
      force = false;
    } else if ((char != null) && typeof char === 'object') {
      force = true;
    }
    if (query.length > 2 || (force && !this.state.open)) {
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
    var contact, count, node, selected, _ref1, _ref2;
    count = (_ref1 = this.state.contacts) != null ? _ref1.count() : void 0;
    selected = this.state.selected;
    switch (evt.key) {
      case "Enter":
        if (13 === evt.keyCode || 13 === evt.which) {
          this.addContactFromInput();
        }
        if (((_ref2 = this.state.contacts) != null ? _ref2.count() : void 0) > 0) {
          contact = this.state.contacts.slice(selected).first();
          this.onContact(contact);
        } else {
          this.onQuery();
        }
        evt.preventDefault();
        return false;
      case "ArrowUp":
        return this.setState({
          selected: selected === 0 ? count - 1 : selected - 1
        });
      case "ArrowDown":
        return this.setState({
          selected: selected === (count - 1) ? 0 : selected + 1
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
    return setTimeout((function(_this) {
      return function() {
        return _this.addContactFromInput(true);
      };
    })(this), 100);
  },
  addContactFromInput: function(isBlur) {
    var address, isContacts, msg, state, value, _ref1;
    if (isBlur == null) {
      isBlur = false;
    }
    if (this.isMounted()) {
      state = {};
      state.open = false;
      value = this.refs.contactInput.getDOMNode().value;
      if (value.trim() !== '') {
        address = MessageUtils.parseAddress(value);
        if (address.isValid) {
          this.state.known.push(address);
          state.known = this.state.known;
          state.unknown = '';
          this.props.valueLink.requestChange(state.known);
          return this.setState(state);
        } else {
          isContacts = ((_ref1 = this.state.contacts) != null ? _ref1.length : void 0) === 0;
          if (!isBlur && isContacts) {
            msg = t('compose wrong email format', {
              address: address.address
            });
            return LayoutActionCreator.alertError(msg);
          }
        }
      } else {
        return this.setState(state);
      }
    }
  },
  onContact: function(contact) {
    var address, known;
    address = {
      name: contact.get('fn'),
      address: contact.get('address')
    };
    known = _.clone(this.state.known);
    known.push(address);
    this.props.valueLink.requestChange(known);
    this.setState({
      unknown: '',
      contacts: null,
      open: false
    });
    return setTimeout((function(_this) {
      return function() {
        var query;
        return query = _this.refs.contactInput.getDOMNode().focus();
      };
    })(this), 200);
  },
  fixHeight: function() {
    var input;
    input = this.refs.contactInput.getDOMNode();
    if (input.scrollHeight > input.clientHeight) {
      return input.style.height = input.scrollHeight + "px";
    }
  },
  onDrop: function(event) {
    var address, exists, known, name, _ref1;
    event.preventDefault();
    event.stopPropagation();
    _ref1 = JSON.parse(event.dataTransfer.getData('address')), name = _ref1.name, address = _ref1.address;
    exists = this.state.known.some(function(item) {
      return item.name === name && item.address === address;
    });
    if ((address != null) && !exists) {
      address = {
        name: name,
        address: address
      };
      known = _.clone(this.state.known);
      known.push(address);
      this.props.valueLink.requestChange(known);
      this.setState({
        unknown: '',
        contacts: null,
        open: false
      });
      return event.dataTransfer.dropEffect = 'move';
    } else {
      return event.dataTransfer.dropEffect = 'none';
    }
  }
});
});

;require.register("components/menu", function(exports, require, module) {
var AccountActionCreator, AccountStore, Dispositions, LayoutActionCreator, LayoutStore, Menu, MenuMailboxItem, MessageActionCreator, MessageUtils, Modal, RefreshIndicator, RouterMixin, SpecialBoxIcons, StoreWatchMixin, ThinProgress, Tooltips, a, aside, button, classer, colorhash, div, i, li, nav, span, specialMailboxes, ul, _ref, _ref1,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ref = React.DOM, div = _ref.div, aside = _ref.aside, nav = _ref.nav, ul = _ref.ul, li = _ref.li, span = _ref.span, a = _ref.a, i = _ref.i, button = _ref.button;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

StoreWatchMixin = require('../mixins/store_watch_mixin');

AccountActionCreator = require('../actions/account_action_creator');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

AccountStore = require('../stores/account_store');

LayoutStore = require('../stores/layout_store');

Modal = require('./modal');

ThinProgress = require('./thin_progress');

MessageUtils = require('../utils/message_utils');

colorhash = require('../utils/colorhash');

RefreshIndicator = require('./menu_refresh_indicator');

_ref1 = require('../constants/app_constants'), Dispositions = _ref1.Dispositions, SpecialBoxIcons = _ref1.SpecialBoxIcons, Tooltips = _ref1.Tooltips;

specialMailboxes = ['inboxMailbox', 'draftMailbox', 'sentMailbox', 'trashMailbox', 'junkMailbox', 'allMailbox'];

module.exports = Menu = React.createClass({
  displayName: 'Menu',
  mixins: [RouterMixin, StoreWatchMixin([LayoutStore])],
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
  getStateFromStores: function() {
    return {
      isDrawerExpanded: LayoutStore.isDrawerExpanded()
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
    var closeLabel, closeModal, composeUrl, content, modal, modalErrors, newMailboxClass, newMailboxUrl, selectedAccountUrl, settingsClass, settingsUrl, subtitle, title, _ref2, _ref3;
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
    if (this.props.layout.firstPanel.action === 'settings' || ((_ref3 = this.props.layout.secondPanel) != null ? _ref3.action : void 0) === 'settings') {
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
    composeUrl = this.buildUrl({
      direction: 'first',
      action: 'compose',
      parameters: null,
      fullWidth: true
    });
    return aside({
      role: 'menubar',
      'aria-expanded': this.state.isDrawerExpanded
    }, modal, this.props.accounts.length ? a({
      href: composeUrl,
      className: 'compose-action btn btn-cozy-contrast btn-cozy'
    }, i({
      className: 'fa fa-pencil'
    }), span({
      className: 'item-label'
    }, " " + (t('menu compose')))) : void 0, nav({
      className: 'mainmenu'
    }, this.props.accounts.length ? this.props.accounts.map((function(_this) {
      return function(account, key) {
        return _this.getAccountRender(account, key);
      };
    })(this)).toJS() : void 0), nav({
      className: 'submenu'
    }, a({
      href: newMailboxUrl,
      role: 'menuitem',
      className: "btn new-account-action " + newMailboxClass
    }, i({
      className: 'fa fa-plus'
    }), span({
      className: 'item-label'
    }, t('menu account new'))), button({
      role: 'menuitem',
      className: classer({
        btn: true,
        fa: true,
        'drawer-toggle': true,
        'fa-toggle-right': !this.state.isDrawerExpanded,
        'fa-toggle-left': this.state.isDrawerExpanded
      }),
      onClick: LayoutActionCreator.drawerToggle
    })));
  },
  getAccountRender: function(account, key) {
    var accountClasses, accountID, configMailboxUrl, defaultMailbox, icon, isActive, isSelected, mailboxes, nbUnread, progress, refreshes, specialMboxes, toggleActive, toggleDisplay, toggleFavorites, toggleFavoritesLabel, url, _ref2;
    isSelected = ((this.props.selectedAccount == null) && key === 0) || ((_ref2 = this.props.selectedAccount) != null ? _ref2.get('id') : void 0) === account.get('id');
    accountID = account.get('id');
    nbUnread = account.get('totalUnread');
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
          return _this.setState({
            displayActiveAccount: true
          });
        }
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
    isActive = isSelected && this.state.displayActiveAccount;
    accountClasses = classer({
      active: isActive
    });
    if (this.state.onlyFavorites) {
      mailboxes = this.props.favorites;
      icon = 'fa-ellipsis-h';
      toggleFavoritesLabel = t('menu favorites off');
    } else {
      mailboxes = this.props.mailboxes;
      icon = 'fa-ellipsis-h';
      toggleFavoritesLabel = t('menu favorites on');
    }
    configMailboxUrl = this.buildUrl({
      direction: 'first',
      action: 'account.config',
      parameters: [accountID, 'account'],
      fullWidth: true
    });
    specialMboxes = specialMailboxes.map(function(mbox) {
      return account.get(mbox);
    });
    return div({
      className: accountClasses,
      key: key
    }, div({
      className: 'account-title'
    }, a({
      href: url,
      role: 'menuitem',
      className: 'account ' + accountClasses,
      onClick: toggleActive,
      onDoubleClick: toggleDisplay,
      'data-toggle': 'tooltip',
      'data-delay': '10000',
      'data-placement': 'right'
    }, i({
      className: 'avatar',
      style: {
        'background-color': colorhash(account.get('label'))
      }
    }, account.get('label')[0]), span({
      'data-account-id': key,
      className: 'item-label'
    }, account.get('label')), (progress = refreshes.get(accountID)) ? (progress.get('errors').length ? span({
      className: 'refresh-error'
    }, i({
      className: 'fa warning',
      onClick: this.displayErrors.bind(null, progress)
    })) : void 0, progress.get('firstImport') ? ThinProgress({
      done: progress.get('done'),
      total: progress.get('total')
    }) : void 0) : void 0), isSelected ? a({
      href: configMailboxUrl,
      className: 'mailbox-config'
    }, i({
      className: 'fa fa-cog',
      'aria-describedby': Tooltips.ACCOUNT_PARAMETERS,
      'data-tooltip-direction': 'right'
    })) : void 0, nbUnread > 0 && !progress ? span({
      className: 'badge'
    }, nbUnread) : void 0), isSelected ? ul({
      role: 'group',
      className: 'list-unstyled mailbox-list'
    }, mailboxes != null ? mailboxes.filter((function(_this) {
      return function(mailbox) {
        var _ref3;
        return _ref3 = mailbox.get('id'), __indexOf.call(specialMboxes, _ref3) >= 0;
      };
    })(this)).map((function(_this) {
      return function(mailbox, key) {
        var selectedMailboxID;
        selectedMailboxID = _this.props.selectedMailboxID;
        return MenuMailboxItem({
          account: account,
          mailbox: mailbox,
          key: key,
          selectedMailboxID: selectedMailboxID,
          refreshes: refreshes,
          displayErrors: _this.displayErrors
        });
      };
    })(this)).toJS() : void 0, mailboxes != null ? mailboxes.filter((function(_this) {
      return function(mailbox) {
        var _ref3;
        return _ref3 = mailbox.get('id'), __indexOf.call(specialMboxes, _ref3) < 0;
      };
    })(this)).map((function(_this) {
      return function(mailbox, key) {
        var selectedMailboxID;
        selectedMailboxID = _this.props.selectedMailboxID;
        return MenuMailboxItem({
          account: account,
          mailbox: mailbox,
          key: key,
          selectedMailboxID: selectedMailboxID,
          refreshes: refreshes,
          displayErrors: _this.displayErrors
        });
      };
    })(this)).toJS() : void 0, li({
      className: 'toggle-favorites'
    }, a({
      role: 'menuitem',
      tabIndex: 0,
      onClick: toggleFavorites,
      key: 'toggle'
    }, i({
      className: 'fa ' + icon
    }), span({
      className: 'item-label'
    }, toggleFavoritesLabel)))) : void 0);
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
    var attrib, classesChild, classesParent, displayError, icon, mailboxID, mailboxIcon, mailboxUrl, nbRecent, nbTotal, nbUnread, progress, specialMailbox, title;
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
    mailboxIcon = 'fa-folder-o';
    specialMailbox = false;
    for (attrib in SpecialBoxIcons) {
      icon = SpecialBoxIcons[attrib];
      if (this.props.account.get(attrib) === mailboxID) {
        mailboxIcon = icon;
        specialMailbox = attrib;
      }
    }
    classesParent = classer({
      active: mailboxID === this.props.selectedMailboxID,
      target: this.state.target
    });
    classesChild = classer({
      target: this.state.target,
      special: specialMailbox,
      news: nbRecent > 0
    });
    if (specialMailbox) {
      classesChild += " " + specialMailbox;
    }
    progress = this.props.refreshes.get(mailboxID);
    displayError = this.props.displayErrors.bind(null, progress);
    return li({
      className: classesParent
    }, a({
      href: mailboxUrl,
      onClick: this.props.hideMenu,
      className: "" + classesChild + " lv-" + (this.props.mailbox.get('depth')),
      role: 'menuitem',
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
    }), span({
      className: 'item-label'
    }, "" + (this.props.mailbox.get('label'))), progress && progress.get('firstImport') ? ThinProgress({
      done: progress.get('done'),
      total: progress.get('total')
    }) : void 0, (progress != null ? progress.get('errors').length : void 0) ? span({
      className: 'refresh-error',
      onClick: displayError
    }, i({
      className: 'fa fa-warning'
    }, null)) : void 0), this.props.account.get('trashMailbox') === mailboxID ? button({
      'aria-describedby': Tooltips.EXPUNGE_MAILBOX,
      'data-tooltip-direction': 'right',
      onClick: this.expungeMailbox
    }, span({
      className: 'fa fa-recycle'
    })) : void 0, !progress && nbUnread && nbUnread > 0 ? span({
      className: 'badge'
    }, nbUnread) : void 0);
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
  onDrop: function(event, to) {
    var conversationID, data, mailboxID, messageID, _ref2;
    data = event.dataTransfer.getData('text');
    _ref2 = JSON.parse(data), messageID = _ref2.messageID, mailboxID = _ref2.mailboxID, conversationID = _ref2.conversationID;
    this.setState({
      target: false
    });
    return MessageActionCreator.move({
      messageID: messageID,
      conversationID: conversationID
    }, mailboxID, to);
  },
  expungeMailbox: function(e) {
    var accountID, mailbox, mailboxID;
    accountID = this.props.account.get('id');
    mailboxID = this.props.mailbox.get('id');
    e.preventDefault();
    if (window.confirm(t('account confirm delbox'))) {
      mailbox = {
        accountID: accountID,
        mailboxID: mailboxID
      };
      return AccountActionCreator.mailboxExpunge(mailbox, (function(_this) {
        return function(error) {
          var params;
          if (error != null) {
            if (accountID === mailbox.accountID && mailboxID === mailbox.mailboxID) {
              params = _.clone(MessageStore.getParams());
              params.accountID = accountID;
              params.mailboxID = mailboxID;
              LayoutActionCreator.showMessageList({
                parameters: params
              });
            }
            return LayoutActionCreator.alertError("" + (t("mailbox expunge ko")) + " " + error);
          } else {
            return LayoutActionCreator.notify(t("mailbox expunge ok"), {
              autoclose: true
            });
          }
        };
      })(this));
    }
  }
});
});

;require.register("components/menu_refresh_indicator", function(exports, require, module) {
var LayoutActionCreator, Spinner, button, span, _ref;

_ref = React.DOM, span = _ref.span, button = _ref.button;

LayoutActionCreator = require('../actions/layout_action_creator');

Spinner = require('./basic_components').Spinner;

module.exports = React.createClass({
  displayName: 'RefreshIndicator',
  protoTypes: {
    refreshes: React.PropTypes.object.isRequired,
    selectedAccount: React.PropTypes.object.isRequired,
    selectedMailboxID: React.PropTypes.string
  },
  getInitialState: function() {
    return {
      isRefreshing: false
    };
  },
  render: function() {
    if (!this.state.isRefreshing) {
      return button({
        className: 'btn',
        type: 'button',
        role: 'menuitem',
        disabled: null,
        title: t("menu refresh label"),
        onClick: this.refresh
      }, span({
        className: 'fa fa-refresh'
      }));
    } else {
      return button({
        className: 'btn',
        type: 'button',
        role: 'menuitem',
        disabled: true,
        title: t("menu refreshing"),
        onClick: this.refresh
      }, span({
        className: 'fa fa-refresh fa-spin'
      }));
    }
  },
  refresh: function(event) {
    this.setState({
      isRefreshing: true
    });
    event.preventDefault();
    return LayoutActionCreator.refreshMessages((function(_this) {
      return function() {
        return _this.setState({
          isRefreshing: false
        });
      };
    })(this));
  }
});
});

;require.register("components/message-list", function(exports, require, module) {
var ContactActionCreator, DomUtils, LayoutActionCreator, LayoutStore, MessageActionCreator, MessageFlags, MessageItem, MessageList, MessageListBody, MessageUtils, Participants, RouterMixin, SocketUtils, Spinner, StoreWatchMixin, ToolbarMessagesList, TooltipRefresherMixin, Tooltips, a, button, classer, colorhash, div, i, img, input, li, p, section, span, ul, _ref, _ref1,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ref = React.DOM, div = _ref.div, section = _ref.section, p = _ref.p, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, button = _ref.button, input = _ref.input, img = _ref.img;

_ref1 = require('../constants/app_constants'), MessageFlags = _ref1.MessageFlags, Tooltips = _ref1.Tooltips;

RouterMixin = require('../mixins/router_mixin');

TooltipRefresherMixin = require('../mixins/tooltip_refresher_mixin');

StoreWatchMixin = require('../mixins/store_watch_mixin');

LayoutStore = require('../stores/layout_store');

classer = React.addons.classSet;

DomUtils = require('../utils/dom_utils');

MessageUtils = require('../utils/message_utils');

SocketUtils = require('../utils/socketio_utils');

colorhash = require('../utils/colorhash');

ContactActionCreator = require('../actions/contact_action_creator');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

Participants = require('./participant');

Spinner = require('./basic_components').Spinner;

ToolbarMessagesList = require('./toolbar_messageslist');

module.exports = MessageList = React.createClass({
  displayName: 'MessageList',
  mixins: [RouterMixin, TooltipRefresherMixin, StoreWatchMixin([LayoutStore])],
  shouldComponentUpdate: function(nextProps, nextState) {
    var should;
    should = !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
    return should;
  },
  getInitialState: function() {
    return {
      edited: false,
      quickFilters: false,
      selected: {},
      allSelected: false
    };
  },
  getStateFromStores: function() {
    return {
      fullscreen: LayoutStore.isPreviewFullscreen()
    };
  },
  componentWillReceiveProps: function(props) {
    var id, isSelected, selected;
    if (props.mailboxID !== this.props.mailboxID) {
      return this.setState({
        allSelected: false,
        edited: false,
        selected: {}
      });
    } else {
      selected = this.state.selected;
      for (id in selected) {
        isSelected = selected[id];
        if (!props.messages.get(id)) {
          delete selected[id];
        }
      }
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
    var afterAction, compact, filterParams, hasMore, nextPage;
    compact = this.props.settings.get('listStyle') === 'compact';
    filterParams = {
      accountID: this.props.accountID,
      mailboxID: this.props.mailboxID,
      query: this.props.query
    };
    hasMore = this.props.query.pageAfter !== '-';
    if (hasMore) {
      afterAction = (function(_this) {
        return function() {
          return setTimeout(function() {
            var listEnd;
            listEnd = _this.refs.nextPage || _this.refs.listEnd || _this.refs.listEmpty;
            if ((listEnd != null) && DomUtils.isVisible(listEnd.getDOMNode())) {
              return LayoutActionCreator.showMessageList({
                parameters: _this.props.query
              });
            }
          }, 100);
        };
      })(this);
    }
    nextPage = (function(_this) {
      return function() {
        return LayoutActionCreator.showMessageList({
          parameters: _this.props.query
        });
      };
    })(this);
    return section({
      key: 'messages-list',
      ref: 'list',
      'data-mailbox-id': this.props.mailboxID,
      className: 'messages-list panel',
      'aria-expanded': !this.state.fullscreen
    }, ToolbarMessagesList({
      settings: this.props.settings,
      accountID: this.props.accountID,
      mailboxID: this.props.mailboxID,
      mailboxes: this.props.mailboxes,
      messages: this.props.messages,
      edited: this.state.edited,
      selected: this.state.selected,
      allSelected: this.state.allSelected,
      displayConversations: this.props.displayConversations,
      toggleEdited: this.toggleEdited,
      toggleAll: this.toggleAll,
      afterAction: afterAction
    }), this.props.messages.count() === 0 ? this.props.fetching ? p(null, t('list fetching')) : p({
      ref: 'listEmpty'
    }, this.props.emptyListMessage) : div({
      className: 'main-content',
      ref: 'scrollable'
    }, MessageListBody({
      messages: this.props.messages,
      settings: this.props.settings,
      mailboxID: this.props.mailboxID,
      messageID: this.props.messageID,
      conversationID: this.props.conversationID,
      conversationLengths: this.props.conversationLengths,
      login: this.props.login,
      edited: this.state.edited,
      selected: this.state.selected,
      allSelected: this.state.allSelected,
      displayConversations: this.props.displayConversations,
      isTrash: this.props.isTrash,
      ref: 'listBody',
      onSelect: (function(_this) {
        return function(id, val) {
          var newState, selected;
          selected = _.clone(_this.state.selected);
          if (val) {
            selected[id] = val;
          } else {
            delete selected[id];
          }
          if (Object.keys(selected).length > 0) {
            newState = {
              edited: true,
              selected: selected
            };
          } else {
            newState = {
              allSelected: false,
              edited: false,
              selected: {}
            };
          }
          return _this.setState(newState);
        };
      })(this)
    }), hasMore ? p({
      className: 'text-center list-footer'
    }, this.props.fetching ? Spinner() : a({
      className: 'more-messages',
      onClick: nextPage,
      ref: 'nextPage'
    }, t('list next page'))) : p({
      ref: 'listEnd'
    }, t('list end'))));
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
  _loadNext: function() {
    var lastMessage, _ref2;
    lastMessage = (_ref2 = this.refs.listBody) != null ? _ref2.getDOMNode().lastElementChild : void 0;
    if ((this.refs.nextPage != null) && (lastMessage != null) && DomUtils.isVisible(lastMessage)) {
      return LayoutActionCreator.showMessageList({
        parameters: this.props.query
      });
    }
  },
  _handleRealtimeGrowth: function() {
    var lastdate;
    if (this.props.pageAfter !== '-' && (this.refs.listEnd != null) && !DomUtils.isVisible(this.refs.listEnd.getDOMNode())) {
      lastdate = this.props.messages.last().get('date');
      return SocketUtils.changeRealtimeScope(this.props.mailboxID, lastdate);
    }
  },
  _initScroll: function() {
    var scrollable;
    if (this.refs.nextPage == null) {
      return;
    }
    if (this.refs.scrollable != null) {
      scrollable = this.refs.scrollable.getDOMNode();
      return setTimeout((function(_this) {
        return function() {
          scrollable.removeEventListener('scroll', _this._loadNext);
          scrollable.addEventListener('scroll', _this._loadNext);
          _this._loadNext();
          if (_this._checkNextInterval == null) {
            return _this._checkNextInterval = window.setInterval(_this._loadNext, 10000);
          }
        };
      })(this), 0);
    }
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
    if (this.refs.scrollable != null) {
      scrollable = this.refs.scrollable.getDOMNode();
      scrollable.removeEventListener('scroll', this._loadNext);
      if (this._checkNextInterval != null) {
        return window.clearInterval(this._checkNextInterval);
      }
    }
  }
});

MessageListBody = React.createClass({
  displayName: 'MessageListBody',
  getInitialState: function() {
    var state;
    return state = {
      messageID: null
    };
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    var should, updatedProps;
    updatedProps = Object.keys(nextProps).filter((function(_this) {
      return function(prop) {
        return typeof nextProps[prop] !== 'function' && !(_.isEqual(nextProps[prop], _this.props[prop]));
      };
    })(this));
    should = !(_.isEqual(nextState, this.state)) || updatedProps.length > 0;
    return should;
  },
  render: function() {
    return ul({
      className: 'list-unstyled'
    }, this.props.messages.map((function(_this) {
      return function(message, key) {
        var cid, id, isActive, _ref2;
        id = message.get('id');
        cid = message.get('conversationID');
        if (_this.props.displayConversations && (cid != null)) {
          isActive = _this.props.conversationID === cid;
        } else {
          isActive = _this.props.messageID === id;
        }
        return MessageItem({
          message: message,
          mailboxID: _this.props.mailboxID,
          conversationLengths: (_ref2 = _this.props.conversationLengths) != null ? _ref2.get(cid) : void 0,
          key: key,
          isActive: isActive,
          edited: _this.props.edited,
          settings: _this.props.settings,
          selected: _this.props.selected[id] != null,
          login: _this.props.login,
          displayConversations: _this.props.displayConversations,
          isTrash: _this.props.isTrash,
          ref: 'messageItem',
          onSelect: function(val) {
            return _this.props.onSelect(id, val);
          }
        });
      };
    })(this)).toJS());
  },
  componentDidMount: function() {
    return this._onMount();
  },
  componentDidUpdate: function() {
    return this._onMount();
  },
  _onMount: function() {
    var active;
    if (this.state.messageID !== this.props.messageID) {
      active = document.querySelector("[data-message-id='" + this.props.messageID + "']");
      if ((active != null) && !DomUtils.isVisible(active)) {
        active.scrollIntoView(false);
      }
      return this.setState({
        messageID: this.props.messageID
      });
    }
  }
});

MessageItem = React.createClass({
  displayName: 'MessagesItem',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    var shouldUpdate, updatedProps;
    updatedProps = Object.keys(nextProps).filter((function(_this) {
      return function(prop) {
        return typeof nextProps[prop] !== 'function' && !(_.isEqual(nextProps[prop], _this.props[prop]));
      };
    })(this));
    shouldUpdate = !_.isEqual(nextState, this.state) || updatedProps.length > 0;
    return shouldUpdate;
  },
  render: function() {
    var action, avatar, cHash, classes, compact, conversationID, date, flags, from, html, message, params, text, url, _ref2, _ref3, _ref4, _ref5;
    message = this.props.message;
    flags = message.get('flags');
    classes = classer({
      message: true,
      unseen: (_ref2 = MessageFlags.SEEN, __indexOf.call(flags, _ref2) < 0),
      active: this.props.isActive,
      edited: this.props.edited
    });
    if ((_ref3 = MessageFlags.DRAFT, __indexOf.call(flags, _ref3) >= 0) && !this.props.isTrash) {
      action = 'edit';
      params = {
        messageID: message.get('id')
      };
    } else {
      conversationID = message.get('conversationID');
      if ((conversationID != null) && this.props.displayConversations) {
        action = 'conversation';
        params = {
          conversationID: conversationID,
          messageID: message.get('id')
        };
      } else {
        action = 'message';
        params = {
          messageID: message.get('id')
        };
      }
    }
    url = this.buildUrl({
      direction: 'second',
      action: action,
      parameters: params
    });
    compact = this.props.settings.get('listStyle') === 'compact';
    date = MessageUtils.formatDate(message.get('createdAt'), compact);
    avatar = MessageUtils.getAvatar(message);
    text = message.get('text');
    html = message.get('html');
    if ((text == null) && (html != null)) {
      text = toMarkdown(html);
    }
    if (text == null) {
      text = '';
    }
    return li({
      className: classes,
      key: this.props.key,
      'data-message-id': message.get('id'),
      'data-conversation-id': message.get('conversationID'),
      draggable: !this.props.edited,
      onClick: this.onMessageClick,
      onDragStart: this.onDragStart
    }, (this.props.edited ? span : a)({
      href: url,
      className: 'wrapper',
      'data-message-id': message.get('id'),
      onClick: this.onMessageClick,
      onDoubleClick: this.onMessageDblClick,
      ref: 'target'
    }, div({
      className: 'markers-wrapper'
    }, i({
      className: classer({
        select: true,
        fa: true,
        'fa-check-square-o': this.props.selected,
        'fa-square-o': !this.props.selected
      }),
      onClick: this.onSelect
    }), (_ref4 = MessageFlags.SEEN, __indexOf.call(flags, _ref4) >= 0) ? i({
      className: 'fa fa-circle-thin'
    }) : i({
      className: 'fa fa-circle'
    }), (_ref5 = MessageFlags.FLAGGED, __indexOf.call(flags, _ref5) >= 0) ? i({
      className: 'fa fa-star'
    }) : void 0), div({
      className: 'avatar-wrapper select-target'
    }, avatar != null ? img({
      className: 'avatar',
      src: avatar
    }) : (from = message.get('from')[0], cHash = "" + from.name + " <" + from.address + ">", i({
      className: 'avatar placeholder',
      style: {
        'background-color': colorhash(cHash)
      }
    }, from.name ? from.name[0] : from.address[0]))), div({
      className: 'metas-wrapper'
    }, div({
      className: 'participants'
    }, this.getParticipants(message)), div({
      className: 'subject'
    }, message.get('subject')), div({
      className: 'date'
    }, date), div({
      className: 'extras'
    }, message.get('hasAttachments') ? i({
      className: 'attachments fa fa-paperclip'
    }) : void 0, this.props.displayConversations && this.props.conversationLengths > 1 ? span({
      className: 'conversation-length'
    }, "[" + this.props.conversationLengths + "]") : void 0), div({
      className: 'preview'
    }, p(null, text.substr(0, 1024))))));
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
    var href, node;
    node = this.refs.target.getDOMNode();
    if (this.props.edited && event.target.classList.contains('select-target')) {
      this.props.onSelect(!this.props.selected);
      event.preventDefault();
      return event.stopPropagation();
    } else {
      if (!(event.target.getAttribute('type') === 'checkbox')) {
        event.preventDefault();
        MessageActionCreator.setCurrent(node.dataset.messageId, true);
        if (this.props.settings.get('displayPreview')) {
          href = '#' + node.getAttribute('href').split('#')[1];
          return this.redirect(href);
        }
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
      mailboxID: this.props.mailboxID
    };
    if (this.props.displayConversations) {
      data.conversationID = event.currentTarget.dataset.conversationId;
    } else {
      data.messageID = event.currentTarget.dataset.messageId;
    }
    event.dataTransfer.setData('text', JSON.stringify(data));
    event.dataTransfer.effectAllowed = 'move';
    return event.dataTransfer.dropEffect = 'move';
  },
  getParticipants: function(message) {
    var from, separator, to;
    from = message.get('from');
    to = message.get('to').concat(message.get('cc')).filter((function(_this) {
      return function(address) {
        var _ref2;
        return address.address !== _this.props.login && address.address !== ((_ref2 = from[0]) != null ? _ref2.address : void 0);
      };
    })(this));
    separator = to.length > 0 ? ', ' : ' ';
    return span(null, Participants({
      participants: from,
      onAdd: this.addAddress,
      ref: 'from'
    }), span(null, separator), Participants({
      participants: to,
      onAdd: this.addAddress,
      ref: 'to'
    }));
  },
  addAddress: function(address) {
    return ContactActionCreator.createContact(address);
  }
});
});

;require.register("components/message", function(exports, require, module) {
var Compose, ComposeActions, ContactActionCreator, LayoutActionCreator, MessageActionCreator, MessageContent, MessageFlags, MessageFooter, MessageHeader, Participants, RouterMixin, ToolbarMessage, TooltipRefresherMixin, a, alertError, alertSuccess, article, button, classer, div, footer, h4, header, i, iframe, li, p, pre, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, article = _ref.article, header = _ref.header, footer = _ref.footer, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, a = _ref.a, button = _ref.button, pre = _ref.pre, iframe = _ref.iframe, h4 = _ref.h4;

MessageHeader = require("./message_header");

MessageFooter = require("./message_footer");

ToolbarMessage = require('./toolbar_message');

Compose = require('./compose');

Participants = require('./participant');

_ref1 = require('../constants/app_constants'), ComposeActions = _ref1.ComposeActions, MessageFlags = _ref1.MessageFlags;

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

ContactActionCreator = require('../actions/contact_action_creator');

RouterMixin = require('../mixins/router_mixin');

TooltipRefresherMixin = require('../mixins/tooltip_refresher_mixin');

classer = React.addons.classSet;

alertError = LayoutActionCreator.alertError;

alertSuccess = LayoutActionCreator.notify;

module.exports = React.createClass({
  displayName: 'Message',
  mixins: [RouterMixin, TooltipRefresherMixin],
  propTypes: {
    accounts: React.PropTypes.object.isRequired,
    active: React.PropTypes.bool,
    inConversation: React.PropTypes.bool,
    displayConversations: React.PropTypes.bool,
    key: React.PropTypes.string.isRequired,
    mailboxes: React.PropTypes.object.isRequired,
    message: React.PropTypes.object.isRequired,
    selectedAccountID: React.PropTypes.string.isRequired,
    selectedAccountLogin: React.PropTypes.string.isRequired,
    selectedMailboxID: React.PropTypes.string.isRequired,
    settings: React.PropTypes.object.isRequired,
    useIntents: React.PropTypes.bool.isRequired,
    setActive: React.PropTypes.func.isRequired
  },
  getInitialState: function() {
    return {
      active: this.props.active,
      composing: this._shouldOpenCompose(this.props),
      composeAction: '',
      headers: false,
      messageDisplayHTML: this.props.settings.get('messageDisplayHTML'),
      messageDisplayImages: this.props.settings.get('messageDisplayImages'),
      currentMessageID: null,
      prepared: {}
    };
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    var should;
    should = !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
    return should;
  },
  _shouldOpenCompose: function(props) {
    var flags, isDeleted, isDraft, trash, _ref2;
    flags = this.props.message.get('flags').slice();
    trash = (_ref2 = this.props.accounts[this.props.selectedAccountID]) != null ? _ref2.trashMailbox : void 0;
    isDraft = flags.indexOf(MessageFlags.DRAFT) > -1;
    isDeleted = this.props.message.get('mailboxIDs')[trash] != null;
    return isDraft && !isDeleted;
  },
  _prepareMessage: function(message) {
    var alternatives, e, flags, fullHeaders, html, key, mailboxes, rich, text, trash, urls, value, _ref2, _ref3;
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
    alternatives = message.get('alternatives');
    urls = /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/gim;
    if ((text == null) && (html == null)) {
      if ((alternatives != null ? alternatives.length : void 0) > 0) {
        text = t('calendar unknown format');
      } else {
        text = '';
      }
    }
    if ((text != null) && (html == null) && this.state.messageDisplayHTML) {
      try {
        html = markdown.toHTML(text.replace(/(^>.*$)([^>]+)/gm, "$1\n$2"));
        html = "<div class='textOnly'>" + html + "</div>";
      } catch (_error) {
        e = _error;
        html = "<div class='textOnly'>" + text + "</div>";
      }
    }
    if ((html != null) && (text == null) && !this.state.messageDisplayHTML) {
      text = toMarkdown(html);
    }
    mailboxes = message.get('mailboxIDs');
    trash = (_ref3 = this.props.accounts[this.props.selectedAccountID]) != null ? _ref3.trashMailbox : void 0;
    if (text != null) {
      rich = text.replace(urls, '<a href="$1" target="_blank">$1</a>');
      rich = rich.replace(/^>>>>>[^>]?.*$/gim, '<span class="quote5">$&</span>');
      rich = rich.replace(/^>>>>[^>]?.*$/gim, '<span class="quote4">$&</span>');
      rich = rich.replace(/^>>>[^>]?.*$/gim, '<span class="quote3">$&</span>');
      rich = rich.replace(/^>>[^>]?.*$/gim, '<span class="quote2">$&</span>');
      rich = rich.replace(/^>[^>]?.*$/gim, '<span class="quote1">$&</span>');
    }
    flags = this.props.message.get('flags').slice();
    return {
      attachments: message.get('attachments'),
      fullHeaders: fullHeaders,
      text: text,
      rich: rich,
      html: html,
      isDraft: flags.indexOf(MessageFlags.DRAFT) > -1,
      isDeleted: mailboxes[trash] != null
    };
  },
  componentWillMount: function() {
    return this._markRead(this.props.message, this.props.active);
  },
  componentWillReceiveProps: function(props) {
    var state;
    state = {
      active: props.active
    };
    if (props.message.get('id') !== this.props.message.get('id')) {
      this._markRead(props.message, props.active);
      state.messageDisplayHTML = props.settings.get('messageDisplayHTML');
      state.messageDisplayImages = props.settings.get('messageDisplayImages');
      state.composing = this._shouldOpenCompose(props);
    }
    return this.setState(state);
  },
  _markRead: function(message, active) {
    var flags, messageID, state;
    messageID = message.get('id');
    if (this.state.currentMessageID !== messageID) {
      state = {
        currentMessageID: messageID,
        prepared: this._prepareMessage(message)
      };
      this.setState(state);
      flags = message.get('flags').slice();
      if (active && flags.indexOf(MessageFlags.SEEN) === -1) {
        return setTimeout(function() {
          return MessageActionCreator.mark({
            messageID: messageID
          }, MessageFlags.SEEN);
        }, 1);
      }
    }
  },
  prepareHTML: function(html) {
    var doc, hideImage, href, image, images, link, messageDisplayHTML, parser, _i, _j, _len, _len1, _ref2;
    messageDisplayHTML = true;
    parser = new DOMParser();
    html = "<html><head>\n    <link rel=\"stylesheet\" href=\"/fonts/fonts.css\" />\n    <link rel=\"stylesheet\" href=\"./mail_stylesheet.css\" />\n    <style>body { visibility: hidden; }</style>\n</head><body>" + html + "</body></html>";
    doc = parser.parseFromString(html, "text/html");
    images = [];
    if (!doc) {
      doc = document.implementation.createHTMLDocument("");
      doc.documentElement.innerHTML = html;
    }
    if (!doc) {
      console.error("Unable to parse HTML content of message");
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
      href = link.getAttribute('href');
      if (href !== '' && !/:\/\//.test(href)) {
        link.setAttribute('href', 'http://' + href);
      }
    }
    if (doc != null) {
      this._htmlContent = doc.documentElement.innerHTML;
    } else {
      this._htmlContent = html;
    }
    return {
      messageDisplayHTML: messageDisplayHTML,
      images: images
    };
  },
  render: function() {
    var classes, images, imagesWarning, isUnread, message, messageDisplayHTML, prepared, setActive, _ref2, _ref3;
    message = this.props.message;
    prepared = this.state.prepared;
    if (this.state.messageDisplayHTML && (prepared.html != null)) {
      _ref2 = this.prepareHTML(prepared.html), messageDisplayHTML = _ref2.messageDisplayHTML, images = _ref2.images;
      imagesWarning = images.length > 0 && !this.state.messageDisplayImages;
    } else {
      messageDisplayHTML = false;
      imagesWarning = false;
    }
    isUnread = message.get('flags').slice().indexOf(MessageFlags.SEEN) === -1;
    setActive = (function(_this) {
      return function() {
        var messageID;
        if (isUnread && !_this.state.active) {
          messageID = message.get('id');
          MessageActionCreator.mark({
            messageID: messageID
          }, MessageFlags.SEEN);
          _this.props.setActive(message.get('id'));
        }
        return _this.setState({
          active: !_this.state.active
        });
      };
    })(this);
    classes = classer({
      message: true,
      active: this.state.active,
      isDraft: prepared.isDraft,
      isDeleted: prepared.isDeleted,
      isUnread: isUnread
    });
    return article({
      className: classes,
      key: this.props.key,
      'data-id': message.get('id')
    }, header({
      onClick: setActive
    }, this.renderHeaders(), this.state.active ? this.renderToolbox() : void 0), this.state.active ? this.renderCompose(prepared.isDraft) : void 0, this.state.active ? div({
      className: 'full-headers'
    }, pre(null, prepared != null ? (_ref3 = prepared.fullHeaders) != null ? _ref3.join("\n") : void 0 : void 0)) : void 0, this.state.active ? MessageContent({
      ref: 'messageContent',
      messageID: message.get('id'),
      messageDisplayHTML: messageDisplayHTML,
      html: this._htmlContent,
      text: prepared.text,
      rich: prepared.rich,
      imagesWarning: imagesWarning,
      composing: this.state.composing,
      displayImages: this.displayImages,
      displayHTML: this.displayHTML
    }) : void 0, this.state.active ? footer(null, this.renderFooter(), this.renderToolbox(false)) : void 0);
  },
  getParticipants: function(message) {
    var from, to;
    from = message.get('from');
    to = message.get('to').concat(message.get('cc'));
    return span(null, Participants({
      participants: from,
      onAdd: this.addAddress,
      tooltip: true,
      ref: 'from'
    }), span(null, ', '), Participants({
      participants: to,
      onAdd: this.addAddress,
      tooltip: true,
      ref: 'to'
    }));
  },
  renderHeaders: function() {
    return MessageHeader({
      message: this.props.message,
      isDraft: this.state.prepared.isDraft,
      isDeleted: this.state.prepared.isDeleted,
      ref: 'header'
    });
  },
  renderToolbox: function(full) {
    if (full == null) {
      full = true;
    }
    if (this.state.composing) {
      return;
    }
    return ToolbarMessage({
      full: full,
      message: this.props.message,
      mailboxes: this.props.mailboxes,
      selectedMailboxID: this.props.selectedMailboxID,
      onReply: this.onReply,
      onReplyAll: this.onReplyAll,
      onForward: this.onForward,
      onDelete: this.onDelete,
      onHeaders: this.onHeaders,
      onMove: this.onMove,
      onMark: this.onMark,
      onConversationDelete: this.onConversationDelete,
      onConversationMark: this.onConversationMark,
      onConversationMove: this.onConversationMove,
      ref: 'toolbarMessage'
    });
  },
  renderFooter: function() {
    return MessageFooter({
      message: this.props.message,
      ref: 'footer'
    });
  },
  renderCompose: function(isDraft) {
    if (this.state.composing) {
      if (isDraft) {
        return Compose({
          layout: 'second',
          action: null,
          inReplyTo: null,
          settings: this.props.settings,
          accounts: this.props.accounts,
          selectedAccountID: this.props.selectedAccountID,
          selectedAccountLogin: this.props.selectedAccountLogin,
          selectedMailboxID: this.props.selectedMailboxID,
          message: this.props.message,
          useIntents: this.props.useIntents,
          ref: 'compose'
        });
      } else {
        return Compose({
          ref: 'compose',
          inReplyTo: this.props.message,
          accounts: this.props.accounts,
          settings: this.props.settings,
          selectedAccountID: this.props.selectedAccountID,
          selectedAccountLogin: this.props.selectedAccountLogin,
          action: this.state.composeAction,
          layout: 'second',
          useIntents: this.props.useIntents,
          callback: (function(_this) {
            return function(error) {
              if (error == null) {
                if (_this.isMounted()) {
                  return _this.setState({
                    composing: false
                  });
                }
              }
            };
          })(this),
          onCancel: (function(_this) {
            return function() {
              if (_this.isMounted()) {
                return _this.setState({
                  composing: false
                });
              }
            };
          })(this)
        });
      }
    }
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
    var confirmMessage, messageID, needConfirmation;
    needConfirmation = this.props.settings.get('messageConfirmDelete');
    messageID = this.props.message.get('id');
    confirmMessage = t('mail confirm delete', {
      subject: this.props.message.get('subject')
    });
    if (!needConfirmation || window.confirm(confirmMessage)) {
      return MessageActionCreator["delete"]({
        messageID: messageID
      });
    }
  },
  onConversationDelete: function() {
    var conversationID;
    conversationID = this.props.message.get('conversationID');
    return MessageActionCreator["delete"]({
      conversationID: conversationID
    });
  },
  onMark: function(flag) {
    var messageID;
    messageID = this.props.message.get('id');
    return MessageActionCreator.mark({
      messageID: messageID
    }, flag);
  },
  onConversationMark: function(flag) {
    var conversationID;
    conversationID = this.props.message.get('conversationID');
    return MessageActionCreator.mark({
      conversationID: conversationID
    }, flag);
  },
  onMove: function(to) {
    var from, messageID, subject;
    messageID = this.props.message.get('id');
    from = this.props.selectedMailboxID;
    subject = this.props.message.get('subject');
    return MessageActionCreator.move({
      messageID: messageID
    }, from, to);
  },
  onConversationMove: function(to) {
    var conversationID, from, subject;
    conversationID = this.props.message.get('conversationID');
    from = this.props.selectedMailboxID;
    subject = this.props.message.get('subject');
    return MessageActionCreator.move({
      conversationID: conversationID
    }, from, to);
  },
  onCopy: function(args) {
    return LayoutActionCreator.alertWarning(t("app unimplemented"));
  },
  onHeaders: function(event) {
    var id;
    event.preventDefault();
    id = this.props.message.get('id');
    return document.querySelector(".conversation [data-id='" + id + "']").classList.toggle('with-headers');
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
      return div(null, this.props.imagesWarning ? div({
        className: "imagesWarning alert alert-warning content-action",
        ref: "imagesWarning"
      }, i({
        className: 'fa fa-shield'
      }), t('message images warning'), button({
        className: 'btn btn-xs btn-warning',
        type: "button",
        ref: 'imagesDisplay',
        onClick: this.props.displayImages
      }, t('message images display'))) : void 0, iframe({
        'data-message-id': this.props.messageID,
        name: "frame-" + this.props.messageID,
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
        className: 'preview',
        ref: content
      }, p({
        dangerouslySetInnerHTML: {
          __html: this.props.rich
        }
      })));
    }
  },
  _initFrame: function(type) {
    var checkResize, doc, frame, loadContent, panel, step, _ref2;
    panel = document.querySelector("#panels > .panel:nth-of-type(2)");
    if ((panel != null) && !this.props.composing) {
      panel.scrollTop = 0;
    }
    if (this.props.messageDisplayHTML && this.refs.content) {
      frame = this.refs.content.getDOMNode();
      doc = frame.contentDocument || ((_ref2 = frame.contentWindow) != null ? _ref2.document : void 0);
      checkResize = false;
      step = 0;
      loadContent = (function(_this) {
        return function(e) {
          var updateHeight, _ref3, _ref4;
          step = 0;
          doc = frame.contentDocument || ((_ref3 = frame.contentWindow) != null ? _ref3.document : void 0);
          if (doc != null) {
            doc.documentElement.innerHTML = _this.props.html;
            window.cozyMails.customEvent("MESSAGE_LOADED", _this.props.messageID);
            updateHeight = function(e) {
              var height, _ref4;
              height = doc.documentElement.scrollHeight;
              if (height < 60) {
                frame.style.height = "60px";
              } else {
                frame.style.height = "" + (height + 60) + "px";
              }
              step++;
              if (checkResize && step > 10) {
                doc.body.removeEventListener('load', loadContent);
                return (_ref4 = frame.contentWindow) != null ? _ref4.removeEventListener('resize') : void 0;
              }
            };
            updateHeight();
            setTimeout(updateHeight, 1000);
            doc.body.onload = updateHeight;
            if (checkResize) {
              frame.contentWindow.onresize = updateHeight;
              window.onresize = updateHeight;
              return (_ref4 = frame.contentWindow) != null ? _ref4.addEventListener('resize', updateHeight, true) : void 0;
            }
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
    } else {
      return window.cozyMails.customEvent("MESSAGE_LOADED", this.props.messageID);
    }
  },
  componentDidMount: function() {
    return this._initFrame('mount');
  },
  componentDidUpdate: function() {
    return this._initFrame('update');
  }
});
});

;require.register("components/message_footer", function(exports, require, module) {
var AttachmentPreview, MessageUtils, a, div, i, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, span = _ref.span, ul = _ref.ul, li = _ref.li, a = _ref.a, i = _ref.i;

MessageUtils = require('../utils/message_utils');

AttachmentPreview = require('./attachement_preview');

module.exports = React.createClass({
  displayName: 'MessageFooter',
  propTypes: {
    message: React.PropTypes.object.isRequired
  },
  render: function() {
    return div({
      className: 'attachments'
    }, this.renderAttachments());
  },
  renderAttachments: function() {
    var attachments, file, resources, _ref1;
    attachments = ((_ref1 = this.props.message.get('attachments')) != null ? _ref1.toJS() : void 0) || [];
    if (!attachments.length) {
      return;
    }
    resources = _.groupBy(attachments, function(file) {
      if (MessageUtils.getAttachmentType(file.contentType) === 'image') {
        return 'preview';
      } else {
        return 'binary';
      }
    });
    return ul({
      className: null
    }, (function() {
      var _i, _len, _ref2, _results;
      if (resources.preview) {
        _ref2 = resources.preview;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          file = _ref2[_i];
          _results.push(AttachmentPreview({
            ref: 'attachmentPreview',
            file: file,
            key: file.checksum,
            preview: true,
            previewLink: true
          }));
        }
        return _results;
      }
    })(), (function() {
      var _i, _len, _ref2, _results;
      if (resources.binary) {
        _ref2 = resources.binary;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          file = _ref2[_i];
          _results.push(AttachmentPreview({
            ref: 'attachmentPreview',
            file: file,
            key: file.checksum,
            preview: false,
            previewLink: true
          }));
        }
        return _results;
      }
    })());
  }
});
});

;require.register("components/message_header", function(exports, require, module) {
var MessageFlags, ParticipantMixin, PopupMessageAttachments, PopupMessageDetails, div, i, img, messageUtils, span, _ref,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __slice = [].slice;

_ref = React.DOM, div = _ref.div, span = _ref.span, i = _ref.i, img = _ref.img;

MessageFlags = require('../constants/app_constants').MessageFlags;

PopupMessageDetails = require('./popup_message_details');

PopupMessageAttachments = require('./popup_message_attachments');

ParticipantMixin = require('../mixins/participant_mixin');

messageUtils = require('../utils/message_utils');

module.exports = React.createClass({
  displayName: 'MessageHeader',
  propTypes: {
    message: React.PropTypes.object.isRequired,
    isDraft: React.PropTypes.bool,
    isDeleted: React.PropTypes.bool
  },
  mixins: [ParticipantMixin],
  render: function() {
    var avatar, _ref1;
    avatar = messageUtils.getAvatar(this.props.message);
    return div({
      key: "message-header-" + (this.props.message.get('id'))
    }, avatar ? div({
      className: 'sender-avatar'
    }, img({
      className: 'media-object',
      src: avatar
    })) : void 0, div({
      className: 'infos'
    }, this.renderAddress('from'), this.renderAddress('to'), this.renderAddress('cc'), div({
      className: 'metas indicators'
    }, this.props.message.get('attachments').length ? PopupMessageAttachments({
      message: this.props.message
    }) : void 0, (_ref1 = MessageFlags.FLAGGED, __indexOf.call(this.props.message.get('flags'), _ref1) >= 0) ? i({
      className: 'fa fa-star'
    }) : void 0, this.props.isDraft ? i({
      className: 'fa fa-edit'
    }) : void 0, this.props.isDeleted ? i({
      className: 'fa fa-trash'
    }) : void 0), div({
      className: 'metas date'
    }, messageUtils.formatDate(this.props.message.get('createdAt'))), PopupMessageDetails({
      message: this.props.message
    })));
  },
  renderAddress: function(field) {
    var users;
    users = this.props.message.get(field);
    if (!users.length) {
      return;
    }
    return div({
      className: "addresses " + field,
      key: "address-" + field
    }, div.apply(null, [{
      className: 'addresses-wrapper'
    }, field !== 'from' ? span(null, t("mail " + field)) : void 0].concat(__slice.call(this.formatUsers(users)))));
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
            image = "<a href=\"/#apps/contacts/contact/" + (contact.get('id')) + "\" target=\"blank\">\n    " + image + "\n</a>";
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
        }, 5000);
      });
      node.addEventListener('mouseout', function() {
        return clearTimeout(delay);
      });
      return node.addEventListener('click', function(event) {
        event.stopPropagation();
        return addTooltip();
      });
    }
  },
  componentDidMount: function() {
    if (this.props.tooltip) {
      return this.tooltip();
    }
  },
  componentDidUpdate: function() {
    if (this.props.tooltip) {
      return this.tooltip();
    }
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
            onAdd: this.props.onAdd,
            tooltip: this.props.tooltip
          }), key < (this.props.participants.length - 1) ? span(null, ', ') : void 0));
        }
        return _results;
      }
    }).call(this));
  }
});

module.exports = Participants;
});

;require.register("components/popup_message_attachments", function(exports, require, module) {
var AttachmentPreview, Tooltips, div, i, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, i = _ref.i;

Tooltips = require('../constants/app_constants').Tooltips;

AttachmentPreview = require('./attachement_preview');

module.exports = React.createClass({
  displayName: 'MessageAttachmentsPopup',
  mixins: [OnClickOutside],
  getInitialState: function() {
    return {
      showAttachements: false
    };
  },
  toggleAttachments: function() {
    return this.setState({
      showAttachements: !this.state.showAttachements
    });
  },
  handleClickOutside: function() {
    return this.setState({
      showAttachements: false
    });
  },
  render: function() {
    var attachments, file, _ref1;
    attachments = ((_ref1 = this.props.message.get('attachments')) != null ? _ref1.toJS() : void 0) || [];
    return div({
      className: 'attachments',
      'aria-expanded': this.state.showAttachements,
      onClick: function(event) {
        return event.stopPropagation();
      }
    }, i({
      className: 'btn fa fa-paperclip fa-flip-horizontal',
      onClick: this.toggleAttachments,
      'aria-describedby': Tooltips.OPEN_ATTACHMENTS,
      'data-tooltip-direction': 'left'
    }), div({
      className: 'popup',
      'aria-hidden': !this.state.showAttachements
    }, ul({
      className: null
    }, (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = attachments.length; _i < _len; _i++) {
        file = attachments[_i];
        _results.push(AttachmentPreview({
          ref: 'attachmentPreview',
          file: file,
          key: file.checksum,
          preview: false
        }));
      }
      return _results;
    })())));
  }
});
});

;require.register("components/popup_message_details", function(exports, require, module) {
var ParticipantMixin, div, i, table, tbody, td, tr, _ref,
  __slice = [].slice;

_ref = React.DOM, div = _ref.div, table = _ref.table, tbody = _ref.tbody, tr = _ref.tr, td = _ref.td, i = _ref.i;

ParticipantMixin = require('../mixins/participant_mixin');

module.exports = React.createClass({
  displayName: 'MessageDetailsPopup',
  mixins: [ParticipantMixin, OnClickOutside],
  getInitialState: function() {
    return {
      showDetails: false
    };
  },
  toggleDetails: function() {
    return this.setState({
      showDetails: !this.state.showDetails
    });
  },
  handleClickOutside: function() {
    return this.setState({
      showDetails: false
    });
  },
  render: function() {
    var cc, dest, from, key, reply, row, to, _ref1;
    from = this.props.message.get('from')[0];
    to = this.props.message.get('to');
    cc = this.props.message.get('cc');
    reply = (_ref1 = this.props.message.get('reply-to')) != null ? _ref1[0] : void 0;
    row = function(id, value, label, rowSpan) {
      var attrs, items;
      if (label == null) {
        label = false;
      }
      if (rowSpan == null) {
        rowSpan = false;
      }
      items = [];
      if (label) {
        attrs = {
          className: 'label'
        };
        if (rowSpan) {
          attrs.rowSpan = rowSpan;
        }
        items.push(td(attrs, t(label)));
      }
      items.push(td({
        key: "cell-" + id
      }, value));
      return tr.apply(null, [{
        key: "row-" + id
      }].concat(__slice.call(items)));
    };
    return div({
      className: 'metas details',
      'aria-expanded': this.state.showDetails,
      onClick: function(event) {
        return event.stopPropagation();
      }
    }, i({
      className: 'fa fa-caret-down',
      onClick: this.toggleDetails
    }), div({
      className: 'popup',
      'aria-hidden': !this.state.showDetails
    }, table(null, tbody(null, row('from', this.formatUsers(from), 'headers from'), to.length ? row('to', this.formatUsers(to[0]), 'headers to', to.length) : void 0, (function() {
      var _i, _len, _ref2, _results;
      if (to.length) {
        _ref2 = to.slice(1);
        _results = [];
        for (key = _i = 0, _len = _ref2.length; _i < _len; key = ++_i) {
          dest = _ref2[key];
          _results.push(row("destTo" + key, this.formatUsers(dest)));
        }
        return _results;
      }
    }).call(this), cc.length ? row('cc', this.formatUsers(cc[0]), 'headers cc', cc.length) : void 0, (function() {
      var _i, _len, _ref2, _results;
      if (cc.length) {
        _ref2 = cc.slice(1);
        _results = [];
        for (key = _i = 0, _len = _ref2.length; _i < _len; key = ++_i) {
          dest = _ref2[key];
          _results.push(row("destCc" + key, this.formatUsers(dest)));
        }
        return _results;
      }
    }).call(this), reply != null ? row('reply', this.formatUsers(reply), 'headers reply-to') : void 0, row('created', this.props.message.get('createdAt'), 'headers date'), row('subject', this.props.message.get('subject'), 'headers subject')))));
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
var ApiUtils, Dispositions, LayoutActionCreator, PluginUtils, SettingsActionCreator, a, button, classer, div, fieldset, form, h3, i, input, label, legend, li, span, ul, _ref,
  __hasProp = {}.hasOwnProperty;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, form = _ref.form, label = _ref.label, input = _ref.input, button = _ref.button, fieldset = _ref.fieldset, legend = _ref.legend, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i;

classer = React.addons.classSet;

LayoutActionCreator = require('../actions/layout_action_creator');

SettingsActionCreator = require('../actions/settings_action_creator');

PluginUtils = require('../utils/plugin_utils');

ApiUtils = require('../utils/api_utils');

Dispositions = require('../constants/app_constants').Dispositions;

module.exports = React.createClass({
  displayName: 'Settings',
  render: function() {
    var classInput, classLabel, layoutStyle, listStyle, pluginConf, pluginName;
    classLabel = 'col-sm-5 col-sm-offset-1 control-label';
    classInput = 'col-sm-6';
    layoutStyle = this.state.settings.layoutStyle || 'vertical';
    listStyle = this.state.settings.listStyle || 'default';
    return div({
      id: 'settings'
    }, h3({
      className: null
    }, t("settings title")), this.props.error ? div({
      className: 'error'
    }, this.props.error) : void 0, form({
      className: 'form-horizontal'
    }, div({
      className: 'form-group'
    }, label({
      htmlFor: 'settings-layoutStyle',
      className: classLabel
    }, t("settings label layoutStyle")), div({
      className: classInput
    }, div({
      className: "dropdown"
    }, button({
      id: 'settings-layoutStyle',
      className: "btn btn-default dropdown-toggle",
      type: "button",
      "data-toggle": "dropdown"
    }, t("settings label layoutStyle " + layoutStyle)), ul({
      className: "dropdown-menu",
      role: "menu"
    }, li({
      role: "presentation",
      'data-target': 'layoutStyle',
      'data-style': Dispositions.VERTICAL,
      onClick: this.handleChange
    }, a({
      role: "menuitem"
    }, t("settings label layoutStyle vertical"))), li({
      role: "presentation",
      'data-target': 'layoutStyle',
      'data-style': Dispositions.HORIZONTAL,
      onClick: this.handleChange
    }, a({
      role: "menuitem"
    }, t("settings label layoutStyle horizontal"))), li({
      role: "presentation",
      'data-target': 'layoutStyle',
      'data-style': Dispositions.THREE,
      onClick: this.handleChange
    }, a({
      role: "menuitem"
    }, t("settings label layoutStyle three"))))))), div({
      className: 'form-group'
    }, label({
      htmlFor: 'settings-listStyle',
      className: classLabel
    }, t("settings label listStyle")), div({
      className: classInput
    }, div({
      className: "dropdown"
    }, button({
      id: 'settings-listStyle',
      className: "btn btn-default dropdown-toggle",
      type: "button",
      "data-toggle": "dropdown"
    }, t("settings label listStyle " + listStyle)), ul({
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
    }, t("settings label listStyle compact")))))))), this._renderOption('displayConversation'), this._renderOption('composeInHTML'), this._renderOption('composeOnTop'), this._renderOption('messageDisplayHTML'), this._renderOption('messageDisplayImages'), this._renderOption('messageConfirmDelete'), this._renderOption('displayPreview'), this._renderOption('desktopNotifications'), this._renderOption('autosaveDraft'), fieldset(null, legend(null, t('settings plugins')), (function() {
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
        }, t('plugin name ' + pluginConf.name, {
          _: pluginConf.name
        })), div({
          className: 'col-sm-1'
        }, pluginConf.url != null ? span({
          className: 'clickable',
          onClick: this.pluginDel,
          'data-plugin': pluginName,
          title: t("settings plugin del")
        }, i({
          className: 'fa fa-trash-o'
        })) : input({
          id: 'settings-plugin-' + pluginName,
          checked: pluginConf.active,
          onChange: this.handleChange,
          'data-target': 'plugin',
          'data-plugin': pluginName,
          type: 'checkbox'
        })), window.plugins[pluginName].onHelp ? div({
          className: 'col-sm-1 plugin-help'
        }, span({
          className: 'clickable',
          onClick: this.pluginHelp,
          'data-plugin': pluginName,
          title: t("settings plugin help")
        }, i({
          className: 'fa fa-question-circle'
        }))) : void 0)));
      }
      return _results;
    }).call(this), form({
      className: 'form-horizontal',
      key: pluginName
    }, div({
      className: 'form-group'
    }, div({
      className: 'col-xs-4'
    }, input({
      id: 'newpluginName',
      name: 'newpluginName',
      ref: 'newpluginName',
      type: 'text',
      className: 'form-control',
      placeholder: t("settings plugin new name")
    })), div({
      className: 'col-xs-6'
    }, input({
      id: 'newpluginUrl',
      name: 'newpluginUrl',
      ref: 'newpluginUrl',
      type: 'text',
      className: 'form-control',
      placeholder: t("settings plugin new url")
    })), span({
      className: "col-xs-1 clickable",
      onClick: this.pluginAdd,
      title: t("settings plugin add")
    }, i({
      className: 'fa fa-plus'
    }))))));
  },
  _renderOption: function(option) {
    var classInput, classLabel;
    classLabel = 'col-sm-5 col-sm-offset-1 control-label';
    classInput = 'col-sm-6';
    return form({
      className: 'form-horizontal'
    }, div({
      className: 'form-group'
    }, label({
      htmlFor: 'settings-' + option,
      className: classLabel
    }, t("settings label " + option)), div({
      className: classInput
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
      case 'autosaveDraft':
      case 'composeInHTML':
      case 'composeOnTop':
      case 'desktopNotifications':
      case 'displayConversation':
      case 'displayPreview':
      case 'messageConfirmDelete':
      case 'messageDisplayHTML':
      case 'messageDisplayImages':
        settings = this.state.settings;
        settings[target.dataset.target] = target.checked;
        this.setState({
          settings: settings
        });
        SettingsActionCreator.edit(settings);
        if ((window.Notification != null) && settings.desktopNotifications) {
          return Notification.requestPermission(function(status) {
            if (Notification.permission !== status) {
              return Notification.permission = status;
            }
          });
        }
        break;
      case 'layoutStyle':
        settings = this.state.settings;
        settings.layoutStyle = target.dataset.style;
        LayoutActionCreator.setDisposition(settings.layoutStyle);
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
          pluginConf.active = window.plugins[pluginName].active;
        }
        this.setState({
          settings: settings
        });
        return SettingsActionCreator.edit(settings);
    }
  },
  pluginAdd: function() {
    var name, url;
    name = this.refs.newpluginName.getDOMNode().value.trim();
    url = this.refs.newpluginUrl.getDOMNode().value.trim();
    return PluginUtils.loadJS(url, (function(_this) {
      return function() {
        var settings;
        PluginUtils.activate(name);
        settings = _this.state.settings;
        settings.plugins[name] = {
          name: name,
          active: true,
          url: url
        };
        _this.setState({
          settings: settings
        });
        return SettingsActionCreator.edit(settings);
      };
    })(this));
  },
  pluginDel: function(event) {
    var pluginName, settings, target;
    event.preventDefault();
    target = event.currentTarget;
    pluginName = target.dataset.plugin;
    settings = this.state.settings;
    PluginUtils.deactivate(pluginName);
    delete settings.plugins[pluginName];
    this.setState({
      settings: settings
    });
    return SettingsActionCreator.edit(settings);
  },
  pluginHelp: function(event) {
    var pluginName, target;
    event.preventDefault();
    target = event.currentTarget;
    pluginName = target.dataset.plugin;
    return window.plugins[pluginName].onHelp();
  },
  registerMailto: function() {
    var loc;
    loc = window.location;
    return window.navigator.registerProtocolHandler("mailto", "" + loc.origin + loc.pathname + "#compose?mailto=%s", "Cozy");
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
var ActionTypes, AlertLevel, AppDispatcher, CSSTransitionGroup, LayoutActionCreator, LayoutStore, Modal, SocketUtils, StoreWatchMixin, Toast, a, button, classer, div, h4, i, pre, span, strong, _ref, _ref1;

_ref = React.DOM, a = _ref.a, h4 = _ref.h4, pre = _ref.pre, div = _ref.div, button = _ref.button, span = _ref.span, strong = _ref.strong, i = _ref.i;

SocketUtils = require('../utils/socketio_utils');

AppDispatcher = require('../app_dispatcher');

Modal = require('./modal');

StoreWatchMixin = require('../mixins/store_watch_mixin');

LayoutStore = require('../stores/layout_store');

LayoutActionCreator = require('../actions/layout_action_creator');

_ref1 = require('../constants/app_constants'), ActionTypes = _ref1.ActionTypes, AlertLevel = _ref1.AlertLevel;

CSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

module.exports = Toast = React.createClass({
  displayName: 'Toast',
  getInitialState: function() {
    return {
      modalErrors: false
    };
  },
  render: function() {
    var className, classes, hasErrors, showModal, toast;
    toast = this.props.toast.toJS();
    hasErrors = (toast.errors != null) && toast.errors.length;
    classes = classer({
      toast: true,
      'alert-dismissible': toast.finished,
      'toast-error': toast.level === AlertLevel.ERROR
    });
    if (hasErrors) {
      showModal = this.showModal.bind(this, toast.errors);
    }
    return div({
      className: classes,
      role: "alert",
      key: this.props.key
    }, this.state.modalErrors ? this.renderModal() : void 0, toast.message ? div({
      className: "message"
    }, toast.message) : void 0, toast.finished ? button({
      type: "button",
      className: "close",
      onClick: this.acknowledge
    }, span({
      'aria-hidden': "true"
    }, "×"), span({
      className: "sr-only"
    }, t("app alert close"))) : void 0, toast.actions != null ? (className = "btn btn-cancel btn-cozy-non-default btn-xs", div({
      className: 'toast-actions'
    }, toast.actions.map(function(action, id) {
      return button({
        className: className,
        type: "button",
        key: id,
        onClick: action.onClick
      }, action.label);
    }))) : void 0, hasErrors ? div({
      className: 'toast-actions'
    }, a({
      onClick: showModal
    }, t('there were errors', {
      smart_count: toast.errors.length
    }))) : void 0);
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
  }
});
});

;require.register("components/toast_container", function(exports, require, module) {
var CSSTransitionGroup, LayoutActionCreator, LayoutStore, Modal, StoreWatchMixin, Toast, ToastContainer, classer, div;

div = React.DOM.div;

Modal = require('./modal');

Toast = require('./toast');

StoreWatchMixin = require('../mixins/store_watch_mixin');

LayoutStore = require('../stores/layout_store');

LayoutActionCreator = require('../actions/layout_action_creator');

CSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

module.exports = ToastContainer = React.createClass({
  displayName: 'ToastContainer',
  mixins: [StoreWatchMixin([LayoutStore])],
  getStateFromStores: function() {
    return {
      toasts: LayoutStore.getToasts(),
      hidden: !LayoutStore.isShown()
    };
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    var isNextProps, isNextState;
    isNextState = _.isEqual(nextState, this.state);
    isNextProps = _.isEqual(nextProps, this.props);
    return !(isNextState && isNextProps);
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
    }, toasts));
  },
  toggleHidden: function() {
    if (this.state.hidden) {
      return LayoutActionCreator.toastsShow();
    } else {
      return LayoutActionCreator.toastsHide();
    }
  },
  _clearToasts: function() {
    return setTimeout(function() {
      var toasts;
      toasts = document.querySelectorAll('.toast-enter');
      return Array.prototype.forEach.call(toasts, function(e) {
        return e.classList.add('hidden');
      });
    }, 10000);
  },
  closeAll: function() {
    return LayoutActionCreator.clearToasts();
  },
  componentDidMount: function() {
    return this._clearToasts();
  },
  componentDidUpdate: function() {
    return this._clearToasts();
  }
});
});

;require.register("components/toolbar_conversation", function(exports, require, module) {
var LayoutActionCreator, LayoutStore, RouterMixin, StoreWatchMixin, Tooltips, a, button, classer, div, nav, _ref;

_ref = React.DOM, nav = _ref.nav, div = _ref.div, button = _ref.button, a = _ref.a;

Tooltips = require('../constants/app_constants').Tooltips;

classer = React.addons.classSet;

LayoutStore = require('../stores/layout_store');

LayoutActionCreator = require('../actions/layout_action_creator');

RouterMixin = require('../mixins/router_mixin');

StoreWatchMixin = require('../mixins/store_watch_mixin');

module.exports = React.createClass({
  displayName: 'ToolbarConversation',
  mixins: [RouterMixin, StoreWatchMixin([LayoutStore])],
  propTypes: {
    nextMessageID: React.PropTypes.string,
    nextConversationID: React.PropTypes.string,
    prevMessageID: React.PropTypes.string,
    prevConversationID: React.PropTypes.string,
    settings: React.PropTypes.object.isRequired
  },
  getStateFromStores: function() {
    return {
      fullscreen: LayoutStore.isPreviewFullscreen()
    };
  },
  getParams: function(messageID, conversationID) {
    if (this.props.settings.get('displayConversation' && (conversationID != null))) {
      return {
        action: 'conversation',
        parameters: {
          messageID: messageID,
          conversationID: conversationID
        }
      };
    } else {
      return {
        action: 'message',
        parameters: {
          messageID: messageID
        }
      };
    }
  },
  render: function() {
    return nav({
      className: 'toolbar toolbar-conversation btn-toolbar'
    }, div({
      className: 'btn-group'
    }, this.renderNav('prev'), this.renderNav('next')), this.renderFullscreen());
  },
  renderNav: function(direction) {
    var angle, conversationID, messageID, params, tooltipID, url, urlParams;
    if (this.props["" + direction + "MessageID"] == null) {
      return;
    }
    messageID = this.props["" + direction + "MessageID"];
    conversationID = this.props["" + direction + "ConversationID"];
    if (direction === 'prev') {
      tooltipID = Tooltips.PREVIOUS_CONVERSATION;
      angle = 'left';
    } else {
      tooltipID = Tooltips.NEXT_CONVERSATION;
      angle = 'right';
    }
    params = this.getParams(messageID, conversationID);
    urlParams = {
      direction: 'second',
      action: params.action,
      parameters: params.parameters
    };
    url = this.buildUrl(urlParams);
    return a({
      className: "btn btn-default fa fa-chevron-" + angle,
      onClick: (function(_this) {
        return function() {
          return _this.redirect(urlParams);
        };
      })(this),
      href: url,
      'aria-describedby': tooltipID,
      'data-tooltip-direction': 'left'
    });
  },
  renderFullscreen: function() {
    return button({
      onClick: LayoutActionCreator.toggleFullscreen,
      className: classer({
        clickable: true,
        btn: true,
        'btn-default': true,
        fa: true,
        fullscreen: true,
        'fa-compress': this.state.fullscreen,
        'fa-expand': !this.state.fullscreen
      })
    });
  }
});
});

;require.register("components/toolbar_message", function(exports, require, module) {
var FlagsConstants, LayoutActionCreator, MessageFlags, ToolboxActions, ToolboxMove, Tooltips, a, alertError, alertSuccess, button, cBtn, cBtnGroup, div, nav, _ref, _ref1,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ref = React.DOM, nav = _ref.nav, div = _ref.div, button = _ref.button, a = _ref.a;

_ref1 = require('../constants/app_constants'), MessageFlags = _ref1.MessageFlags, FlagsConstants = _ref1.FlagsConstants, Tooltips = _ref1.Tooltips;

ToolboxActions = require('./toolbox_actions');

ToolboxMove = require('./toolbox_move');

LayoutActionCreator = require('../actions/layout_action_creator');

alertError = LayoutActionCreator.alertError;

alertSuccess = LayoutActionCreator.notify;

cBtnGroup = 'btn-group btn-group-sm pull-right';

cBtn = 'btn btn-default fa';

module.exports = React.createClass({
  displayName: 'ToolbarMessage',
  propTypes: {
    message: React.PropTypes.object.isRequired,
    mailboxes: React.PropTypes.object.isRequired,
    selectedMailboxID: React.PropTypes.string.isRequired,
    onReply: React.PropTypes.func.isRequired,
    onReplyAll: React.PropTypes.func.isRequired,
    onForward: React.PropTypes.func.isRequired,
    onDelete: React.PropTypes.func.isRequired,
    onMove: React.PropTypes.func.isRequired,
    onHeaders: React.PropTypes.func.isRequired
  },
  render: function() {
    return nav({
      className: 'toolbar toolbar-message btn-toolbar',
      onClick: function(event) {
        return event.stopPropagation();
      }
    }, this.props.full ? div({
      className: cBtnGroup
    }, this.renderToolboxMove(), this.renderToolboxActions()) : void 0, this.props.full ? this.renderQuickActions() : void 0, this.renderReply());
  },
  renderReply: function() {
    return div({
      className: cBtnGroup
    }, button({
      className: "" + cBtn + " fa-mail-reply mail-reply",
      onClick: this.props.onReply,
      'aria-describedby': Tooltips.REPLY,
      'data-tooltip-direction': 'top'
    }), button({
      className: "" + cBtn + " fa-mail-reply-all mail-reply-all",
      onClick: this.props.onReplyAll,
      'aria-describedby': Tooltips.REPLY_ALL,
      'data-tooltip-direction': 'top'
    }), button({
      className: "" + cBtn + " fa-mail-forward mail-forward",
      onClick: this.props.onForward,
      'aria-describedby': Tooltips.FORWARD,
      'data-tooltip-direction': 'top'
    }));
  },
  renderQuickActions: function() {
    return div({
      className: cBtnGroup
    }, button({
      className: "" + cBtn + " fa-trash",
      onClick: this.props.onDelete,
      'aria-describedby': Tooltips.REMOVE_MESSAGE,
      'data-tooltip-direction': 'top'
    }));
  },
  renderToolboxActions: function() {
    var flags, isFlagged, isSeen, _ref2, _ref3;
    flags = this.props.message.get('flags') || [];
    isFlagged = (_ref2 = FlagsConstants.FLAGGED, __indexOf.call(flags, _ref2) >= 0);
    isSeen = (_ref3 = FlagsConstants.SEEN, __indexOf.call(flags, _ref3) >= 0);
    return ToolboxActions({
      ref: 'toolboxActions',
      mailboxes: this.props.mailboxes,
      isSeen: isSeen,
      isFlagged: isFlagged,
      messageID: this.props.message.get('id'),
      message: this.props.message,
      onMark: this.props.onMark,
      onHeaders: this.props.onHeaders,
      onConversationMark: this.props.onConversationMark,
      onConversationMove: this.props.onConversationMove,
      onConversationDelete: this.props.onConversationMove,
      direction: 'right',
      displayConversations: false
    });
  },
  renderToolboxMove: function() {
    return ToolboxMove({
      ref: 'toolboxMove',
      mailboxes: this.props.mailboxes,
      onMove: this.props.onMove,
      direction: 'right'
    });
  }
});
});

;require.register("components/toolbar_messageslist", function(exports, require, module) {
var ActionsToolbarMessagesList, FiltersToolbarMessagesList, LayoutActionCreator, SearchToolbarMessagesList, ToolbarMessagesList, aside, button, classer, i, _ref;

_ref = React.DOM, aside = _ref.aside, i = _ref.i, button = _ref.button;

classer = React.addons.classSet;

FiltersToolbarMessagesList = require('./toolbar_messageslist_filters');

SearchToolbarMessagesList = require('./toolbar_messageslist_search');

ActionsToolbarMessagesList = require('./toolbar_messageslist_actions');

LayoutActionCreator = require('../actions/layout_action_creator');

module.exports = ToolbarMessagesList = React.createClass({
  displayName: 'ToolbarMessagesList',
  propTypes: {
    settings: React.PropTypes.object.isRequired,
    accountID: React.PropTypes.string.isRequired,
    mailboxID: React.PropTypes.string.isRequired,
    mailboxes: React.PropTypes.object.isRequired,
    messages: React.PropTypes.object.isRequired,
    edited: React.PropTypes.bool.isRequired,
    selected: React.PropTypes.object.isRequired,
    allSelected: React.PropTypes.bool.isRequired,
    displayConversations: React.PropTypes.bool.isRequired,
    toggleEdited: React.PropTypes.func.isRequired,
    toggleAll: React.PropTypes.func.isRequired,
    afterAction: React.PropTypes.func
  },
  render: function() {
    return aside({
      role: 'toolbar'
    }, button({
      className: 'drawer-toggle',
      onClick: LayoutActionCreator.drawerToggle,
      title: t('menu toggle')
    }, i({
      className: 'fa fa-navicon'
    })), button({
      role: 'menuitem',
      'aria-selected': this.props.edited,
      onClick: this.props.toggleAll
    }, i({
      className: classer({
        fa: true,
        'fa-square-o': !this.props.edited,
        'fa-check-square-o': this.props.allSelected,
        'fa-minus-square-o': this.props.edited && !this.props.allSelected
      })
    })), this.props.edited ? ActionsToolbarMessagesList({
      settings: this.props.settings,
      mailboxID: this.props.mailboxID,
      mailboxes: this.props.mailboxes,
      messages: this.props.messages,
      selected: this.props.selected,
      displayConversations: this.props.displayConversations,
      afterAction: this.props.afterAction
    }) : void 0, !this.props.edited ? FiltersToolbarMessagesList({
      accountID: this.props.accountID,
      mailboxID: this.props.mailboxID
    }) : void 0, !this.props.edited ? SearchToolbarMessagesList({
      accountID: this.props.accountID,
      mailboxID: this.props.mailboxID
    }) : void 0);
  }
});
});

;require.register("components/toolbar_messageslist_actions", function(exports, require, module) {
var ActionsToolbarMessagesList, MessageActionCreator, ToolboxActions, ToolboxMove, Tooltips, button, div, i, _ref;

_ref = React.DOM, div = _ref.div, i = _ref.i, button = _ref.button;

Tooltips = require('../constants/app_constants').Tooltips;

ToolboxActions = require('./toolbox_actions');

ToolboxMove = require('./toolbox_move');

MessageActionCreator = require('../actions/message_action_creator');

module.exports = ActionsToolbarMessagesList = React.createClass({
  displayName: 'ActionsToolbarMessagesList',
  propTypes: {
    settings: React.PropTypes.object.isRequired,
    mailboxID: React.PropTypes.string.isRequired,
    mailboxes: React.PropTypes.object.isRequired,
    messages: React.PropTypes.object.isRequired,
    selected: React.PropTypes.object.isRequired,
    displayConversations: React.PropTypes.bool.isRequired,
    afterAction: React.PropTypes.func
  },
  _hasSelection: function() {
    return Object.keys(this.props.selected).length > 0;
  },
  _getSelectedAndMode: function(applyToConversation) {
    var conversationIDs, count, selected;
    selected = Object.keys(this.props.selected);
    count = selected.length;
    applyToConversation = Boolean(applyToConversation);
    if (applyToConversation == null) {
      applyToConversation = this.props.displayConversations;
    }
    if (selected.length === 0) {
      LayoutActionCreator.alertError(t('list mass no message'));
      return false;
    } else if (!applyToConversation) {
      return {
        count: count,
        messageIDs: selected,
        applyToConversation: applyToConversation
      };
    } else {
      conversationIDs = selected.map((function(_this) {
        return function(id) {
          return _this.props.messages.get(id).get('conversationID');
        };
      })(this));
      return {
        count: count,
        conversationIDs: conversationIDs,
        applyToConversation: applyToConversation
      };
    }
  },
  render: function() {
    return div({
      role: 'group'
    }, button({
      role: 'menuitem',
      onClick: this.onDelete,
      'aria-disabled': this._hasSelection(),
      'aria-describedby': Tooltips.DELETE_SELECTION,
      'data-tooltip-direction': 'bottom'
    }, i({
      className: 'fa fa-trash-o'
    })), !this.props.displayConversations ? ToolboxMove({
      ref: 'listToolboxMove',
      mailboxes: this.props.mailboxes,
      onMove: this.onMove,
      direction: 'left'
    }) : void 0, ToolboxActions({
      ref: 'listToolboxActions',
      direction: 'left',
      mailboxes: this.props.mailboxes,
      displayConversations: this.props.displayConversations,
      onMark: this.onMark,
      onConversationDelete: this.onConversationDelete,
      onConversationMark: this.onConversationMark,
      onConversationMove: this.onConversationMove
    }));
  },
  onDelete: function(applyToConversation) {
    var msg, noConfirm, options;
    if (!(options = this._getSelectedAndMode(applyToConversation))) {
      return;
    }
    if (options.applyToConversation) {
      msg = t('list delete conv confirm', {
        smart_count: options.count
      });
    } else {
      msg = t('list delete confirm', {
        smart_count: options.count
      });
    }
    noConfirm = !this.props.settings.get('messageConfirmDelete');
    if (noConfirm || window.confirm(msg)) {
      MessageActionCreator["delete"](options, (function(_this) {
        return function() {
          var firstMessageID;
          if (options.count > 0 && _this.props.messages.count() > 0) {
            firstMessageID = _this.props.messages.first().get('id');
            return MessageActionCreator.setCurrent(firstMessageID, true);
          }
        };
      })(this));
      if (this.props.afterAction != null) {
        return this.props.afterAction();
      }
    }
  },
  onMove: function(to, applyToConversation) {
    var from, options;
    if (!(options = this._getSelectedAndMode(applyToConversation))) {
      return;
    }
    from = this.props.mailboxID;
    MessageActionCreator.move(options, from, to, (function(_this) {
      return function() {
        var firstMessageID;
        if (options.count > 0 && _this.props.messages.count() > 0) {
          firstMessageID = _this.props.messages.first().get('id');
          return MessageActionCreator.setCurrent(firstMessageID, true);
        }
      };
    })(this));
    if (this.props.afterAction != null) {
      return this.props.afterAction();
    }
  },
  onMark: function(flag, applyToConversation) {
    var options;
    if (!(options = this._getSelectedAndMode(applyToConversation))) {
      return;
    }
    return MessageActionCreator.mark(options, flag);
  },
  onConversationDelete: function() {
    return this.onDelete(true);
  },
  onConversationMove: function(to) {
    return this.onMove(to, true);
  },
  onConversationMark: function(flag) {
    return this.onMark(flag, true);
  }
});
});

;require.register("components/toolbar_messageslist_filters", function(exports, require, module) {
var DateRangePicker, FiltersToolbarMessagesList, LayoutActionCreator, MessageFilter, MessageStore, Tooltips, button, div, i, span, _ref, _ref1;

_ref = React.DOM, div = _ref.div, span = _ref.span, i = _ref.i, button = _ref.button;

_ref1 = require('../constants/app_constants'), MessageFilter = _ref1.MessageFilter, Tooltips = _ref1.Tooltips;

LayoutActionCreator = require('../actions/layout_action_creator');

MessageStore = require('../stores/message_store');

DateRangePicker = require('./date_range_picker');

module.exports = FiltersToolbarMessagesList = React.createClass({
  displayName: 'FiltersToolbarMessagesList',
  propTypes: {
    accountID: React.PropTypes.string.isRequired,
    mailboxID: React.PropTypes.string.isRequired
  },
  getInitialState: function() {
    return {
      flag: 'ALL',
      filter: false,
      expanded: false
    };
  },
  showList: function() {
    var end, params, start, _ref2;
    LayoutActionCreator.filterMessages(MessageFilter[this.state.flag]);
    if (this.state.filter) {
      _ref2 = this.state.filter, start = _ref2[0], end = _ref2[1];
    } else {
      start = end = '';
    }
    LayoutActionCreator.sortMessages({
      order: '-',
      field: 'date',
      before: start,
      after: end
    });
    params = _.clone(MessageStore.getParams());
    params.accountID = this.props.accountID;
    params.mailboxID = this.props.mailboxID;
    return LayoutActionCreator.showMessageList({
      parameters: params
    });
  },
  onDateFilter: function(start, end) {
    var params;
    params = !!start && !!end ? {
      flag: false,
      filter: [start, end]
    } : {
      filter: false
    };
    return this.setState(params, this.showList);
  },
  toggleFilters: function(name) {
    var params;
    params = this.state.flag === name ? {
      flag: 'ALL'
    } : {
      flag: name,
      filter: false
    };
    return this.setState(params, this.showList);
  },
  render: function() {
    return div({
      role: 'group',
      className: 'filters',
      'aria-expanded': this.state.expanded
    }, i({
      role: 'presentation',
      className: 'fa fa-filter',
      onClick: this.toggleExpandState
    }), button({
      role: 'menuitem',
      'aria-selected': this.state.flag === 'UNSEEN',
      onClick: this.toggleFilters.bind(this, 'UNSEEN'),
      'aria-describedby': Tooltips.FILTER_ONLY_UNREAD,
      'data-tooltip-direction': 'bottom'
    }, i({
      className: 'fa fa-circle'
    }), span({
      className: 'btn-label'
    }, t('filters unseen'))), button({
      role: 'menuitem',
      'aria-selected': this.state.flag === 'FLAGGED',
      onClick: this.toggleFilters.bind(this, 'FLAGGED'),
      'aria-describedby': Tooltips.FILTER_ONLY_IMPORTANT,
      'data-tooltip-direction': 'bottom'
    }, i({
      className: 'fa fa-star'
    }), span({
      className: 'btn-label'
    }, t('filters flagged'))), button({
      role: 'menuitem',
      'aria-selected': this.state.flag === 'ATTACH',
      onClick: this.toggleFilters.bind(this, 'ATTACH'),
      'aria-describedby': Tooltips.FILTER_ONLY_WITH_ATTACHMENT,
      'data-tooltip-direction': 'bottom'
    }, i({
      className: 'fa fa-paperclip'
    }), span({
      className: 'btn-label'
    }, t('filters attach'))), DateRangePicker({
      active: !!this.state.filter,
      onDateFilter: this.onDateFilter
    }));
  },
  toggleExpandState: function() {
    return this.setState({
      expanded: !this.state.expanded
    });
  }
});
});

;require.register("components/toolbar_messageslist_search", function(exports, require, module) {
var Dropdown, LayoutActionCreator, MessageStore, SearchToolbarMessagesList, button, div, filters, i, input, _ref;

_ref = React.DOM, div = _ref.div, i = _ref.i, button = _ref.button, input = _ref.input;

Dropdown = require('./basic_components').Dropdown;

LayoutActionCreator = require('../actions/layout_action_creator');

MessageStore = require('../stores/message_store');

filters = {
  from: t("list filter from"),
  dest: t("list filter dest")
};

module.exports = SearchToolbarMessagesList = React.createClass({
  displayName: 'SearchToolbarMessagesList',
  propTypes: {
    accountID: React.PropTypes.string.isRequired,
    mailboxID: React.PropTypes.string.isRequired
  },
  getInitialState: function() {
    return {
      type: 'from',
      value: '',
      isEmpty: true
    };
  },
  showList: function() {
    var params;
    LayoutActionCreator.sortMessages({
      order: '-',
      field: this.state.type,
      after: "" + this.state.value + "\uFFFF",
      before: this.state.value
    });
    params = _.clone(MessageStore.getParams());
    params.accountID = this.props.accountID;
    params.mailboxID = this.props.mailboxID;
    return LayoutActionCreator.showMessageList({
      parameters: params
    });
  },
  onTypeChange: function(filter) {
    return this.setState({
      type: filter
    });
  },
  onChange: function(event) {
    return this.setState({
      value: event.target.value,
      isEmpty: event.target.value.length === 0
    });
  },
  onKeyUp: function(event) {
    if (event.key === "Enter" || this.state.isEmpty) {
      return this.showList();
    }
  },
  reset: function() {
    return this.setState({
      value: '',
      isEmpty: true
    }, this.showList);
  },
  render: function() {
    return div({
      role: 'group',
      className: 'search'
    }, Dropdown({
      value: this.state.type,
      values: filters,
      onChange: this.onTypeChange
    }), div({
      role: 'search'
    }, input({
      ref: 'searchterms',
      type: 'text',
      placeholder: t('filters search placeholder'),
      value: this.state.value,
      onChange: this.onChange,
      onKeyUp: this.onKeyUp
    }), !this.state.isEmpty ? div({
      className: 'btn-group'
    }, button({
      className: 'btn fa fa-check',
      onClick: this.showList
    }), button({
      className: 'btn fa fa-close',
      onClick: this.reset
    })) : void 0));
  }
});
});

;require.register("components/toolbox_actions", function(exports, require, module) {
var FlagsConstants, MenuDivider, MenuHeader, MenuItem, ToolboxActions, a, button, div, li, span, ul, _ref, _ref1,
  __slice = [].slice;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, a = _ref.a, button = _ref.button;

_ref1 = require('./basic_components'), MenuHeader = _ref1.MenuHeader, MenuItem = _ref1.MenuItem, MenuDivider = _ref1.MenuDivider;

FlagsConstants = require('../constants/app_constants').FlagsConstants;

module.exports = ToolboxActions = React.createClass({
  displayName: 'ToolboxActions',
  propTypes: {
    direction: React.PropTypes.string.isRequired,
    displayConversations: React.PropTypes.bool.isRequired,
    isFlagged: React.PropTypes.bool,
    isSeen: React.PropTypes.bool,
    mailboxes: React.PropTypes.object.isRequired,
    message: React.PropTypes.object,
    messageID: React.PropTypes.string,
    onConversationDelete: React.PropTypes.func.isRequired,
    onConversationMark: React.PropTypes.func.isRequired,
    onConversationMove: React.PropTypes.func.isRequired,
    onHeaders: React.PropTypes.func,
    onMark: React.PropTypes.func.isRequired
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var direction;
    direction = this.props.direction === 'right' ? 'right' : 'left';
    return div({
      className: 'menu-action btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default dropdown-toggle fa fa-cog',
      type: 'button',
      'data-toggle': 'dropdown'
    }, ' ', span({
      className: 'caret'
    })), ul.apply(null, [{
      className: "dropdown-menu dropdown-menu-" + direction,
      role: 'menu'
    }, !this.props.displayConversations ? this.renderMarkActions() : void 0, !this.props.displayConversations ? MenuDivider() : void 0].concat(__slice.call(this.renderRawActions()), [MenuDivider({
      key: 'divider'
    })], [MenuHeader({
      key: 'header-move'
    }, t('mail action conversation move'))], [this.renderMailboxes()])));
  },
  renderMarkActions: function() {
    var items;
    items = [
      MenuHeader({
        key: 'header-mark'
      }, t('mail action mark')), (this.props.isSeen == null) || !this.props.isSeen ? MenuItem({
        key: 'action-mark-seen',
        onClick: (function(_this) {
          return function() {
            return _this.props.onMark(FlagsConstants.SEEN);
          };
        })(this)
      }, t('mail mark read')) : void 0, (this.props.isSeen == null) || this.props.isSeen ? MenuItem({
        key: 'action-mark-unseen',
        onClick: (function(_this) {
          return function() {
            return _this.props.onMark(FlagsConstants.UNSEEN);
          };
        })(this)
      }, t('mail mark unread')) : void 0, (this.props.isFlagged == null) || this.props.isFlagged ? MenuItem({
        key: 'action-mark-noflag',
        onClick: (function(_this) {
          return function() {
            return _this.props.onMark(FlagsConstants.NOFLAG);
          };
        })(this)
      }, t('mail mark nofav')) : void 0, (this.props.isFlagged == null) || !this.props.isFlagged ? MenuItem({
        key: 'action-mark-flagged',
        onClick: (function(_this) {
          return function() {
            return _this.props.onMark(FlagsConstants.FLAGGED);
          };
        })(this)
      }, t('mail mark fav')) : void 0
    ];
    return items.filter(function(child) {
      return Boolean(child);
    });
  },
  renderRawActions: function() {
    var items;
    items = [
      !this.props.displayConversations ? MenuHeader({
        key: 'header-more'
      }, t('mail action more')) : void 0, this.props.messageID != null ? MenuItem({
        key: 'action-headers',
        onClick: this.props.onHeaders
      }, t('mail action headers')) : void 0, this.props.message != null ? MenuItem({
        key: 'action-raw',
        href: "raw/" + (this.props.message.get('id')),
        target: '_blank'
      }, t('mail action raw')) : void 0, MenuItem({
        key: 'conv-delete',
        onClick: this.props.onConversationDelete
      }, t('mail action conversation delete')), MenuItem({
        key: 'conv-seen',
        onClick: (function(_this) {
          return function() {
            return _this.props.onConversationMark(FlagsConstants.SEEN);
          };
        })(this)
      }, t('mail action conversation seen')), MenuItem({
        key: 'conv-unseen',
        onClick: (function(_this) {
          return function() {
            return _this.props.onConversationMark(FlagsConstants.UNSEEN);
          };
        })(this)
      }, t('mail action conversation unseen')), MenuItem({
        key: 'conv-flagged',
        onClick: (function(_this) {
          return function() {
            return _this.props.onConversationMark(FlagsConstants.FLAGGED);
          };
        })(this)
      }, t('mail action conversation flagged')), MenuItem({
        key: 'conv-noflag',
        onClick: (function(_this) {
          return function() {
            return _this.props.onConversationMark(FlagsConstants.NOFLAG);
          };
        })(this)
      }, t('mail action conversation noflag'))
    ];
    return items.filter(function(child) {
      return Boolean(child);
    });
  },
  renderMailboxes: function() {
    var id, mbox, _ref2, _results;
    _ref2 = this.props.mailboxes;
    _results = [];
    for (id in _ref2) {
      mbox = _ref2[id];
      if (id !== this.props.selectedMailboxID) {
        _results.push((function(_this) {
          return function(id) {
            return MenuItem({
              key: id,
              className: "pusher pusher-" + mbox.depth,
              onClick: function() {
                return _this.props.onConversationMove(id);
              }
            }, mbox.label);
          };
        })(this)(id));
      }
    }
    return _results;
  }
});
});

;require.register("components/toolbox_move", function(exports, require, module) {
var MenuHeader, MenuItem, ToolboxMove, a, button, div, i, li, p, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, a = _ref.a, button = _ref.button;

_ref1 = require('./basic_components'), MenuHeader = _ref1.MenuHeader, MenuItem = _ref1.MenuItem;

module.exports = ToolboxMove = React.createClass({
  displayName: 'ToolboxMove',
  shouldComponentUpdate: function(nextProps, nextState) {
    return !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
  },
  render: function() {
    var direction;
    direction = this.props.direction === 'right' ? 'right' : 'left';
    return div({
      className: 'menu-move btn-group btn-group-sm'
    }, button({
      className: 'btn btn-default dropdown-toggle fa fa-folder-open',
      type: 'button',
      'data-toggle': 'dropdown'
    }, ' ', span({
      className: 'caret'
    })), ul({
      className: "dropdown-menu dropdown-menu-" + direction,
      role: 'menu'
    }, MenuHeader(null, t('mail action move')), this.renderMailboxes()));
  },
  renderMailboxes: function() {
    var id, mbox, _ref2, _results;
    _ref2 = this.props.mailboxes;
    _results = [];
    for (id in _ref2) {
      mbox = _ref2[id];
      if (id !== this.props.selectedMailboxID) {
        _results.push((function(_this) {
          return function(id) {
            return MenuItem({
              key: id,
              className: "pusher pusher-" + mbox.depth,
              onClick: function() {
                return _this.props.onMove(id);
              }
            }, mbox.label);
          };
        })(this)(id));
      }
    }
    return _results;
  }
});
});

;require.register("components/tooltips-manager", function(exports, require, module) {

/*
This component must be used to declare tooltips.
They can't be then referenced from the other components.

See https://github.com/m4dz/aria-tips#use
 */
var Tooltips, div, p, _ref;

Tooltips = require('../constants/app_constants').Tooltips;

_ref = React.DOM, div = _ref.div, p = _ref.p;

module.exports = React.createClass({
  displayName: 'TooltipManager',
  shouldComponentUpdate: function() {
    return false;
  },
  render: function() {
    return div(null, this.getTooltip(Tooltips.REPLY, t('tooltip reply')), this.getTooltip(Tooltips.REPLY_ALL, t('tooltip reply all')), this.getTooltip(Tooltips.FORWARD, t('tooltip forward')), this.getTooltip(Tooltips.REMOVE_MESSAGE, t('tooltip remove message')), this.getTooltip(Tooltips.OPEN_ATTACHMENTS, t('tooltip open attachments')), this.getTooltip(Tooltips.OPEN_ATTACHMENT, t('tooltip open attachment')), this.getTooltip(Tooltips.DOWNLOAD_ATTACHMENT, t('tooltip download attachment')), this.getTooltip(Tooltips.PREVIOUS_CONVERSATION, t('tooltip previous conversation')), this.getTooltip(Tooltips.NEXT_CONVERSATION, t('tooltip next conversation')), this.getTooltip(Tooltips.FILTER_ONLY_UNREAD, t('tooltip filter only unread')), this.getTooltip(Tooltips.FILTER_ONLY_IMPORTANT, t('tooltip filter only important')), this.getTooltip(Tooltips.FILTER_ONLY_WITH_ATTACHMENT, t('tooltip filter only attachment')), this.getTooltip(Tooltips.ACCOUNT_PARAMETERS, t('tooltip account parameters')), this.getTooltip(Tooltips.DELETE_SELECTION, t('tooltip delete selection')), this.getTooltip(Tooltips.FILTER, t('tooltip filter')), this.getTooltip(Tooltips.QUICK_FILTER, t('tooltip display filters')), this.getTooltip(Tooltips.EXPUNGE_MAILBOX, t('tooltip expunge mailbox')));
  },
  getTooltip: function(id, content) {
    return p({
      id: id,
      role: "tooltip",
      'aria-hidden': "true"
    }, content);
  }
});
});

;require.register("components/topbar", function(exports, require, module) {
var LayoutActionCreator, MailboxList, ReactCSSTransitionGroup, RouterMixin, SearchForm, Topbar, a, body, button, div, form, i, input, p, span, strong, _ref;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span, a = _ref.a, button = _ref.button, strong = _ref.strong;

MailboxList = require('./mailbox_list');

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
          parameters: [selectedAccount != null ? selectedAccount.get('id') : void 0, mailbox.id]
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
      selectedMailboxID: selectedMailboxID
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
    'MAILBOX_EXPUNGE': 'MAILBOX_EXPUNGE',
    'RECEIVE_RAW_MESSAGE': 'RECEIVE_RAW_MESSAGE',
    'RECEIVE_RAW_MESSAGES': 'RECEIVE_RAW_MESSAGES',
    'MESSAGE_SEND': 'MESSAGE_SEND',
    'MESSAGE_DELETE': 'MESSAGE_DELETE',
    'MESSAGE_BOXES': 'MESSAGE_BOXES',
    'MESSAGE_FLAG': 'MESSAGE_FLAG',
    'LAST_ACTION': 'LAST_ACTION',
    'MESSAGE_CURRENT': 'MESSAGE_CURRENT',
    'RECEIVE_MESSAGE_DELETE': 'RECEIVE_MESSAGE_DELETE',
    'RECEIVE_MAILBOX_UPDATE': 'RECEIVE_MAILBOX_UPDATE',
    'SET_FETCHING': 'SET_FETCHING',
    'SET_SEARCH_QUERY': 'SET_SEARCH_QUERY',
    'RECEIVE_RAW_SEARCH_RESULTS': 'RECEIVE_RAW_SEARCH_RESULTS',
    'CLEAR_SEARCH_RESULTS': 'CLEAR_SEARCH_RESULTS',
    'SET_CONTACT_QUERY': 'SET_CONTACT_QUERY',
    'RECEIVE_RAW_CONTACT_RESULTS': 'RECEIVE_RAW_CONTACT_RESULTS',
    'CLEAR_CONTACT_RESULTS': 'CLEAR_CONTACT_RESULTS',
    'CONTACT_LOCAL_SEARCH': 'CONTACT_LOCAL_SEARCH',
    'SET_DISPOSITION': 'SET_DISPOSITION',
    'RESIZE_PREVIEW_PANE': 'RESIZE_PREVIEW_PANE',
    'MAXIMIZE_PREVIEW_PANE': 'MAXIMIZE_PREVIEW_PANE',
    'MINIMIZE_PREVIEW_PANE': 'MINIMIZE_PREVIEW_PANE',
    'DISPLAY_ALERT': 'DISPLAY_ALERT',
    'HIDE_ALERT': 'HIDE_ALERT',
    'REFRESH': 'REFRESH',
    'INTENT_AVAILABLE': 'INTENT_AVAILABLE',
    'RECEIVE_RAW_MAILBOXES': 'RECEIVE_RAW_MAILBOXES',
    'SETTINGS_UPDATED': 'SETTINGS_UPDATED',
    'RECEIVE_TASK_UPDATE': 'RECEIVE_TASK_UPDATE',
    'RECEIVE_TASK_DELETE': 'RECEIVE_TASK_DELETE',
    'CLEAR_TOASTS': 'CLEAR_TOASTS',
    'RECEIVE_REFRESH_UPDATE': 'RECEIVE_REFRESH_UPDATE',
    'RECEIVE_REFRESH_STATUS': 'RECEIVE_REFRESH_STATUS',
    'RECEIVE_REFRESH_DELETE': 'RECEIVE_REFRESH_DELETE',
    'RECEIVE_REFRESH_NOTIF': 'RECEIVE_REFRESH_NOTIF',
    'LIST_FILTER': 'LIST_FILTER',
    'LIST_SORT': 'LIST_SORT',
    'TOASTS_SHOW': 'TOASTS_SHOW',
    'TOASTS_HIDE': 'TOASTS_HIDE',
    'DRAWER_SHOW': 'DRAWER_SHOW',
    'DRAWER_HIDE': 'DRAWER_HIDE',
    'DRAWER_TOGGLE': 'DRAWER_TOGGLE'
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
    'ATTACH': 'attach',
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
    COL: 'column',
    ROW: 'row',
    RROW: 'row-reverse'
  },
  SpecialBoxIcons: {
    inboxMailbox: 'fa-inbox',
    draftMailbox: 'fa-file-text-o',
    sentMailbox: 'fa-send-o',
    trashMailbox: 'fa-trash-o',
    junkMailbox: 'fa-fire',
    allMailbox: 'fa-archive'
  },
  Tooltips: {
    REPLY: 'TOOLTIP_REPLY',
    REPLY_ALL: 'TOOLTIP_REPLY_ALL',
    FORWARD: 'TOOLTIP_FORWARD',
    REMOVE_MESSAGE: 'TOOLTIP_REMOVE_MESSAGE',
    OPEN_ATTACHMENTS: 'TOOLTIP_OPEN_ATTACHMENTS',
    OPEN_ATTACHMENT: 'TOOLTIP_OPEN_ATTACHMENT',
    DOWNLOAD_ATTACHMENT: 'TOOLTIP_DOWNLOAD_ATTACHMENT',
    PREVIOUS_CONVERSATION: 'TOOLTIP_PREVIOUS_CONVERSATION',
    NEXT_CONVERSATION: 'TOOLTIP_NEXT_CONVERSATION',
    FILTER_ONLY_UNREAD: 'TOOLTIP_FILTER_ONLY_UNREAD',
    FILTER_ONLY_IMPORTANT: 'TOOLTIP_FILTER_ONLY_IMPORTANT',
    FILTER_ONLY_WITH_ATTACHMENT: 'TOOLTIP_FILTER_ONLY_WITH_ATTACHMENT',
    ACCOUNT_PARAMETERS: 'TOOLTIP_ACCOUNT_PARAMETERS',
    DELETE_SELECTION: 'TOOLTIP_DELETE_SELECTION',
    FILTER: 'TOOLTIP_FILTER',
    QUICK_FILTER: 'TOOLTIP_QUICK_FILTER',
    COMPOSE_IMAGE: 'TOOLTIP_COMPOSE_IMAGE',
    COMPOSE_MOCK: 'TOOLTIP_COMPOSE_MOCK',
    EXPUNGE_MAILBOX: 'TOOLTIP_EXPUNGE_MAILBOX'
  }
};
});

;require.register("initialize", function(exports, require, module) {
var initIntent, initPerformances, initPlugins, logPerformances;

initPerformances = function() {
  var referencePoint;
  referencePoint = 0;
  window.start = function() {
    if ((typeof performance !== "undefined" && performance !== null ? performance.now : void 0) != null) {
      referencePoint = performance.now();
    }
    return React.addons.Perf.start();
  };
  window.stop = function() {
    if ((typeof performance !== "undefined" && performance !== null ? performance.now : void 0) != null) {
      console.log(performance.now() - referencePoint);
    }
    return React.addons.Perf.stop();
  };
  window.printWasted = function() {
    stop();
    return React.addons.Perf.printWasted();
  };
  window.printInclusive = function() {
    stop();
    return React.addons.Perf.printInclusive();
  };
  return window.printExclusive = function() {
    stop();
    return React.addons.Perf.printExclusive();
  };
};

logPerformances = function() {
  var message, now, timing, _ref, _ref1;
  timing = (_ref = window.performance) != null ? _ref.timing : void 0;
  now = Math.ceil((_ref1 = window.performance) != null ? _ref1.now() : void 0);
  if (timing != null) {
    message = "Response at " + (timing.responseEnd - timing.navigationStart) + "ms\nOnload at " + (timing.loadEventStart - timing.navigationStart) + "ms\nPage loaded in " + now + "ms";
    return window.cozyMails.logInfo(message);
  }
};

initIntent = function() {
  var IntentManager;
  IntentManager = require("./utils/intent_manager");
  window.intentManager = new IntentManager();
  return window.intentManager.send('nameSpace', {
    type: 'ping',
    from: 'mails'
  }).then(function(message) {
    return LayoutActionCreator.intentAvailability(true);
  }, function(error) {
    console.log("Intents not available");
    return LayoutActionCreator.intentAvailability(false);
  });
};

initPlugins = function() {
  var PluginUtils;
  PluginUtils = require("./utils/plugin_utils");
  if (window.settings.plugins == null) {
    window.settings.plugins = {};
  }
  PluginUtils.merge(window.settings.plugins);
  return PluginUtils.init();
};

window.onerror = function(msg, url, line, col, error) {
  var data, exception, xhr;
  console.error(msg, url, line, col, error, error != null ? error.stack : void 0);
  exception = (error != null ? error.toString() : void 0) || msg;
  if (exception !== window.lastError) {
    data = {
      data: {
        type: 'error',
        error: {
          msg: msg,
          full: exception,
          stack: error != null ? error.stack : void 0
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
  var AccountStore, Application, ContactStore, LayoutActionCreator, LayoutStore, MessageStore, PluginUtils, Router, SearchStore, SettingsStore, application, data, e, exception, locale, xhr;
  try {
    window.__DEV__ = window.location.hostname === 'localhost';
    initPerformances();
    window.cozyMails = require('./utils/api_utils');
    if (window.settings == null) {
      window.settings = {};
    }
    locale = window.locale || window.navigator.language || "en";
    window.cozyMails.setLocale(locale);
    LayoutActionCreator = require('./actions/layout_action_creator/');
    LayoutActionCreator.setDisposition(window.settings.layoutStyle);
    PluginUtils = require("./utils/plugin_utils");
    if (window.settings.plugins == null) {
      window.settings.plugins = {};
    }
    PluginUtils.merge(window.settings.plugins);
    PluginUtils.init();
    window.cozyMails.setSetting('plugins', window.settings.plugins);
    initIntent();
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
    window.rootComponent = React.renderComponent(application, document.body);
    Backbone.history.start();
    require('./utils/socketio_utils');
    if (window.settings.desktopNotifications && (window.Notification != null)) {
      Notification.requestPermission(function(status) {
        if (Notification.permission !== status) {
          return Notification.permission = status;
        }
      });
    }
    return logPerformances();
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

require.register("libs/flux/store/Store", function(exports, require, module) {
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

;require.register("locales/de", function(exports, require, module) {
module.exports = {
  "app loading": "Laden…",
  "app back": "Zurück",
  "app cancel": "Abbrechen",
  "app menu": "Menü",
  "app search": "Suchen…",
  "app alert close": "Schließen",
  "app unimplemented": "Noch nicht implementiert",
  "app error": "Argh, Ich bin nicht fähig diese Aktion auszuführen, bitte probieren Sie es wieder",
  "compose": "Neue E-Mail erstellen",
  "compose default": 'Hallo, wie geht es Ihnen Heute?',
  "compose from": "Von",
  "compose to": "An",
  "compose to help": "Empfänger Liste",
  "compose cc": "Cc",
  "compose cc help": "Kopie Liste",
  "compose bcc": "Bcc",
  "compose bcc help": "Verborgene Kopie Liste",
  "compose subject": "Betreff",
  "compose content": "Inhalt",
  "compose subject help": "Nachrichten Betreff",
  "compose reply prefix": "Re: ",
  "compose reply separator": "\n\nOn %{date}, %{sender} hat geschrieben \n",
  "compose forward prefix": "Fwd: ",
  "compose forward separator": "\n\nOn %{date}, %{sender} hat geschrieben \n",
  "compose action draft": "Entwurf speichern",
  "compose action send": "Senden",
  "compose action delete": "Entwurf löschen",
  "compose action sending": "Sendet",
  "compose toggle cc": "Cc",
  "compose toggle bcc": "Bcc",
  "compose error no dest": "Sie können keine Nachricht an Niemanden senden",
  "compose error no subject": "Bitte vergeben Sie einen Betreff",
  "compose confirm keep draft": "Nachricht wurde nicht gesandet, Entwurft behalten?",
  "compose wrong email format": "Die vergebene E-Mail Adresse hat kein geeignes Format: %{address}.",
  "compose forward header": "Gesendete Nachricht",
  "compose forward subject": "Betreff:",
  "compose forward date": "Datum:",
  "compose forward from": "Von:",
  "compose forward to": "An:",
  "menu show": "Menü anzeigen",
  "menu compose": "Erstellen",
  "menu account new": "Neues Konto",
  "menu settings": "Parameter",
  "menu mailbox total": "%{smart_count} Nachricht |||| %{smart_count} Nachrichten",
  "menu mailbox unread": ", %{smart_count} ungelesene Nachricht ||||, %{smart_count} ungelesene Nachrichten ",
  "menu mailbox new": " und %{smart_count} neue Nachricht |||| und %{smart_count} neue Nachrichten ",
  "menu favorites on": "Favoriten",
  "menu favorites off": "Alle",
  "menu toggle": "Menü umschalten",
  "menu refresh label": "Refresh",
  "menu refreshing": "Refreshing...",
  "list empty": "Keine E-Mail in diesem Postfach.",
  "no flagged message": "Keine wichtige E-Mail in diesem Postfach.",
  "no unseen message": "Alle E-Mails in dieser Box wurden gelesen",
  "no attach message": "Keine Nachrichten mit Anhängen",
  "no filter message": "Keine E-Mail für diesen Filter.",
  "list fetching": "Laden…",
  "list search empty": "Keine Ergebnis für diese Regel gefundnen \"%{query}\".",
  "list count": "%{smart_count} Nachricht in diesem Postfach |||| %{smart_count} NAchrichten in diesem Postfach",
  "list search count": "%{smart_count} result found. |||| %{smart_count} results found.",
  "list filter": "Filter",
  "list filter all": "Alle",
  "list filter unseen": "Ungelesen",
  "list filter flagged": "Wichtig",
  "list filter attach": "Anhänge",
  "list sort": "Sortieren",
  "list sort date": "Datum",
  "list sort subject": "Betreff",
  "list option compact": "Kompact",
  "list next page": "Mehr Nachrichten",
  "list end": "Das ist das Ende der Liste",
  "list mass no message": "Keine Nachrichten ausgewählt",
  "list delete confirm": "Möchten Sie wirklich diese Nachricht löschen ? ||||\nMöchten Sie wirklich diese %{smart_count} Nachrichten löschen ?",
  "list delete conv confirm": "Möchten Sie wirklich diese Unterhaltung löschen ? ||||\nMöchten Sie wirklich diese %{smart_count} Unterhaltungen löschen?",
  "mail to": "An: ",
  "mail cc": "Cc: ",
  "headers from": "Von",
  "headers to": "An",
  "headers cc": "Cc",
  "headers reply-to": "Antwort an",
  "headers date": "Datum",
  "headers subject": "Betreff",
  "length bytes": "Bytes",
  "length kbytes": "kB",
  "length mbytes": "MB",
  "mail action reply": "Anworten",
  "mail action reply all": "Allen antworten",
  "mail action forward": "Weiterleiten",
  "mail action delete": "Löschen",
  "mail action mark": "Markieren als",
  "mail action copy": "Kopie",
  "mail action move": "Verschieben",
  "mail action more": "Mehr",
  "mail action headers": "Headers",
  "mail action raw": "Roh Nachricht",
  "mail mark spam": "Spam",
  "mail mark nospam": "Kein Spam",
  "mail mark fav": "wichtig",
  "mail mark nofav": "Nicht wichtig",
  "mail mark read": "Gelesen",
  "mail mark unread": "Ungelesen",
  "mail confirm delete": "Möchten Sie wirklich die Nachricht löschen “%{subject}”?",
  "mail confirm delete nosubject": "Möchten Sie wirklich diese Nachricht löschen?",
  "mail action conversation delete": "Unterhaltung löschen",
  "mail action conversation move": "Unterhaltung verschieben",
  "mail action conversation seen": "Unterhaltung als gelesen markieren",
  "mail action conversation unseen": "Unterhaltung als ungelesen markieren",
  "mail conversation length": "%{smart_count} Nachricht in Unterhaltung. ||||\n%{smart_count} Nachrichten in Unterhaltung.",
  "account new": "Neues Konto",
  "account edit": "Konto bearbeiten",
  "account add": "Hinzufügen",
  "account save": "Speichern",
  "account saving": "Speicherung",
  "account check": "Verbindung prüfen",
  "account accountType short": "IMAP",
  "account accountType": "Konto Typ",
  "account imapPort short": "993",
  "account imapPort": "Port",
  "account imapSSL": "SSL verwenden",
  "account imapServer short": "imap.provider.tld",
  "account imapServer": "IMAP Server",
  "account imapTLS": "TLS verwenden",
  "account label short": "Ein kurzer Postfach Name",
  "account label": "Konto Name",
  "account login short": "Ihre E-Mail Addresse",
  "account login": "E-Mail Addresse",
  "account name short": "Ihr Name, dieser wird angezeigt",
  "account name": "Ihr Name",
  "account password": "Passwort",
  "account receiving server": "Postausgang Server",
  "account sending server": "Posteingang Server",
  "account smtpLogin short": "SMTP Benutzer",
  "account smtpLogin": "SMTP Benutzer (wenn abweichend vom Haupt Login)",
  "account smtpMethod": "Authentifizierungsmethode",
  "account smtpMethod NONE": "Keine",
  "account smtpMethod PLAIN": "Plain",
  "account smtpMethod LOGIN": "Login",
  "account smtpMethod CRAM-MD5": "Cram-MD5",
  "account smtpPassword short": "SMTP Passwort",
  "account smtpPassword": "SMTP Passwort (wenn abweichend vom Haupt Passwort)",
  "account smtpPort short": "465",
  "account smtpPort": "Port",
  "account smtpSSL": "SSL verwenden",
  "account smtpServer short": "smtp.provider.tld",
  "account smtpServer": "SMTP Server",
  "account smtpTLS": "STARTTLS verwenden",
  "account remove": "Konto löschen",
  "account remove confirm": "Möchten Sie dieses Konto wirklich löschen?",
  "account draft mailbox": "Entwurffach",
  "account sent mailbox": "Posteingang",
  "account trash mailbox": "Papierkorb",
  "account mailboxes": "Ordner",
  "account special mailboxes": "Specielle Postfächer",
  "account newmailbox label": "Neuer Ordner",
  "account newmailbox placeholder": "Name",
  "account newmailbox parent": "Parent:",
  "account confirm delbox": "Möchten Sie wirklich alle Nachrichtenn in diesem Postfach löschen?",
  "account tab account": "Konto",
  "account tab mailboxes": "Ordner",
  "account errors": "Einige Daten fehlen oder sind ungültig",
  "account type": "Konto Typ",
  "account updated": "Konto aktualisiert",
  "account checked": "Parameter ok",
  "account creation ok": "Yeah! Das Konot wurde erfolgreich erstellt. Wählen Sie nun die Postfächer, die Sie im Menü sehen möchten",
  "account refreshed": "Konto aktualisiert",
  "account refresh error": "Fehler beim aktualisieren der Konten, Parameter prüfen",
  "account identifiers": "Identifikation",
  "account actions": "Aktionen",
  "account danger zone": "Danger Zone",
  "account no special mailboxes": "Bitte konfigurieren Sie erst spezielle Ordner",
  "account smtp hide advanced": "Erweiterte Parameter verbergen",
  "account smtp show advanced": "Erweiterte Parameter anzeigen",
  "mailbox create ok": "Ordner erstellt",
  "mailbox create ko": "Fehler beim Ordner erstellen",
  "mailbox update ok": "Ordner aktualisiert",
  "mailbox update ko": "Fehler beim Ordner aktualisieren",
  "mailbox delete ok": "Ordner gelöscht",
  "mailbox delete ko": "Fehler beim Ordner löschen",
  "mailbox expunge ok": "Papierkorb geleeren",
  "mailbox expunge ko": "Fehler beim Papierkorb leeren",
  "mailbox title edit": "Ordner umbennen",
  "mailbox title delete": "Ordner löschen",
  "mailbox title edit save": "Speichern",
  "mailbox title edit cancel": "Abbrechen",
  "mailbox title add": "Neuen Ordner hinzufügen",
  "mailbox title add cancel": "Abbrechen",
  "mailbox title favorite": "Ordner wird angezeigt",
  "mailbox title not favorite": "Ordner wird nicht angezeigt",
  "mailbox title total": "Zusammen",
  "mailbox title unread": "Ungelesen",
  "mailbox title new": "Neu",
  "config error auth": "Falsche Verbindungsparameter",
  "config error imapPort": "Falscher IMAP Port",
  "config error imapServer": "Falscher IMAP Server",
  "config error imapTLS": "Falscher IMAP TLS",
  "config error smtpPort": "Falscher SMTP Port",
  "config error smtpServer": "Falscher SMTP Server",
  "config error nomailboxes": "Kein Ordner in diesem Konto, bitte erstellen Sie einen",
  "message action sent ok": "Nachricht senden",
  "message action sent ko": "Fehler beim Nachricht senden: ",
  "message action draft ok": "Nachricht gespeichert",
  "message action draft ko": "Fehler beim Nachricht speichern: ",
  "message delete ok": "Nachricht “%{subject}” gelöscht",
  "message delete ko": "Fehler bei Nachricht löschen: ",
  "message move ok": "Nachricht “%{subject}” wurde verschoben",
  "message move ko": "Fehler beim verschieben von Nachricht “%{subject}”: ",
  "message mark ok": "Nachricht markiert",
  "message mark ko": "Fehler beim Nachricht markieren: ",
  "conversation move ok": "Unterhaltung “%{subject}” wurde verschoben",
  "conversation move ko": "Fehler beim verschieben der Unterhaltung “%{subject}”",
  "conversation delete ok": "Unterhaltung “%{subject}” wurde gelöscht",
  "conversation delete ko": "Fehler beim löschen der Unterhaltung",
  "conversation seen ok": "Unterhaltung markiert als gelesen",
  "conversation seen ko": "Fehler beim gelesen markieren",
  "conversation unseen ok": "Conversation marked as unread",
  "conversation unseen ko": "Fehler beim ungelesen markieren",
  "undo last action": "Rückgänig",
  "message images warning": "Anzeige von Bildern innerhalb der Nachricht wurde geblockt",
  "message images display": "Bilder anzeigen",
  "message html display": "HTML anzeigen",
  "message delete no trash": "Bitte wählen Sie einen Ordner als Papierkorb",
  "message delete already": "Nachricht bereits im Papierkorb",
  "message move already": "Nachricht bereits in diesem Ordner",
  "undo ok": "Nachrichten wieder hergestellt",
  "undo ko": "Fehler beim Nachrichten Wiederherstellen",
  "undo unavalable": "Rückgängig Nachrichten löschen nicht möglich",
  "message preview title": "Anhänge ansehen",
  "settings title": "Einstellungen",
  "settings button save": "Speichern",
  "settings plugins": "Plugins",
  "settings plugins": "Ergänzende Module",
  "settings plugin add": "Hinzufügen",
  "settings plugin del": "Löschen",
  "settings plugin help": "Hilfe",
  "settings plugin new name": "Plugin Name",
  "settings plugin new url": "Plugin URL",
  "settings label composeInHTML": "Rich Nachrichten Editor",
  "settings label composeOnTop": "Antwort am Anfang der Nachricht",
  "settings label desktopNotifications": "Mitteilungen",
  "settings label displayConversation": "Unterhaltungen anzeigen",
  "settings label displayPreview": "Nachrichten Vorschau anzeigen",
  "settings label messageDisplayHTML": "Nachricht in HTML anzeigen",
  "settings label messageDisplayImages": "Bilder in der Nachrichten anzeigen",
  "settings label messageConfirmDelete": "Bestätigung bevor Nachricht löschen",
  "settings label layoutStyle": "Layout anzeigen",
  "settings label layoutStyle horizontal": "Horizontal",
  "settings label layoutStyle vertical": "Vertikal",
  "settings label layoutStyle three": "Drei Spalten",
  "settings label listStyle": "Nachrichten Listen Stil",
  "settings label listStyle default": "Normal",
  "settings label listStyle compact": "Kompact",
  "settings lang": "Sprache",
  "settings lang en": "English",
  "settings lang fr": "Français",
  "settings lang de": "Deutsch",
  "settings save error": "Einstellungen können nicht gespeichert werden, bitte propieren Sie es erneut",
  "picker drop here": "Dateien hier ablegen",
  "mailbox pick one": "Eine auswählen",
  "mailbox pick null": "Kein Postfach dafür",
  "task account-fetch": 'Holen %{account}',
  "task box-fetch": 'Holen %{box}',
  "task apply-diff-fetch": 'Holen Nachrichtenn aus %{box} von %{account}',
  "task apply-diff-remove": 'Löschen Nachrichten aus %{box} von %{account}',
  "task recover-uidvalidity": 'Analysiere',
  "there were errors": '%{smart_count} Fehler. |||| %{smart_count} Fehler.',
  "modal please report": "Bitte übertragen Sie diese Information zum Cozy.",
  "modal please contribute": "Bitte beitragen",
  "validate must not be empty": "Pflichtfeld",
  "toast hide": "Alarme verbergen",
  "toast show": "Alarme anzeigen",
  "toast close all": "Alle Alarme schließen",
  "notif new title": 'CozyEmail',
  "notif new": "%{smart_count} Nachricht nicht gelesen in Konto %{account}||||\n%{smart_count} Nachrichten nicht gelesen in Konto %{account}",
  "notif complete": "Import des Kontos %{account} abgeschlossen.",
  "contact form": "Kontakte auswählen",
  "contact form placeholder": "Kontakt Name",
  "contact create success": "%{contact} wurden zu Ihren Kontakten hinzu gefügt",
  "contact create error": "Fehler beim Hinzufügen Ihrer Kontakte : {error}",
  "gmail security tile": "Über GMAIL Sicherheit",
  "gmail security body": "GMAIL betrachtet Verbindungen die Benutzername und Passwort verwenden nicht als sicher.\nBitte klicken Sie auf den folgenden Link, Stellen Sie sicher das\nSie sich mit Ihrem Konto %{login} angemelden und geben Sie Apps mit geringerer Sicherheit frei.",
  "gmail security link": "Freigabe für Apps mit geringerer Sicherheit.",
  'plugin name Gallery': 'Anhang Gallerie',
  'plugin name medium-editor': 'Medium Editor',
  'plugin name MiniSlate': 'MiniSlate Editor',
  'plugin name Sample JS': 'Beispiel',
  'plugin name Keyboard shortcuts': 'Tastaturkombinationen',
  'plugin name VCard': 'Kontact VCards',
  'plugin modal close': 'Schließen',
  'calendar unknown format': "Diese Nachricht enthält eine Einladung für ein Ereignis in einem derzeitig unbekannten Format.",
  "tooltip reply": "Answer",
  "tooltip reply all": "Answer to all",
  "tooltip forward": "Forward",
  "tooltip remove message": "Remove",
  "tooltip open attachments": "Open attachment list",
  "tooltip open attachment": "Open attachment",
  "tooltip download attachment": "Download the attachment",
  "tooltip previous conversation": "Go to previous conversation",
  "tooltip next conversation": "Go to next conversation",
  "tooltip filter only unread": "Nur ungelesene Nachrichten anzeigen",
  "tooltip filter only important": "Nur wichtige Nachrichten anzeigen",
  "tooltip filter only attachment": "Nur Nachrichten mit Anhängen anzeigen",
  "tooltip account parameters": "Account parameters",
  "tooltip delete selection": "Delete all selected messages"
};
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
  "compose wrong email format": "The given email is unproperly formatted: %{address}.",
  "compose forward header": "Forwarded message",
  "compose forward subject": "Subject:",
  "compose forward date": "Date:",
  "compose forward from": "From:",
  "compose forward to": "To:",
  "menu show": "Show menu",
  "menu compose": "Write",
  "menu account new": "New Mailbox",
  "menu settings": "Parameters",
  "menu mailbox total": "%{smart_count} message|||| %{smart_count} messages",
  "menu mailbox unread": ", %{smart_count} unread message ||||, %{smart_count} unread messages ",
  "menu mailbox new": " and %{smart_count} new message|||| and %{smart_count} new messages ",
  "menu favorites on": "Favorites",
  "menu favorites off": "All",
  "menu toggle": "Toggle Menu",
  "menu refresh label": "Refresh",
  "menu refreshing": "Refreshing...",
  "list empty": "No email in this box.",
  "no flagged message": "No Important email in this box.",
  "no unseen message": "All emails have been read in this box",
  "no attach message": "No message with attachments",
  "no filter message": "No email for this filter.",
  "list fetching": "Loading…",
  "list search empty": "No result found for the query \"%{query}\".",
  "list count": "%{smart_count} message in this box |||| %{smart_count} messages in this box",
  "list search count": "%{smart_count} result found. |||| %{smart_count} results found.",
  "list filter": "Filter",
  "list filter all": "All",
  "list filter unseen": "Unseen",
  "list filter flagged": "Important",
  "list filter attach": "Attachments",
  "list filter from": "Sender is",
  "list filter date": "Date in",
  "list filter date placeholder": "DD/MM/YYYY",
  "list filter dest": "Recipient is",
  "list filter subject": "Subject starts with…",
  "list sort": "Sort",
  "list sort date": "Date",
  "list sort subject": "Subject",
  "list option compact": "Compact",
  "list next page": "More messages",
  "list end": "This is the end of the road",
  "list mass no message": "No message selected",
  "list delete confirm": "Do you really want to delete this message ? ||||\nDo you really want to delete %{smart_count} messages?",
  "list delete conv confirm": "Do you really want to delete this conversation ? ||||\nDo you really want to delete %{smart_count} conversation?",
  "mail to": "To: ",
  "mail cc": "Cc: ",
  "headers from": "From",
  "headers to": "To",
  "headers cc": "Cc",
  "headers reply-to": "Reply to",
  "headers date": "Date",
  "headers subject": "Subject",
  "load more messages": "load %{smart_count} more message |||| load %{smart_count} more messages",
  "length bytes": "bytes",
  "length kbytes": "Kb",
  "length mbytes": "Mb",
  "mail action reply": "Reply",
  "mail action reply all": "Reply all",
  "mail action forward": "Forward",
  "mail action delete": "Delete",
  "mail action mark": "Mark as",
  "mail action copy": "Copy",
  "mail action move": "Move",
  "mail action more": "More",
  "mail action headers": "Headers",
  "mail action raw": "Raw message",
  "mail mark spam": "Spam",
  "mail mark nospam": "No spam",
  "mail mark fav": "Important",
  "mail mark nofav": "Not important",
  "mail mark read": "Read",
  "mail mark unread": "Unread",
  "mail confirm delete": "Do you really want to delete message “%{subject}”?",
  "mail confirm delete nosubject": "Do you really want to delete this message?",
  "mail action conversation delete": "Delete conversation",
  "mail action conversation move": "Move conversation",
  "mail action conversation seen": "Mark conversation as read",
  "mail action conversation unseen": "Mark conversation as unread",
  "mail action conversation flagged": "Mark conversation as important",
  "mail action conversation noflag": "Mark conversation as normal",
  "mail conversation length": "%{smart_count} message dans cette conversation. ||||\n%{smart_count} messages dans cette conversation.",
  "account new": "New account",
  "account edit": "Edit account",
  "account add": "Add",
  "account save": "Save",
  "account saving": "Saving",
  "account check": "Check connection",
  "account accountType short": "IMAP",
  "account accountType": "Account type",
  "account imapPort short": "993",
  "account imapPort": "Port",
  "account imapSSL": "Use SSL",
  "account imapServer short": "imap.provider.tld",
  "account imapServer": "IMAP server",
  "account imapTLS": "Use TLS",
  "account imapLogin short": "IMAP user",
  "account imapLogin": "IMAP user (if different from email address)",
  "account label short": "A short mailbox name",
  "account label": "Account label",
  "account login short": "Your email address",
  "account login": "Email address",
  "account name short": "Your name, as it will be displayed",
  "account name": "Your name",
  "account password": "Password",
  "account receiving server": "Receiving server",
  "account sending server": "Sending server",
  "account smtpLogin short": "SMTP user",
  "account smtpLogin": "SMTP user (if different from email address)",
  "account smtpMethod": "Authentification method",
  "account smtpMethod NONE": "None",
  "account smtpMethod PLAIN": "Plain",
  "account smtpMethod LOGIN": "Login",
  "account smtpMethod CRAM-MD5": "Cram-MD5",
  "account smtpPassword short": "SMTP password",
  "account smtpPassword": "SMTP password (if different from IMAP password)",
  "account smtpPort short": "465",
  "account smtpPort": "Port",
  "account smtpSSL": "Use SSL",
  "account smtpServer short": "smtp.provider.tld",
  "account smtpServer": "SMTP server",
  "account smtpTLS": "Use STARTTLS",
  "account remove": "Remove this account",
  "account remove confirm": "Do you really want to remove this account?",
  "account draft mailbox": "Draft box",
  "account sent mailbox": "Sent box",
  "account trash mailbox": "Trash",
  "account mailboxes": "Folders",
  "account special mailboxes": "Special mailboxes",
  "account newmailbox label": "New Folder",
  "account newmailbox placeholder": "Name",
  "account newmailbox parent": "Parent:",
  "account confirm delbox": "Do you really want to delete all messages in this box?",
  "account tab account": "Account",
  "account tab mailboxes": "Folders",
  "account errors": "Some data are missing or invalid",
  "account type": "Account type",
  "account updated": "Account updated",
  "account checked": "Parameters ok",
  "account creation ok": "Yeah! The account has been successfully created. Now select the mailboxes you want to see in the menu",
  "account refreshed": "Account refreshed",
  "account refresh error": "Error refreshing accounts, check parameters",
  "account identifiers": "Identification",
  "account actions": "Actions",
  "account danger zone": "Danger Zone",
  "account no special mailboxes": "Please configure special folders first",
  "account imap hide advanced": "Hide advanced parameters",
  "account imap show advanced": "Show advanced parameters",
  "account smtp hide advanced": "Hide advanced parameters",
  "account smtp show advanced": "Show advanced parameters",
  "account tab signature": "Signature",
  "account signature short": "Type here the text that will be added to the bottom of all your emails.",
  "account signature": "Email Signature",
  "account signature save": "Save",
  "mailbox create ok": "Folder created",
  "mailbox create ko": "Error creating folder",
  "mailbox update ok": "Folder updated",
  "mailbox update ko": "Error updating folder",
  "mailbox delete ok": "Folder deleted",
  "mailbox delete ko": "Error deleting folder",
  "mailbox expunge ok": "Folder expunged",
  "mailbox expunge ko": "Error expunging folder",
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
  "config error imapPort": "Wrong IMAP parameters",
  "config error imapServer": "Wrong IMAP server",
  "config error imapTLS": "Wrong IMAP TLS",
  "config error smtpPort": "Wrong SMTP Port",
  "config error smtpServer": "Wrong SMTP Server",
  "config error nomailboxes": "No folder in this account, please create one",
  "action undo": "Undo",
  "action undo ok": "Action cancelled",
  "action undo ko": "Unable to undo action",
  "message action sent ok": "Message sent",
  "message action sent ko": "Error sending message: ",
  "message action draft ok": "Message saved",
  "message action draft ko": "Error saving message: ",
  "message delete ok": "Message “%{subject}” deleted",
  "message delete ko": "Error deleting message: ",
  "message move ok": "Message “%{subject}” moved",
  "message move ko": "Error moving message “%{subject}”: ",
  "message mark ok": "Message marked",
  "message mark ko": "Error marking message: ",
  "draft delete ok": "Draft “%{subject}” deleted",
  "draft delete ko": "Error deleting draft: ",
  "draft move ok": "Draft “%{subject}” moved",
  "draft move ko": "Error moving draft “%{subject}”: ",
  "draft mark ok": "Draft marked",
  "draft mark ko": "Error marking message: ",
  "conversation move ok": "Conversation “%{subject}” moved",
  "conversation move ko": "Error moving conversation “%{subject}”",
  "conversation delete ok": "Conversation “%{subject}” deleted",
  "conversation delete ko": "Error deleting conversation",
  "conversation seen ok": "Conversation marked as read",
  "conversation seen ko": "Error",
  "conversation unseen ok": "Conversation marked as unread",
  "conversation unseen ko": "Error",
  "undo last action": "Undo last action",
  "conversation flagged ko": "Error",
  "conversation noflag ko": "Error",
  "conversations move ok": "%{smart_count} conversation moved||||\n%{smart_count} conversations moved",
  "conversations move ko": "Error moving %{smart_count} conversation||||\nError moving %{smart_count} conversations",
  "conversations delete ok": "%{smart_count} conversation deleted||||\n%{smart_count} conversations deleted",
  "conversations delete ko": "Error deleting %{smart_count} conversation ||||\nError deleting %{smart_count} conversations",
  "conversations seen ok": "%{smart_count} conversation moved||||\n%{smart_count} conversations moved",
  "conversations seen ko": "Error marking %{smart_count} as read||||\nError marking %{smart_count} as read",
  "conversations unseen ok": "%{smart_count} conversation marked as unread||||\n%{smart_count} conversations marked as unread",
  "conversations unseen ko": "Error marking %{smart_count} conversations as unread||||\nError marking %{smart_count} conversations as unread",
  "conversations flagged ko": "Error marking %{smart_count} conversation as flagged||||\nError marking %{smart_count} conversations as flagged",
  "conversations noflag ko": "%{smart_count} conversation unflagged||||\n%{smart_count} conversations unflagged",
  "message images warning": "Display of images inside message has been blocked",
  "message images display": "Display images",
  "message html display": "Display HTML",
  "message delete no trash": "Please select a Trash folder",
  "message delete already": "Message already in trash folder",
  "message move already": "Message already in this folder",
  "undo ok": "Undone",
  "undo ko": "Error undoing some action",
  "undo unavailable": "Undo not available",
  "message preview title": "View attachments",
  "settings title": "Settings",
  "settings button save": "Save",
  "settings plugins": "Add ons",
  "settings plugins": "Modules complémentaires",
  "settings plugin add": "Add",
  "settings plugin del": "Delete",
  "settings plugin help": "Help",
  "settings plugin new name": "Plugin Name",
  "settings plugin new url": "Plugin URL",
  "settings label autosaveDraft": "Save draft message while composing",
  "settings label composeInHTML": "Rich message editor",
  "settings label composeOnTop": "Reply on top of message",
  "settings label desktopNotifications": "Notifications",
  "settings label displayConversation": "Display conversations",
  "settings label displayPreview": "Display message preview",
  "settings label messageDisplayHTML": "Display message in HTML",
  "settings label messageDisplayImages": "Display images inside messages",
  "settings label messageConfirmDelete": "Confirm before deleting a message",
  "settings label layoutStyle": "Display Layout",
  "settings label layoutStyle horizontal": "Horizontal",
  "settings label layoutStyle vertical": "Vertical",
  "settings label layoutStyle three": "Three cols",
  "settings label listStyle": "Message list style",
  "settings label listStyle default": "Normal",
  "settings label listStyle compact": "Compact",
  "settings lang": "Language",
  "settings lang en": "English",
  "settings lang fr": "Français",
  "settings lang de": "Deutsch",
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
  "validate must not be empty": "This field is required",
  "toast hide": "Hide alerts",
  "toast show": "Display alerts",
  "toast close all": "Close all alerts",
  "notif new title": 'CozyEmail',
  "notif new": "%{smart_count} message not read in account %{account}||||\n%{smart_count} messages not read in account %{account}",
  "notif complete": "Importation of account %{account} complete.",
  "contact form": "Select contacts",
  "contact form placeholder": "contact name",
  "contact create success": "%{contact} has been added to your contacts",
  "contact create error": "Error adding to your contacts : {error}",
  "message contact creation": "Do you want to create a contact for %{contact}?",
  "gmail security tile": "About Gmail security",
  "gmail security body": "Gmail considers connection using username and password not safe.\nPlease click on the following link, make sure\nyou are connected with your %{login} account and enable access for\nless secure apps.",
  "gmail security link": "Enable access for less secure apps.",
  'plugin name Gallery': 'Attachment gallery',
  'plugin name medium-editor': 'Medium editor',
  'plugin name MiniSlate': 'MiniSlate editor',
  'plugin name Sample JS': 'Sample',
  'plugin name Keyboard shortcuts': 'Keyboard shortcuts',
  'plugin name VCard': 'Contacts VCards',
  'plugin modal close': 'Close',
  'calendar unknown format': "This message contains an invite to an event in a currently unknown format.",
  "tooltip reply": "Answer",
  "tooltip reply all": "Answer to all",
  "tooltip forward": "Forward",
  "tooltip remove message": "Remove",
  "tooltip open attachments": "Open attachment list",
  "tooltip open attachment": "Open attachment",
  "tooltip download attachment": "Download the attachment",
  "tooltip previous conversation": "Go to previous conversation",
  "tooltip next conversation": "Go to next conversation",
  "tooltip filter only unread": "Show only unread messages",
  "tooltip filter only important": "Show only important messages",
  "tooltip filter only attachment": "Show only messages with attachment",
  "tooltip account parameters": "Account parameters",
  "tooltip delete selection": "Delete all selected messages",
  'tooltip filter': 'Filter',
  'tooltip display filters': 'Display filters',
  'tooltip expunge mailbox': 'Expunge mailbox',
  'filters unseen': 'unread',
  'filters flagged': 'stared',
  'filters attach': 'attachments',
  'filters search placeholder': 'Search...',
  'daterangepicker placeholder': 'by date',
  'daterangepicker presets yesterday': 'yesterday',
  'daterangepicker presets last week': 'last week',
  'daterangepicker presets last month': 'last month',
  'daterangepicker clear': 'clear'
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
  "compose action draft": "Enregistrer",
  "compose action send": "Envoyer",
  "compose action sending": "Envoi…",
  "compose action delete": "Supprimer",
  "compose toggle cc": "Copie à",
  "compose toggle bcc": "Copie cachée à",
  "compose error no dest": "Vous n'avez pas saisi de destinataires",
  "compose error no subject": "Vous n'avez pas saisi de sujet",
  "compose confirm keep draft": "Vous n'avez pas envoyé le message, voulez-vous conserver le brouillon ?",
  "compose wrong email format": "L'addresse mail donnée n'est pas bien formattée : %{address}.",
  "compose forward header": "Message transféré",
  "compose forward subject": "Sujet :",
  "compose forward date": "Date :",
  "compose forward from": "De :",
  "compose forward to": "Pour :",
  "menu show": "Montrer le menu",
  "menu compose": "Écrire",
  "menu account new": "Ajouter un compte",
  "menu settings": "Paramètres",
  "menu mailbox total": "%{smart_count} message |||| %{smart_count} messages ",
  "menu mailbox unread": " dont %{smart_count} non lu |||| dont %{smart_count} non lus ",
  "menu mailbox new": " et %{smart_count} nouveaux |||| et %{smart_count} nouveaux ",
  "menu favorites on": "Favoris",
  "menu favorites off": "Toutes",
  "menu toggle": "Menu",
  "menu refresh label": "Rafraîchir",
  "menu refreshing": "Rafraîchissement en cours...",
  "list empty": "Pas d'email dans cette boîte..",
  "no flagged message": "Pas d'email important dans cette boîte.",
  "no unseen message": "Pas d'email non-lu dans cette boîte.",
  "no attach message": "Pas d'email avec des pièces jointes.",
  "no filter message": "Pas d'email pour ce filtre.",
  "list fetching": "Chargement…",
  "list search empty": "Aucun résultat trouvé pour la requête \"%{query}\".",
  "list count": "%{smart_count} message dans cette boite |||| %{smart_count} messages dans cette boite",
  "list search count": "%{smart_count} résultat trouvé. |||| %{smart_count} résultats trouvés.",
  "list filter": "Filtrer",
  "list filter all": "Tous",
  "list filter unseen": "Non lus",
  "list filter flagged": "Importants",
  "list filter attach": "Pièces jointes",
  "list filter from": "Expédié par",
  "list filter date": "Date entre",
  "list filter date placeholder": "JJ/MM/AAAA",
  "list filter dest": "Destiné à",
  "list filter subject": "Sujet commence par…",
  "list sort": "Trier",
  "list sort date": "Date",
  "list sort subject": "Sujet",
  "list option compact": "Compact",
  "list next page": "Davantage de messages",
  "list end": "FIN",
  "list mass no message": "Aucun message sélectionné",
  "list delete confirm": "Voulez-vous vraiment supprimer ce message ?||||\nVoulez-vous vraiment supprimer %{smart_count} messages ?",
  "list delete conv confirm": "Voulez-vous vraiment supprimer cette conversation ?||||\nVoulez-vous vraiment supprimer %{smart_count} conversations ?",
  "mail to": "À ",
  "mail cc": "Copie ",
  "headers from": "De",
  "headers to": "À",
  "headers cc": "Copie",
  "headers reply-to": "Répondre à",
  "headers date": "Date",
  "headers subject": "Objet",
  "load more messages": "afficher %{smart_count} message supplémentaire |||| afficher %{smart_count} messages supplémentaires",
  "length bytes": "octets",
  "length kbytes": "ko",
  "length mbytes": "Mo",
  "mail action reply": "Répondre",
  "mail action reply all": "Répondre à tous",
  "mail action forward": "Transférer",
  "mail action delete": "Supprimer",
  "mail action mark": "Marquer comme",
  "mail action copy": "Copier",
  "mail action move": "Déplacer",
  "mail action more": "Plus",
  "mail action headers": "Entêtes",
  "mail action raw": "Message brut",
  "mail mark spam": "Pourriel",
  "mail mark nospam": "Légitime",
  "mail mark fav": "Important",
  "mail mark nofav": "Normal",
  "mail mark read": "Lu",
  "mail mark unread": "Non lu",
  "mail confirm delete": "Voulez-vous vraiment supprimer le message « %{subject} » ?",
  "mail confirm delete nosubject": "Voulez-vous vraiment supprimer ce message",
  "mail action conversation delete": "Supprimer la conversation",
  "mail action conversation move": "Déplacer la conversation",
  "mail action conversation seen": "Marquer la conversation comme lue",
  "mail action conversation unseen": "Marquer la conversation comme non lue",
  "mail action conversation flagged": "Marquer la conversation comme importante",
  "mail action conversation noflag": "Marquer la conversation comme normale",
  "mail conversation length": "%{smart_count} message dans cette conversation. ||||\n%{smart_count} messages dans cette conversation.",
  "account new": "Nouveau compte",
  "account edit": "Modifier le compte",
  "account add": "Créer",
  "account save": "Enregistrer",
  "account saving": "En cours…",
  "account check": "Tester la connexion",
  "account accountType short": "IMAP",
  "account accountType": "Type de compte",
  "account imapPort short": "993",
  "account imapPort": "Port",
  "account imapSSL": "Utiliser SSL",
  "account imapServer short": "imap.fournisseur.tld",
  "account imapServer": "Serveur IMAP",
  "account imapTLS": "Utiliser STARTTLS",
  "account imapLogin short": "Utilisateur IMAP",
  "account imapLogin": "Utilisateur IMAP (s'il est différent de l'adresse mail)",
  "account label short": "Nom abrégé",
  "account label": "Nom du compte",
  "account login short": "Votre adresse électronique",
  "account login": "Adresse",
  "account name short": "Votre nom, tel qu'il sera affiché",
  "account name": "Votre nom",
  "account password": "Mot de passe",
  "account receiving server": "Serveur de réception",
  "account sending server": "Serveur d'envoi",
  "account smtpLogin short": "Utilisateur SMTP",
  "account smtpLogin": "Utilisateur SMTP (s'il est différent de l'adresse Mail)",
  "account smtpMethod": "Méthode d'authentification",
  "account smtpMethod NONE": "Aucune",
  "account smtpMethod PLAIN": "Simple",
  "account smtpMethod LOGIN": "Login",
  "account smtpMethod CRAM-MD5": "Cram-MD5",
  "account smtpPassword short": "Mot de passe SMTP",
  "account smtpPassword": "Mot de passe SMTP (s'il est différent de celui du serveur IMAP)",
  "account smtpPort short": "465",
  "account smtpPort": "Port",
  "account smtpSSL": "Utiliser SSL",
  "account smtpServer short": "smtp.fournisseur.tld",
  "account smtpServer": "Serveur sortant",
  "account smtpTLS": "Utiliser STARTTLS",
  "account remove": "Supprimer ce compte",
  "account remove confirm": "Voulez-vous vraiment supprimer ce compte ?",
  "account draft mailbox": "Enregistrer les brouillons dans",
  "account sent mailbox": "Enregistrer les messages envoyés dans",
  "account trash mailbox": "Corbeille",
  "account mailboxes": "Dossiers",
  "account special mailboxes": "Dossiers spéciaux",
  "account newmailbox label": "Nouveaux dossier",
  "account newmailbox placeholder": "Nom",
  "account newmailbox parent": "Créer sous",
  "account confirm delbox": "Voulez-vous vraiment supprimer tous les messages de la corbeille ?",
  "account tab account": "Compte",
  "account tab mailboxes": "Dossiers",
  "account errors": "Certaines informations manquent ou sont incorrectes",
  "account type": "Type de compte",
  "account updated": "Modification enregistrée",
  "account checked": "Paramètres corrects",
  "account refreshed": "Actualisé",
  "account refresh error": "Une erreur est survenue, vérifiez les paramètres de connexion aux comptes",
  "account creation ok": "Youpi, le compte a été créé ! Sélectionnez à présent les dossiers que vous voulez voir apparaitre dans le menu",
  "account identifiers": "Identification",
  "account danger zone": "Zone dangereuse",
  "account actions": "Actions",
  "account no special mailboxes": "Vous n'avez pas configuré les dossiers spéciaux",
  "account imap hide advanced": "Masquer les paramètres avancés",
  "account imap show advanced": "Afficher les paramètres avancés",
  "account smtp hide advanced": "Masquer les paramètres avancés",
  "account smtp show advanced": "Afficher les paramètres avancés",
  "account tab signature": "Signature",
  "account signature short": "Saisissez ici le texte qui sera ajouté à la fin de vos courriers.",
  "account signature": "Signature des courriers",
  "account signature save": "Enregistrer",
  "mailbox create ok": "Dossier créé",
  "mailbox create ko": "Erreur de création du dossier",
  "mailbox update ok": "Dossier mis à jour",
  "mailbox update ko": "Erreur de mise à jour",
  "mailbox delete ok": "Dossier supprimé",
  "mailbox delete ko": "Erreur de suppression du dossier",
  "mailbox expunge ok": "Corbeille vidée",
  "mailbox expunge ko": "Erreur de suppression des messages",
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
  "config error imapPort": "Paramètres du serveur IMAP invalides",
  "config error imapServer": "Serveur IMAP invalide",
  "config error imapTLS": "Erreur IMAP TLS",
  "config error smtpPort": "Port du serveur d'envoi invalide",
  "config error smtpServer": "Serveur d'envoi invalide",
  "config error nomailboxes": "Ce compte n'a pas encore de dossier, commencez par en créer",
  "action undo": "Annuler",
  "action undo ok": "Action Annulée",
  "action undo ko": "Impossible d'annuler l'action",
  "message action sent ok": "Message envoyé !",
  "message action sent ko": "Une erreur est survenue : ",
  "message action draft ok": "Message sauvegardé !",
  "message action draft ko": "Une erreur est survenue : ",
  "message delete ok": "Message « %{subject} » supprimé",
  "message delete ko": "Impossible de supprimer le message : ",
  "message move ok": "Message « %{subject} » déplacé",
  "message move ko": "Le déplacement de « %{subject} » a échoué",
  "message mark ok": "Le message a été mis à jour",
  "message mark ko": "L'opération a échoué",
  "draft delete ok": "Le brouillon « %{subject} » a été supprimé",
  "draft delete ko": "Erreur lors de la suppression du brouillon « %{subject} » : ",
  "draft move ok": "Le brouillon a été « %{subject} » déplacé",
  "draft move ko": "Erreur lors du déplacement du brouillon « %{subject} » : ",
  "draft mark ok": "Brouillon « %{subject} » mis à jour",
  "draft mark ko": "Erreur de mise à jour du brouillon « %{subject} » : ",
  "conversation move ok": "Conversation « %{subject} » déplacée",
  "conversation move ko": "Le déplacement de « %{subject} » a échoué",
  "conversation delete ok": "Conversation « %{subject} » supprimée",
  "conversation delete ko": "L'opération a échoué",
  "conversation seen ok": "Ok",
  "conversation seen ko": "L'opération a échoué",
  "conversation unseen ok": "Ok",
  "conversation unseen ko": "L'opération a échoué",
  "undo last action": "Annuler",
  "conversation flagged ko": "L'opération a échoué",
  "conversation noflag ko": "L'opération a échoué",
  "conversations move ok": "%{smart_count} conversation déplacée||||\n%{smart_count} conversations déplacées",
  "conversations move ko": "Erreur au déplacement de %{smart_count} conversation||||\nError au déplacement de %{smart_count} conversations",
  "conversations delete ok": "%{smart_count} conversation supprimée||||\n%{smart_count} conversations supprimées",
  "conversations delete ko": "Erreur de suppression de %{smart_count} conversation ||||\nErreur de suppression de %{smart_count} conversations",
  "conversations seen ok": "%{smart_count} conversation marquée lue||||\n%{smart_count} conversations marquées lues",
  "conversations seen ko": "Erreur en marquant %{smart_count} conversation lue||||\nErreur en marquant %{smart_count} conversations lues",
  "conversations unseen ok": "%{smart_count} conversation marquée non-lue||||\n%{smart_count} conversations marquées non-lues",
  "conversations unseen ko": "Erreur en marquant %{smart_count} conversation non-lue||||\nErreur en marquant %{smart_count} conversations non-lues",
  "conversations flagged ko": "Erreur en marquant %{smart_count} conversation importante||||\nErreur en marquant %{smart_count} conversations importantes",
  "conversations noflag ko": "Erreur en marquant %{smart_count} conversation non importante||||\nErreur en marquant %{smart_count} conversations non importantes",
  "message images warning": "L'affichage des images du message a été bloqué",
  "message images display": "Afficher les images",
  "message html display": "Afficher en HTML",
  "message delete no trash": "Choisissez d'abord un dossier Corbeille",
  "message delete already": "Ce message est déjà dans la corbeille",
  "message move already": "Ce message est déjà dans ce dossier",
  "undo ok": "Action annulée",
  "undo ko": "Impossible d'annuler l'action",
  "undo unavailable": "Impossible d'annuler l'action",
  "message preview title": "Voir les pièces jointes",
  "settings title": "Paramètres",
  "settings button save": "Enregistrer",
  "settings plugins": "Modules complémentaires",
  "settings plugin add": "Ajouter",
  "settings plugin del": "Supprimer",
  "settings plugin help": "Documentation",
  "settings plugin new name": "Nom du plugin",
  "settings plugin new url": "Url du plugin",
  "settings label autosaveDraft": "Enregistrer périodiquement les brouillons",
  "settings label composeInHTML": "Éditeur riche",
  "settings label composeOnTop": "Répondre au-dessus du message",
  "settings label desktopNotifications": "Notifications",
  "settings label displayConversation": "Afficher les conversations",
  "settings label displayPreview": "Prévisualiser les messages",
  "settings label messageDisplayHTML": "Afficher les messages en HTML",
  "settings label messageDisplayImages": "Afficher les images",
  "settings label messageConfirmDelete": "Demander confirmation avant de supprimer un message",
  "settings label layoutStyle": "Affichage",
  "settings label layoutStyle horizontal": "Message sous la liste",
  "settings label layoutStyle vertical": "Message à côté de la liste",
  "settings label layoutStyle three": "Trois colonnes",
  "settings label listStyle": "Affichage de la liste des messages",
  "settings label listStyle default": "Normal",
  "settings label listStyle compact": "Compact",
  "settings lang": "Langue",
  "settings lang en": "English",
  "settings lang fr": "Français",
  "settings lang de": "Deutsch",
  "settings save error": "Erreur d'enregistrement des paramètres, veuillez réessayer",
  "picker drop here": "Déposer les fichiers ici",
  "mailbox pick one": "Choisissez une boîte",
  "mailbox pick null": "Pas de boîte pour ça",
  "task account-fetch": 'Rafraîchissement %{account}',
  "task box-fetch": 'Rafraîchissement %{box}',
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
  "notif new title": 'Messagerie Cozy',
  "notif new": "%{smart_count} message non-lu dans le compte %{account}||||\n%{smart_count} messages non-lus dans le compte  %{account}",
  "notif complete": "Importation du compte %{account} finie.",
  "contact form": "Sélectionnez des contacts",
  "contact form placeholder": "Nom",
  "contact create success": "%{contact} a été ajouté(e) à vos contacts",
  "contact create error": "L'ajout à votre carnet d'adresses a échoué : {error}",
  "message contact creation": "Voulez vous ajouter %{contact} à votre carnet d'adresse ?",
  "gmail security tile": "Sécurité Gmail",
  "gmail security body": "Gmail considère les connexions par nom d'utilisateur et mot de passe\ncomme non sécurisées. Veuillez cliquer sur le lien ci-dessous, assurez-vous\nd'être connecté avec le compte %{login} et activez l'accès\npour les applications moins sécurisées.",
  "gmail security link": "Activer l'accès pour les applications moins sécurisées",
  'plugin name Gallery': 'Galerie de pièces jointes',
  'plugin name medium-editor': 'Éditeur Medium',
  'plugin name MiniSlate': 'Éditeur MiniSlate',
  'plugin name Sample JS': 'Exemple',
  'plugin name Keyboard shortcuts': 'Raccourcis clavier',
  'plugin name VCard': 'Affichage de VCard',
  'plugin modal close': 'Fermer',
  'calendar unknown format': "Ce message contient une invitation à un évènement\ndans un format actuellement non pris en charge.",
  "tooltip reply": "Répondre",
  "tooltip reply all": "Répondre à tous",
  "tooltip forward": "Transférer",
  "tooltip remove message": "Supprimer",
  "tooltip open attachments": "Ouvrir la liste des pièces jointes",
  "tooltip open attachment": "Ouvrir la pièce jointe",
  "tooltip download attachment": "Télécharger la pièce jointe",
  "tooltip previous conversation": "Aller à la conversation précédente",
  "tooltip next conversation": "Aller à la conversation suivante",
  "tooltip filter only unread": "Montrer seulement les messages non lus",
  "tooltip filter only important": "Montrer seulement les messages importants",
  "tooltip filter only attachment": "Montrer seulement les messages avec pièce jointe",
  "tooltip account parameters": "Paramètres du compte",
  "tooltip delete selection": "Supprimer les messages sélectionnés",
  'tooltip filter': 'Filtrer',
  'tooltip display filters': 'Afficher les filtres',
  'tooltip expunge mailbox': 'Vider la boite',
  'filters unseen': 'non-lus',
  'filters flagged': 'favoris',
  'filters attach': 'pièces jointes',
  'filters search placeholder': 'rechercher…',
  'daterangepicker placeholder': 'par date',
  'daterangepicker presets yesterday': 'hier',
  'daterangepicker presets last week': 'semaine dernière',
  'daterangepicker presets last month': 'mois dernier',
  'daterangepicker clear': 'effacer'
};
});

;require.register("mixins/participant_mixin", function(exports, require, module) {

/*
    Participant mixin.
 */
var ContactLabel, ContactStore, a, i, span, _ref;

_ref = React.DOM, span = _ref.span, a = _ref.a, i = _ref.i;

ContactStore = require('../stores/contact_store');

ContactLabel = require('../components/contact_label');

module.exports = {
  formatUsers: function(users) {
    var items, user, _i, _len;
    if (users == null) {
      return;
    }
    if (_.isArray(users)) {
      items = [];
      for (_i = 0, _len = users.length; _i < _len; _i++) {
        user = users[_i];
        items.push(ContactLabel({
          contact: user
        }));
        if (user !== _.last(users)) {
          items.push(", ");
        }
      }
      return items;
    } else {
      return ContactLabel({
        contact: users
      });
    }
  }
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

;require.register("mixins/tooltip_refresher_mixin", function(exports, require, module) {
var TooltipRefresherMixin;

module.exports = TooltipRefresherMixin = {
  componentDidMount: function() {
    return AriaTips.bind();
  },
  componentDidUpdate: function() {
    return AriaTips.bind();
  }
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
      pattern: 'conversation/:conversationID/:messageID/',
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
    var defaultAccount, defaultAccountID, defaultMailboxID, defaultParameters, mailbox, _ref, _ref1;
    switch (action) {
      case 'account.mailbox.messages':
      case 'account.mailbox.messages.full':
        defaultAccountID = (_ref = AccountStore.getDefault()) != null ? _ref.get('id') : void 0;
        mailbox = AccountStore.getDefaultMailbox(defaultAccountID);
        defaultMailboxID = mailbox != null ? mailbox.get('id') : void 0;
        defaultParameters = _.clone(MessageStore.getParams());
        defaultParameters.accountID = defaultAccountID;
        defaultParameters.mailboxID = defaultMailboxID;
        defaultParameters.pageAfter = '-';
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
    if (account != null) {
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
    }
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
    var account, diffTotalUnread, mailboxes, totalUnread, updated, _ref;
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
    diffTotalUnread = ((_ref = diff[accountID]) != null ? _ref.nbUnread : void 0) || 0;
    if (diffTotalUnread) {
      totalUnread = account.get('totalUnread') + diffTotalUnread;
      account = account.set('totalUnread', totalUnread);
    }
    if (updated !== mailboxes) {
      account = account.set('mailboxes', updated);
    }
    if (account !== _accounts.get(accountID)) {
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
    handle(ActionTypes.RECEIVE_MAILBOX_UPDATE, function(boxData) {
      setMailbox(boxData.accountID, boxData.id, boxData);
      return this.emit('change');
    });
    return handle(ActionTypes.RECEIVE_REFRESH_NOTIF, function(data) {
      var account;
      account = _accounts.get(data.accountID);
      account = account.set('totalUnread', data.totalUnread);
      _accounts.set(data.accountID, account);
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

  ContactStore.prototype.isExist = function(address) {
    return this.getByAddress(address) != null;
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
  var _alert, _disposition, _drawer, _intentAvailable, _previewFullscreen, _previewSize, _shown, _tasks;

  __extends(LayoutStore, _super);

  function LayoutStore() {
    return LayoutStore.__super__.constructor.apply(this, arguments);
  }

  _disposition = Dispositions.COL;

  _previewSize = 50;

  _previewFullscreen = false;

  _alert = {
    level: null,
    message: null
  };

  _tasks = Immutable.OrderedMap();

  _shown = true;

  _intentAvailable = false;

  _drawer = false;


  /*
      Defines here the action handlers.
   */

  LayoutStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.SET_DISPOSITION, function(disposition) {
      _disposition = disposition;
      return this.emit('change');
    });
    handle(ActionTypes.RESIZE_PREVIEW_PANE, function(factor) {
      if (factor) {
        _previewSize += factor;
        if (_previewSize < 20) {
          _previewSize = 20;
        }
        if (_previewSize > 80) {
          _previewSize = 80;
        }
      } else {
        _previewSize = 50;
      }
      return this.emit('change');
    });
    handle(ActionTypes.MINIMIZE_PREVIEW_PANE, function() {
      _previewFullscreen = false;
      return this.emit('change');
    });
    handle(ActionTypes.MAXIMIZE_PREVIEW_PANE, function() {
      _previewFullscreen = true;
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
          setTimeout(remove, 5000);
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
    handle(ActionTypes.TOASTS_HIDE, function() {
      _shown = false;
      return this.emit('change');
    });
    handle(ActionTypes.INTENT_AVAILABLE, function(avaibility) {
      _intentAvailable = avaibility;
      return this.emit('change');
    });
    handle(ActionTypes.DRAWER_SHOW, function() {
      if (_drawer === true) {
        return;
      }
      _drawer = true;
      return this.emit('change');
    });
    handle(ActionTypes.DRAWER_HIDE, function() {
      if (_drawer === false) {
        return;
      }
      _drawer = false;
      return this.emit('change');
    });
    return handle(ActionTypes.DRAWER_TOGGLE, function() {
      _drawer = !_drawer;
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  LayoutStore.prototype.getDisposition = function() {
    return _disposition;
  };

  LayoutStore.prototype.getPreviewSize = function() {
    return _previewSize;
  };

  LayoutStore.prototype.isPreviewFullscreen = function() {
    return _previewFullscreen;
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

  LayoutStore.prototype.intentAvailable = function() {
    return _intentAvailable;
  };

  LayoutStore.prototype.isDrawerExpanded = function() {
    return _drawer;
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
  var computeMailboxDiff, onReceiveRawMessage, reverseDateSort, __getSortFunction, __sortFunction, _conversationLengths, _conversationMemoize, _conversationMemoizeID, _currentID, _currentMessages, _fetching, _filter, _messages, _params, _prevAction, _sortField, _sortOrder;

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

  _conversationMemoizeID = null;

  _currentID = null;

  _prevAction = null;

  computeMailboxDiff = function(oldmsg, newmsg) {
    var accountID, added, changed, deltaUnread, isRead, newboxes, oldboxes, out, removed, stayed, wasRead, _ref1, _ref2;
    if (!oldmsg) {
      return {};
    }
    changed = false;
    wasRead = (_ref1 = MessageFlags.SEEN, __indexOf.call(oldmsg.get('flags'), _ref1) >= 0);
    isRead = (_ref2 = MessageFlags.SEEN, __indexOf.call(newmsg.get('flags'), _ref2) >= 0);
    accountID = newmsg.get('accountID');
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
    if (deltaUnread !== 0) {
      changed = true;
    }
    out[accountID] = {
      nbUnread: deltaUnread
    };
    stayed.forEach(function(boxid) {
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
    var diff, messageMap, oldmsg, updated;
    oldmsg = _messages.get(message.id);
    updated = oldmsg != null ? oldmsg.get('updated') : void 0;
    if (!((message.updated != null) && (updated != null) && updated > message.updated)) {
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
      message.updated = Date.now();
      messageMap = Immutable.Map(message);
      messageMap.prettyPrint = function() {
        return "" + message.id + " \"" + message.from[0].name + "\" \"" + message.subject + "\"";
      };
      _messages = _messages.set(message.id, messageMap);
      if (diff = computeMailboxDiff(oldmsg, messageMap)) {
        return AccountStore._applyMailboxDiff(message.accountID, diff);
      }
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
      var before, lengths, message, next, url, _i, _len;
      if ((messages.links != null) && (messages.links.next != null)) {
        _params = {};
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
      } else if (messages.mailboxID) {
        _params.pageAfter = '-';
      }
      if (messages.mailboxID) {
        before = _params.pageAfter === '-' ? void 0 : _params.pageAfter;
        SocketUtils.changeRealtimeScope(messages.mailboxID, before);
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
      }).toOrderedMap();
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
      if (sort.order != null) {
        newOrder = sort.order;
        _sortOrder = sort.order === '-' ? 1 : -1;
      } else {
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
      }
      return _params = {
        after: sort.after || '-',
        flag: _params.flag,
        before: sort.before || '-',
        pageAfter: '-',
        sort: newOrder + sort.field
      };
    });
    handle(ActionTypes.LAST_ACTION, function(action) {
      return _prevAction = action;
    });
    handle(ActionTypes.MESSAGE_CURRENT, function(value) {
      this.setCurrentID(value.messageID, value.conv);
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
    handle(ActionTypes.MAILBOX_EXPUNGE, function(mailboxID) {
      _messages = _messages.filter(function(message) {
        var mailboxes;
        mailboxes = Object.keys(message.get('mailboxIDs'));
        return __indexOf.call(mailboxes, mailboxID) < 0;
      }).toOrderedMap();
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

  MessageStore.prototype.getCurrentID = function() {
    return _currentID;
  };

  MessageStore.prototype.setCurrentID = function(messageID, conv) {
    if (conv != null) {
      this.getConversation(this.getByID(messageID).get('conversationID'));
    }
    return _currentID = messageID;
  };

  MessageStore.prototype.getCurrentConversationID = function() {
    return _conversationMemoizeID;
  };

  MessageStore.prototype.getPreviousMessage = function(isConv) {
    var convID, currentMessage, idx, keys, prev;
    if ((isConv != null) && isConv) {
      if (_conversationMemoize == null) {
        return null;
      }
      idx = _conversationMemoize.findIndex(function(message) {
        return _currentID === message.get('id');
      });
      if (idx < 0) {
        return null;
      } else if (idx === _conversationMemoize.length - 1) {
        keys = Object.keys(_currentMessages.toJS());
        idx = keys.indexOf(_conversationMemoize.last().get('id'));
        if (idx < 1) {
          return null;
        } else {
          currentMessage = _currentMessages.get(keys[idx - 1]);
          convID = currentMessage != null ? currentMessage.get('conversationID') : void 0;
          if (convID == null) {
            return null;
          }
          prev = _messages.filter(function(message) {
            return message.get('conversationID') === convID;
          }).sort(reverseDateSort).first();
          return prev;
        }
      } else {
        return _conversationMemoize.get(idx + 1);
      }
    } else {
      keys = Object.keys(_currentMessages.toJS());
      idx = keys.indexOf(_currentID);
      if (idx === -1) {
        return null;
      } else {
        return _currentMessages.get(keys[idx - 1]);
      }
    }
  };

  MessageStore.prototype.getNextMessage = function(isConv) {
    var idx, keys;
    if ((isConv != null) && isConv) {
      if (_conversationMemoize == null) {
        return null;
      }
      idx = _conversationMemoize.findIndex(function(message) {
        return _currentID === message.get('id');
      });
      if (idx < 0) {
        return null;
      } else if (idx === 0) {
        keys = Object.keys(_currentMessages.toJS());
        idx = keys.indexOf(_conversationMemoize.last().get('id'));
        if (idx === -1 || idx === (keys.length - 1)) {
          return null;
        } else {
          return _currentMessages.get(keys[idx + 1]);
        }
      } else {
        return _conversationMemoize.get(idx - 1);
      }
    } else {
      keys = Object.keys(_currentMessages.toJS());
      idx = keys.indexOf(_currentID);
      if (idx === -1 || idx === (keys.length - 1)) {
        return null;
      } else {
        return _currentMessages.get(keys[idx + 1]);
      }
    }
  };

  MessageStore.prototype.getNextOrPrevious = function(isConv) {
    return this.getNextMessage(isConv) || this.getPreviousMessage(isConv);
  };

  MessageStore.prototype.getConversation = function(conversationID) {
    _conversationMemoize = _messages.filter(function(message) {
      return message.get('conversationID') === conversationID;
    }).sort(reverseDateSort).toVector();
    _conversationMemoizeID = conversationID;
    return _conversationMemoize;
  };

  MessageStore.prototype.getMixed = function(target) {
    if (target.messageID) {
      return [_messages.get(target.messageID)];
    } else if (target.messageIDs) {
      return target.messageIDs.map(function(id) {
        return _messages.get(id);
      });
    } else if (target.conversationID) {
      return _messages.filter(function(message) {
        return message.get('conversationID') === target.conversationID;
      }).toArray();
    } else if (target.conversationIDs) {
      return _messages.filter(function(message) {
        var _ref1;
        return _ref1 = message.get('conversationID'), __indexOf.call(target.conversationIDs, _ref1) >= 0;
      }).toArray();
    } else {
      throw new Error('Wrong Usage : unrecognized target AS.getMixed');
    }
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
    handle(ActionTypes.RECEIVE_REFRESH_DELETE, function(refreshID) {
      _refreshes = _refreshes.filter(function(refresh) {
        return refresh.get('id') !== refreshID;
      }).toOrderedMap();
      return this.emit('change');
    });
    return handle(ActionTypes.RECEIVE_REFRESH_NOTIF, function(data) {
      return this.emit('notify', t('notif new title'), {
        body: data.message
      });
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
var AccountStore, LayoutActionCreator, MessageActionCreator, MessageStore, SettingsStore, onMessageList,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __hasProp = {}.hasOwnProperty;

AccountStore = require('../stores/account_store');

MessageStore = require('../stores/message_store');

SettingsStore = require('../stores/settings_store');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

onMessageList = function() {
  var actions, _ref, _ref1;
  actions = ["account.mailbox.messages", "account.mailbox.messages.full"];
  return _ref = (_ref1 = router.current.firstPanel) != null ? _ref1.action : void 0, __indexOf.call(actions, _ref) >= 0;
};

module.exports = {
  getCurrentAccount: function() {
    var _ref;
    return (_ref = AccountStore.getSelected()) != null ? _ref.toJS() : void 0;
  },
  getCurrentMailbox: function() {
    var _ref;
    return (_ref = AccountStore.getSelectedMailbox()) != null ? _ref.toJS() : void 0;
  },
  getCurrentMessage: function() {
    var message, messageID;
    messageID = MessageStore.getCurrentID();
    message = MessageStore.getByID(messageID);
    return message != null ? message.toJS() : void 0;
  },
  getMessage: function(id) {
    var message;
    message = MessageStore.getByID(id);
    return message != null ? message.toJS() : void 0;
  },
  getCurrentConversation: function() {
    var conversationID, _ref;
    conversationID = MessageStore.getCurrentConversationID();
    if (conversationID != null) {
      return (_ref = MessageStore.getConversation(conversationID)) != null ? _ref.toJS() : void 0;
    }
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
    var ActionTypes, AppDispatcher, k, settings, v;
    AppDispatcher = require('../app_dispatcher');
    ActionTypes = require('../constants/app_constants').ActionTypes;
    settings = SettingsStore.get().toJS();
    if (typeof key === 'object') {
      for (k in key) {
        if (!__hasProp.call(key, k)) continue;
        v = key[k];
        settings[k] = v;
      }
    } else {
      settings[key] = value;
    }
    return AppDispatcher.handleViewAction({
      type: ActionTypes.SETTINGS_UPDATED,
      value: settings
    });
  },
  messageNavigate: function(direction, inConv) {
    var conv, next;
    if (!onMessageList()) {
      return;
    }
    conv = inConv && SettingsStore.get('displayConversation') && SettingsStore.get('displayPreview');
    if (direction === 'prev') {
      next = MessageStore.getPreviousMessage(conv);
    } else {
      next = MessageStore.getNextMessage(conv);
    }
    if (next == null) {
      return;
    }
    MessageActionCreator.setCurrent(next.get('id'), true);
    if (SettingsStore.get('displayPreview')) {
      return this.messageDisplay(next);
    }
  },
  messageDisplay: function(message, force) {
    var action, conversationID, params, url, urlOptions;
    if (message == null) {
      message = MessageStore.getByID(MessageStore.getCurrentID());
    }
    if (message == null) {
      return;
    }
    if (force === false && (window.router.current.secondPanel == null)) {
      return;
    }
    conversationID = message.get('conversationID');
    if (SettingsStore.get('displayConversation') && (conversationID != null)) {
      action = 'conversation';
      params = {
        messageID: message.get('id'),
        conversationID: conversationID
      };
    } else {
      action = 'message';
      params = {
        messageID: message.get('id')
      };
    }
    urlOptions = {
      direction: 'second',
      action: action,
      parameters: params
    };
    url = window.router.buildUrl(urlOptions);
    return window.router.navigate(url, {
      trigger: true
    });
  },
  messageClose: function() {
    var closeUrl;
    closeUrl = window.router.buildUrl({
      direction: 'first',
      action: 'account.mailbox.messages',
      parameters: {
        accountID: AccountStore.getSelected().get('id'),
        mailboxID: AccountStore.getSelectedMailbox().get('id')
      },
      fullWidth: true
    });
    return window.router.navigate(closeUrl, {
      trigger: true
    });
  },
  messageDeleteCurrent: function() {
    var confirm, confirmMessage, conversation, messageID, settings;
    if (!onMessageList()) {
      return;
    }
    messageID = MessageStore.getCurrentID();
    if (messageID == null) {
      return;
    }
    settings = SettingsStore.get();
    conversation = settings.get('displayConversation');
    confirm = settings.get('messageConfirmDelete');
    if (confirm) {
      if (conversation) {
        confirmMessage = t('list delete conv confirm', {
          smart_count: 1
        });
      } else {
        confirmMessage = t('list delete confirm', {
          smart_count: 1
        });
      }
    }
    if ((!confirm) || window.confirm(confirmMessage)) {
      return MessageActionCreator["delete"]({
        messageID: messageID
      });
    }
  },
  messageUndo: function() {
    return MessageActionCreator.undo();
  },
  customEvent: function(name, data) {
    var domEvent;
    domEvent = new CustomEvent(name, {
      detail: data
    });
    return window.dispatchEvent(domEvent);
  },
  simulateUpdate: function() {
    var AppDispatcher;
    AppDispatcher = require('../app_dispatcher');
    return window.setInterval(function() {
      var content, _ref, _ref1;
      content = {
        "accountID": (_ref = AccountStore.getDefault()) != null ? _ref.get('id') : void 0,
        "id": (_ref1 = AccountStore.getDefaultMailbox()) != null ? _ref1.get('id') : void 0,
        "label": "INBOX",
        "path": "INBOX",
        "tree": ["INBOX"],
        "delimiter": ".",
        "uidvalidity": Date.now(),
        "attribs": [],
        "docType": "Mailbox",
        "lastSync": new Date().toISOString(),
        "nbTotal": 467,
        "nbUnread": 0,
        "nbRecent": 5,
        "weight": 1000,
        "depth": 0
      };
      return AppDispatcher.handleServerAction({
        type: 'RECEIVE_MAILBOX_UPDATE',
        value: content
      });
    }, 5000);
  },
  notify: function(title, options) {
    if ((window.Notification != null) && SettingsStore.get('desktopNotifications')) {
      return new Notification(title, options);
    } else {
      if (options == null) {
        options = {
          body: title
        };
      }
      return window.setTimeout(function() {
        return LayoutActionCreator.notify("" + title + " - " + options.body);
      }, 0);
    }
  },
  log: function(error) {
    var url;
    url = error.stack.split('\n')[0].split('@')[1].split(/:\d/)[0].split('/').slice(0, -2).join('/');
    return window.onerror(error.name, url, error.lineNumber, error.colNumber, error);
  },
  dump: function() {
    var _dump;
    _dump = function(root) {
      var key, res, value, _ref, _ref1, _ref2;
      res = {
        children: {},
        state: {},
        props: {}
      };
      _ref = root.state;
      for (key in _ref) {
        value = _ref[key];
        if (typeof value === 'object') {
          res.state[key] = _.clone(value);
        } else {
          res.state[key] = value;
        }
      }
      _ref1 = root.props;
      for (key in _ref1) {
        value = _ref1[key];
        if (typeof value === 'object') {
          res.props[key] = _.clone(value);
        } else {
          res.props[key] = value;
        }
      }
      _ref2 = root.refs;
      for (key in _ref2) {
        value = _ref2[key];
        res.children[key] = _dump(root.refs[key]);
      }
      return res;
    };
    return _dump(window.rootComponent);
  },
  logInfo: function(message) {
    var data, xhr;
    data = {
      data: {
        type: 'debug',
        message: message
      }
    };
    xhr = new XMLHttpRequest();
    xhr.open('POST', 'activity', true);
    xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    xhr.send(JSON.stringify(data));
    return console.log(message);
  }
};
});

;require.register("utils/colorhash", function(exports, require, module) {

/*
ColorHash

This file exports a simple method that return an hex color from a given string.
A same string will always returns the same color.
 */
var hslToRgb, hue2rgb;

hue2rgb = function(p, q, t) {
  if (t < 0) {
    t += 1;
  }
  if (t > 1) {
    t -= 1;
  }
  if (t < 1 / 6) {
    return p + (q - p) * 6 * t;
  }
  if (t < 1 / 2) {
    return q;
  }
  if (t < 2 / 3) {
    return p + (q - p) * (2 / 3 - t) * 6;
  }
  return p;
};

hslToRgb = function(h, s, l) {
  var b, color, g, p, q, r;
  if (s === 0) {
    r = g = b = l;
  } else {
    q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    p = 2 * l - q;
    r = hue2rgb(p, q, h + 1 / 3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1 / 3);
  }
  color = (1 << 24) + (r * 255 << 16) + (g * 255 << 8) + parseInt(b * 255);
  return "#" + (color.toString(16).slice(1));
};

module.exports = function(tag) {
  var colour, h, hash, i, l, s, _i, _ref;
  hash = 0;
  for (i = _i = 0, _ref = tag.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
    hash = tag.charCodeAt(i) + (hash << 5) - hash;
  }
  h = (hash % 100) / 100;
  s = (hash % 1000) / 1000;
  l = 0.5 + 0.2 * (hash % 2) / 2;
  colour = hslToRgb(h, s, l);
  return colour;
};
});

;require.register("utils/dom_utils", function(exports, require, module) {
var DomUtils;

module.exports = DomUtils = {
  isVisible: function(node) {
    var height, rect, width;
    rect = node.getBoundingClientRect();
    height = window.innerHeight || document.documentElement.clientHeight;
    width = window.innerWidth || document.documentElement.clientWidth;
    if (height === 0 || width === 0) {
      return false;
    } else {
      return rect.bottom <= (height + 0) && rect.top >= 0;
    }
  }
};
});

;require.register("utils/file_utils", function(exports, require, module) {
var FileUtils;

module.exports = FileUtils = {
  dataURItoBlob: function(dataURI) {
    var byteString, i, res, _i, _ref;
    if (dataURI.split(',')[0].indexOf('base64') >= 0) {
      byteString = atob(dataURI.split(',')[1]);
    } else {
      byteString = window.unescape(dataURI.split(',')[1]);
    }
    res = {
      mime: dataURI.split(',')[0].split(':')[1].split(';')[0],
      blob: new Uint8Array(byteString.length)
    };
    for (i = _i = 0, _ref = byteString.length; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      res.blob[i] = byteString.charCodeAt(i);
    }
    return res;
  },
  fileToDataURI: function(file, cb) {
    var fileReader;
    fileReader = new FileReader();
    fileReader.readAsDataURL(file);
    return fileReader.onload = function() {
      return cb(fileReader.result);
    };
  }
};
});

;require.register("utils/intent_manager", function(exports, require, module) {
var IntentManager, TIMEOUT;

TIMEOUT = 3000;

module.exports = IntentManager = (function() {
  function IntentManager() {
    this.talker = new Talker(window.parent, '*');
  }

  IntentManager.prototype.send = function(nameSpace, intent, timeout) {
    this.talker.timeout = timeout ? timeout : TIMEOUT;
    return this.talker.send('nameSpace', intent);
  };

  return IntentManager;

})();
});

;require.register("utils/message_utils", function(exports, require, module) {
var COMPOSE_STYLE, ComposeActions, ContactStore, MessageUtils, QUOTE_STYLE;

ComposeActions = require('../constants/app_constants').ComposeActions;

ContactStore = require('../stores/contact_store');

QUOTE_STYLE = "margin-left: 0.8ex; padding-left: 1ex; border-left: 3px solid #34A6FF;";

COMPOSE_STYLE = "<style>\np {margin: 0;}\npre {background: transparent; border: 0}\n</style>";

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
    } else {
      res = [];
      for (_i = 0, _len = addresses.length; _i < _len; _i++) {
        item = addresses[_i];
        if (item == null) {
          break;
        }
        res.push(MessageUtils.displayAddress(item, full));
      }
      return res.join(", ");
    }
  },
  parseAddress: function(text) {
    var address, emailRe, match;
    text = text.trim();
    if (match = text.match(/"{0,1}(.*)"{0,1} <(.*)>/)) {
      address = {
        name: match[1],
        address: match[2]
      };
    } else {
      address = {
        address: text.replace(/^\s*/, '')
      };
    }
    emailRe = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/;
    address.isValid = address.address.match(emailRe);
    return address;
  },
  getReplyToAddress: function(message) {
    var from, reply;
    reply = message.get('replyTo');
    from = message.get('from');
    if ((reply != null) && reply.length !== 0) {
      return reply;
    } else {
      return from;
    }
  },
  addSignature: function(message, signature) {
    var signatureHtml;
    message.text += "\n\n-- \n" + signature;
    signatureHtml = signature.replace(/\n/g, '<br>');
    return message.html += "<p><br></p><p id=\"signature\">-- \n<br>" + signatureHtml + "</p>";
  },
  makeReplyMessage: function(myAddress, inReplyTo, action, inHTML, signature) {
    var dateHuman, e, html, isSignature, message, notMe, options, sender, text;
    message = {
      composeInHTML: inHTML,
      attachments: Immutable.Vector.empty()
    };
    if (inReplyTo) {
      message.accountID = inReplyTo.get('accountID');
      message.conversationID = inReplyTo.get('conversationID');
      dateHuman = this.formatReplyDate(inReplyTo.get('createdAt'));
      sender = this.displayAddresses(inReplyTo.get('from'));
      text = inReplyTo.get('text');
      html = inReplyTo.get('html');
      if (text == null) {
        text = '';
      }
      if ((text != null) && (html == null) && inHTML) {
        try {
          html = markdown.toHTML(text);
        } catch (_error) {
          e = _error;
          console.log("Error converting message to Markdown: " + e);
          html = "<div class='text'>" + text + "</div>";
        }
      }
      if ((html != null) && (text == null) && !inHTML) {
        text = toMarkdown(html);
      }
      message.inReplyTo = [inReplyTo.get('id')];
      message.references = inReplyTo.get('references') || [];
      message.references = message.references.concat(message.inReplyTo);
    }
    if ((signature != null) && signature.length > 0) {
      isSignature = true;
    } else {
      isSignature = false;
    }
    options = {
      message: message,
      inReplyTo: inReplyTo,
      dateHuman: dateHuman,
      sender: sender,
      text: text,
      html: html,
      signature: signature,
      isSignature: isSignature
    };
    switch (action) {
      case ComposeActions.REPLY:
        this.setMessageAsReply(options);
        break;
      case ComposeActions.REPLY_ALL:
        this.setMessageAsReplyAll(options);
        break;
      case ComposeActions.FORWARD:
        this.setMessageAsForward(options);
        break;
      case null:
        this.setMessageAsDefault(options);
    }
    notMe = function(dest) {
      return dest.address !== myAddress;
    };
    message.to = message.to.filter(notMe);
    message.cc = message.cc.filter(notMe);
    return message;
  },
  setMessageAsReply: function(options) {
    var dateHuman, html, inReplyTo, isSignature, message, params, sender, separator, signature, text;
    message = options.message, inReplyTo = options.inReplyTo, dateHuman = options.dateHuman, sender = options.sender, text = options.text, html = options.html, signature = options.signature, isSignature = options.isSignature;
    params = {
      date: dateHuman,
      sender: sender
    };
    separator = t('compose reply separator', params);
    message.to = this.getReplyToAddress(inReplyTo);
    message.cc = [];
    message.bcc = [];
    message.subject = this.getReplySubject(inReplyTo);
    message.text = separator + this.generateReplyText(text) + "\n";
    message.html = "" + COMPOSE_STYLE + "\n<p>" + separator + "<span class=\"originalToggle\"> … </span></p>\n<blockquote style=\"" + QUOTE_STYLE + "\">" + html + "</blockquote>\n<p><br></p>";
    if (isSignature) {
      return this.addSignature(message, signature);
    }
  },
  setMessageAsReplyAll: function(options) {
    var dateHuman, html, inReplyTo, isSignature, message, params, sender, separator, signature, text, toAddresses;
    message = options.message, inReplyTo = options.inReplyTo, dateHuman = options.dateHuman, sender = options.sender, text = options.text, html = options.html, signature = options.signature, isSignature = options.isSignature;
    params = {
      date: dateHuman,
      sender: sender
    };
    separator = t('compose reply separator', params);
    message.to = this.getReplyToAddress(inReplyTo);
    toAddresses = message.to.map(function(dest) {
      return dest.address;
    });
    message.cc = [].concat(inReplyTo.get('from'), inReplyTo.get('to'), inReplyTo.get('cc')).filter(function(dest) {
      return (dest != null) && toAddresses.indexOf(dest.address) === -1;
    });
    message.bcc = [];
    message.subject = this.getReplySubject(inReplyTo);
    message.text = separator + this.generateReplyText(text) + "\n";
    message.html = "" + COMPOSE_STYLE + "\n<p>" + separator + "<span class=\"originalToggle\"> … </span></p>\n<blockquote style=\"" + QUOTE_STYLE + "\">" + html + "</blockquote>\n<p><br></p>";
    if (isSignature) {
      return this.addSignature(message, signature);
    }
  },
  setMessageAsForward: function(options) {
    var addresses, dateHuman, fromField, html, htmlSeparator, inReplyTo, isSignature, message, sender, senderAddress, senderInfos, senderName, separator, signature, text, textSeparator;
    message = options.message, inReplyTo = options.inReplyTo, dateHuman = options.dateHuman, sender = options.sender, text = options.text, html = options.html, signature = options.signature, isSignature = options.isSignature;
    addresses = inReplyTo.get('to').map(function(address) {
      return address.address;
    }).join(', ');
    senderInfos = this.getReplyToAddress(inReplyTo);
    senderName = "";
    senderAddress = senderInfos.length > 0 ? (senderName = senderInfos[0].name, senderAddress = senderInfos[0].address) : void 0;
    if (senderName.length > 0) {
      fromField = "" + senderName + " &lt;" + senderAddress + "&gt;";
    } else {
      fromField = senderAddress;
    }
    separator = "\n----- " + (t('compose forward header')) + " ------\n" + (t('compose forward subject')) + " " + (inReplyTo.get('subject')) + "\n" + (t('compose forward date')) + " " + dateHuman + "\n" + (t('compose forward from')) + " " + fromField + "\n" + (t('compose forward to')) + " " + addresses + "\n";
    textSeparator = separator.replace('&lt;', '<').replace('&gt;', '>');
    textSeparator = textSeparator.replace('<pre>', '').replace('</pre>', '');
    htmlSeparator = separator.replace(/(\n)+/g, '<br>');
    this.setMessageAsDefault(options);
    message.subject = "" + (t('compose forward prefix')) + (inReplyTo.get('subject'));
    message.text = textSeparator + text;
    message.html = "" + COMPOSE_STYLE;
    if (isSignature) {
      this.addSignature(message, signature);
    }
    message.html += "\n<p>" + htmlSeparator + "</p><p><br></p>" + html;
    message.attachments = inReplyTo.get('attachments');
    return message;
  },
  setMessageAsDefault: function(options) {
    var dateHuman, html, inReplyTo, isSignature, message, sender, signature, text;
    message = options.message, inReplyTo = options.inReplyTo, dateHuman = options.dateHuman, sender = options.sender, text = options.text, html = options.html, signature = options.signature, isSignature = options.isSignature;
    message.to = [];
    message.cc = [];
    message.bcc = [];
    message.subject = '';
    message.text = '';
    message.html = "" + COMPOSE_STYLE + "\n<p><br></p>";
    if (isSignature) {
      this.addSignature(message, signature);
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
  formatReplyDate: function(date) {
    if (date == null) {
      date = moment();
    }
    date = moment(date);
    return date.format('lll');
  },
  formatDate: function(date, compact) {
    var formatter, today;
    if (date == null) {
      return null;
    } else {
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
    }
  },
  getAvatar: function(message) {
    if (message.get('from')[0] != null) {
      return ContactStore.getAvatar(message.get('from')[0].address);
    } else {
      return null;
    }
  },
  cleanReplyText: function(html) {
    var result, tmp;
    try {
      result = html.replace(/<(style>)[^\1]*\1/gim, '');
      result = toMarkdown(result);
    } catch (_error) {
      if (html != null) {
        result = html.replace(/<(style>)[^\1]*\1/gim, '');
        result = html.replace(/<[^>]*>/gi, '');
      }
    }
    tmp = document.createElement('div');
    tmp.innerHTML = result;
    result = tmp.textContent;
    result = result.replace(/>[ \t]+/ig, '> ');
    result = result.replace(/(> \n)+/g, '> \n');
    return result;
  },
  wrapReplyHtml: function(html) {
    html = html.replace(/<p>/g, '<p style="margin: 0">');
    return "<style type=\"text/css\">\nblockquote {\n    margin: 0.8ex;\n    padding-left: 1ex;\n    border-left: 3px solid #34A6FF;\n}\np {margin: 0;}\npre {background: transparent; border: 0}\n</style>\n" + html;
  },
  getReplySubject: function(inReplyTo) {
    var replyPrefix, subject;
    subject = inReplyTo.get('subject') || '';
    replyPrefix = t('compose reply prefix');
    if (subject.indexOf(replyPrefix) !== 0) {
      subject = "" + replyPrefix + subject;
    }
    return subject;
  }
};
});

;require.register("utils/plugin_utils", function(exports, require, module) {
var helpers,
  __hasProp = {}.hasOwnProperty;

helpers = {
  modal: function(options) {
    var win;
    win = document.createElement('div');
    win.classList.add('modal');
    win.classList.add('fade');
    win.innerHTML = "<div class=\"modal-dialog\">\n    <div class=\"modal-content\">\n        <div class=\"modal-header\">\n            <button type=\"button\" class=\"close\" data-dismiss=\"modal\"\n                    aria-label=\"Close\">\n                <span aria-hidden=\"true\">&times;</span>\n            </button>\n            <h4 class=\"modal-title\"></h4>\n        </div>\n        <div class=\"modal-body\"> </div>\n        <div class=\"modal-footer\">\n            <button type=\"button\" class=\"btn btn-default\"\n                    data-dismiss=\"modal\">" + (t('plugin modal close')) + "\n            </button>\n        </div>\n    </div>\n</div>";
    if (options.title != null) {
      win.querySelector('.modal-title').innerHTML = options.title;
    }
    if (options.body != null) {
      if (typeof options.body === 'string') {
        win.querySelector('.modal-body').innerHTML = options.body;
      } else {
        win.querySelector('.modal-body').appendChild(options.body);
      }
    }
    if (options.size === 'small') {
      win.querySelector('.modal-dialog').classList.add('modal-sm');
    }
    if (options.size === 'large') {
      win.querySelector('.modal-dialog').classList.add('modal-lg');
    }
    if (options.show !== false) {
      document.body.appendChild(win);
      window.jQuery(win).modal('show');
    }
    return win;
  }
};

module.exports = {
  init: function() {
    var config, observer, onMutation;
    if (window.plugins == null) {
      window.plugins = {};
    }
    window.plugins.helpers = helpers;
    Object.keys(window.plugins).forEach((function(_this) {
      return function(pluginName) {
        var onLoad, pluginConf;
        pluginConf = window.plugins[pluginName];
        if (pluginConf.url != null) {
          onLoad = function() {
            return _this.activate(pluginName);
          };
          return _this.loadJS(pluginConf.url, onLoad);
        } else {
          if (pluginConf.active) {
            return _this.activate(pluginName);
          }
        }
      };
    })(this));
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
          var listener, pluginConf, pluginName, _ref, _results;
          if (node.nodeType !== Node.ELEMENT_NODE) {
            return;
          }
          _ref = window.plugins;
          _results = [];
          for (pluginName in _ref) {
            if (!__hasProp.call(_ref, pluginName)) continue;
            pluginConf = _ref[pluginName];
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
        var pluginConf, pluginName, _ref, _results;
        _ref = window.plugins;
        _results = [];
        for (pluginName in _ref) {
          if (!__hasProp.call(_ref, pluginName)) continue;
          pluginConf = _ref[pluginName];
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
    var e, event, listener, plugin, pluginConf, pluginName, type, _ref, _ref1;
    try {
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
        for (pluginName in _ref1) {
          if (!__hasProp.call(_ref1, pluginName)) continue;
          pluginConf = _ref1[pluginName];
          if (pluginName === key) {
            continue;
          }
          if (pluginConf.type === type && pluginConf.active) {
            this.deactivate(pluginName);
          }
        }
      }
      event = new CustomEvent('plugin', {
        detail: {
          action: 'activate',
          name: key
        }
      });
      return window.dispatchEvent(event);
    } catch (_error) {
      e = _error;
      return console.log("Unable to activate plugin " + key + ": " + e);
    }
  },
  deactivate: function(key) {
    var e, event, listener, plugin, _ref;
    try {
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
        plugin.onDeactivate();
      }
      event = new CustomEvent('plugin', {
        detail: {
          action: 'deactivate',
          name: key
        }
      });
      return window.dispatchEvent(event);
    } catch (_error) {
      e = _error;
      return console.log("Unable to deactivate plugin " + key + ": " + e);
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
        if (pluginConf.url != null) {
          window.plugins[pluginName] = pluginConf;
        } else {
          delete remote[pluginName];
        }
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
  },
  loadJS: function(url, onLoad) {
    var script;
    script = document.createElement('script');
    script.type = 'text/javascript';
    script.async = true;
    script.src = url;
    if (onLoad != null) {
      script.addEventListener('load', onLoad);
    }
    return document.body.appendChild(script);
  },
  load: function(url) {
    var base, e, xhr;
    if (!/:\/\//.test(url)) {
      try {
        throw new Error();
      } catch (_error) {
        e = _error;
        base = e.stack.split('\n')[0].split('@')[1].split(/:\d/)[0].split('/').slice(0, -2).join('/');
        url = base + '/' + url + '/';
      }
    }
    xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    return xhr.onload = function() {
      var doc, parser;
      parser = new DOMParser();
      doc = parser.parseFromString(xhr.response, 'text/html');
      if (doc) {
        Array.prototype.forEach.call(doc.querySelectorAll('style'), function(sheet) {
          var style;
          style = document.createElement('style');
          document.body.appendChild(style);
          return Array.prototype.forEach.call(sheet.sheet.cssRules, function(rule, id) {
            return style.sheet.insertRule(rule.cssText, id);
          });
        });
        Array.prototype.forEach.call(doc.querySelectorAll('script'), function(script) {
          var s;
          s = document.createElement('script');
          s.textContent = script.textContent;
          return document.body.appendChild(s);
        });
      }
      return xhr.send();
    };
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
  path: pathToSocketIO,
  reconnectionDelayMax: 60000,
  reconectionDelay: 2000,
  reconnectionAttempts: 3
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

socket.on('refresh.notify', dispatchAs(ActionTypes.RECEIVE_REFRESH_NOTIF));

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
    if (raw.mailboxes == null) {
      raw.mailboxes = [];
    }
    if ((raw.draftMailbox == null) || (raw.sentMailbox == null) || (raw.trashMailbox == null)) {
      raw.mailboxes.forEach(function(box) {
        var _ref, _ref1, _ref2;
        if ((raw.draftMailbox == null) && (_ref = MailboxFlags.DRAFT, __indexOf.call(box.attribs, _ref) >= 0)) {
          raw.draftMailbox = box.id;
        }
        if ((raw.sentMailbox == null) && (_ref1 = MailboxFlags.SENT, __indexOf.call(box.attribs, _ref1) >= 0)) {
          raw.sentMailbox = box.id;
        }
        if ((raw.trashMailbox == null) && (_ref2 = MailboxFlags.TRASH, __indexOf.call(box.attribs, _ref2) >= 0)) {
          return raw.trashMailbox = box.id;
        }
      });
    }
    if ((raw.draftMailbox == null) || (raw.sentMailbox == null) || (raw.trashMailbox == null)) {
      raw.mailboxes.forEach(function(box) {
        if ((raw.draftMailbox == null) && /draft/i.test(box.label)) {
          raw.draftMailbox = box.id;
        }
        if ((raw.sentMailbox == null) && /sent/i.test(box.label)) {
          raw.sentMailbox = box.id;
        }
        if ((raw.trashMailbox == null) && /trash/i.test(box.label)) {
          return raw.trashMailbox = box.id;
        }
      });
    }
    mailboxes = Immutable.Sequence(raw.mailboxes).mapKeys(function(_, box) {
      return box.id;
    }).map(function(box) {
      var label;
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
  fetchConversation: function(conversationID, callback) {
    return request.get("messages/batchFetch?conversationID=" + conversationID).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        res.body.conversationLengths = {};
        res.body.conversationLengths[conversationID] = res.body.length;
        return callback(null, res.body);
      } else {
        console.log("Error in fetchConversation", conversationID, (_ref = res.body) != null ? _ref.error : void 0);
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
  mailboxExpunge: function(data, callback) {
    return request.del("mailbox/" + data.mailboxID + "/expunge").set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in mailboxExpunge", data, (_ref = res.body) != null ? _ref.error : void 0);
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
      var _ref, _ref1, _ref2;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in messageSend", message, (_ref = res.body) != null ? _ref.error : void 0);
        return callback((_ref1 = res.body) != null ? (_ref2 = _ref1.error) != null ? _ref2.message : void 0 : void 0);
      }
    });
  },
  batchFetch: function(target, callback) {
    var body;
    body = _.extend({}, target);
    return request.put("messages/batchFetch").send(target).end(function(res) {
      var err, _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        err = (_ref = res.body) != null ? _ref.error.message : void 0;
        if (err == null) {
          err = new Error('Network batchFetch');
        }
        return callback(err);
      }
    });
  },
  batchAddFlag: function(target, flag, callback) {
    var body;
    body = _.extend({
      flag: flag
    }, target);
    return request.put("messages/batchAddFlag").send(body).end(function(res) {
      var err, _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        err = (_ref = res.body) != null ? _ref.error.message : void 0;
        if (err == null) {
          err = new Error('Network batchAddFlag');
        }
        return callback(err);
      }
    });
  },
  batchRemoveFlag: function(target, flag, callback) {
    var body;
    body = _.extend({
      flag: flag
    }, target);
    return request.put("messages/batchRemoveFlag").send(body).end(function(res) {
      var err, _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        err = (_ref = res.body) != null ? _ref.error.message : void 0;
        if (err == null) {
          err = new Error('Network batchRemoveFlag');
        }
        return callback(err);
      }
    });
  },
  batchDelete: function(target, callback) {
    var body;
    body = _.extend({}, target);
    return request.put("messages/batchTrash").send(target).end(function(res) {
      var err, _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        err = (_ref = res.body) != null ? _ref.error.message : void 0;
        if (err == null) {
          err = new Error('Network batchDelete');
        }
        return callback(err);
      }
    });
  },
  batchMove: function(target, from, to, callback) {
    var body;
    body = _.extend({
      from: from,
      to: to
    }, target);
    return request.put("messages/batchMove").send(body).end(function(res) {
      var err, _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        err = (_ref = res.body) != null ? _ref.error.message : void 0;
        if (err == null) {
          err = new Error('Network batchMove');
        }
        return callback(err);
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
  checkAccount: function(account, callback) {
    return request.put("accountUtil/check").send(account).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in checkAccount", res.body);
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
      if (res.ok) {
        return callback(null, res.text);
      } else {
        return callback(res.body);
      }
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