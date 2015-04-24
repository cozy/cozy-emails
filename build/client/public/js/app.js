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
    return LayoutActionCreator.alertError(error.message);
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
  edit: function(inputValues, accountID) {
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
        return LayoutActionCreator.notify(t('account updated'), {
          autoclose: true
        });
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

;require.register("actions/conversation_action_creator", function(exports, require, module) {
var AccountStore, ActionTypes, AppDispatcher, LayoutActionCreator, MessageActionCreator, MessageFlags, MessageStore, XHRUtils, doPatch;

AppDispatcher = require('../app_dispatcher');

ActionTypes = require('../constants/app_constants').ActionTypes;

XHRUtils = require('../utils/xhr_utils');

MessageFlags = require('../constants/app_constants').MessageFlags;

LayoutActionCreator = require('./layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

AccountStore = require("../stores/account_store");

MessageStore = require('../stores/message_store');

doPatch = function(conversationID, patches, callback) {
  return XHRUtils.conversationPatch(conversationID, patches, function(error, messages) {
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
};

module.exports = {
  "delete": function(conversationID, callback) {
    var account, conversation, error, messages, messagesActions, trash;
    conversation = MessageStore.getConversation(conversationID);
    account = AccountStore.getByID(conversation.get(0).get('accountID'));
    trash = account.get('trashMailbox');
    if ((trash == null) || trash === '') {
      callback(t('message delete no trash'));
      return;
    }
    messages = [];
    messagesActions = [];
    error = '';
    conversation.map(function(message) {
      var action, id, mailboxIDs, msg;
      mailboxIDs = message.get('mailboxIDs');
      if (mailboxIDs[trash] == null) {
        action = {
          id: message.get('id'),
          from: Object.keys(mailboxIDs),
          to: trash
        };
        messagesActions.push(action);
        msg = message.toJS();
        for (id in msg.mailboxIDs) {
          delete msg.mailboxIDs[id];
        }
        msg.mailboxIDs[trash] = -1;
        return messages.push(msg);
      }
    }).toJS();
    if (error !== '') {
      callback(error);
      return;
    }
    XHRUtils.conversationDelete(conversationID, function(error, messages) {
      var msgOk, options;
      if (error == null) {
        AppDispatcher.handleViewAction({
          type: ActionTypes.RECEIVE_RAW_MESSAGES,
          value: messages
        });
      }
      options = {
        autoclose: true,
        actions: [
          {
            label: t('conversation undelete'),
            onClick: function() {
              return MessageActionCreator.undelete();
            }
          }
        ]
      };
      msgOk = t('conversation delete ok', {
        subject: messages[0].subject
      });
      LayoutActionCreator.notify(msgOk, options);
      if (callback != null) {
        return callback(error);
      }
    });
    AppDispatcher.handleViewAction({
      type: ActionTypes.RECEIVE_RAW_MESSAGES,
      value: messages
    });
    return AppDispatcher.handleViewAction({
      type: ActionTypes.CONVERSATION_ACTION,
      value: {
        messages: messagesActions
      }
    });
  },
  move: function(message, from, to, callback) {
    var conversation, conversationID, messages, msg, observer, patches;
    if (typeof message === 'string') {
      message = MessageStore.getByID(message);
    }
    conversationID = message.get('conversationID');
    if (conversationID == null) {
      return MessageActionCreator.move(message, from, to, callback);
    } else {
      msg = message.toJSON();
      AppDispatcher.handleViewAction({
        type: ActionTypes.CONVERSATION_ACTION,
        value: {
          id: msg.conversationID,
          from: from,
          to: to
        }
      });
      observer = jsonpatch.observe(msg);
      delete msg.mailboxIDs[from];
      msg.mailboxIDs[to] = -1;
      patches = jsonpatch.generate(observer);
      XHRUtils.conversationPatch(msg.conversationID, patches, function(error, messages) {
        var msgOk, options;
        if (error == null) {
          AppDispatcher.handleViewAction({
            type: ActionTypes.RECEIVE_RAW_MESSAGES,
            value: messages
          });
          options = {
            autoclose: true,
            actions: [
              {
                label: t('action undo'),
                onClick: function() {
                  return MessageActionCreator.undelete();
                }
              }
            ]
          };
          msgOk = t('conversation move ok', {
            subject: messages[0].subject
          });
          LayoutActionCreator.notify(msgOk, options);
        }
        if (callback != null) {
          return callback(error);
        }
      });
      conversation = MessageStore.getConversation(conversationID);
      messages = [];
      conversation.map(function(message) {
        var id;
        msg = message.toJS();
        for (id in msg.mailboxIDs) {
          delete msg.mailboxIDs[from];
        }
        msg.mailboxIDs[to] = -1;
        return messages.push(msg);
      }).toJS();
      return AppDispatcher.handleViewAction({
        type: ActionTypes.RECEIVE_RAW_MESSAGES,
        value: messages
      });
    }
  },
  seen: function(conversationID, callback) {
    var conversation, observer, patches;
    conversation = {
      flags: []
    };
    observer = jsonpatch.observe(conversation);
    conversation.flags.push(MessageFlags.SEEN);
    patches = jsonpatch.generate(observer);
    return doPatch(conversationID, patches, callback);
  },
  unseen: function(conversationID, callback) {
    var conversation, observer, patches;
    conversation = {
      flags: [MessageFlags.SEEN]
    };
    observer = jsonpatch.observe(conversation);
    conversation.flags = [];
    patches = jsonpatch.generate(observer);
    return doPatch(conversationID, patches, callback);
  },
  flag: function(conversationID, callback) {
    var conversation, observer, patches;
    conversation = {
      flags: []
    };
    observer = jsonpatch.observe(conversation);
    conversation.flags.push(MessageFlags.FLAGGED);
    patches = jsonpatch.generate(observer);
    return doPatch(conversationID, patches, callback);
  },
  noflag: function(conversationID, callback) {
    var conversation, observer, patches;
    conversation = {
      flags: [MessageFlags.FLAGGED]
    };
    observer = jsonpatch.observe(conversation);
    conversation.flags = [];
    patches = jsonpatch.generate(observer);
    return doPatch(conversationID, patches, callback);
  },
  fetch: function(conversationID) {
    return XHRUtils.fetchConversation(conversationID, function(err, rawMessages) {
      if (err == null) {
        return MessageActionCreator.receiveRawMessages(rawMessages);
      }
    });
  }
};
});

;require.register("actions/layout_action_creator", function(exports, require, module) {
var AccountActionCreator, AccountStore, ActionTypes, AlertLevel, AppDispatcher, LayoutActionCreator, LayoutStore, MessageActionCreator, MessageFlags, MessageStore, SearchActionCreator, SocketUtils, XHRUtils, _cachedDisposition, _cachedQuery, _ref;

XHRUtils = require('../utils/xhr_utils');

SocketUtils = require('../utils/socketio_utils');

AccountStore = require('../stores/account_store');

LayoutStore = require('../stores/layout_store');

MessageStore = require('../stores/message_store');

AppDispatcher = require('../app_dispatcher');

_ref = require('../constants/app_constants'), ActionTypes = _ref.ActionTypes, AlertLevel = _ref.AlertLevel, MessageFlags = _ref.MessageFlags;

AccountActionCreator = require('./account_action_creator');

MessageActionCreator = require('./message_action_creator');

SearchActionCreator = require('./search_action_creator');

_cachedQuery = {};

_cachedDisposition = null;

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
  toggleFullscreen: function() {
    if (_cachedDisposition != null) {
      AppDispatcher.handleViewAction({
        type: ActionTypes.SET_DISPOSITION,
        value: {
          disposition: _cachedDisposition
        }
      });
      return _cachedDisposition = null;
    } else {
      _cachedDisposition = _.clone(LayoutStore.getDisposition());
      return AppDispatcher.handleViewAction({
        type: ActionTypes.SET_DISPOSITION,
        value: {
          type: _cachedDisposition.type,
          value: 0
        }
      });
    }
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
      task.level = options.level;
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
      return XHRUtils.fetchMessagesByFolder(mailboxID, query, function(err, rawMsg) {
        MessageActionCreator.setFetching(false);
        if (err != null) {
          return LayoutActionCreator.alertError(err);
        } else {
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
    var conversationID, message, messageID, onMessage;
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
    return XHRUtils.fetchConversation(conversationID, function(err, rawMessages) {
      if (err != null) {
        return LayoutActionCreator.alertError(err);
      } else {
        if (rawMessages.length === 1) {
          message = MessageStore.getByID(rawMessages[0].id);
          if ((message != null) && rawMessages[0].flags.length === 0 && message.get('flags').length === 1 && message.get('flags')[0] === MessageFlags.SEEN) {
            rawMessages[0].flags = MessageFlags.SEEN;
          }
        }
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
  refreshMessages: function() {
    return XHRUtils.refresh(true, function(err, results) {
      if (err != null) {
        console.log(err);
        return LayoutActionCreator.notify(t('account refresh error'), {
          autoclose: false,
          finished: true,
          errors: [JSON.stringify(err)]
        });
      } else {
        if (results === "done") {
          MessageActionCreator.receiveRawMessages(null);
          return LayoutActionCreator.notify(t('account refreshed'), {
            autoclose: true
          });
        }
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
    var LAC, doDelete, mass;
    LAC = require('./layout_action_creator');
    doDelete = (function(_this) {
      return function(message) {
        var account, id, msg, observer, patches, trash;
        if (typeof message === "string") {
          message = MessageStore.getByID(message);
        }
        account = AccountStore.getByID(message.get('accountID'));
        if (account == null) {
          console.log("No account with id " + (message.get('accountID')) + "\nfor message " + (message.get('id')));
          LAC.alertError(t('app error'));
          return;
        }
        trash = account.get('trashMailbox');
        msg = message.toJSON();
        if ((trash == null) || trash === '') {
          return LAC.alertError(t('message delete no trash'));
        } else if (msg.mailboxIDs[trash] != null) {
          return LAC.alertError(t('message delete already'));
        } else {
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
          XHRUtils.messagePatch(message.get('id'), patches, function(err, res) {
            var notifOk, options;
            if (err != null) {
              LAC.alertError("" + (t("message action delete ko")) + " " + err);
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
              notifOk = t('message action delete ok', {
                subject: msg.subject || ''
              });
              LAC.notify(notifOk, options);
              if (callback != null) {
                return callback(err);
              }
            }
          });
          return AppDispatcher.handleViewAction({
            type: ActionTypes.MESSAGE_DELETE,
            value: msg
          });
        }
      };
    })(this);
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
    var LAC, msg, observer, patches;
    LAC = require('./layout_action_creator');
    if (from === to) {
      LAC.alertWarning(t('message move already'));
      callback();
      return;
    }
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
    var LAC, action, message;
    LAC = require('./layout_action_creator');
    action = MessageStore.getPrevAction();
    if (action != null) {
      if (action.target === 'message') {
        message = MessageStore.getByID(action.id);
        return action.from.forEach((function(_this) {
          return function(from) {
            return _this.move(message, action.to, from, function(err) {
              if (err == null) {
                return LAC.notify(t('message undelete ok'), {
                  autoclose: true
                });
              } else {
                return LAC.notify(t('message undelete error'));
              }
            });
          };
        })(this));
      } else if (action.target === 'conversation' && Array.isArray(action.messages)) {
        return action.messages.forEach((function(_this) {
          return function(message) {
            return message.from.forEach(function(from) {
              return _this.move(message.id, message.to, from, function(err) {
                if (err == null) {
                  return LAC.notify(t('message undelete ok'), {
                    autoclose: true
                  });
                } else {
                  return LAC.notify(t('message undelete error'));
                }
              });
            });
          };
        })(this));
      } else {
        return LAC.alertError(t('message undelete unavailable'));
      }
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
      var updated;
      updated = message.toJS();
      updated.flags = flags;
      return AppDispatcher.handleViewAction({
        type: ActionTypes.RECEIVE_RAW_MESSAGE,
        value: updated
      });
    }, 0);
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
var AccountActionCreator, AccountConfigMailboxes, AccountConfigMain, Container, LayoutActions, RouterMixin, Tabs, Title, _ref;

AccountActionCreator = require('../actions/account_action_creator');

LayoutActions = require('../actions/layout_action_creator');

RouterMixin = require('../mixins/router_mixin');

_ref = require('./basic_components'), Container = _ref.Container, Title = _ref.Title, Tabs = _ref.Tabs;

AccountConfigMain = require('./account_config_main');

AccountConfigMailboxes = require('./account_config_mailboxes');

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
    }) : void 0, !this.props.tab || this.props.tab === 'account' ? AccountConfigMain(mainOptions) : AccountConfigMailboxes(mailboxesOptions));
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
    var tabAccountClass, tabAccountUrl, tabMailboxClass, tabMailboxUrl, tabs;
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
    tabs = [
      {
        "class": tabAccountClass,
        url: tabAccountUrl,
        text: t("account tab account")
      }, {
        "class": tabMailboxClass,
        url: tabMailboxUrl,
        text: t("account tab mailboxes")
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
  editAccount: function(values) {
    return AccountActionCreator.edit(values, this.state.id);
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
          return state.errors[field] = "" + (t('config error ')) + field;
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
var AccountInput, ErrorLine, RouterMixin, classer, div, input, label, _ref;

_ref = React.DOM, div = _ref.div, label = _ref.label, input = _ref.input;

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
    }, type !== 'checkbox' ? input({
      id: "mailbox-" + name,
      name: "mailbox-" + name,
      valueLink: this.linkState('value').value,
      type: type,
      className: 'form-control',
      placeholder: placeHolder,
      onBlur: this.onBlur,
      onInput: this.props.onInput || null
    }) : input({
      id: "mailbox-" + name,
      name: "mailbox-" + name,
      checkedLink: this.linkState('value').value,
      type: type,
      onClick: this.props.onClick
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
    if (type === 'text' || type === 'email') {
      placeHolder = t("account " + name + " short");
    }
    return placeHolder;
  }
});
});

;require.register("components/account_config_item", function(exports, require, module) {
var AccountActionCreator, LayoutActionCreator, MailboxItem, RouterMixin, classer, i, li, span, _ref;

_ref = React.DOM, li = _ref.li, span = _ref.span, i = _ref.i;

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
          return layoutActionCreator.notify(t("mailbox delete ok"), {
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
        onChange: this.onMailboxChange
      })));
    }
  },
  onMailboxChange: (function(_this) {
    return function(mailbox) {
      var newState;
      _this.state[box].requestChange(mailbox);
      newState = {};
      newState[box] = mailbox;
      return _this.setState(newState, function() {
        return _this.props.onSubmit();
      });
    };
  })(this),
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
    state.smtpAdvanced = false;
    return state;
  },
  componentWillReceiveProps: function(props) {
    var key, state, value;
    state = {};
    for (key in props) {
      value = props[key];
      state[key] = value;
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
    }), FieldSet({
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
var AccountConfig, AccountStore, Alert, Application, Compose, ContactStore, Conversation, Dispositions, LayoutActionCreator, LayoutStore, Menu, MessageFilter, MessageList, MessageStore, ReactCSSTransitionGroup, RefreshesStore, RouterMixin, SearchForm, SearchStore, Settings, SettingsStore, StoreWatchMixin, Stores, ToastContainer, TooltipRefesherMixin, Tooltips, Topbar, a, body, button, classer, div, form, i, input, p, span, strong, _ref, _ref1;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span, a = _ref.a, button = _ref.button, strong = _ref.strong;

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
    var alert, disposition, firstPanelLayoutMode, getUrl, isFullWidth, keyFirst, keySecond, layout, panelClasses, panelsClasses, responsiveClasses;
    layout = this.props.router.current;
    if (layout == null) {
      return div(null, t("app loading"));
    }
    isFullWidth = layout.secondPanel == null;
    firstPanelLayoutMode = isFullWidth ? 'full' : 'first';
    disposition = LayoutStore.getDisposition();
    panelsClasses = classer({
      horizontal: disposition.type === Dispositions.HORIZONTAL,
      three: disposition.type === Dispositions.THREE,
      vertical: disposition.type === Dispositions.VERTICAL,
      full: isFullWidth
    });
    panelClasses = this.getPanelClasses(isFullWidth);
    responsiveClasses = classer;
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
      if (layout.secondPanel.parameters.messageID != null) {
        MessageStore.setCurrentID(layout.secondPanel.parameters.messageID);
      } else {
        MessageStore.setCurrentID(null);
      }
    } else {
      if (layout.firstPanel.action !== 'compose') {
        MessageStore.setCurrentID(null);
      }
    }
    return div({
      className: 'container-fluid'
    }, div({
      className: 'row'
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
      disposition: disposition,
      toggleMenu: this.toggleMenu
    }), div({
      id: 'page-content',
      className: responsiveClasses
    }, Alert({
      alert: alert
    }), ToastContainer(), div({
      id: 'panels',
      className: panelsClasses
    }, div({
      className: panelClasses.firstPanel,
      key: keyFirst
    }, this.getPanelComponent(layout.firstPanel, firstPanelLayoutMode)), !isFullWidth && (layout.secondPanel != null) ? div({
      className: panelClasses.secondPanel,
      key: keySecond
    }, this.getPanelComponent(layout.secondPanel, 'second')) : void 0)), Tooltips()));
  },
  getPanelClasses: function(isFullWidth) {
    var classes, disposition, first, firstClass, layout, previous, second, secondClass, wasFullWidth;
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
        firstClass = "col-md-12 row-" + disposition.height;
        secondClass = "col-md-12 row-" + (10 - disposition.height);
      } else {
        firstClass = "col-md-" + disposition.width + " row-10";
        secondClass = "col-md-" + (12 - disposition.width) + " row-10";
      }
      classes = {
        firstPanel: "col-xs-12 hidden-xs hidden-sm " + firstClass,
        secondPanel: "col-xs-12 " + secondClass
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
    var account, accountID, conversation, conversationID, conversationLength, conversationLengths, counterMessage, direction, displayConversations, emptyListMessage, error, favoriteMailboxes, fetching, isDraft, isTrash, isWaiting, lengths, mailbox, mailboxID, mailboxes, message, messageID, messages, messagesCount, nextMessage, prevMessage, query, ref, selectedAccount, selectedMailboxID, settings, tab, _ref2, _ref3, _ref4, _ref5;
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
        messagesCount: messagesCount,
        accountID: accountID,
        mailboxID: mailboxID,
        messageID: messageID,
        conversationID: conversationID,
        login: AccountStore.getByID(accountID).get('login'),
        mailboxes: this.state.mailboxesFlat,
        settings: this.state.settings,
        fetching: fetching,
        refreshes: this.state.refreshes,
        query: query,
        isTrash: isTrash,
        conversationLengths: conversationLengths,
        emptyListMessage: emptyListMessage,
        counterMessage: counterMessage,
        ref: 'messageList',
        toggleMenu: this.toggleMenu,
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
        layout: layout,
        readability: this.state.readability,
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
        displayConversations: displayConversations
      });
    } else if (panelInfo.action === 'compose') {
      return Compose({
        layout: layout,
        action: null,
        inReplyTo: null,
        settings: this.state.settings,
        accounts: this.state.accountsFlat,
        selectedAccountID: this.state.selectedAccount.get('id'),
        selectedAccountLogin: this.state.selectedAccount.get('login'),
        message: null,
        ref: 'compose'
      });
    } else if (panelInfo.action === 'edit') {
      messageID = panelInfo.parameters.messageID;
      message = MessageStore.getByID(messageID);
      return Compose({
        layout: layout,
        action: null,
        inReplyTo: null,
        settings: this.state.settings,
        accounts: this.state.accountsFlat,
        selectedAccountID: this.state.selectedAccount.get('id'),
        selectedAccountLogin: this.state.selectedAccount.get('login'),
        selectedMailboxID: this.state.selectedMailboxID,
        message: message,
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
    var accounts, accountsFlat, disposition, firstPanelInfo, mailboxes, mailboxesFlat, readability, selectedAccount, selectedAccountID, selectedMailboxID, _ref2;
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
        trashMailbox: account.get('trashMailbox')
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
    readability = 0 === disposition.width || 0 === disposition.height;
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
      readability: readability,
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
    var account;
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
          return LayoutActionCreator.alertError(t('account no special mailboxes'));
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
  },
  toggleMenu: function(event) {
    return this.setState({
      isResponsiveMenuShown: !this.state.isResponsiveMenuShown
    });
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
var AddressLabel, Container, ErrorLine, FieldSet, Form, FormButton, FormButtons, FormDropdown, SubTitle, Tabs, Title, a, button, div, fieldset, form, h3, h4, i, img, label, legend, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, h4 = _ref.h4, ul = _ref.ul, li = _ref.li, a = _ref.a, i = _ref.i, button = _ref.button, span = _ref.span, fieldset = _ref.fieldset, legend = _ref.legend, label = _ref.label, img = _ref.img, form = _ref.form;

Container = React.createClass({
  render: function() {
    return div({
      id: this.props.id,
      key: this.props.key
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
    var tab;
    return ul({
      className: "nav nav-tabs",
      role: "tablist"
    }, (function() {
      var _i, _len, _ref1, _results;
      _ref1 = this.props.tabs;
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        tab = _ref1[_i];
        _results.push(li({
          className: tab["class"]
        }, a({
          href: tab.url
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
    }, this.props.spinner ? span(null, img({
      src: 'images/spinner-white.svg',
      className: 'button-spinner'
    })) : span({
      className: "fa fa-" + this.props.icon
    }), span(null, this.props.text));
  }
});

FormButtons = React.createClass({
  render: function() {
    var formButton;
    return div(null, div({
      className: 'col-sm-offset-4'
    }, (function() {
      var _i, _len, _ref1, _results;
      _ref1 = this.props.buttons;
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        formButton = _ref1[_i];
        _results.push(FormButton(formButton));
      }
      return _results;
    }).call(this)));
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
    var key, result;
    if ((this.props.contact.name != null) && this.props.contact.name.length > 0) {
      key = this.props.contact.address.replace(/\W/g, '');
      result = span(null, span(null, "" + this.props.contact.name + " "), span({
        className: 'contact-address',
        key: key
      }, "<" + this.props.contact.address + ">"));
    } else {
      result = span(null, this.props.contact.address);
    }
    return result;
  }
});

module.exports = {
  AddressLabel: AddressLabel,
  Container: Container,
  ErrorLine: ErrorLine,
  Form: Form,
  FieldSet: FieldSet,
  FormButton: FormButton,
  FormButtons: FormButtons,
  FormDropdown: FormDropdown,
  SubTitle: SubTitle,
  Title: Title,
  Tabs: Tabs
};
});

;require.register("components/compose", function(exports, require, module) {
var AccountPicker, Compose, ComposeActions, ComposeEditor, ConversationActionCreator, FilePicker, LayoutActionCreator, MailsInput, MessageActionCreator, RouterMixin, a, button, classer, div, form, h3, i, img, input, label, li, messageUtils, span, textarea, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, a = _ref.a, i = _ref.i, textarea = _ref.textarea, form = _ref.form, label = _ref.label, button = _ref.button;

_ref1 = React.DOM, span = _ref1.span, ul = _ref1.ul, li = _ref1.li, input = _ref1.input, img = _ref1.img;

classer = React.addons.classSet;

FilePicker = require('./file_picker');

MailsInput = require('./mails_input');

AccountPicker = require('./account_picker');

ComposeActions = require('../constants/app_constants').ComposeActions;

messageUtils = require('../utils/message_utils');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

RouterMixin = require('../mixins/router_mixin');

module.exports = Compose = React.createClass({
  displayName: 'Compose',
  mixins: [RouterMixin, React.addons.LinkedStateMixin],
  propTypes: {
    selectedAccountID: React.PropTypes.string.isRequired,
    selectedAccountLogin: React.PropTypes.string.isRequired,
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
    var classBcc, classCc, classInput, classLabel, closeUrl, focusEditor, labelSend, onCancel, toggleFullscreen, _ref2, _ref3;
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
    return div({
      id: 'email-compose'
    }, this.props.layout !== 'full' ? a({
      onClick: toggleFullscreen,
      className: 'expand pull-right clickable'
    }, i({
      className: 'fa fa-arrows-h'
    })) : a({
      onClick: toggleFullscreen,
      className: 'close-email pull-right clickable'
    }, i({
      className: 'fa fa-compress'
    })), h3({
      'data-message-id': ((_ref2 = this.props.message) != null ? _ref2.get('id') : void 0) || ''
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
      messageID: (_ref3 = this.props.message) != null ? _ref3.get('id') : void 0,
      html: this.linkState('html'),
      text: this.linkState('text'),
      settings: this.props.settings,
      onSend: this.onSend,
      composeInHTML: this.state.composeInHTML,
      focus: focusEditor,
      ref: 'editor'
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
    }, this.state.sending ? span(null, img({
      src: 'images/spinner-white.svg',
      className: 'button-spinner'
    })) : span({
      className: 'fa fa-send'
    }), span(null, labelSend)), button({
      className: 'btn btn-cozy btn-save',
      disable: this.state.saving ? true : null,
      type: 'button',
      onClick: this.onDraft
    }, this.state.saving ? span(null, img({
      src: 'images/spinner-white.svg',
      className: 'button-spinner'
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
    var message;
    if (this._saveInterval) {
      window.clearInterval(this._saveInterval);
    }
    if (this.state.isDraft && (this.state.id != null)) {
      if (!window.confirm(t('compose confirm keep draft'))) {
        return window.setTimeout((function(_this) {
          return function() {
            return MessageActionCreator["delete"](_this.state.id, function(error) {
              if (error != null) {
                return LayoutActionCreator.alertError("" + (t("message action delete ko")) + " " + error);
              } else {
                return LayoutActionCreator.notify(t('compose draft deleted'), {
                  autoclose: true
                });
              }
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
            var msg;
            if (error != null) {
              msg = "" + (t("message action draft ko")) + " " + error;
              return LayoutActionCreator.alertError(msg);
            } else {
              msg = "" + (t("message action draft ok"));
              LayoutActionCreator.notify(msg, {
                autoclose: true
              });
              if (message.conversationID != null) {
                return ConversationActionCreator.fetch(message.conversationID);
              }
            }
          });
        }
      }
    }
  },
  getInitialState: function(forceDefault) {
    var key, message, state, value, _ref2;
    if (message = this.props.message) {
      state = {
        composeInHTML: this.props.settings.get('composeInHTML')
      };
      if ((message.get('html') == null) && message.get('text')) {
        state.conposeInHTML = false;
      }
      _ref2 = message.toJS();
      for (key in _ref2) {
        value = _ref2[key];
        state[key] = value;
      }
      state.attachments = message.get('attachments');
    } else {
      state = messageUtils.makeReplyMessage(this.props.selectedAccountLogin, this.props.inReplyTo, this.props.action, this.props.settings.get('composeInHTML'));
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
        message.text = messageUtils.cleanReplyText(message.html);
        message.html = messageUtils.wrapReplyHtml(message.html);
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
          var key, msgKo, msgOk, state, value;
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
            state[key] = value;
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
                ConversationActionCreator.fetch(message.conversationID);
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
    var confirmMessage, params, subject;
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
      return MessageActionCreator["delete"](this.props.message, (function(_this) {
        return function(error) {
          var msg, parameters;
          if (error != null) {
            msg = "" + (t("message action delete ko")) + " " + error;
            return LayoutActionCreator.alertError(msg);
          } else {
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
    var focus, toggle, _i, _len, _ref2;
    toggle = function(e) {
      return e.classList.toggle('shown');
    };
    _ref2 = this.getDOMNode().querySelectorAll('.compose-cc');
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      e = _ref2[_i];
      toggle(e);
    }
    focus = !this.state.ccShown ? 'cc' : '';
    return this.setState({
      ccShown: !this.state.ccShown,
      focus: focus
    });
  },
  onToggleBcc: function(e) {
    var focus, toggle, _i, _len, _ref2;
    toggle = function(e) {
      return e.classList.toggle('shown');
    };
    _ref2 = this.getDOMNode().querySelectorAll('.compose-bcc');
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      e = _ref2[_i];
      toggle(e);
    }
    focus = !this.state.bccShown ? 'bcc' : '';
    return this.setState({
      bccShown: !this.state.bccShown,
      focus: focus
    });
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
  render: function() {
    var folded, onHTMLChange, onTextChange;
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
    if (this.props.settings.get('composeOnTop')) {
      folded = 'folded';
    } else {
      folded = '';
    }
    if (this.props.composeInHTML) {
      return div({
        className: "form-control rt-editor " + folded,
        ref: 'html',
        contentEditable: true,
        onKeyDown: this.onKeyDown,
        onInput: onHTMLChange,
        onBlur: onHTMLChange,
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
    var e, gecko, header, node, r, range, rect, s, _ref2;
    if (this.props.composeInHTML) {
      if (this.props.focus) {
        node = (_ref2 = this.refs.html) != null ? _ref2.getDOMNode() : void 0;
        if (node == null) {
          return;
        }
        document.querySelector(".rt-editor").focus();
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
            node.focus();
          }
        }
      }
      gecko = document.queryCommandEnabled('insertBrOnReturn');
      jQuery('.rt-editor').on('keypress', function(e) {
        var quote;
        if (e.keyCode !== 13) {
          return;
        }
        quote = function() {
          var br, depth, getPath, isInsideQuote, range, selection, target, targetElement;
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
  componentDidMount: function() {
    return this._initCompose();
  },
  componentDidUpdate: function(nextProps, nextState) {
    if (nextProps.messageID !== this.props.messageID) {
      return this._initCompose();
    }
  },
  onKeyDown: function(evt) {
    if (evt.ctrlKey && evt.key === 'Enter') {
      return this.props.onSend();
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
var Message, MessageFlags, RouterMixin, Toolbar, a, button, classer, h3, header, i, li, p, section, span, ul, _ref,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ref = React.DOM, section = _ref.section, header = _ref.header, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a, button = _ref.button;

Message = require('./message');

Toolbar = require('./toolbar_conversation');

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

MessageFlags = require('../constants/app_constants').MessageFlags;

module.exports = React.createClass({
  displayName: 'Conversation',
  mixins: [RouterMixin],
  propTypes: {
    message: React.PropTypes.object,
    conversation: React.PropTypes.object,
    selectedAccountID: React.PropTypes.string.isRequired,
    selectedAccountLogin: React.PropTypes.string.isRequired,
    layout: React.PropTypes.string.isRequired,
    readability: React.PropTypes.bool.isRequired,
    selectedMailboxID: React.PropTypes.string,
    mailboxes: React.PropTypes.object.isRequired,
    settings: React.PropTypes.object.isRequired,
    accounts: React.PropTypes.object.isRequired,
    displayConversations: React.PropTypes.bool
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
      displayConversations: this.props.displayConversation
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
    this.props.conversation.map(function(message, key) {
      var isSeen, last, _ref1;
      isSeen = (_ref1 = MessageFlags.SEEN, __indexOf.call(message.get('flags'), _ref1) >= 0);
      if (!isSeen || key === lastMessageIndex) {
        return messages.push(key);
      } else {
        last = messages[messages.length - 1];
        if (!_.isArray(last)) {
          messages.push(last = []);
        }
        return last.push(key);
      }
    }).toJS();
    return section({
      className: 'conversation'
    }, header(null, this.renderToolbar(), h3({
      className: 'conversation-title',
      'data-message-id': this.props.message.get('id')
    }, this.props.message.get('subject'))), (function() {
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
var AccountStore, ConversationActionCreator, Dispositions, LayoutActionCreator, Menu, MenuMailboxItem, MessageActionCreator, MessageUtils, Modal, RouterMixin, SpecialBoxIcons, ThinProgress, a, classer, div, i, li, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

LayoutActionCreator = require('../actions/layout_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

AccountStore = require('../stores/account_store');

Modal = require('./modal');

ThinProgress = require('./thin_progress');

MessageUtils = require('../utils/message_utils');

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
    var classes, closeLabel, closeModal, content, modal, modalErrors, newMailboxClass, newMailboxUrl, selectedAccountUrl, settingsClass, settingsUrl, subtitle, title, _ref2, _ref3;
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
    classes = classer({
      'hidden-xs hidden-sm': !this.props.isResponsiveMenuShown,
      'collapsed': this.props.disposition.type !== Dispositions.THREE,
      'expanded': this.props.disposition.type === Dispositions.THREE,
      'three': this.props.disposition.type === Dispositions.THREE
    });
    return div({
      id: 'menu',
      className: classes
    }, modal, this.props.accounts.length !== 0 ? ul({
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
    }, t('menu account new'))));
  },
  getAccountRender: function(account, key) {
    var accountClasses, accountID, defaultMailbox, icon, isSelected, mailboxes, nbUnread, progress, refreshes, toggleActive, toggleDisplay, toggleFavorites, toggleFavoritesLabel, url, _ref2;
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
    })) : void 0, progress.get('firstImport') ? ThinProgress({
      done: progress.get('done'),
      total: progress.get('total')
    }) : void 0) : nbUnread > 0 ? span({
      className: 'badge'
    }, nbUnread) : void 0), isSelected ? ul({
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
    }, "" + pusher + (this.props.mailbox.get('label'))), progress && progress.get('firstImport') ? ThinProgress({
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
    var conversation, data, mailboxID, messageID, newID, _ref2;
    data = event.dataTransfer.getData('text');
    _ref2 = JSON.parse(data), messageID = _ref2.messageID, mailboxID = _ref2.mailboxID, conversation = _ref2.conversation;
    newID = event.currentTarget.dataset.mailboxId;
    this.setState({
      target: false
    });
    return MessageUtils.move(messageID, conversation, mailboxID, newID);
  }
});
});

;require.register("components/message-list", function(exports, require, module) {
var AccountActionCreator, ContactActionCreator, ConversationActionCreator, DomUtils, FlagsConstants, LayoutActionCreator, MailboxList, MessageActionCreator, MessageFilter, MessageFlags, MessageItem, MessageList, MessageListBody, MessageStore, MessageUtils, MessagesFilter, MessagesQuickFilter, MessagesSort, Participants, RouterMixin, SocketUtils, ToolboxActions, ToolboxMove, TooltipRefresherMixin, Tooltips, a, alertError, button, classer, div, i, img, input, li, p, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, p = _ref.p, button = _ref.button, input = _ref.input, img = _ref.img;

classer = React.addons.classSet;

RouterMixin = require('../mixins/router_mixin');

TooltipRefresherMixin = require('../mixins/tooltip_refresher_mixin');

DomUtils = require('../utils/dom_utils');

MessageUtils = require('../utils/message_utils');

SocketUtils = require('../utils/socketio_utils');

_ref1 = require('../constants/app_constants'), MessageFlags = _ref1.MessageFlags, MessageFilter = _ref1.MessageFilter, FlagsConstants = _ref1.FlagsConstants, Tooltips = _ref1.Tooltips;

AccountActionCreator = require('../actions/account_action_creator');

ContactActionCreator = require('../actions/contact_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

LayoutActionCreator = require('../actions/layout_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

MessageStore = require('../stores/message_store');

MailboxList = require('./mailbox_list');

Participants = require('./participant');

ToolboxActions = require('./toolbox_actions');

ToolboxMove = require('./toolbox_move');

alertError = LayoutActionCreator.alertError;

MessageList = React.createClass({
  displayName: 'MessageList',
  mixins: [RouterMixin, TooltipRefresherMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    var should;
    should = !(_.isEqual(nextState, this.state)) || !(_.isEqual(nextProps, this.props));
    return should;
  },
  getInitialState: function() {
    return {
      edited: false,
      filterFlag: false,
      filterUnsead: false,
      filterAttach: false,
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
    var advanced, btnClasses, btnGrpClasses, classCompact, classEdited, classList, compact, composeUrl, configMailboxUrl, filterParams, getMailboxUrl, nbSelected, nextPage, showList, toggleFilterAttach, toggleFilterFlag, toggleFilterUnseen;
    compact = this.props.settings.get('listStyle') === 'compact';
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
          parameters: [_this.props.accountID, mailbox.id]
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
    if (Object.keys(this.state.selected).length > 0) {
      nbSelected = null;
    } else {
      nbSelected = true;
    }
    showList = (function(_this) {
      return function() {
        var params;
        params = _.clone(MessageStore.getParams());
        params.accountID = _this.props.accountID;
        params.mailboxID = _this.props.mailboxID;
        return LayoutActionCreator.showMessageList({
          parameters: params
        });
      };
    })(this);
    toggleFilterFlag = (function(_this) {
      return function() {
        var filter;
        if (_this.state.filterFlag) {
          filter = MessageFilter.ALL;
        } else {
          filter = MessageFilter.FLAGGED;
        }
        LayoutActionCreator.filterMessages(filter);
        showList();
        return _this.setState({
          filterFlag: !_this.state.filterFlag,
          filterUnseen: false,
          filterAttach: false
        });
      };
    })(this);
    toggleFilterUnseen = (function(_this) {
      return function() {
        var filter;
        if (_this.state.filterUnseen) {
          filter = MessageFilter.ALL;
        } else {
          filter = MessageFilter.UNSEEN;
        }
        LayoutActionCreator.filterMessages(filter);
        showList();
        return _this.setState({
          filterUnseen: !_this.state.filterUnseen,
          filterFlag: false,
          filterAttach: false
        });
      };
    })(this);
    toggleFilterAttach = (function(_this) {
      return function() {
        var filter;
        if (_this.state.filterAttach) {
          filter = MessageFilter.ALL;
        } else {
          filter = MessageFilter.ATTACH;
        }
        LayoutActionCreator.filterMessages(filter);
        showList();
        return _this.setState({
          filterAttach: !_this.state.filterAttach,
          filterFlag: false,
          filterUnseen: false
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
    btnClasses = 'btn btn-default ';
    btnGrpClasses = 'btn-group btn-group-sm message-list-option ';
    composeUrl = this.buildUrl({
      direction: 'first',
      action: 'compose',
      parameters: null,
      fullWidth: true
    });
    return div({
      className: 'message-list ' + classList,
      ref: 'list',
      'data-mailbox-id': this.props.mailboxID
    }, div({
      className: 'message-list-actions'
    }, div({
      className: 'btn-toolbar',
      role: 'toolbar'
    }, div({
      className: 'btn-group'
    }, advanced ? div({
      className: btnGrpClasses
    }, button({
      type: "button",
      className: btnClasses + classEdited,
      onClick: this.toggleEdited
    }, i({
      className: 'fa fa-square-o'
    }))) : void 0, advanced && !this.state.edited ? div({
      className: btnGrpClasses
    }, MailboxList({
      getUrl: getMailboxUrl,
      mailboxes: this.props.mailboxes,
      selectedMailboxID: this.props.mailboxID,
      ref: 'mailboxList'
    })) : void 0, !advanced && !this.state.edited ? div({
      className: btnGrpClasses + ' toggle-menu-button'
    }, button({
      onClick: this.props.toggleMenu,
      title: t('menu toggle'),
      className: btnClasses
    }, span({
      className: 'fa fa-inbox'
    }))) : void 0, !advanced && !this.state.edited ? div({
      className: btnGrpClasses
    }, button({
      onClick: toggleFilterUnseen,
      className: btnClasses + (this.state.filterUnseen ? ' shown' : void 0),
      'aria-describedby': Tooltips.FILTER_ONLY_UNREAD,
      'data-tooltip-direction': 'bottom'
    }, span({
      className: 'fa fa-envelope'
    }))) : void 0, !advanced && !this.state.edited ? div({
      className: btnGrpClasses
    }, button({
      onClick: toggleFilterFlag,
      className: btnClasses + (this.state.filterFlag ? ' shown' : void 0),
      'aria-describedby': Tooltips.FILTER_ONLY_IMPORTANT,
      'data-tooltip-direction': 'bottom'
    }, span({
      className: 'fa fa-star'
    }))) : void 0, !advanced && !this.state.edited ? div({
      className: btnGrpClasses
    }, button({
      onClick: toggleFilterAttach,
      className: btnClasses + (this.state.filterAttach ? ' shown' : void 0),
      'aria-describedby': Tooltips.FILTER_ONLY_WITH_ATTACHMENT,
      'data-tooltip-direction': 'bottom'
    }, span({
      className: 'fa fa-paperclip'
    }))) : void 0, advanced && !this.state.edited ? div({
      className: btnGrpClasses
    }, MessagesFilter(filterParams)) : void 0, advanced && !this.state.edited ? div({
      className: btnGrpClasses
    }, MessagesSort(filterParams)) : void 0, !this.state.edited ? div({
      className: btnGrpClasses
    }, this.props.refreshes.length === 0 ? button({
      className: btnClasses,
      type: 'button',
      disabled: null,
      onClick: this.refresh
    }, span({
      className: 'fa fa-refresh',
      'aria-describedby': Tooltips.TRIGGER_REFRESH,
      'data-tooltip-direction': 'bottom'
    })) : img({
      src: 'images/spinner.svg',
      alt: 'spinner',
      className: 'spin'
    })) : void 0, !this.state.edited ? div({
      className: btnGrpClasses
    }, a({
      href: configMailboxUrl,
      className: btnClasses + 'mailbox-config'
    }, i({
      className: 'fa fa-cog',
      'aria-describedby': Tooltips.ACCOUNT_PARAMETERS,
      'data-tooltip-direction': 'bottom'
    }))) : void 0, this.state.edited ? div({
      className: btnGrpClasses
    }, button({
      type: "button",
      className: btnClasses + classEdited,
      onClick: this.toggleAll
    }, i({
      className: 'fa fa-square-o'
    }))) : void 0, this.state.edited ? div({
      className: btnGrpClasses
    }, button({
      className: "" + btnClasses + "trash",
      type: 'button',
      disabled: nbSelected,
      onClick: this.onDelete,
      'aria-describedby': Tooltips.DELETE_SELECTION,
      'data-tooltip-direction': 'bottom'
    }, span({
      className: 'fa fa-trash-o'
    }))) : void 0, this.state.edited ? ToolboxMove({
      ref: 'listToolboxMove',
      mailboxes: this.props.mailboxes,
      onMove: this.onMove,
      direction: 'left'
    }) : void 0, this.state.edited ? ToolboxActions({
      ref: 'listToolboxActions',
      mailboxes: this.props.mailboxes,
      onMark: this.onMark,
      onConversation: this.onConversation,
      onMove: this.onConversationMove,
      displayConversations: this.props.displayConversations,
      onHeaders: this.onHeaders,
      direction: 'left'
    }) : void 0, this.props.isTrash && !this.state.edited ? div({
      className: btnGrpClasses
    }, button({
      className: btnClasses,
      type: 'button',
      disabled: null,
      onClick: this.expungeMailbox
    }, span({
      className: 'fa fa-recycle'
    }))) : void 0), a({
      href: composeUrl,
      className: 'menu-item compose-action btn btn-cozy-contrast btn-cozy'
    }, i({
      className: 'fa fa-edit'
    }), span({
      className: 'item-label'
    }, t('menu compose'))))), this.props.messages.count() === 0 ? this.props.fetching ? p(null, t('list fetching')) : p(null, this.props.emptyListMessage) : div(null, MessageListBody({
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
    }), this.moreToSee() && (this.props.query.pageAfter != null) ? p({
      className: 'text-center list-footer'
    }, this.props.fetching ? img({
      src: 'images/spinner.svg'
    }) : a({
      className: 'more-messages',
      onClick: nextPage,
      ref: 'nextPage'
    }, t('list next page'))) : p({
      ref: 'listEnd'
    }, t('list end'))));
  },
  moreToSee: function() {
    var nbInConv, nbMessages;
    nbMessages = parseInt(this.props.messagesCount, 10);
    if (this.props.displayConversations) {
      nbInConv = 0;
      this.props.messages.map((function(_this) {
        return function(message) {
          var length;
          length = _this.props.conversationLengths.get(message.get('conversationID'));
          if (length != null) {
            return nbInConv += _this.props.conversationLengths.get(message.get('conversationID'));
          }
        };
      })(this)).toJS();
      return nbInConv < nbMessages;
    } else {
      return this.props.messages.count() < nbMessages;
    }
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
  onDelete: function(conv) {
    var confirm, confirmMessage, selected;
    selected = Object.keys(this.state.selected);
    if (conv == null) {
      conv = this.props.displayConversations;
    }
    if (selected.length === 0) {
      return alertError(t('list mass no message'));
    } else {
      confirm = this.props.settings.get('messageConfirmDelete');
      if (confirm) {
        if (conv) {
          confirmMessage = t('list delete conv confirm', {
            smart_count: selected.length
          });
        } else {
          confirmMessage = t('list delete confirm', {
            smart_count: selected.length
          });
        }
      }
      if ((!confirm) || window.confirm(confirmMessage)) {
        return MessageUtils["delete"](selected, conv, (function(_this) {
          return function() {
            var firstMessageID;
            if (selected.length > 0 && _this.props.messages.count() > 0) {
              firstMessageID = _this.props.messages.first().get('id');
              return MessageActionCreator.setCurrent(firstMessageID, true);
            }
          };
        })(this));
      }
    }
  },
  onConversationMove: function(args) {
    return this.onMove(args, true);
  },
  onMove: function(args, conv) {
    var newbox, selected;
    selected = Object.keys(this.state.selected);
    if (conv == null) {
      conv = this.props.displayConversations;
    }
    if (selected.length === 0) {
      return alertError(t('list mass no message'));
    } else {
      newbox = args.target.dataset.value;
      return MessageUtils.move(selected, conv, this.props.mailboxID, newbox, (function(_this) {
        return function() {
          var firstMessageID;
          if (selected.length > 0 && _this.props.messages.count() > 0) {
            firstMessageID = _this.props.messages.first().get('id');
            return MessageActionCreator.setCurrent(firstMessageID, true);
          }
        };
      })(this));
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
    var action, selected;
    selected = Object.keys(this.state.selected);
    action = args.target.dataset.action;
    if (action === 'delete') {
      return this.onDelete(true);
    } else {
      if (selected.length === 0) {
        return alertError(t('list mass no message'));
      } else {
        return selected.forEach((function(_this) {
          return function(id) {
            var conversationID, message;
            message = _this.props.messages.get(id);
            conversationID = message.get('conversationID');
            switch (action) {
              case 'seen':
                return ConversationActionCreator.seen(conversationID, function(error) {
                  if (error != null) {
                    return alertError("" + (t("conversation seen ko ")) + " " + error);
                  }
                });
              case 'unseen':
                return ConversationActionCreator.unseen(conversationID, function(error) {
                  if (error != null) {
                    return alertError("" + (t("conversation unseen ko")) + " " + error);
                  }
                });
              case 'flagged':
                return ConversationActionCreator.flag(conversationID, function(error) {
                  if (error != null) {
                    return alertError("" + (t("conversation flagged ko ")) + " " + error);
                  }
                });
              case 'noflag':
                return ConversationActionCreator.noflag(conversationID, function(error) {
                  if (error != null) {
                    return alertError("" + (t("conversation noflag ko")) + " " + error);
                  }
                });
            }
          };
        })(this));
      }
    }
  },
  expungeMailbox: function(e) {
    var mailbox;
    e.preventDefault();
    if (window.confirm(t('account confirm delbox'))) {
      mailbox = {
        mailboxID: this.props.mailboxID,
        accountID: this.props.accountID
      };
      return AccountActionCreator.mailboxExpunge(mailbox, (function(_this) {
        return function(error) {
          var params;
          if (error != null) {
            if (_this.props.accountID === mailbox.accountID && _this.props.mailboxID === mailbox.mailboxID) {
              params = _.clone(MessageStore.getParams());
              params.accountID = _this.props.accountID;
              params.mailboxID = _this.props.mailboxID;
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
  },
  _loadNext: function() {
    if ((this.refs.nextPage != null) && DomUtils.isVisible(this.refs.nextPage.getDOMNode())) {
      return LayoutActionCreator.showMessageList({
        parameters: this.props.query
      });
    }
  },
  _handleRealtimeGrowth: function() {
    var lastdate, nbMessages;
    nbMessages = parseInt(this.props.messagesCount, 10);
    if ((!this.moreToSee()) && (this.refs.listEnd != null) && !DomUtils.isVisible(this.refs.listEnd.getDOMNode())) {
      lastdate = this.props.messages.last().get('date');
      return SocketUtils.changeRealtimeScope(this.props.mailboxID, lastdate);
    }
  },
  _initScroll: function() {
    var scrollable;
    if (this.refs.nextPage == null) {
      return;
    }
    scrollable = this.refs.list.getDOMNode().parentNode;
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
    scrollable.removeEventListener('scroll', this._loadNext);
    if (this._checkNextInterval != null) {
      return window.clearInterval(this._checkNextInterval);
    }
  }
});

module.exports = MessageList;

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
    var messages;
    messages = this.props.messages.map((function(_this) {
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
    })(this)).toJS();
    return ul({
      className: 'list-unstyled'
    }, messages);
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
    var action, avatar, classes, compact, conversationID, date, flags, isDraft, message, params, preview, tag, text, url;
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
    if (isDraft && !this.props.isTrash) {
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
    if (!this.props.edited) {
      tag = a;
    } else {
      tag = span;
    }
    compact = this.props.settings.get('listStyle') === 'compact';
    date = MessageUtils.formatDate(message.get('createdAt'), compact);
    avatar = MessageUtils.getAvatar(message);
    text = message.get('text');
    preview = text != null ? text.substr(0, 100) + "…" : '';
    return li({
      className: classes,
      key: this.props.key,
      'data-message-id': message.get('id'),
      'data-conversation-id': message.get('conversationID'),
      draggable: !this.props.edited,
      onClick: this.onMessageClick,
      onDragStart: this.onDragStart
    }, tag({
      href: url,
      className: 'wrapper',
      'data-message-id': message.get('id'),
      onClick: this.onMessageClick,
      onDoubleClick: this.onMessageDblClick,
      ref: 'target'
    }, div({
      className: 'avatar-wrapper select-target'
    }, input({
      ref: 'select',
      className: 'select select-target',
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
    }, this.props.displayConversations && this.props.conversationLengths > 1 ? span({
      className: 'badge conversation-length'
    }, this.props.conversationLengths) : void 0, span({
      className: 'title'
    }, message.get('subject')), p(null, preview)), span({
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
      messageID: event.currentTarget.dataset.messageId,
      mailboxID: this.props.mailboxID,
      conversation: this.props.displayConversations
    };
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
    }, t('list filter flagged'))), li({
      role: 'presentation'
    }, a({
      onClick: this.onFilter,
      'data-filter': MessageFilter.ATTACH
    }, t('list filter attach')))));
  },
  onFilter: function(ev) {
    var params;
    LayoutActionCreator.filterMessages(ev.target.dataset.filter);
    params = _.clone(MessageStore.getParams());
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
    params = _.clone(MessageStore.getParams());
    params.accountID = this.props.accountID;
    params.mailboxID = this.props.mailboxID;
    return LayoutActionCreator.showMessageList({
      parameters: params
    });
  }
});
});

;require.register("components/message", function(exports, require, module) {
var Compose, ComposeActions, ContactActionCreator, ConversationActionCreator, FlagsConstants, LayoutActionCreator, MessageActionCreator, MessageContent, MessageFlags, MessageFooter, MessageHeader, MessageUtils, Participants, RouterMixin, ToolbarMessage, TooltipRefresherMixin, a, alertError, alertSuccess, article, button, classer, div, footer, h4, header, i, iframe, img, li, p, pre, span, ul, _ref, _ref1;

_ref = React.DOM, div = _ref.div, article = _ref.article, header = _ref.header, footer = _ref.footer, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, a = _ref.a, button = _ref.button, pre = _ref.pre, iframe = _ref.iframe, img = _ref.img, h4 = _ref.h4;

MessageUtils = require('../utils/message_utils');

MessageHeader = require("./message_header");

MessageFooter = require("./message_footer");

ToolbarMessage = require('./toolbar_message');

Compose = require('./compose');

Participants = require('./participant');

_ref1 = require('../constants/app_constants'), ComposeActions = _ref1.ComposeActions, MessageFlags = _ref1.MessageFlags, FlagsConstants = _ref1.FlagsConstants;

LayoutActionCreator = require('../actions/layout_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

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
    settings: React.PropTypes.object.isRequired
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
    if ((text == null) && (html == null) && (alternatives != null ? alternatives.length : void 0) > 0) {
      text = t('calendar unknown format');
    }
    if ((text != null) && (html == null) && this.state.messageDisplayHTML) {
      try {
        html = markdown.toHTML(text.replace(/(^>.*$)([^>]+)/gm, "$1\n$2"));
      } catch (_error) {
        e = _error;
        html = "<div class='text'>" + text + "</div>";
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
    return this._markRead(this.props.message);
  },
  componentWillReceiveProps: function(props) {
    var state;
    state = {
      active: props.active
    };
    if (props.message.get('id') !== this.props.message.get('id')) {
      this._markRead(props.message);
      state.messageDisplayHTML = props.settings.get('messageDisplayHTML');
      state.messageDisplayImages = props.settings.get('messageDisplayImages');
      state.composing = this._shouldOpenCompose(props);
    }
    return this.setState(state);
  },
  _markRead: function(message) {
    var flags, messageID, state;
    messageID = message.get('id');
    if (this.state.currentMessageID !== messageID) {
      state = {
        currentMessageID: messageID,
        prepared: this._prepareMessage(message)
      };
      flags = message.get('flags').slice();
      if (flags.indexOf(MessageFlags.SEEN) === -1) {
        flags.push(MessageFlags.SEEN);
        MessageActionCreator.updateFlag(message, flags);
      }
      return this.setState(state);
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
    var classes, images, imagesWarning, message, messageDisplayHTML, prepared, _ref2, _ref3;
    message = this.props.message;
    prepared = this.state.prepared;
    if (this.state.messageDisplayHTML && (prepared.html != null)) {
      _ref2 = this.prepareHTML(prepared.html), messageDisplayHTML = _ref2.messageDisplayHTML, images = _ref2.images;
      imagesWarning = images.length > 0 && !this.state.messageDisplayImages;
    } else {
      messageDisplayHTML = false;
      imagesWarning = false;
    }
    classes = classer({
      message: true,
      active: this.state.active,
      isDraft: prepared.isDraft,
      isDeleted: prepared.isDeleted
    });
    return article({
      className: classes,
      key: this.props.key,
      'data-id': message.get('id')
    }, header({
      onClick: (function(_this) {
        return function() {
          return _this.setState({
            active: !_this.state.active
          });
        };
      })(this)
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
      onMove: this.onMove,
      onHeaders: this.onHeaders,
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
  displayNextMessage: function() {
    var nextConversationID, nextMessageID;
    if (this.props.nextMessageID != null) {
      nextMessageID = this.props.nextMessageID;
      nextConversationID = this.props.nextConversationID;
    } else {
      nextMessageID = this.props.prevMessageID;
      nextConversationID = this.props.prevConversationID;
    }
    if (nextMessageID) {
      if (this.props.displayConversations && (nextConversationID != null)) {
        return this.redirect({
          direction: 'second',
          action: 'conversation',
          parameters: {
            messageID: nextMessageID,
            conversationID: nextConversationID
          }
        });
      } else {
        return this.redirect({
          direction: 'second',
          action: 'message',
          parameters: {
            messageID: nextMessageID
          }
        });
      }
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
    var message;
    message = this.props.message;
    if ((!this.props.settings.get('messageConfirmDelete')) || window.confirm(t('mail confirm delete', {
      subject: message.get('subject')
    }))) {
      this.displayNextMessage();
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
    var newbox, oldbox, subject;
    newbox = args.target.dataset.value;
    oldbox = this.props.selectedMailboxID;
    subject = this.props.message.get('subject');
    if (args.target.dataset.conversation != null) {
      return ConversationActionCreator.move(this.props.message, oldbox, newbox, (function(_this) {
        return function(error) {
          if (error != null) {
            return alertError("" + (t("conversation move ko", {
              subject: subject
            })) + " " + error);
          } else {
            alertSuccess(t("conversation move ok", {
              subject: subject
            }));
            return _this.displayNextMessage();
          }
        };
      })(this));
    } else {
      return MessageActionCreator.move(this.props.message, oldbox, newbox, (function(_this) {
        return function(error) {
          if (error != null) {
            return alertError("" + (t("message action move ko", {
              subject: subject
            })) + " " + error);
          } else {
            alertSuccess(t("message action move ok", {
              subject: subject
            }));
            return _this.displayNextMessage();
          }
        };
      })(this));
    }
  },
  onHeaders: function(event) {
    var messageID;
    event.preventDefault();
    messageID = event.target.dataset.messageId;
    return document.querySelector(".conversation [data-id='" + messageID + "']").classList.toggle('with-headers');
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
var AttachmentPreview, MessageUtils, a, div, i, img, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, span = _ref.span, ul = _ref.ul, li = _ref.li, img = _ref.img, a = _ref.a, i = _ref.i;

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
var AttachmentPreview, ContactLabel, MessageFlags, ParticipantMixin, PopupMessageDetails, Tooltips, a, div, i, img, li, messageUtils, span, table, tbody, td, tr, ul, _ref, _ref1,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __slice = [].slice;

_ref = React.DOM, div = _ref.div, span = _ref.span, ul = _ref.ul, li = _ref.li, table = _ref.table, tbody = _ref.tbody, tr = _ref.tr, td = _ref.td, img = _ref.img, a = _ref.a, i = _ref.i;

AttachmentPreview = require('./attachement_preview');

PopupMessageDetails = require('./popup_message_details');

ParticipantMixin = require('../mixins/participant_mixin');

ContactLabel = require('./contact_label');

messageUtils = require('../utils/message_utils');

_ref1 = require('../constants/app_constants'), MessageFlags = _ref1.MessageFlags, Tooltips = _ref1.Tooltips;

module.exports = React.createClass({
  displayName: 'MessageHeader',
  mixins: [ParticipantMixin],
  propTypes: {
    message: React.PropTypes.object.isRequired,
    isDraft: React.PropTypes.bool,
    isDeleted: React.PropTypes.bool
  },
  getInitialState: function() {
    return {
      showDetails: false,
      showAttachements: false
    };
  },
  render: function() {
    var avatar, _ref2;
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
      className: 'indicators'
    }, this.props.message.get('attachments').length ? this.renderAttachementsIndicator() : void 0, (_ref2 = MessageFlags.FLAGGED, __indexOf.call(this.props.message.get('flags'), _ref2) >= 0) ? i({
      className: 'fa fa-star'
    }) : void 0, this.props.isDraft ? i({
      className: 'fa fa-edit'
    }) : void 0, this.props.isDeleted ? i({
      className: 'fa fa-trash'
    }) : void 0), div({
      className: 'date'
    }, messageUtils.formatDate(this.props.message.get('createdAt'))), this.renderDetailsPopup()));
  },
  renderAddress: function(field) {
    var users;
    users = this.props.message.get(field);
    if (!users.length) {
      return;
    }
    return div.apply(null, [{
      className: "addresses " + field,
      key: "address-" + field
    }, field !== 'from' ? span(null, t("mail " + field)) : void 0].concat(__slice.call(this.formatUsers(users))));
  },
  renderAttachementsIndicator: function() {
    var attachments, file, _ref2;
    attachments = ((_ref2 = this.props.message.get('attachments')) != null ? _ref2.toJS() : void 0) || [];
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
  },
  renderDetailsPopup: function() {
    var cc, dest, from, key, reply, row, to, _ref2;
    from = this.props.message.get('from')[0];
    to = this.props.message.get('to');
    cc = this.props.message.get('cc');
    reply = (_ref2 = this.props.message.get('reply-to')) != null ? _ref2[0] : void 0;
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
      className: 'details',
      'aria-expanded': this.state.showDetails,
      onClick: function(event) {
        return event.stopPropagation();
      }
    }, i({
      className: 'btn fa fa-caret-down',
      onClick: this.toggleDetails
    }), div({
      className: 'popup',
      'aria-hidden': !this.state.showDetails
    }, table(null, tbody(null, row('from', this.formatUsers(from), 'headers from'), to.length ? row('to', this.formatUsers(to[0]), 'headers to', to.length) : void 0, (function() {
      var _i, _len, _ref3, _results;
      if (to.length) {
        _ref3 = to.slice(1);
        _results = [];
        for (key = _i = 0, _len = _ref3.length; _i < _len; key = ++_i) {
          dest = _ref3[key];
          _results.push(row("destTo" + key, this.formatUsers(dest)));
        }
        return _results;
      }
    }).call(this), cc.length ? row('cc', this.formatUsers(cc[0]), 'headers cc', cc.length) : void 0, (function() {
      var _i, _len, _ref3, _results;
      if (cc.length) {
        _ref3 = cc.slice(1);
        _results = [];
        for (key = _i = 0, _len = _ref3.length; _i < _len; key = ++_i) {
          dest = _ref3[key];
          _results.push(row("destCc" + key, this.formatUsers(dest)));
        }
        return _results;
      }
    }).call(this), reply != null ? row('reply', this.formatUsers(reply), 'headers reply-to') : void 0, row('created', this.props.message.get('createdAt'), 'headers date'), row('subject', this.props.message.get('subject'), 'headers subject')))));
  },
  toggleDetails: function() {
    return this.setState({
      showDetails: !this.state.showDetails
    });
  },
  toggleAttachments: function() {
    return this.setState({
      showAttachements: !this.state.showAttachements
    });
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
      className: 'details',
      'aria-expanded': this.state.showDetails,
      onClick: function(event) {
        return event.stopPropagation();
      }
    }, i({
      className: 'btn fa fa-caret-down',
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
var LayoutActionCreator, RouterMixin, Tooltips, a, button, cBtn, div, nav, _ref;

_ref = React.DOM, nav = _ref.nav, div = _ref.div, button = _ref.button, a = _ref.a;

LayoutActionCreator = require('../actions/layout_action_creator');

Tooltips = require('../constants/app_constants').Tooltips;

RouterMixin = require('../mixins/router_mixin');

cBtn = 'btn btn-default fa';

module.exports = React.createClass({
  displayName: 'ToolbarConversation',
  mixins: [RouterMixin],
  propTypes: {
    readability: React.PropTypes.bool.isRequired,
    nextMessageID: React.PropTypes.string,
    nextConversationID: React.PropTypes.string,
    prevMessageID: React.PropTypes.string,
    prevConversationID: React.PropTypes.string,
    settings: React.PropTypes.object.isRequired
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
      className: "btn btn-default fa fa-angle-" + angle,
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
    if (this.props.readability) {
      return button({
        onClick: LayoutActionCreator.toggleFullscreen,
        className: "clickable " + cBtn + " fa-compress"
      });
    } else {
      return button({
        onClick: LayoutActionCreator.toggleFullscreen,
        className: "hidden-xs hidden-sm clickable " + cBtn + " fa-expand"
      });
    }
  }
});
});

;require.register("components/toolbar_message", function(exports, require, module) {
var ConversationActionCreator, FlagsConstants, LayoutActionCreator, MessageActionCreator, MessageFlags, ToolboxActions, ToolboxMove, Tooltips, a, alertError, alertSuccess, button, cBtn, cBtnGroup, div, nav, _ref, _ref1,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ref = React.DOM, nav = _ref.nav, div = _ref.div, button = _ref.button, a = _ref.a;

_ref1 = require('../constants/app_constants'), MessageFlags = _ref1.MessageFlags, FlagsConstants = _ref1.FlagsConstants, Tooltips = _ref1.Tooltips;

ToolboxActions = require('./toolbox_actions');

ToolboxMove = require('./toolbox_move');

LayoutActionCreator = require('../actions/layout_action_creator');

ConversationActionCreator = require('../actions/conversation_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

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
      mailboxID: this.props.selectedMailboxID,
      messageID: this.props.message.get('id'),
      message: this.props.message,
      onMark: this.onMark,
      onConversation: this.onConversation,
      onMove: this.props.onMove,
      onHeaders: this.props.onHeaders,
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
      case 'flagged':
        return ConversationActionCreator.flag(id, function(error) {
          if (error != null) {
            return alertError("" + (t("conversation flagged ko ")) + " " + error);
          }
        });
      case 'noflag':
        return ConversationActionCreator.noflag(id, function(error) {
          if (error != null) {
            return alertError("" + (t("conversation noflag ko")) + " " + error);
          }
        });
    }
  }
});
});

;require.register("components/toolbox_actions", function(exports, require, module) {
var FlagsConstants, ToolboxActions, a, button, div, li, span, ul, _ref,
  __slice = [].slice;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, a = _ref.a, button = _ref.button;

FlagsConstants = require('../constants/app_constants').FlagsConstants;

module.exports = ToolboxActions = React.createClass({
  displayName: 'ToolboxActions',
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
    }, !this.props.displayConversations ? this.renderMarkActions() : void 0, !this.props.displayConversations ? li({
      role: 'presentation',
      className: 'divider'
    }) : void 0].concat(__slice.call(this.renderRawActions()), [li({
      role: 'presentation',
      className: 'divider'
    })], [li({
      role: 'presentation',
      className: 'dropdown-header'
    }, t('mail action conversation move'))], [this.renderMailboxes()])));
  },
  renderMarkActions: function() {
    var buildMenuItem, items;
    items = [];
    items.push(li({
      role: 'presentation',
      className: 'dropdown-header'
    }, t('mail action mark')));
    buildMenuItem = (function(_this) {
      return function(args) {
        return li({
          role: 'presentation'
        }, a({
          role: 'menuitemu',
          onClick: _this.props.onMark,
          'data-value': args.value
        }, args.label));
      };
    })(this);
    if ((this.props.isSeen == null) || !this.props.isSeen) {
      items.push(buildMenuItem({
        value: FlagsConstants.SEEN,
        label: t('mail mark read')
      }));
    }
    if ((this.props.isSeen == null) || this.props.isSeen) {
      items.push(buildMenuItem({
        value: FlagsConstants.UNSEEN,
        label: t('mail mark unread')
      }));
    }
    if ((this.props.isFlagged == null) || this.props.isFlagged) {
      items.push(buildMenuItem({
        value: FlagsConstants.NOFLAG,
        label: t('mail mark nofav')
      }));
    }
    if ((this.props.isFlagged == null) || !this.props.isFlagged) {
      items.push(buildMenuItem({
        value: FlagsConstants.FLAGGED,
        label: t('mail mark fav')
      }));
    }
    return items;
  },
  renderRawActions: function() {
    var items;
    items = [];
    if (!this.props.displayConversations) {
      items.push(li({
        role: 'presentation',
        className: 'dropdown-header'
      }, t('mail action more')));
    }
    if (this.props.messageID != null) {
      items.push(li({
        role: 'presentation'
      }, a({
        onClick: this.props.onHeaders,
        'data-message-id': this.props.messageID
      }, t('mail action headers'))));
    }
    if (this.props.message != null) {
      items.push(li({
        role: 'presentation'
      }, a({
        href: "raw/" + (this.props.message.get('id')),
        target: '_blank'
      }, t('mail action raw'))));
    }
    items.push(li({
      role: 'presentation'
    }, a({
      onClick: this.props.onConversation,
      'data-action': 'delete'
    }, t('mail action conversation delete'))));
    items.push(li({
      role: 'presentation'
    }, a({
      onClick: this.props.onConversation,
      'data-action': 'seen'
    }, t('mail action conversation seen'))));
    items.push(li({
      role: 'presentation'
    }, a({
      onClick: this.props.onConversation,
      'data-action': 'unseen'
    }, t('mail action conversation unseen'))));
    items.push(li({
      role: 'presentation'
    }, a({
      onClick: this.props.onConversation,
      'data-action': 'flagged'
    }, t('mail action conversation flagged'))));
    items.push(li({
      role: 'presentation'
    }, a({
      onClick: this.props.onConversation,
      'data-action': 'noflag'
    }, t('mail action conversation noflag'))));
    return items;
  },
  renderMailboxes: function() {
    var id, mbox, _ref1, _results;
    _ref1 = this.props.mailboxes;
    _results = [];
    for (id in _ref1) {
      mbox = _ref1[id];
      if (id !== this.props.selectedMailboxID) {
        _results.push(this.renderMailbox(mbox, id));
      }
    }
    return _results;
  },
  renderMailbox: function(mbox, id) {
    return li({
      role: 'presentation',
      key: id
    }, a({
      className: "pusher pusher-" + mbox.depth,
      role: 'menuitem',
      onClick: this.props.onMove,
      'data-value': id
    }, mbox.label));
  }
});
});

;require.register("components/toolbox_move", function(exports, require, module) {
var ToolboxMove, a, button, div, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, a = _ref.a, button = _ref.button;

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
    }, li({
      role: 'presentation',
      className: 'dropdown-header'
    }, t('mail action move')), this.renderMailboxes()));
  },
  renderMailboxes: function() {
    var id, mbox, _ref1, _results;
    _ref1 = this.props.mailboxes;
    _results = [];
    for (id in _ref1) {
      mbox = _ref1[id];
      if (id !== this.props.selectedMailboxID) {
        _results.push(this.renderMailbox(mbox, id));
      }
    }
    return _results;
  },
  renderMailbox: function(mbox, id) {
    return li({
      role: 'presentation',
      key: id
    }, a({
      className: "pusher pusher-" + mbox.depth,
      role: 'menuitem',
      onClick: this.props.onMove,
      'data-value': id
    }, mbox.label));
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
    return div(null, this.getTooltip(Tooltips.REPLY, t('tooltip reply')), this.getTooltip(Tooltips.REPLY_ALL, t('tooltip reply all')), this.getTooltip(Tooltips.FORWARD, t('tooltip forward')), this.getTooltip(Tooltips.REMOVE_MESSAGE, t('tooltip remove message')), this.getTooltip(Tooltips.OPEN_ATTACHMENTS, t('tooltip open attachments')), this.getTooltip(Tooltips.OPEN_ATTACHMENT, t('tooltip open attachment')), this.getTooltip(Tooltips.DOWNLOAD_ATTACHMENT, t('tooltip download attachment')), this.getTooltip(Tooltips.PREVIOUS_CONVERSATION, t('tooltip previous conversation')), this.getTooltip(Tooltips.NEXT_CONVERSATION, t('tooltip next conversation')), this.getTooltip(Tooltips.FILTER_ONLY_UNREAD, t('tooltip filter only unread')), this.getTooltip(Tooltips.FILTER_ONLY_IMPORTANT, t('tooltip filter only important')), this.getTooltip(Tooltips.FILTER_ONLY_WITH_ATTACHMENT, t('tooltip filter only attachment')), this.getTooltip(Tooltips.TRIGGER_REFRESH, t('tooltip trigger refresh')), this.getTooltip(Tooltips.ACCOUNT_PARAMETERS, t('tooltip account parameters')), this.getTooltip(Tooltips.DELETE_SELECTION, t('tooltip delete selection')));
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
    'MESSAGE_ACTION': 'MESSAGE_ACTION',
    'CONVERSATION_ACTION': 'CONVERSATION_ACTION',
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
    'RECEIVE_REFRESH_NOTIF': 'RECEIVE_REFRESH_NOTIF',
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
    TRIGGER_REFRESH: 'TOOLTIP_TRIGGER_REFRESH',
    ACCOUNT_PARAMETERS: 'TOOLTIP_ACCOUNT_PARAMETERS',
    DELETE_SELECTION: 'TOOLTIP_DELETE_SELECTION'
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
  var AccountStore, Application, ContactStore, LayoutActionCreator, LayoutStore, MessageStore, PluginUtils, Router, SearchStore, SettingsStore, application, data, e, exception, locale, referencePoint, xhr;
  try {
    window.__DEV__ = window.location.hostname === 'localhost';
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
    window.printExclusive = function() {
      stop();
      return React.addons.Perf.printExclusive();
    };
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
      return Notification.requestPermission(function(status) {
        if (Notification.permission !== status) {
          return Notification.permission = status;
        }
      });
    }
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
  "compose draft deleted": "Entwurf gelöscht",
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
  "message action delete ok": "Nachricht “%{subject}” gelöscht",
  "message action delete ko": "Fehler bei Nachricht löschen: ",
  "message action move ok": "Nachricht “%{subject}” wurde verschoben",
  "message action move ko": "Fehler beim verschieben von Nachricht “%{subject}”: ",
  "message action mark ok": "Nachricht markiert",
  "message action mark ko": "Fehler beim Nachricht markieren: ",
  "conversation move ok": "Unterhaltung “%{subject}” wurde verschoben",
  "conversation move ko": "Fehler beim verschieben der Unterhaltung “%{subject}”",
  "conversation delete ok": "Unterhaltung “%{subject}” wurde gelöscht",
  "conversation delete ko": "Fehler beim löschen der Unterhaltung",
  "conversation seen ok": "Unterhaltung markiert als gelesen",
  "conversation seen ko": "Fehler beim gelesen markieren",
  "conversation unseen ok": "Conversation marked as unread",
  "conversation unseen ko": "Fehler beim ungelesen markieren",
  "conversation undelete": "Rückgänig Unterhaltung löschen",
  "message images warning": "Anzeige von Bildern innerhalb der Nachricht wurde geblockt",
  "message images display": "Bilder anzeigen",
  "message html display": "HTML anzeigen",
  "message delete no trash": "Bitte wählen Sie einen Ordner als Papierkorb",
  "message delete already": "Nachricht bereits im Papierkorb",
  "message move already": "Nachricht bereits in diesem Ordner",
  "message undelete": "Rückgängig Nachrichten löschen",
  "message undelete ok": "Nachrichten wieder hergestellt",
  "message undelete error": "Fehler beim Nachrichten Wiederherstellen",
  "message undelete unavalable": "Rückgängig Nachrichten löschen nicht möglich",
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
  "tooltip trigger refresh": "Refresh",
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
  "compose draft deleted": "Draft deleted",
  "compose wrong email format": "The given email is unproperly formatted: %{address}.",
  "compose forward header": "Forwarded message",
  "compose forward subject": "Subject:",
  "compose forward date": "Date:",
  "compose forward from": "From:",
  "compose forward to": "To:",
  "menu show": "Show menu",
  "menu compose": "Compose",
  "menu account new": "New Mailbox",
  "menu settings": "Parameters",
  "menu mailbox total": "%{smart_count} message|||| %{smart_count} messages",
  "menu mailbox unread": ", %{smart_count} unread message ||||, %{smart_count} unread messages ",
  "menu mailbox new": " and %{smart_count} new message|||| and %{smart_count} new messages ",
  "menu favorites on": "Favorites",
  "menu favorites off": "All",
  "menu toggle": "Toggle Menu",
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
  "account imapLogin": "IMAP user (if different from login)",
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
  "account smtpLogin": "SMTP user (if different from main login)",
  "account smtpMethod": "Authentification method",
  "account smtpMethod NONE": "None",
  "account smtpMethod PLAIN": "Plain",
  "account smtpMethod LOGIN": "Login",
  "account smtpMethod CRAM-MD5": "Cram-MD5",
  "account smtpPassword short": "SMTP password",
  "account smtpPassword": "SMTP password (if different from main password)",
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
  "config error imapPort": "Wrong IMAP port",
  "config error imapServer": "Wrong IMAP server",
  "config error imapTLS": "Wrong IMAP TLS",
  "config error smtpPort": "Wrong SMTP Port",
  "config error smtpServer": "Wrong SMTP Server",
  "config error nomailboxes": "No folder in this account, please create one",
  "action undo": "Undo",
  "action undo ok": "Action cancelled",
  "action undo ko": "Unable to undo action",
  "message contact creation": "Do you want to create a contact for %{contact}?",
  "message action sent ok": "Message sent",
  "message action sent ko": "Error sending message: ",
  "message action draft ok": "Message saved",
  "message action draft ko": "Error saving message: ",
  "message action delete ok": "Message “%{subject}” deleted",
  "message action delete ko": "Error deleting message: ",
  "message action move ok": "Message “%{subject}” moved",
  "message action move ko": "Error moving message “%{subject}”: ",
  "message action mark ok": "Message marked",
  "message action mark ko": "Error marking message: ",
  "conversation move ok": "Conversation “%{subject}” moved",
  "conversation move ko": "Error moving conversation “%{subject}”",
  "conversation delete ok": "Conversation “%{subject}” deleted",
  "conversation delete ko": "Error deleting conversation",
  "conversation seen ok": "Conversation marked as read",
  "conversation seen ko": "Error",
  "conversation unseen ok": "Conversation marked as unread",
  "conversation unseen ko": "Error",
  "conversation undelete": "Undo conversation deletion",
  "conversation flagged ko": "Error",
  "conversation noflag ko": "Error",
  "message images warning": "Display of images inside message has been blocked",
  "message images display": "Display images",
  "message html display": "Display HTML",
  "message delete no trash": "Please select a Trash folder",
  "message delete already": "Message already in trash folder",
  "message move already": "Message already in this folder",
  "message undelete": "Undo message deletion",
  "message undelete ok": "Message undeleted",
  "message undelete error": "Error undoing some action",
  "message undelete unavailable": "Undo not available",
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
  "tooltip trigger refresh": "Refresh",
  "tooltip account parameters": "Account parameters",
  "tooltip delete selection": "Delete all selected messages"
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
  "compose draft deleted": "Brouillon supprimé",
  "compose wrong email format": "L'addresse mail donnée n'est pas bien formattée : %{address}.",
  "compose forward header": "Message transféré",
  "compose forward subject": "Sujet :",
  "compose forward date": "Date :",
  "compose forward from": "De :",
  "compose forward to": "Pour :",
  "menu show": "Montrer le menu",
  "menu compose": "Nouveau",
  "menu account new": "Ajouter un compte",
  "menu settings": "Paramètres",
  "menu mailbox total": "%{smart_count} message |||| %{smart_count} messages ",
  "menu mailbox unread": " dont %{smart_count} non lu |||| dont %{smart_count} non lus ",
  "menu mailbox new": " et %{smart_count} nouveaux |||| et %{smart_count} nouveaux ",
  "menu favorites on": "Favorites",
  "menu favorites off": "Toutes",
  "menu toggle": "Menu",
  "list empty": "Pas d'email dans cette boîte..",
  "no flagged message": "Pas d'email important dans cette boîte.",
  "no unseen message": "Pas d'email non-lu dans cette boîte.",
  "no attach message": "Pas d'email avec des pièces-jointes.",
  "no filter message": "Pas d'email pour ce filtre.",
  "list fetching": "Chargement…",
  "list search empty": "Aucun résultat trouvé pour la requête \"%{query}\".",
  "list count": "%{smart_count} message dans cette boite |||| %{smart_count} messages dans cette boite",
  "list search count": "%{smart_count} résultat trouvé. |||| %{smart_count} résultats trouvés.",
  "list filter": "Filtrer",
  "list filter all": "Tous",
  "list filter unseen": "Non lus",
  "list filter flagged": "Importants",
  "list filter attach": "Pièces-jointes",
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
  "account imapLogin": "Utilisateur IMAP (s'il est différent du login)",
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
  "account smtpLogin": "Utilisateur SMTP (s'il est différent)",
  "account smtpMethod": "Méthode d'authentification",
  "account smtpMethod NONE": "Aucune",
  "account smtpMethod PLAIN": "Plain",
  "account smtpMethod LOGIN": "Login",
  "account smtpMethod CRAM-MD5": "Cram-MD5",
  "account smtpPassword short": "Mot de passe SMTP",
  "account smtpPassword": "Mot de passe SMTP (s'il est différent)",
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
  "config error imapPort": "Port du serveur IMAP invalide",
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
  "message action delete ok": "Message « %{subject} » supprimé",
  "message action delete ko": "Impossible de supprimer le message : ",
  "message action move ok": "Message « %{subject} » déplacé",
  "message action move ko": "Le déplacement de « %{subject} » a échoué",
  "message action mark ok": "Le message a été mis à jour",
  "message action mark ko": "L'opération a échoué",
  "conversation move ok": "Conversation « %{subject} » déplacée",
  "conversation move ko": "Le déplacement de « %{subject} » a échoué",
  "conversation delete ok": "Conversation « %{subject} » supprimée",
  "conversation delete ko": "L'opération a échoué",
  "conversation seen ok": "Ok",
  "conversation seen ko": "L'opération a échoué",
  "conversation unseen ok": "Ok",
  "conversation unseen ko": "L'opération a échoué",
  "conversation undelete": "Annuler la suppression",
  "conversation flagged ko": "L'opération a échoué",
  "conversation noflag ko": "L'opération a échoué",
  "message images warning": "L'affichage des images du message a été bloqué",
  "message images display": "Afficher les images",
  "message html display": "Afficher en HTML",
  "message delete no trash": "Choisissez d'abord un dossier Corbeille",
  "message delete already": "Ce message est déjà dans la corbeille",
  "message move already": "Ce message est déjà dans ce dossier",
  "message undelete": "Annuler la suppression",
  "message undelete ok": "Message restauré",
  "message undelete error": "Impossible d'annuler l'action",
  "message undelete unavailable": "Impossible d'annuler l'action",
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
  "tooltip trigger refresh": "Rafraîchir",
  "tooltip account parameters": "Paramètres du compte",
  "tooltip delete selection": "Supprimer les messages sélectionnés"
};
});

;require.register("mixins/participant_mixin", function(exports, require, module) {

/*
    Participant mixin.
 */
var ContactStore, a, i, span, _ref;

_ref = React.DOM, span = _ref.span, a = _ref.a, i = _ref.i;

ContactStore = require('../stores/contact_store');

module.exports = {
  formatUsers: function(users) {
    var contact, format, items, user, _i, _len;
    if (users == null) {
      return;
    }
    format = function(user) {
      var items, key;
      items = [];
      if (user.name) {
        key = user.address.replace(/\W/g, '');
        items.push("" + user.name + " ");
        items.push(span({
          className: 'contact-address',
          key: key
        }, i({
          className: 'fa fa-angle-left'
        }), user.address, i({
          className: 'fa fa-angle-right'
        })));
      } else {
        items.push(user.address);
      }
      return items;
    };
    if (_.isArray(users)) {
      items = [];
      for (_i = 0, _len = users.length; _i < _len; _i++) {
        user = users[_i];
        contact = ContactStore.getByAddress(user.address);
        items.push(contact != null ? a({
          target: '_blank',
          href: "/#apps/contacts/contact/" + (contact.get('id')),
          onClick: function(event) {
            return event.stopPropagation();
          }
        }, format(user)) : span({
          className: 'participant',
          onClick: function(event) {
            return event.stopPropagation();
          }
        }, format(user)));
        if (user !== _.last(users)) {
          items.push(", ");
        }
      }
      return items;
    } else {
      return format(users);
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
        defaultParameters.sort = '-';
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
      if (disposition.disposition != null) {
        _disposition = disposition.disposition;
      } else {
        _disposition.type = disposition.type;
        if (_disposition.type === Dispositions.VERTICAL) {
          if (disposition.value == null) {
            disposition.value = _disposition.width;
          }
          _disposition.height = 5;
          _disposition.width = disposition.value;
        } else if (_disposition.type === Dispositions.HORIZONTAL) {
          if (disposition.value == null) {
            disposition.value = _disposition.height;
          }
          _disposition.height = disposition.value;
          _disposition.width = 6;
        } else if (_disposition.type === Dispositions.THREE) {
          if (disposition.value == null) {
            disposition.value = _disposition.width;
          }
          _disposition.height = 5;
          _disposition.width = disposition.value;
        }
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
      if (messages.links != null) {
        if (messages.links.next != null) {
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
      action.target = 'message';
      return _prevAction = action;
    });
    handle(ActionTypes.CONVERSATION_ACTION, function(action) {
      action.target = 'conversation';
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
    var convID, idx, keys, prev, _ref1;
    if ((isConv != null) && isConv) {
      if (_conversationMemoize == null) {
        return null;
      }
      idx = _conversationMemoize.findIndex(function(message) {
        return _currentID === message.get('id');
      });
      if (idx === _conversationMemoize.length - 1) {
        keys = Object.keys(_currentMessages.toJS());
        idx = keys.indexOf(_conversationMemoize.last().get('id'));
        if (idx < 1) {
          return null;
        } else {
          convID = (_ref1 = _currentMessages.get(keys[idx - 1])) != null ? _ref1.get('conversationID') : void 0;
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
      if (idx === 0) {
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

  MessageStore.prototype.getConversation = function(conversationID) {
    _conversationMemoize = _messages.filter(function(message) {
      return message.get('conversationID') === conversationID;
    }).sort(reverseDateSort).toVector();
    _conversationMemoizeID = conversationID;
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
var AccountStore, LayoutActionCreator, MessageActionCreator, MessageStore, MessageUtils, SettingsStore, onMessageList,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __hasProp = {}.hasOwnProperty;

MessageUtils = require('./message_utils');

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
      message = MessageStore.getById(MessageStore.getCurrentID());
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
      return MessageUtils["delete"](messageID, conversation);
    }
  },
  messageUndo: function() {
    return MessageActionCreator.undelete();
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
  }
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
    return rect.bottom <= (height + 0) && rect.top >= 0;
  }
};
});

;require.register("utils/message_utils", function(exports, require, module) {
var COMPOSE_STYLE, ComposeActions, ContactStore, ConversationActionCreator, LayoutActionCreator, MessageActionCreator, MessageStore, MessageUtils, QUOTE_STYLE;

ComposeActions = require('../constants/app_constants').ComposeActions;

ContactStore = require('../stores/contact_store');

MessageStore = require('../stores/message_store');

ConversationActionCreator = require('../actions/conversation_action_creator');

MessageActionCreator = require('../actions/message_action_creator');

LayoutActionCreator = require('../actions/layout_action_creator');

QUOTE_STYLE = "margin-left: 0.8ex; padding-left: 1ex; border-left: 3px solid #34A6FF;";

COMPOSE_STYLE = "<style>\np {margin: 0;}\npre {background: transparent; border: 0}^8\n</style>";

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
  makeReplyMessage: function(myAddress, inReplyTo, action, inHTML) {
    var dateHuman, e, html, message, notMe, options, sender, text;
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
    options = {
      message: message,
      inReplyTo: inReplyTo,
      dateHuman: dateHuman,
      sender: sender,
      text: text,
      html: html
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
        this.setMessgeAsDefault(message);
    }
    notMe = function(dest) {
      return dest.address !== myAddress;
    };
    message.to = message.to.filter(notMe);
    message.cc = message.cc.filter(notMe);
    return message;
  },
  setMessageAsReply: function(options) {
    var dateHuman, html, inReplyTo, message, params, sender, separator, text;
    message = options.message, inReplyTo = options.inReplyTo, dateHuman = options.dateHuman, sender = options.sender, text = options.text, html = options.html;
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
    return message.html = "" + COMPOSE_STYLE + "\n<p>" + separator + "<span class=\"originalToggle\"> … </span></p>\n<blockquote style=\"" + QUOTE_STYLE + "\">" + html + "</blockquote>\n<p><br /></p>";
  },
  setMessageAsReplyAll: function(options) {
    var dateHuman, html, inReplyTo, message, params, sender, separator, text, toAddresses;
    message = options.message, inReplyTo = options.inReplyTo, dateHuman = options.dateHuman, sender = options.sender, text = options.text, html = options.html;
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
    return message.html = "" + COMPOSE_STYLE + "\n<p>" + separator + "<span class=\"originalToggle\"> … </span></p>\n<blockquote style=\"" + QUOTE_STYLE + "\">" + html + "</blockquote>\n<p><br /></p>";
  },
  setMessageAsForward: function(options) {
    var addresses, dateHuman, fromField, html, htmlSeparator, inReplyTo, message, sender, senderAddress, senderInfos, senderName, separator, text, textSeparator;
    message = options.message, inReplyTo = options.inReplyTo, dateHuman = options.dateHuman, sender = options.sender, text = options.text, html = options.html;
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
    htmlSeparator = separator.replace(/(\n)+/g, '<br />');
    this.setMessageAsDefault(message);
    message.subject = "" + (t('compose forward prefix')) + (inReplyTo.get('subject'));
    message.text = textSeparator + text;
    message.html = "" + COMPOSE_STYLE + "\n\n<p>" + htmlSeparator + "</p><p><br /></p>" + html;
    message.attachments = inReplyTo.get('attachments');
    return message;
  },
  setMessageAsDefault: function(message) {
    message.to = [];
    message.cc = [];
    message.bcc = [];
    message.subject = '';
    message.text = '';
    message.html = '';
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
      result = toMarkdown(html);
    } catch (_error) {
      if (html != null) {
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
  },
  "delete": function(ids, conversation, cb) {
    return this.action('delete', ids, conversation, null, cb);
  },
  move: function(ids, conversation, from, to, cb) {
    var options;
    options = {
      from: from,
      to: to
    };
    return this.action('move', ids, conversation, options, cb);
  },
  action: function(action, ids, conversation, options, cb) {
    var handleConversation, handleMessage, mass, next, onDone, selected;
    if (Array.isArray(ids)) {
      mass = ids.length;
      selected = ids;
    } else {
      mass = 1;
      selected = [ids];
    }
    if (selected.length > 1) {
      window.cozyMails.messageClose();
    } else {
      next = MessageStore.getNextMessage(conversation);
    }
    onDone = _.after(selected.length, function() {
      if (typeof cb === 'function') {
        return cb();
      }
    });
    handleMessage = function(id) {
      var from, to;
      switch (action) {
        case 'move':
          from = options.from, to = options.to;
          return MessageActionCreator.move(id, from, to, function(error) {
            var msg;
            if (error != null) {
              msg = "" + (t("message action move ko")) + " " + error;
              LayoutActionCreator.alertError(msg);
            }
            return onDone();
          });
        case 'delete':
          return MessageActionCreator["delete"](id, function(error) {
            var msg;
            if (error != null) {
              msg = "" + (t("message action delete ko")) + " : " + error;
              LayoutActionCreator.alertError(msg);
            }
            return onDone();
          });
      }
    };
    handleConversation = function(message) {
      var conversationID, from, messageID, params, to;
      messageID = message.get('id');
      conversationID = message.get('conversationID');
      if (conversationID != null) {
        params = {
          subject: message.get('subject')
        };
        switch (action) {
          case 'move':
            from = options.from, to = options.to;
            return ConversationActionCreator.move(message, from, to, function(error) {
              var msg;
              if (error != null) {
                msg = "" + (t("message action move ko", params)) + " " + error;
                LayoutActionCreator.alertError(msg);
              }
              return onDone();
            });
          case 'delete':
            return ConversationActionCreator["delete"](conversationID, function(error) {
              var msg;
              if (error != null) {
                msg = "" + (t("conversation delete ko", params)) + " : " + error;
                LayoutActionCreator.alertError(msg);
              }
              return onDone();
            });
        }
      } else {
        return handleMessage(messageID);
      }
    };
    selected.forEach(function(id) {
      var message;
      if (conversation) {
        if (typeof id === 'string') {
          message = MessageStore.getByID(id);
        } else {
          message = id;
        }
        return handleConversation(message);
      } else {
        if (typeof id !== 'string') {
          id = id.get('id');
        }
        return handleMessage(id);
      }
    });
    if (next != null) {
      MessageActionCreator.setCurrent(next.get('id'), true);
      return window.cozyMails.messageDisplay(next, false);
    }
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
    return request.get("conversation/" + conversationID).set('Accept', 'application/json').end(function(res) {
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
  messagePatch: function(messageID, patch, callback) {
    return request.patch("message/" + messageID, patch).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in messagePatch", messageID, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  conversationDelete: function(conversationID, callback) {
    return request.del("conversation/" + conversationID).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in conversationDelete", conversationID, (_ref = res.body) != null ? _ref.error : void 0);
        return callback(t('app error'));
      }
    });
  },
  conversationPatch: function(conversationID, patch, callback) {
    return request.patch("conversation/" + conversationID, patch).set('Accept', 'application/json').end(function(res) {
      var _ref;
      if (res.ok) {
        return callback(null, res.body);
      } else {
        console.log("Error in conversationPatch", conversationID, (_ref = res.body) != null ? _ref.error : void 0);
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