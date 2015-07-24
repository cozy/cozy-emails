//jshint browser: true, strict: false
/*global require, Mousetrap */
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
(function (root) {
  "use strict";
  function bindingNew(e) {
    if (e && e instanceof Event) { e.preventDefault(); }
    window.cozyMails.messageNew();
  }
  function bindingHelp() {
    var container, help;
    container = document.getElementById('mailkeysHelp');
    if (container) {
      document.body.removeChild(container);
      return;
    }
    container = document.createElement('div');
    help      = document.createElement('dl');
    container.id = 'mailkeysHelp';
    Object.keys(root.mailkeys._binding).forEach(function (key) {
      var binding = root.mailkeys._binding[key],
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
  function layoutRatio(direction) {
    var layoutAction = require('actions/layout_action_creator');
    if (direction > 0) {
      layoutAction.increasePreviewPanel(direction);
    } else if (direction < 0) {
      layoutAction.decreasePreviewPanel(direction);
    } else {
      layoutAction.resetPreviewPanel();
    }
  }
  function mailAction(action) {
    var current, btn;
    Array.prototype.forEach.call(document.querySelectorAll('article.message .content, article.message .preview'), function (e) {
      var rect = e.getBoundingClientRect(),
          visible = rect.bottom >= 0 && rect.top <= (window.innerHeight || document.documentElement.clientHeight);
      if (visible) {
        current = e;
      }
    });
    if (typeof current !== 'undefined') {
      btn = document.querySelector("section.conversation article.message[data-id='" + current.dataset.messageId + "'] button.btn.mail-" + action);
      if (btn !== null) {
        btn.dispatchEvent(new MouseEvent('click', { 'view': window, 'bubbles': true, 'cancelable': true }));
      }
    }
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
          var btnConfirm = document.querySelector('.modal .modal-footer .modal-action');
          if (btnConfirm !== null) {
            btnConfirm.dispatchEvent(new MouseEvent('click', { 'view': window, 'bubbles': true, 'cancelable': true }));
          } else {
            if (window.cozyMails.getCurrentActions().indexOf('account.mailbox.messages') === 0 &&
               ['INPUT', 'BUTTON'].indexOf(document.activeElement.tagName) === -1) {
              if (e && e instanceof Event) { e.preventDefault(); }
              window.cozyMails.messageDisplay();
            }
          }
        }
      },
      'esc': {
        name: "Close current message",
        alias: ['x'],
        action: function (e) {
          var btnClose = document.querySelector('.modal .modal-header button.close');
          if (btnClose !== null) {
            btnClose.dispatchEvent(new MouseEvent('click', { 'view': window, 'bubbles': true, 'cancelable': true }));
          } else {
            if (e && e instanceof Event) { e.preventDefault(); }
            window.cozyMails.messageClose();
          }
        }
      },
      'h': {
        name: "Previous mailbox",
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
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
          if (e && e instanceof Event) { e.preventDefault(); }
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
          if (e && e instanceof Event) { e.preventDefault(); }
          window.cozyMails.messageNavigate('next');
        }
      },
      'right': {
        name: "Next Message in conversation",
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          window.cozyMails.messageNavigate('next', true);
        }
      },
      'k': {
        name: "Previous Message",
        alias: ['up'],
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          window.cozyMails.messageNavigate('prev');
        }
      },
      'left': {
        name: "Previous Message in conversation",
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          window.cozyMails.messageNavigate('prev', true);
        }
      },
      'ctrl+down': {
        name: 'Scroll message down',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          var panel = document.querySelector("#panels > .panel:nth-of-type(2)");
          if (panel) {
            panel.scrollTop += panel.clientHeight * 0.8;
          }
        }
      },
      '(': {
        name: 'Increase message layout size',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          layoutRatio(1);
        }
      },
      'alt+(': {
        name: 'Increase by 10 message layout size',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          layoutRatio(10);
        }
      },
      ')': {
        name: 'Decrease message layout size',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          layoutRatio(-1);
        }
      },
      'alt+)': {
        name: 'Decrease by 10 message layout size',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          layoutRatio(-10);
        }
      },
      '=': {
        name: 'Reset message layout size',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          layoutRatio();
        }
      },
      'F': {
        name: "Toggle fullscreen",
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          require('actions/layout_action_creator').toggleFullscreen();
        }
      },
      'w': {
        name: "Toggle layout",
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          var layoutStore  = require('stores/layout_store'),
              layoutAction = require('actions/layout_action_creator'),
              dispositions = require('constants/app_constants').Dispositions;

          switch (layoutStore.getDisposition()) {
          case dispositions.RROW:
            layoutAction.setDisposition(dispositions.COL);
            break;
          case dispositions.COL:
            layoutAction.setDisposition(dispositions.ROW);
            break;
          case dispositions.ROW:
            layoutAction.setDisposition(dispositions.RROW);
            break;
          }

        }
      },
      'ctrl+up': {
        name: 'Scroll message up',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          var panel = document.querySelector("#panels > .panel:nth-of-type(2)");
          if (panel) {
            panel.scrollTop -= panel.clientHeight * 0.8;
          }
        }
      },
      'n': {
        alias: ['ctrl+n'],
        name: "New message",
        action: bindingNew
      },
      'd': {
        name: "Delete message",
        alias: ['backspace', 'del'],
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          window.cozyMails.messageDeleteCurrent();
        }
      },
      'ctrl+z': {
        name: 'Undelete message',
        alias: ['u'],
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          var MessageActionCreator = window.require('actions/message_action_creator');
          MessageActionCreator.undelete();
        }
      },
      'r': {
        name: 'Reply',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          mailAction('reply');
        }
      },
      'g': {
        name: 'Reply all',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          mailAction('reply-all');
        }
      },
      'f': {
        name: 'Forward',
        action: function (e) {
          if (e && e instanceof Event) { e.preventDefault(); }
          mailAction('forward');
        }
      },
      '?': {
        name: "Toggle display of available bindings",
        action: bindingHelp
      }
    },
    name: "Keyboard shortcuts",
    active: true,
    /*
     * Called when plugin is activated
     */
    onActivate: function () {
      Object.keys(root.mailkeys._binding).forEach(function (key) {
        var binding = root.mailkeys._binding[key];
        Mousetrap.bind(key, binding.action.bind(root.mailkeys));
        if (Array.isArray(binding.alias)) {
          binding.alias.forEach(function (alias) {
            Mousetrap.bind(alias, binding.action.bind(root.mailkeys));
          });
        }
      });
    },
    /*
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
