//jshint browser: true
require('./css/minislate.css');

var Minislate = require('./js/minislate.js');


if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.minislate = {
  name: "MiniSlate",
  type: "editor",
  active: true,
  onAdd: {
    condition: function (node) {
      "use strict";
      return node.querySelector('.rt-editor') !== null;
    },
    action: function (node) {
      // jshint unused: false
      "use strict";
      var editorNode = node.querySelector('.rt-editor'),
          editor = new Minislate.simpleEditor([editorNode]);
    }
  }
};
