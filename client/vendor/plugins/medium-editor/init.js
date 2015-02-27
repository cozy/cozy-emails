//jshint browser: true
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.mediumeditor = {
  name: "medium-editor",
  type: "editor",
  active: false,
  onAdd: {
    condition: function (node) {
      "use strict";
      return node.querySelector('.rt-editor') !== null;
    },
    action: function (node) {
      /* eslint no-unused-vars: 0 */
      "use strict";
      var editorNode = node.querySelector('.rt-editor'),
          medium;
      if (!editorNode.classList.contains('medium-editor')) {
        medium = new window.MediumEditor(editorNode);
        editorNode.classList.add('medium-editor');
      }
    }
  }
};
