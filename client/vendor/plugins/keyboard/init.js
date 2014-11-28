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
      var binding = self._binding[key],
          name = [key];
      if (Array.isArray(binding.alias)) {
        name = name.concat(binding.alias);
      }
      help.innerHTML += "<dt>" + name.join(', ') + "&nbsp;: </dt><dd>" + binding.name + "</dd>";
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
      'esc': {
        name: "Close current message",
        alias: ['x'],
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageClose();
        }
      },
      'j': {
        name: "Next Message",
        alias: ['down', 'right'],
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('next');
        }
      },
      'k': {
        name: "Previous Message",
        alias: ['up', 'left'],
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
        alias: ['backspace', 'del'],
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageDeleteCurrent();
        }
      },
      'ctrl+z': {
        name: 'Undelete message',
        alias: ['u'],
        action: function (e) {
          e.preventDefault();
          var MessageActionCreator = window.require('actions/message_action_creator');
          MessageActionCreator.undelete();
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
        var binding = self._binding[key];
        Mousetrap.bind(key, binding.action.bind(self));
        if (Array.isArray(binding.alias)) {
          binding.alias.forEach(function (alias) {
            Mousetrap.bind(alias, binding.action.bind(self));
          });
        }
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
