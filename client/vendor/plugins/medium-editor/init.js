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
          medium,
          options;
      options = {
        imageDragging: false, // We handle image drag'n'drop ourself
        cleanPastedHTML: true,
        static: true,
        targetBlank: true,
        toolbar: {
          buttons: ['bold', 'italic', 'underline', 'anchor', 'h2', 'h3']
        }
      }
      if (!editorNode.classList.contains('medium-editor')) {
        medium = new window.MediumEditor(editorNode, options);
        editorNode.classList.add('medium-editor');
      }
    }
  }
};
