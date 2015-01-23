//jshint browser: true, strict: false
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.microdata = {
  name: "MicroData parser",
  active: false,
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
    'MESSAGE_LOADED': function (params) {
      if (typeof document.getItems === 'undefined') {
        // @TODO Add Polyfill
        return;
      }
      var parser, html, doc, items, actions = [];
      parser = new DOMParser();
      html   = "<html><head></head><body>" + params.detail.html + "</body></html>";
      doc    = parser.parseFromString(html, "text/html");
      items  = doc.getItems();
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
  }
};
