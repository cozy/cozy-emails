//jshint browser: true, strict: false
/*global require */
VCF = require('./js/vcardjs-0.3.js').VCF;

var ContactActionCreator = require('../../app/actions/contact_action_creator');


if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.vcard = {
  name: "VCard",
  active: true,
  getVCard: function (node) {
    if (typeof node === 'undefined') {
      node = document;
    }
    return node.querySelectorAll("[data-file-url$=vcf]");
  },
  render: function (params) {
    var cards;
    cards = this.getVCard();
    if (cards.length > 0) {
      Array.prototype.forEach.call(cards, function (elmt, idx) {
        var a, create;
        create = ContactActionCreator.createContact;
        function addAddress() {
            var req = new XMLHttpRequest();
            req.open("GET", elmt.dataset.fileUrl, true);
            req.onload = function (e) {
                VCF.parse(req.response, function (vcard) {
                    if (vcard.fn && Array.isArray(vcard.email)) {
                      vcard.email.forEach(function (m) {
                        var address = {
                          name: vcard.fn,
                          address: m.value
                        };
                        create(address);
                      });
                    }
                    console.log(vcard);
                });
            };
            req.send(null);
        }
        a = document.createElement('a');
        a.textContent = ' + ';
        a.addEventListener('click', addAddress);
        if (elmt.nextElementSibling) {
          elmt.parentNode.insertBefore(a, elmt.nextElementSibling);
        } else {
          elmt.parentNode.appendChild(a);
        }
      });
    }
  },
  onAdd: {
    /**
     * Should return true if plugin applies on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    condition: function (node) {
      return this.getVCard(node).length > 0;
    },
    /**
     * Perform action on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    action: function (node) {
      this.render();
    }
  },
  onDelete: {
    condition: function (node) {
      return this.getVCard(node).length > 0;
    },
    action: function (node) {
      this.render();
    }
  },
  /**
   * Called when plugin is activated
   */
  onActivate: function () {
  },
  /**
   * Called when plugin is deactivated
   */
  onDeactivate: function () {
  },
  listeners: {
    'load': function (params) {
      this.render();
    }
  }
};
