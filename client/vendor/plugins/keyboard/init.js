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
    var self = this,
        container = document.createElement('div'),
        help = document.createElement('dl');
    Object.keys(this._binding).forEach(function (key) {
      help.innerHTML += "<dt>" + key + "</dt><dd>" + self._binding[key].name + "</dd>";
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
      'j': {
        name: "Next Message",
        action: function () {window.cozyMails.messageNavigate('next'); }
      },
      'down': {
        name: "Next Message",
        action: function () {window.cozyMails.messageNavigate('next'); }
      },
      'k': {
        name: "Previous Message",
        action: function () {window.cozyMails.messageNavigate('prev'); }
      },
      'up': {
        name: "Previous Message",
        action: function () {window.cozyMails.messageNavigate('prev'); }
      },
      'n': {
        name: "New message",
        action: bindingNew
      },
      '?': {
        name: "Display available bindings",
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
