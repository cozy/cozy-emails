//jshint browser: true, strict: false
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.sample = {
  name: "Sample JS",
  active: false,
  onAdd: {
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
      console.log('Add', node);
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
