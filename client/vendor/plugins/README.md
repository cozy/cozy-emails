# Plugins

Each plugin folder should contain a `_init.js` or `_init.coffee` file that register the plugin.

Registering the plugin only require to add an object to `window.plugins` with the following fields:

 - name: string, mandatory
 - active: boolean, mandatory
 - type: only one plugin of each type can be active at the same time
 - onAdd: functions called everytime a node is added to the DOM
 - onActivate: called when plugin is activated
 - onDeactivate: called when plugin is deActivated

Only one plugin of each type can be active at the same time. So to prevent conflicts, conflicting plugin must use the same type. For example, all available rich text editors use `type: "editor"`, so when one is choosen, the others are deactivated
