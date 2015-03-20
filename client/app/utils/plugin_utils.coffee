helpers =
    # Display a Bootstrap modal window
    #
    # Available options:
    # title: modal window title
    # body: modal window body
    # size: null, 'small' or 'large'
    # show: if not false, show modal
    modal: (options) ->
        win = document.createElement 'div'
        win.classList.add 'modal'
        win.classList.add 'fade'
        win.innerHTML = """
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal"
                            aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                    <h4 class="modal-title"></h4>
                </div>
                <div class="modal-body"> </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default"
                            data-dismiss="modal">#{t 'plugin modal close'}
                    </button>
                </div>
            </div>
        </div>
        """
        if options.title?
            win.querySelector('.modal-title').innerHTML = options.title
        if options.body?
            if typeof options.body is 'string'
                win.querySelector('.modal-body').innerHTML = options.body
            else
                win.querySelector('.modal-body').appendChild options.body
        if options.size is 'small'
            win.querySelector('.modal-dialog').classList.add 'modal-sm'
        if options.size is 'large'
            win.querySelector('.modal-dialog').classList.add 'modal-lg'
        if options.show isnt false
            document.body.appendChild win
            window.jQuery(win).modal 'show'
        return win

module.exports =

    init: ->
        if not window.plugins?
            window.plugins = {}

        # Observe addition and deletion of plugins
        #if Object.observe?
        #    Object.observe window.plugins, (changes) =>
        #        changes.forEach (change) =>
        #            if change.type is 'add'
        #                @activate change.name
        #            else if change.type is 'delete'
        #                @deactivate change.name

        window.plugins.helpers = helpers

        # Init every plugins
        Object.keys(window.plugins).forEach (pluginName) =>
            pluginConf = window.plugins[pluginName]
            if pluginConf.url?
                onLoad = =>
                    @activate pluginName
                @loadJS pluginConf.url, onLoad
            else
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
        try
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

            event = new CustomEvent('plugin',
                detail:
                    action: 'activate'
                    name: key
            )
            window.dispatchEvent event
        catch e
            console.log "Unable to activate plugin #{key}: #{e}"

    deactivate: (key) ->
        try
            plugin = window.plugins[key]
            plugin.active = false

            # remove custom events listeners
            if plugin.listeners?
                for own event, listener of plugin.listeners
                    window.removeEventListener event, listener

            if plugin.onDeactivate
                plugin.onDeactivate()

            event = new CustomEvent('plugin',
                detail:
                    action: 'deactivate'
                    name: key
            )
            window.dispatchEvent event
        catch e
            console.log "Unable to deactivate plugin #{key}: #{e}"

    merge: (remote) ->
        for own pluginName, pluginConf of remote
            local = window.plugins[pluginName]
            if local?
                local.active = pluginConf.active
            else
                if pluginConf.url?
                    window.plugins[pluginName] = pluginConf
                else
                    delete remote[pluginName]

        for own pluginName, pluginConf of window.plugins
            if not remote[pluginName]?
                remote[pluginName] =
                    name: pluginConf.name
                    active: pluginConf.active

    loadJS: (url, onLoad) ->
        script = document.createElement 'script'
        script.type  = 'text/javascript'
        script.async = true
        script.src   = url
        if onLoad?
            script.addEventListener 'load', onLoad
        document.body.appendChild script

    load: (url) ->
        # Get absolute path of this script, allowing to load plugins relatives
        # to it
        unless /:\/\//.test(url)
            try
                throw new Error()
            catch e
                base = e.stack.split('\n')[0].split('@')[1].split(/:\d/)[0].split('/').slice(0, -2).join('/')
                url = base + '/' + url + '/'

        xhr = new XMLHttpRequest()
        xhr.open 'GET', url, true
        xhr.onload = ->
            parser = new DOMParser()
            doc = parser.parseFromString(xhr.response, 'text/html')
            if doc
                # Chrome doesn't like to iterate on doc.styleSheets
                Array::forEach.call doc.querySelectorAll('style'), (sheet) ->
                    style = document.createElement('style')
                    document.body.appendChild style
                    Array::forEach.call sheet.sheet.cssRules, (rule, id) ->
                        style.sheet.insertRule rule.cssText, id

                Array::forEach.call doc.querySelectorAll('script'), (script) ->
                    s = document.createElement('script')
                    s.textContent = script.textContent
                    document.body.appendChild s

            xhr.send()
