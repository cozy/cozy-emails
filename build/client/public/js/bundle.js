(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({"./app/initialize.coffee":[function(require,module,exports){
window.onload = function() {
  var AccountStore, Application, LayoutStore, MailboxStore, MessageStore, Router, application, err, locale, locales, polyglot;
  window.true = window.location.hostname === 'localhost';
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
  LayoutStore = require('./stores/LayoutStore');
  MessageStore = require('./stores/MessageStore');
  AccountStore = require('./stores/AccountStore');
  MailboxStore = require('./stores/MailboxStore');
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



},{"./components/application":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/application.coffee","./locales/en":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/locales/en.coffee","./router":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/router.coffee","./stores/AccountStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/AccountStore.coffee","./stores/LayoutStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/LayoutStore.coffee","./stores/MailboxStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/MailboxStore.coffee","./stores/MessageStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/MessageStore.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/AppDispatcher.coffee":[function(require,module,exports){
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



},{"./constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee","./libs/flux/dispatcher/Dispatcher":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/dispatcher/Dispatcher.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/AccountActionCreator.coffee":[function(require,module,exports){
var AccountActionCreator, ActionTypes, AppDispatcher, MailboxStore, XHRUtils;

XHRUtils = require('../utils/XHRUtils');

AppDispatcher = require('../AppDispatcher');

MailboxStore = require('../stores/MailboxStore');

ActionTypes = require('../constants/AppConstants').ActionTypes;

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
  edit: function(inputValues) {
    AccountActionCreator._setNewAccountWaitingStatus(true);
    return XHRUtils.editAccount(inputValues, function(error, account) {
      return setTimeout(function() {
        AccountActionCreator._setNewAccountWaitingStatus(false);
        if (error != null) {
          return AccountActionCreator._setNewAccountError(error);
        } else {
          return AppDispatcher.handleViewAction({
            type: ActionTypes.EDIT_ACCOUNT,
            value: account
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
    var mailboxes;
    AppDispatcher.handleViewAction({
      type: ActionTypes.SELECT_ACCOUNT,
      value: accountID
    });
    mailboxes = MailboxStore.getByAccount(accountID);
    if (((mailboxes == null) || mailboxes.count() === 0) && accountID) {
      return XHRUtils.fetchMailboxByAccount(accountID);
    }
  }
};



},{"../AppDispatcher":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/AppDispatcher.coffee","../constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee","../stores/MailboxStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/MailboxStore.coffee","../utils/XHRUtils":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/utils/XHRUtils.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/LayoutActionCreator.coffee":[function(require,module,exports){
var AccountActionCreator, AccountStore, ActionTypes, AppDispatcher, LayoutActionCreator, XHRUtils;

XHRUtils = require('../utils/XHRUtils');

AccountStore = require('../stores/AccountStore');

AppDispatcher = require('../AppDispatcher');

ActionTypes = require('../constants/AppConstants').ActionTypes;

AccountActionCreator = require('./AccountActionCreator');

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
  showMessageList: function(panelInfo, direction) {
    var accountID, defaultAccount;
    LayoutActionCreator.hideReponsiveMenu();
    defaultAccount = AccountStore.getDefault();
    accountID = panelInfo.parameters[0] || (defaultAccount != null ? defaultAccount.get('id') : void 0);
    AccountActionCreator.selectAccount(accountID);
    if (accountID != null) {
      return XHRUtils.fetchMessagesByAccount(accountID);
    }
  },
  showConversation: function(panelInfo, direction) {
    LayoutActionCreator.hideReponsiveMenu();
    return XHRUtils.fetchConversation(panelInfo.parameters[0], function(err, rawMessage) {
      var selectedAccount;
      selectedAccount = AccountStore.getSelected();
      if ((selectedAccount == null) && (rawMessage != null ? rawMessage.mailbox : void 0)) {
        return AccountActionCreator.selectAccount(rawMessage.mailbox);
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
  }
};



},{"../AppDispatcher":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/AppDispatcher.coffee","../constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee","../stores/AccountStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/AccountStore.coffee","../utils/XHRUtils":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/utils/XHRUtils.coffee","./AccountActionCreator":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/AccountActionCreator.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/MailboxActionCreator.coffee":[function(require,module,exports){
var ActionTypes, AppDispatcher;

AppDispatcher = require('../AppDispatcher');

ActionTypes = require('../constants/AppConstants').ActionTypes;

module.exports = {
  receiveRawMailboxes: function(mailboxes) {
    return AppDispatcher.handleViewAction({
      type: ActionTypes.RECEIVE_RAW_MAILBOXES,
      value: mailboxes
    });
  }
};



},{"../AppDispatcher":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/AppDispatcher.coffee","../constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/MessageActionCreator.coffee":[function(require,module,exports){
var ActionTypes, AppDispatcher;

AppDispatcher = require('../AppDispatcher');

ActionTypes = require('../constants/AppConstants').ActionTypes;

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
  }
};



},{"../AppDispatcher":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/AppDispatcher.coffee","../constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/account-config.coffee":[function(require,module,exports){
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
      valueLink: this.linkState('email'),
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
      mailboxValue.id = this.props.initialAccountConfig.get('id');
      return AccountActionCreator.edit(this.state);
    } else {
      return AccountActionCreator.create(this.state);
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
        email: this.props.initialAccountConfig.get('email'),
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



},{"../actions/AccountActionCreator":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/AccountActionCreator.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/application.coffee":[function(require,module,exports){
var AccountConfig, AccountStore, Application, Compose, Conversation, LayoutActionCreator, LayoutStore, MailboxList, MailboxStore, Menu, MessageList, MessageStore, ReactCSSTransitionGroup, RouterMixin, StoreWatchMixin, a, body, classer, div, form, i, input, p, span, _ref;

_ref = React.DOM, body = _ref.body, div = _ref.div, p = _ref.p, form = _ref.form, i = _ref.i, input = _ref.input, span = _ref.span, a = _ref.a;

Menu = require('./menu');

MessageList = require('./message-list');

Conversation = require('./conversation');

Compose = require('./compose');

AccountConfig = require('./account-config');

MailboxList = require('./mailbox-list');

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup;

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

StoreWatchMixin = require('../mixins/StoreWatchMixin');

AccountStore = require('../stores/AccountStore');

MessageStore = require('../stores/MessageStore');

LayoutStore = require('../stores/LayoutStore');

MailboxStore = require('../stores/MailboxStore');

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
  mixins: [StoreWatchMixin([AccountStore, MessageStore, LayoutStore, MailboxStore]), RouterMixin],
  render: function() {
    var configMailboxUrl, isFullWidth, layout, leftPanelLayoutMode, panelClasses, responsiveBackUrl, responsiveClasses, showMailboxConfigButton;
    layout = this.props.router.current;
    if (layout == null) {
      return div(null, t("app loading"));
    }
    isFullWidth = layout.rightPanel == null;
    leftPanelLayoutMode = isFullWidth ? 'full' : 'left';
    panelClasses = this.getPanelClasses(isFullWidth);
    showMailboxConfigButton = (this.state.selectedAccount != null) && layout.leftPanel.action !== 'account.new';
    if (showMailboxConfigButton) {
      if (layout.leftPanel.action === 'account.config') {
        configMailboxUrl = this.buildUrl({
          direction: 'left',
          action: 'account.messages',
          parameters: this.state.selectedAccount.get('id'),
          fullWidth: true
        });
      } else {
        configMailboxUrl = this.buildUrl({
          direction: 'left',
          action: 'account.config',
          parameters: this.state.selectedAccount.get('id'),
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
      accounts: this.state.accounts,
      selectedAccount: this.state.selectedAccount,
      isResponsiveMenuShown: this.state.isResponsiveMenuShown,
      layout: this.props.router.current,
      favoriteMailboxes: this.state.favoriteMailboxes
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
    }), div({
      className: 'form-group pull-left'
    }, div({
      className: 'input-group'
    }, input({
      className: 'form-control',
      type: 'text',
      placeholder: t("app search", {
        onFocus: this.onFocusSearchInput,
        onBlur: this.onBlurSearchInput
      })
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
      if ((previous != null) && left.action === 'account.config') {
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
    var accountID, conversation, direction, error, firstMailbox, initialAccountConfig, isWaiting, mailboxID, message, openMessage, otherPanelInfo, selectedAccount;
    if (panelInfo.action === 'account.messages') {
      firstMailbox = AccountStore.getDefault();
      openMessage = null;
      direction = layout === 'left' ? 'rightPanel' : 'leftPanel';
      otherPanelInfo = this.props.router.current[direction];
      if ((otherPanelInfo != null ? otherPanelInfo.action : void 0) === 'message') {
        openMessage = MessageStore.getByID(otherPanelInfo.parameters[0]);
      }
      if ((panelInfo.parameters != null) && panelInfo.parameters.length > 0) {
        MessageStore = MessageStore;
        accountID = panelInfo.parameters[0];
        return MessageList({
          messages: MessageStore.getMessagesByAccount(accountID),
          accountID: accountID,
          layout: layout,
          openMessage: openMessage
        });
      } else if (((panelInfo.parameters == null) || panelInfo.parameters.length === 0) && (firstMailbox != null)) {
        MessageStore = MessageStore;
        accountID = firstMailbox.id;
        return MessageList({
          messages: MessageStore.getMessagesByAccount(accountID),
          accountID: accountID,
          layout: layout,
          openMessage: openMessage
        });
      } else {
        return div(null, 'Handle no mailbox or mailbox not found case');
      }
    } else if (panelInfo.action === 'account.mailbox.messages') {
      accountID = panelInfo.parameters[0];
      mailboxID = panelInfo.parameters[1];
      openMessage = null;
      direction = layout === 'left' ? 'rightPanel' : 'leftPanel';
      otherPanelInfo = this.props.router.current[direction];
      if ((otherPanelInfo != null ? otherPanelInfo.action : void 0) === 'message') {
        openMessage = MessageStore.getByID(otherPanelInfo.parameters[0]);
      }
      return MessageList({
        messages: MessageStore.getMessagesByMailbox(mailboxID),
        accountID: accountID,
        layout: layout,
        openMessage: openMessage
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
      return Compose({
        selectedAccount: selectedAccount,
        layout: layout
      });
    } else {
      return div(null, 'Unknown component');
    }
  },
  getStateFromStores: function() {
    var leftPanelInfo, selectedAccount, selectedAccountID, selectedMailbox, selectedMailboxID, _ref1;
    selectedAccount = AccountStore.getSelected();
    selectedAccountID = (selectedAccount != null ? selectedAccount.get('id') : void 0) || null;
    leftPanelInfo = (_ref1 = this.props.router.current) != null ? _ref1.leftPanel : void 0;
    if ((leftPanelInfo != null ? leftPanelInfo.action : void 0) === 'account.account.messages') {
      selectedMailboxID = leftPanelInfo.parameters[1];
    } else {
      selectedMailboxID = null;
    }
    selectedMailbox = MailboxStore.getSelected(selectedAccountID, selectedMailboxID);
    return {
      accounts: AccountStore.getAll(),
      selectedAccount: selectedAccount,
      isResponsiveMenuShown: LayoutStore.isMenuShown(),
      mailboxes: MailboxStore.getByAccount(selectedAccountID),
      selectedMailbox: selectedMailbox,
      favoriteMailboxes: MailboxStore.getFavorites(selectedAccountID)
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
      return LayoutActionCreator.hideReponsiveMenu();
    } else {
      return LayoutActionCreator.showReponsiveMenu();
    }
  }
});



},{"../actions/LayoutActionCreator":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/LayoutActionCreator.coffee","../mixins/RouterMixin":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/RouterMixin.coffee","../mixins/StoreWatchMixin":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/StoreWatchMixin.coffee","../stores/AccountStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/AccountStore.coffee","../stores/LayoutStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/LayoutStore.coffee","../stores/MailboxStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/MailboxStore.coffee","../stores/MessageStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/MessageStore.coffee","./account-config":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/account-config.coffee","./compose":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/compose.coffee","./conversation":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/conversation.coffee","./mailbox-list":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/mailbox-list.coffee","./menu":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/menu.coffee","./message-list":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/message-list.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/compose.coffee":[function(require,module,exports){
var Compose, RouterMixin, a, classer, div, h3, i, textarea, _ref;

_ref = React.DOM, div = _ref.div, h3 = _ref.h3, a = _ref.a, i = _ref.i, textarea = _ref.textarea;

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

module.exports = Compose = React.createClass({
  displayName: 'Compose',
  mixins: [RouterMixin],
  render: function() {
    var closeUrl, collapseUrl, expandUrl, _ref1;
    expandUrl = this.buildUrl({
      direction: 'left',
      action: 'compose',
      fullWidth: true
    });
    collapseUrl = this.buildUrl({
      leftPanel: {
        action: 'account.messages',
        parameters: (_ref1 = this.props.selectedAccount) != null ? _ref1.get('id') : void 0
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
    }))), textarea({
      defaultValue: t('compose default')
    }));
  }
});



},{"../mixins/RouterMixin":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/RouterMixin.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/conversation.coffee":[function(require,module,exports){
var Message, RouterMixin, a, classer, div, h3, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a;

Message = require('./message');

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

module.exports = React.createClass({
  displayName: 'Conversation',
  mixins: [RouterMixin],
  render: function() {
    var closeIcon, closeUrl, collapseUrl, expandUrl, isLast, key, message, selectedAccountID;
    if ((this.props.message == null) || !this.props.conversation) {
      return p(null, t("app loading"));
    }
    expandUrl = this.buildUrl({
      direction: 'left',
      action: 'message',
      parameters: this.props.message.get('id'),
      fullWidth: true
    });
    if (window.router.previous != null) {
      selectedAccountID = this.props.selectedAccount.get('id');
    } else {
      selectedAccountID = this.props.conversation[0].mailbox;
    }
    collapseUrl = this.buildUrl({
      leftPanel: {
        action: 'account.messages',
        parameters: selectedAccountID
      },
      rightPanel: {
        action: 'message',
        parameters: this.props.conversation[0].get('id')
      }
    });
    if (this.props.layout === 'full') {
      closeUrl = this.buildUrl({
        direction: 'left',
        action: 'account.messages',
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
        _results.push(Message({
          message: message,
          key: key,
          isLast: isLast
        }));
      }
      return _results;
    }).call(this)));
  }
});



},{"../mixins/RouterMixin":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/RouterMixin.coffee","./message":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/message.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/mailbox-list.coffee":[function(require,module,exports){
var RouterMixin, a, button, div, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, a = _ref.a, button = _ref.button;

RouterMixin = require('../mixins/RouterMixin');

module.exports = React.createClass({
  displayName: 'MailboxList',
  mixins: [RouterMixin],
  render: function() {
    var firstItem;
    if (this.props.mailboxes.length > 0) {
      firstItem = this.props.selectedMailbox;
      return div({
        className: 'dropdown pull-left'
      }, button({
        className: 'btn btn-default dropdown-toggle',
        type: 'button',
        'data-toggle': 'dropdown'
      }, firstItem.get('name'), span({
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
      return div(null, t("app loading"));
    }
  },
  getMailboxRender: function(mailbox, key) {
    var url;
    url = this.buildUrl({
      direction: 'left',
      action: 'account.mailbox.messages',
      parameters: [this.props.selectedAccount.get('id'), mailbox.get('id')]
    });
    return li({
      role: 'presentation',
      key: key
    }, a({
      href: url,
      role: 'menuitem'
    }, mailbox.get('name')));
  }
});



},{"../mixins/RouterMixin":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/RouterMixin.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/menu.coffee":[function(require,module,exports){
var Menu, RouterMixin, a, classer, div, i, li, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i;

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

module.exports = Menu = React.createClass({
  displayName: 'Menu',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !Immutable.is(nextProps.accounts, this.props.accounts) || !Immutable.is(nextProps.selectedAccount, this.props.selectedAccount) || !_.isEqual(nextProps.layout, this.props.layout) || nextProps.isResponsiveMenuShown !== this.props.isResponsiveMenuShown || !Immutable.is(nextProps.favoriteMailboxes, this.props.favoriteMailboxes);
  },
  render: function() {
    var classes, composeUrl, newMailboxUrl, selectedAccountUrl, _ref1, _ref2;
    selectedAccountUrl = this.buildUrl({
      direction: 'left',
      action: 'account.messages',
      parameters: (_ref1 = this.props.selectedAccount) != null ? _ref1.get('id') : void 0,
      fullWidth: true
    });
    if (this.props.layout.leftPanel.action === 'compose' || ((_ref2 = this.props.layout.rightPanel) != null ? _ref2.action : void 0) === 'compose') {
      composeUrl = selectedAccountUrl;
    } else {
      composeUrl = this.buildUrl({
        direction: 'right',
        action: 'compose',
        parameters: null,
        fullWidth: false
      });
    }
    if (this.props.layout.leftPanel.action === 'account.new') {
      newMailboxUrl = selectedAccountUrl;
    } else {
      newMailboxUrl = this.buildUrl({
        direction: 'left',
        action: 'account.new',
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
    }, t('menu account new'))));
  },
  getAccountRender: function(account, key) {
    var accountClasses, isSelected, url, _ref1;
    isSelected = ((this.props.selectedAccount == null) && key === 0) || ((_ref1 = this.props.selectedAccount) != null ? _ref1.get('id') : void 0) === account.get('id');
    accountClasses = classer({
      active: isSelected
    });
    url = this.buildUrl({
      direction: 'left',
      action: 'account.messages',
      parameters: account.get('id'),
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
        return _this.getMailboxRender(mailbox, key);
      };
    })(this)).toJS()));
  },
  getMailboxRender: function(mailbox, key) {
    var mailboxUrl;
    mailboxUrl = this.buildUrl({
      direction: 'left',
      action: 'account.mailbox.messages',
      parameters: [mailbox.get('mailbox'), mailbox.get('id')]
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
    }, mailbox.get('name')));
  }
});



},{"../mixins/RouterMixin":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/RouterMixin.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/message-list.coffee":[function(require,module,exports){
var RouterMixin, a, classer, div, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, a = _ref.a, span = _ref.span, i = _ref.i, p = _ref.p;

classer = React.addons.classSet;

RouterMixin = require('../mixins/RouterMixin');

module.exports = React.createClass({
  displayName: 'MessageList',
  mixins: [RouterMixin],
  shouldComponentUpdate: function(nextProps, nextState) {
    return !Immutable.is(nextProps.messages, this.props.messages) || !Immutable.is(nextProps.openMessage, this.props.openMessage);
  },
  render: function() {
    return div({
      className: 'message-list'
    }, this.props.messages.count() === 0 ? t("list empty") : ul({
      className: 'list-unstyled'
    }, this.props.messages.map((function(_this) {
      return function(message, key) {
        var isActive;
        if (message.get('inReplyTo').length === 0) {
          isActive = (_this.props.openMessage != null) && _this.props.openMessage.get('id') === message.get('id');
          return _this.getMessageRender(message, key, isActive);
        }
      };
    })(this)).toJS()));
  },
  getMessageRender: function(message, key, isActive) {
    var classes, date, formatter, today, url;
    classes = classer({
      read: message.get('isRead'),
      active: isActive
    });
    url = this.buildUrl({
      direction: 'right',
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
  getParticipants: function(message) {
    return "" + (message.get('from')) + ", " + (message.get('to'));
  }
});



},{"../mixins/RouterMixin":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/RouterMixin.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/components/message.coffee":[function(require,module,exports){
var a, classer, div, h3, i, li, p, span, ul, _ref;

_ref = React.DOM, div = _ref.div, ul = _ref.ul, li = _ref.li, span = _ref.span, i = _ref.i, p = _ref.p, h3 = _ref.h3, a = _ref.a;

classer = React.addons.classSet;

module.exports = React.createClass({
  displayName: 'Message',
  getInitialState: function() {
    return {
      active: false
    };
  },
  render: function() {
    var classes, clickHandler, date, formatter, today;
    clickHandler = this.props.isLast ? null : this.onClick;
    classes = classer({
      message: true,
      active: this.state.active
    });
    today = moment();
    date = moment(this.props.message.get('createdAt'));
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
      className: 'header'
    }, i({
      className: 'fa fa-user'
    }), div({
      className: 'participants'
    }, span({
      className: 'sender'
    }, this.props.message.get('from')), span({
      className: 'receivers'
    }, t("mail receivers", {
      dest: this.props.message.get('to')
    }))), span({
      className: 'hour'
    }, date.format(formatter))), div({
      className: 'preview'
    }, p(null, this.props.message.get('text'))), div({
      className: 'content'
    }, this.props.message.get('text')), div({
      className: 'clearfix'
    }));
  },
  onClick: function(args) {
    return this.setState({
      active: !this.state.active
    });
  }
});



},{}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee":[function(require,module,exports){
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
    'SHOW_MENU_RESPONSIVE': 'SHOW_MENU_RESPONSIVE',
    'HIDE_MENU_RESPONSIVE': 'HIDE_MENU_RESPONSIVE',
    'SELECT_ACCOUNT': 'SELECT_ACCOUNT',
    'RECEIVE_RAW_MAILBOX': 'RECEIVE_RAW_MAILBOX'
  },
  PayloadSources: {
    'VIEW_ACTION': 'VIEW_ACTION',
    'SERVER_ACTION': 'SERVER_ACTION'
  }
};



},{}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/PanelRouter.coffee":[function(require,module,exports){

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
var LayoutActionCreator, MailboxStore, Router,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LayoutActionCreator = require('../actions/LayoutActionCreator');

MailboxStore = require('../stores/MailboxStore');

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
      this.routes["" + route.pattern + "/*rightPanel"] = key;
    }
    this._bindRoutes();
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
      fluxAction = LayoutActionCreator[pattern.fluxAction];
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

  Router.prototype._getDefaultParameters = function(action) {
    var defaultImapFolder, defaultMailbox, defaultParameters;
    defaultParameters = null;
    switch (action) {
      case 'mailbox.emails':
      case 'mailbox.config':
        defaultMailbox = MailboxStore.getDefault();
        if (defaultMailbox) {
          defaultParameters = [defaultMailbox.id];
        }
        break;
      case 'mailbox.imap.emails':
        defaultMailbox = MailboxStore.getDefault().id;
        if (defaultMailbox) {
          defaultImapFolder = 'lala';
          defaultParameters = [defaultMailbox, defaultImapFolder];
        }
        break;
      default:
        defaultParameters = null;
    }
    return defaultParameters;
  };

  return Router;

})(Backbone.Router);



},{"../actions/LayoutActionCreator":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/LayoutActionCreator.coffee","../stores/MailboxStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/MailboxStore.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/dispatcher/Dispatcher.coffee":[function(require,module,exports){

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



},{"../invariant":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/invariant.js"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/invariant.js":[function(require,module,exports){
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
  if (true) {
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
},{}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/store/Store.coffee":[function(require,module,exports){
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
    if (true) {
      throw new Error("The store " + this.constructor.name + " must define a `__bindHandlers` method");
    }
  };

  return Store;

})(EventEmitter);



},{"../../../AppDispatcher":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/AppDispatcher.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/locales/en.coffee":[function(require,module,exports){
module.exports = {
  "app loading": "Chargement…",
  "app back": "Back",
  "app menu": "Menu",
  "app search": "Search…",
  "compose": "Compose new email",
  "compose default": 'Hello, how are you doing today ?',
  "menu compose": "Compose",
  "menu account new": "New account",
  "list empty": "No email in this box.",
  "mail receivers": "To %{dest}",
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
  "mailbox remove": "Remove"
};



},{}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/RouterMixin.coffee":[function(require,module,exports){

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



},{}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/mixins/StoreWatchMixin.coffee":[function(require,module,exports){
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



},{}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/router.coffee":[function(require,module,exports){
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
      pattern: 'account/:id/mailbox/:mailbox',
      fluxAction: 'showMessageList'
    },
    'account.messages': {
      pattern: 'account/:id',
      fluxAction: 'showMessageList'
    },
    'message': {
      pattern: 'message/:id',
      fluxAction: 'showConversation'
    },
    'compose': {
      pattern: 'compose',
      fluxAction: 'showComposeNewMessage'
    }
  };

  Router.prototype.routes = {
    '': 'account.messages'
  };

  Router.prototype._getDefaultParameters = function(action) {
    var defaultAccount, defaultMailbox, defaultParameters, _ref, _ref1;
    switch (action) {
      case 'account.messages':
      case 'account.config':
        defaultAccount = (_ref = AccountStore.getDefault()) != null ? _ref.id : void 0;
        defaultParameters = [defaultAccount];
        break;
      case 'account.imap.messages':
        defaultAccount = (_ref1 = AccountStore.getDefault()) != null ? _ref1.id : void 0;
        defaultMailbox = 'lala';
        defaultParameters = [defaultAccount, defaultMailbox];
        break;
      default:
        defaultParameters = null;
    }
    return defaultParameters;
  };

  return Router;

})(PanelRouter);



},{"./libs/PanelRouter":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/PanelRouter.coffee","./stores/AccountStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/AccountStore.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/AccountStore.coffee":[function(require,module,exports){
var AccountStore, ActionTypes, Store, fixtures,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/Store');

ActionTypes = require('../constants/AppConstants').ActionTypes;

fixtures = [];

AccountStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var accounts, _accounts, _newAccountError, _newAccountWaiting, _selectedAccount;

  __extends(AccountStore, _super);

  function AccountStore() {
    return AccountStore.__super__.constructor.apply(this, arguments);
  }

  accounts = window.accounts || fixtures;

  if (accounts.length === 0) {
    accounts = fixtures;
  }

  _accounts = Immutable.Sequence(accounts).map(function(account) {
    account.id = account.id || account._id;
    return account;
  }).sort(function(mb1, mb2) {
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
    return Immutable.Map(account);
  }).toOrderedMap();

  _selectedAccount = null;

  _newAccountWaiting = false;

  _newAccountError = null;


  /*
      Defines here the action handlers.
   */

  AccountStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.ADD_ACCOUNT, function(account) {
      account = Immutable.Map(account);
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
    handle(ActionTypes.EDIT_ACCOUNT, function(account) {
      account = Immutable.Map(account);
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

  AccountStore.prototype.getDefault = function() {
    return _accounts.first() || null;
  };

  AccountStore.prototype.getSelected = function() {
    return _selectedAccount;
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



},{"../constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee","../libs/flux/store/Store":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/store/Store.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/LayoutStore.coffee":[function(require,module,exports){
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
  var _responsiveMenuShown;

  __extends(LayoutStore, _super);

  function LayoutStore() {
    return LayoutStore.__super__.constructor.apply(this, arguments);
  }

  _responsiveMenuShown = false;


  /*
      Defines here the action handlers.
   */

  LayoutStore.prototype.__bindHandlers = function(handle) {
    handle(ActionTypes.SHOW_MENU_RESPONSIVE, function() {
      _responsiveMenuShown = true;
      return this.emit('change');
    });
    return handle(ActionTypes.HIDE_MENU_RESPONSIVE, function() {
      _responsiveMenuShown = false;
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  LayoutStore.prototype.isMenuShown = function() {
    return _responsiveMenuShown;
  };

  return LayoutStore;

})(Store);

module.exports = new LayoutStore();



},{"../constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee","../libs/flux/store/Store":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/store/Store.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/MailboxStore.coffee":[function(require,module,exports){
var AccountStore, ActionTypes, AppDispatcher, MailboxStore, Store, fixtures,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/Store');

AppDispatcher = require('../AppDispatcher');

AccountStore = require('./AccountStore');

ActionTypes = require('../constants/AppConstants').ActionTypes;

fixtures = [];

MailboxStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var mailboxes, _mailboxes;

  __extends(MailboxStore, _super);

  function MailboxStore() {
    return MailboxStore.__super__.constructor.apply(this, arguments);
  }

  if ((window.accounts == null) || window.accounts.length === 0) {
    mailboxes = fixtures;
  } else {
    mailboxes = [];
  }

  _mailboxes = Immutable.Sequence(mailboxes).map(function(mailbox) {
    mailbox.id = mailbox.id || mailbox._id;
    return mailbox;
  }).mapKeys(function(_, mailbox) {
    return mailbox.id;
  }).map(function(mailbox) {
    return Immutable.Map(mailbox);
  }).toOrderedMap();


  /*
      Defines here the action handlers.
   */

  MailboxStore.prototype.__bindHandlers = function(handle) {
    return handle(ActionTypes.RECEIVE_RAW_MAILBOX, function(rawMailboxes) {
      _mailboxes = _mailboxes.withMutations(function(map) {
        var mailbox, rawMailbox, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = rawMailboxes.length; _i < _len; _i++) {
          rawMailbox = rawMailboxes[_i];
          mailbox = Immutable.Map(rawMailbox);
          _results.push(map.set(mailbox.get('id'), mailbox));
        }
        return _results;
      });
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  MailboxStore.prototype.getByAccount = function(accountID) {
    return _mailboxes.filter(function(mailbox) {
      return mailbox.get('mailbox') === accountID;
    }).toOrderedMap();
  };

  MailboxStore.prototype.getSelected = function(accountID, mailboxID) {
    mailboxes = this.getByAccount(accountID);
    if (mailboxID != null) {
      return mailboxes.get(mailboxID);
    } else {
      return mailboxes.first();
    }
  };

  MailboxStore.prototype.getFavorites = function(accountID) {
    return _mailboxes.filter(function(mailbox) {
      return mailbox.get('mailbox') === accountID;
    }).skip(1).take(3).toOrderedMap();
  };

  return MailboxStore;

})(Store);

module.exports = new MailboxStore();



},{"../AppDispatcher":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/AppDispatcher.coffee","../constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee","../libs/flux/store/Store":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/store/Store.coffee","./AccountStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/AccountStore.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/MessageStore.coffee":[function(require,module,exports){
var AccountStore, ActionTypes, AppDispatcher, MessageStore, Store, fixtures, _idGenerator,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Store = require('../libs/flux/store/Store');

AppDispatcher = require('../AppDispatcher');

AccountStore = require('./AccountStore');

ActionTypes = require('../constants/AppConstants').ActionTypes;

fixtures = [];

_idGenerator = 0;

MessageStore = (function(_super) {

  /*
      Initialization.
      Defines private variables here.
   */
  var messages, _message;

  __extends(MessageStore, _super);

  function MessageStore() {
    return MessageStore.__super__.constructor.apply(this, arguments);
  }

  if ((window.accounts == null) || window.accounts.length === 0) {
    messages = fixtures;
    messages.sort(function(e1, e2) {
      if (e1.createdAt < e2.createdAt) {
        return 1;
      } else if (e1.createdAt > e2.createdAt) {
        return -1;
      } else {
        return 0;
      }
    });
  } else {
    messages = [];
  }

  _message = Immutable.Sequence(messages).map(function(message) {
    message.id = message.id || message._id || 'id_' + _idGenerator++;
    return message;
  }).mapKeys(function(_, message) {
    return message.id;
  }).map(function(message) {
    return Immutable.Map(message);
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
      _message = _message.set(message.get('id'), message);
      if (!silent) {
        return this.emit('change');
      }
    });
    handle(ActionTypes.RECEIVE_RAW_MESSAGE, function(messages) {
      var message, _i, _len;
      for (_i = 0, _len = messages.length; _i < _len; _i++) {
        message = messages[_i];
        onReceiveRawmessage(message, true);
      }
      return this.emit('change');
    });
    return handle(ActionTypes.REMOVE_ACCOUNT, function(accountID) {
      AppDispatcher.waitFor([AccountStore.dispatchToken]);
      messages = this.getMessagesByAccount(accountID);
      _message = _message.withMutations(function(map) {
        return messages.forEach(function(message) {
          return map.remove(message.get('id'));
        });
      });
      return this.emit('change');
    });
  };


  /*
      Public API
   */

  MessageStore.prototype.getAll = function() {
    return _message;
  };

  MessageStore.prototype.getByID = function(messageID) {
    return _message.get(messageID) || null;
  };

  MessageStore.prototype.getMessagesByAccount = function(accountID) {
    return _message.filter(function(message) {
      return message.get('mailbox') === accountID;
    }).toOrderedMap();
  };

  MessageStore.prototype.getMessagesByMailbox = function(mailboxID) {
    return _message.filter(function(message) {
      return message.get('imapFolder') === mailboxID;
    }).toOrderedMap();
  };

  MessageStore.prototype.getMessagesByConversation = function(messageID) {
    var conversation, idToLook, idsToLook, temp;
    idsToLook = [messageID];
    conversation = [];
    while (idToLook = idsToLook.pop()) {
      conversation.push(this.getByID(idToLook));
      temp = _message.filter(function(message) {
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



},{"../AppDispatcher":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/AppDispatcher.coffee","../constants/AppConstants":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/constants/AppConstants.coffee","../libs/flux/store/Store":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/libs/flux/store/Store.coffee","./AccountStore":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/stores/AccountStore.coffee"}],"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/utils/XHRUtils.coffee":[function(require,module,exports){
var MailboxActionCreator, MessageActionCreator;

MessageActionCreator = require('../actions/MessageActionCreator');

MailboxActionCreator = require('../actions/MailboxActionCreator');

module.exports = {
  fetchMessagesByAccount: function(mailboxID) {
    return request.get("account/" + mailboxID + "/messages").set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return MessageActionCreator.receiveRawMessages(res.body);
      } else {
        return console.log("Something went wrong -- " + res.body);
      }
    });
  },
  fetchConversation: function(emailID, callback) {
    return request.get("message/" + emailID).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        MessageActionCreator.receiveRawMessage(res.body);
        return callback(null, res.body);
      } else {
        return callback("Something went wrong -- " + res.body);
      }
    });
  },
  fetchMailboxByAccount: function(accountID) {
    return request.get("account/" + accountID + "/mailboxes").set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return MailboxActionCreator.receiveRawMailboxes(res.body);
      } else {
        return console.log("Something went wrong -- " + res.body);
      }
    });
  },
  fetchMessagesByFolder: function(mailboxID) {
    return request.get("mailbox/" + mailboxID + "/messages").set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return MessageActionCreator.receiveRawMessage(res.body);
      } else {
        return console.log("Something went wrong -- " + res.body);
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
    return request.put("account/" + account.id).send(account).set('Accept', 'application/json').end(function(res) {
      if (res.ok) {
        return callback(null, res.body);
      } else {
        return callback(res.body, null);
      }
    });
  },
  removeAccount: function(accountID) {
    return request.del("account/" + accountID).set('Accept', 'application/json').end(function(res) {});
  }
};



},{"../actions/MailboxActionCreator":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/MailboxActionCreator.coffee","../actions/MessageActionCreator":"/Users/joseph/Documents/Developement/cozycloud/dev-env/emails/client/app/actions/MessageActionCreator.coffee"}]},{},["./app/initialize.coffee"])


//# sourceMappingURL=bundle.js.map