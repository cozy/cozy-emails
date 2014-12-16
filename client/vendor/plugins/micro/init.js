//jshint browser: true, strict: false
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
var frame;
window.plugins.microdata = {
  name: "MicroData parser",
  active: false,
  onAdd: {
    /**
     * Should return true if plugin applies on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    condition: function (node) {
      return node.querySelector('iframe.content') !== null;
    },
    /**
     * Perform action on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    action: function (node) {
      var actions = [];
      frame = node.querySelector('iframe.content');
      function onload(e) {
        var doc   = frame.contentWindow.document,
            items = doc.getItems();
        function parseItem(item) {
          var props = item.properties;
          //console.log(item.itemType.value, item.properties);
          [].slice.call(props).forEach(function (e) {
            var prop   = props[e.itemProp.value],
                values = prop.getValues();
            //console.log(e.itemProp.value, values);
            values.forEach(function (val) {
              if (val instanceof Element) {
                parseItem(val);
              }
            });
          });
          if (item.itemType.value === 'http://schema.org/ViewAction') {
            var action = {};
            ['name', 'url'].forEach(function (key) {
              action[key] = item.properties[key].getValues().shift();
            });
            actions.push(action);
          }
        }
        [].slice.call(items).forEach(parseItem);
        if (actions.length > 0) {
          var container = document.querySelector('.messageToolbox + .row');
          var actionbar = document.createElement('div');
          actionbar.classList.add('content-action');
          actions.forEach(function (action) {
            var a = document.createElement('a');
            a.classList.add('btn');
            a.classList.add('btn-default');
            a.target = '_blank';
            a.href        = action.url;
            a.textContent = action.name;
            actionbar.appendChild(a);
          });
          container.insertBefore(actionbar, container.firstChild);
        }
      }
      frame.addEventListener('load', onload);
    }
  },
  onDelete: {
    /**
     * Should return true if plugin applies on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    condition: function (node) {
      //return node.querySelector('iframe.content') !== null;
      return false;
    },
    /**
     * Perform action on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    action: function (node) {
      console.log('Del', node);
    }
  },
  /**
   * Called when plugin is activated
   */
  onActivate: function () {
    //console.log('Plugin sample activated');
  },
  /**
   * Called when plugin is deactivated
   */
  onDeactivate: function () {
    //console.log('Plugin sample deactivated');
  },
  listeners: {
    'VIEW_ACTION': function (params) {
      //console.log('Got View action', params.detail);
    }
  }
};
