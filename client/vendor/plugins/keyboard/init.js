//jshint browser: true, strict: false
/*global require, Mousetrap */
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
      help.innerHTML += "<dt><kbd>" + name.join(', ') + "&nbsp;: </kbd></dt><dd>" + binding.name + "</dd>";
    });
    container.appendChild(help);
    container.classList.add('mailkeys-container');
    help.classList.add('mailkeys-help');
    document.body.appendChild(container);
    function closeHelp(e) {
      document.body.removeChild(container);
      Mousetrap.unbind("esc");
    }
    container.addEventListener('click', closeHelp);
    Mousetrap.bind("esc", closeHelp);
  }
  function layoutWidth(direction) {
    if (direction !== 1 && direction !== -1) {
      direction = 1;
    }
    var layoutStore  = require('stores/layout_store'),
        layoutAction = require('actions/layout_action_creator'),
        disposition  = layoutStore.getDisposition();
    layoutAction.setDisposition('vertical', disposition.width - direction);
    /*
    var panels, w1;
    panels = document.querySelectorAll('#panels > .panel');
    function updateClass(panel, nb) {
      var cl, res;
      cl = Array.prototype.slice.call(panel.classList).filter(function (c) {
        return c.substr(0, 6) === 'col-md';
      })[0];
      panel.classList.remove(cl);
      res = (parseInt(cl.split('-')[2], 10) + nb);
      panel.classList.add('col-md-' + res);
      return res;
    }
    w1 = updateClass(panels[0], -1 * direction);
    updateClass(panels[1], 1 * direction);
    panels[1].style.left = (100 / 12 * w1) + '%';
    */
  }
  function layoutHeight(direction) {
    if (direction !== 1 && direction !== -1) {
      direction = 1;
    }
    var layoutStore  = require('stores/layout_store'),
        layoutAction = require('actions/layout_action_creator'),
        disposition  = layoutStore.getDisposition();
    layoutAction.setDisposition('horizontal', disposition.height - direction);
    /*
    var panels;
    panels = document.querySelectorAll('#panels > .panel');
    function updateClass(panel, nb) {
      var cl, res;
      cl = Array.prototype.slice.call(panel.classList).filter(function (c) {
        return c.substr(0, 4) === 'row-';
      })[0];
      panel.classList.remove(cl);
      res = (parseInt(cl.split('-')[1], 10) + nb);
      panel.classList.add('row-' + res);
      cl = Array.prototype.slice.call(panel.classList).filter(function (c) {
        return c.substr(0, 11) === 'row-offset-';
      })[0];
      if (cl) {
        panel.classList.remove(cl);
        res = (parseInt(cl.split('-')[2], 10) - nb);
        panel.classList.add('row-offset-' + res);
      }
      return res;
    }
    var height = updateClass(panels[0], -1 * direction);
    updateClass(panels[1], 1 * direction);
    require('actions/layout_action_creator').setDisposition('vertical', height);
    */
  }
  function menuNavigate() {
    var links, prev, next;
    links = Array.prototype.slice.call(document.querySelectorAll('#menu .mailbox-list a[href]'));
    links.some(function (item, e) {
      if (item.parentNode.classList.contains('active') && item.parentNode.parentNode.parentNode.classList.contains('active')) {
        prev = links[e - 1];
        next = links[e + 1];
        return true;
      } else {
        return false;
      }
    });
    return [prev, next];
  }
  root.mailkeys = {
    _binding: {
      'enter': {
        name: "Display current message",
        action: function (e) {
          if (window.cozyMails.getCurrentActions().indexOf('account.mailbox.messages') === 0 &&
             ['INPUT', 'BUTTON'].indexOf(document.activeElement.tagName) === -1) {
            e.preventDefault();
            window.cozyMails.messageDisplay();
          }
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
      'h': {
        name: "Previous mailbox",
        action: function (e) {
          e.preventDefault();
          var prev = menuNavigate()[0];
          if (prev) {
            window.location = prev.href;
          } else {
            prev = document.querySelector('#account-list > li.active').previousElementSibling.querySelector('a.account');
            if (prev) {
              window.location = prev.href;
            }
          }
        }
      },
      'l': {
        name: "Next mailbox",
        action: function (e) {
          e.preventDefault();
          var next = menuNavigate()[1];
          if (next) {
            window.location = next.href;
          } else {
            next = document.querySelector('#account-list > li.active').nextElementSibling.querySelector('a.account');
            if (next) {
              window.location = next.href;
            }
          }
        }
      },
      'j': {
        name: "Next Message",
        alias: ['down'],
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('next');
        }
      },
      'right': {
        name: "Next Message in conversation",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('next', true);
        }
      },
      'k': {
        name: "Previous Message",
        alias: ['up'],
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('prev');
        }
      },
      'left': {
        name: "Previous Message in conversation",
        action: function (e) {
          e.preventDefault();
          window.cozyMails.messageNavigate('prev', true);
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
      'alt+left': {
        name: 'Increase message layout width',
        action: function (e) {
          e.preventDefault();
          layoutWidth(1);
        }
      },
      'alt+right': {
        name: 'Decrease message layout width',
        action: function (e) {
          e.preventDefault();
          layoutWidth(-1);
        }
      },
      'alt+up': {
        name: 'Increase message layout height',
        action: function (e) {
          e.preventDefault();
          layoutHeight(1);
        }
      },
      'alt+down': {
        name: 'Decrease message layout height',
        action: function (e) {
          e.preventDefault();
          layoutHeight(-1);
        }
      },
      'f': {
        name: "Toggle fullscreen",
        action: function (e) {
          e.preventDefault();
          require('actions/layout_action_creator').toggleFullscreen();
        }
      },
      'w': {
        name: "Toggle layout",
        action: function (e) {
          e.preventDefault();
          var layoutStore  = require('stores/layout_store'),
              layoutAction = require('actions/layout_action_creator'),
              disposition  = layoutStore.getDisposition();

          switch (disposition.type) {
          case 'horizontal':
            layoutAction.setDisposition('three');
            break;
          case 'vertical':
            layoutAction.setDisposition('horizontal');
            break;
          case 'three':
            layoutAction.setDisposition('vertical');
            break;
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
      'r': {
        name: 'Reply',
        action: function () {
          var current, btn;
          Array.prototype.forEach.call(document.querySelectorAll('.row > .content, .row > .preview'), function (e) {
            var rect = e.getBoundingClientRect(),
                visible = rect.bottom >= 0 && rect.top <= (window.innerHeight || document.documentElement.clientHeight)
            if (visible) {
              current = e;
            }
          });
          if (typeof current !== 'undefined') {
            btn = document.querySelector(".thread li.message[data-id='" + current.dataset.messageId + "'] button.btn.reply");
            if (btn !== null) {
                btn.dispatchEvent(new MouseEvent('click', { 'view': window, 'bubbles': true, 'cancelable': true }));
            }
          }
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
    onHelp: bindingHelp,
    listeners: {
    }
  };
})(window.plugins);
