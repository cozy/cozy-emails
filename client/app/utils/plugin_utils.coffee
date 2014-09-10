{PayloadSources} = require '../constants/app_constants'

module.exports =

    init: ->
        if not window.plugins?
            window.plugins = {}

        for own pluginName, pluginConf of window.plugins
            @activate pluginName

        if MutationObserver?
            # Observes DOM mutation to see if a plugin should be called
            observer = new MutationObserver (mutations) ->
                checkNode = (node) ->
                    if node.nodeType isnt Node.ELEMENT_NODE
                        return

                    for own pluginName, pluginConf of window.plugins
                        if pluginConf.active
                            if pluginConf.onAdd?
                                if pluginConf.onAdd.condition node
                                    pluginConf.onAdd.action node

                check = (mutation) ->
                    nodes = Array.prototype.slice.call mutation.addedNodes
                    checkNode node for node in nodes

                check mutation for mutation in mutations

            config =
                attributes: false
                childList: true
                characterData: false
                subtree: true
            observer.observe document.body, config

        else
            # Dirty fallback for IE
            # @TODO use polyfill ???
            setInterval ->
                for own pluginName, pluginConf of window.plugins
                    if pluginConf.active
                        if pluginConf.onAdd?
                            if pluginConf.onAdd.condition document.body
                                pluginConf.onAdd.action document.body

            , 200

    activate: (key) ->
        plugin = window.plugins[key]
        type   = plugin.type
        plugin.active = true

        # Add custom events listeners
        if plugin.listeners?
            for own event, listener of plugin.listeners
                window.addEventListener event, listener

        if plugin.onActivate
            plugin.onActivate()

        if type?
            for own pluginName, pluginConf of window.plugins
                if pluginName is key
                    continue
                if pluginConf.type is type and pluginConf.active
                    @deactivate pluginName

    deactivate: (key) ->
        plugin = window.plugins[key]
        plugin.active = false

        # remove custom events listeners
        if plugin.listeners?
            for own event, listener of plugin.listeners
                window.removeEventListener event, listener

        if plugin.onDeactivate
            plugin.onDeactivate()


