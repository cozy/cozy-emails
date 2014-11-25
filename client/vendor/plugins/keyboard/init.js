//jshint browser: true, strict: false
/*global Mousetrap */
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
(function (root) {
  function bindingNew() {
    window.cozyMails.messageNew();
  }
  function bindingHelp() {
    var self, container, help;
    container = document.getElementById('mailkeysHelp');
    if (container) {
      document.body.removeChild(container);
      return;
    }
    self      = this;
    container = document.createElement('div');
    help      = document.createElement('dl');
    container.id = 'mailkeysHelp';
    Object.keys(this._binding).forEach(function (key) {
      help.innerHTML += "<dt>" + key + "&nbsp;: </dt><dd>" + self._binding[key].name + "</dd>";
    });
    container.appendChild(help);
    container.classList.add('mailkeys-container');
    help.classList.add('mailkeys-help');
    document.body.appendChild(container);
    Mousetrap.bind("esc", function () {
      document.body.removeChild(container);
      Mousetrap.unbind("esc");
    });
  }
  root.mailkeys = {
    _binding: {
      'enter': {
        name: "Display current message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageDisplay();
        }
      },
      'x': {
        name: "Close current message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageClose();
        }
      },
      'esc': {
        name: "Close current message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageClose();
        }
      },
      'j': {
        name: "Next Message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('next');
        }
      },
      'down': {
        name: "Next Message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('next');
        }
      },
      'k': {
        name: "Previous Message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('prev');
        }
      },
      'up': {
        name: "Previous Message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('prev');
        }
      },
      'ctrl+down': {
        name: 'Scroll message down',
        action: function (e) {
          e.preventDefault();
          var panel = document.querySelector("#panels > .panel:nth-of-type(2)");
          if (panel) {
            panel.scrollTop += panel.clientHeight * 0.8;
          }
        }
      },
      'ctrl+up': {
        name: 'Scroll message up',
        action: function (e) {
          e.preventDefault();
          var panel = document.querySelector("#panels > .panel:nth-of-type(2)");
          if (panel) {
            panel.scrollTop -= panel.clientHeight * 0.8;
          }
        }
      },
      'n': {
        name: "New message",
        action: bindingNew
      },
      'd': {
        name: "Delete message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageDeleteCurrent();
        }
      },
      'ctrl+z': {
        name: 'Undelete message',
        action: function (e) {
          e.preventDefault();
          var MessageActionCreator = window.require('actions/message_action_creator');
          MessageActionCreator.undelete();
        }
      },
      'backspace': {
        name: "Delete message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageDeleteCurrent();
        }
      },
      'del': {
        name: "Delete message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageDeleteCurrent();
        }
      },
      'u': {
        name: "Undelete message",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageUndo();
        }
      },
      '?': {
        name: "Toggle display of available bindings",
        action: bindingHelp
      }
    },
    name: "Keyboard shortcuts",
    active: true,
    onAdd: {
      /**
       * Should return true if plugin applies on added subtree
       *
       * @param {DOMNode} root node of added subtree
       */
      condition: function (node) {
        return false;
      },
      /**
       * Perform action on added subtree
       *
       * @param {DOMNode} root node of added subtree
       */
      action: function (node) {
      }
    },
    /**
     * Called when plugin is activated
     */
    onActivate: function () {
      var self = this;
      Object.keys(this._binding).forEach(function (key) {
        Mousetrap.bind(key, self._binding[key].action.bind(self));
      });
    },
    /**
     * Called when plugin is deactivated
     */
    onDeactivate: function () {
      Mousetrap.reset();
    },
    listeners: {
    }
  };
})(window.plugins);
