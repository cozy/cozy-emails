//jshint browser: true
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
          editor = new window.Minislate.simpleEditor([editorNode]);
    }
  }
};
