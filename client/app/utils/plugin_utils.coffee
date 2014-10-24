module.exports =

    init: ->
        if not window.plugins?
            window.plugins = {}

        for own pluginName, pluginConf of window.plugins
            if pluginConf.active
                @activate pluginName

        if MutationObserver?

            config =
                attributes: false
                childList: true
                characterData: false
                subtree: true

            onMutation = (mutations) ->
                checkNode = (node, action) ->
                    if node.nodeType isnt Node.ELEMENT_NODE
                        return

                    for own pluginName, pluginConf of window.plugins
                        if pluginConf.active
                            listener = pluginConf.onAdd if action is 'add'
                            listener = pluginConf.onDelete if action is 'delete'
                            if listener? and
                            listener.condition.bind(pluginConf)(node)
                                listener.action.bind(pluginConf)(node)

                check = (mutation) ->

                    nodes = Array.prototype.slice.call mutation.addedNodes
                    checkNode node, 'add' for node in nodes

                    nodes = Array.prototype.slice.call mutation.removedNodes
                    checkNode node, 'del' for node in nodes

                check mutation for mutation in mutations

            # Observes DOM mutation to see if a plugin should be called
            observer = new MutationObserver onMutation
            observer.observe document, config

        else
            # Dirty fallback for IE
            # @TODO use polyfill ???
            setInterval ->
                for own pluginName, pluginConf of window.plugins
                    if pluginConf.active
                        if pluginConf.onAdd?
                            if pluginConf.onAdd.condition.bind(pluginConf)(document.body)
                                pluginConf.onAdd.action.bind(pluginConf)(document.body)
                        if pluginConf.onDelete?
                            if pluginConf.onDelete.condition.bind(pluginConf)(document.body)
                                pluginConf.onDelete.action.bind(pluginConf)(document.body)

            , 200

    activate: (key) ->
        plugin = window.plugins[key]
        type   = plugin.type
        plugin.active = true

        # Add custom events listeners
        if plugin.listeners?
            for own event, listener of plugin.listeners
                window.addEventListener event, listener.bind(plugin)

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

    merge: (remote) ->
        for own pluginName, pluginConf of remote
            local = window.plugins[pluginName]
            if local?
                local.active = pluginConf.active
            else
                delete remote[pluginName]

        for own pluginName, pluginConf of window.plugins
            if not remote[pluginName]?
                remote[pluginName] =
                    name: pluginConf.name
                    active: pluginConf.active

