//jshint browser: true, strict: false
require('./baguetteBox.css');

var baguetteBox = require('./baguetteBox.js');

if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.gallery = {
  name: "Gallery",
  active: true,
  getImages: function (node) {
    if (typeof node === 'undefined') {
      node = document;
    }
    return node.querySelectorAll("[data-file-url$=jpg], [data-file-url$=png]");
  },
  addGallery: function (params) {
    var images, gal;
    images = this.getImages();
    if (images.length > 0) {
      gal = document.getElementById('gallery');
      if (gal === null) {
        gal = document.createElement('div');
        gal.id = "gallery";
        gal.style.display = "none";
        document.body.appendChild(gal);
      } else {
        gal.innerHTML = '';
      }
      Array.prototype.forEach.call(images, function (elmt, idx) {
        var a, img, icon;
        a = document.createElement('a');
        a.href = elmt.dataset.fileUrl;
        img = document.createElement('img');
        a.appendChild(img);
        gal.appendChild(a);
        if (elmt.parentNode.querySelectorAll("[data-gallery]").length === 0) {
          icon = document.createElement('a');
          icon.style.paddingLeft = '.5em';
          icon.innerHTML = "<i class='fa fa-eye' data-gallery></i>";
          icon.addEventListener('click', function () {
            var event = document.createEvent("MouseEvent");
            event.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
            a.dispatchEvent(event);
          });
          if (elmt.nextElementSibling) {
            elmt.parentNode.insertBefore(icon, elmt.nextElementSibling);
          } else {
            elmt.parentNode.appendChild(icon);
          }
        }
      });
      baguetteBox.run('#gallery', {
        captions: true,       // true|false - Display image captions
        buttons: 'auto',      // 'auto'|true|false - Display buttons
        async: false,         // true|false - Load files asynchronously
        preload: 2,           // [number] - How many files should be preloaded from current image
        animation: 'slideIn'  // 'slideIn'|'fadeIn'|false - Animation type
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
      return this.getImages(node).length > 0;
    },
    /**
     * Perform action on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    action: function (node) {
      this.addGallery();
    }
  },
  onDelete: {
    condition: function (node) {
      return this.getImages(node).length > 0;
    },
    action: function (node) {
      this.addGallery();
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
      this.addGallery();
    }
  }
};
