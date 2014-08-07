###
    Routing component. We let Backbone handling browser stuff
    and we format the varying parts of the layout.

    URLs are built in the following way:
        - a first part that represents the left panel
        - a second part that represents the right panel
        - if there is just one part, it represents a full width panel

    Since Backbone.Router only handles one part, routes initialization mechanism
    is overriden so we can post-process the second part of the URL.

    Example: a defined pattern will generates two routes.
        - `mailbox/a/path/:id`
        - `mailbox/a/path/:id/*rightPanel`

        Each pattern is actually the pattern itself plus the pattern and
        another pattern.

    Currently, only one parameter is supported per pattern.
###

module.exports = class Router extends Backbone.Router

    patterns:
        'mailbox.config':
            pattern: 'mailbox/:id/config'
            fluxAction: 'showConfigMailbox'
        'mailbox.new':
            pattern: 'mailbox/new'
            fluxAction: 'showCreateMailbox'
        'mailbox.emails':
            pattern: 'mailbox/:id'
            fluxAction: 'showEmailList'
        'email':
            pattern: 'email/:id'
            fluxAction: 'showEmailThread'
        'compose':
            pattern: 'compose'
            fluxAction: 'showComposeNewEmail'

    # default route
    routes: '': 'mailbox.emails'

    previous: null
    current: null

    # we store a regexified version of each patterns
    cachedPatterns: []

    initialize: (options) ->

        # defines the routes from the patterns
        for key, route of @patterns

            # caches each regex' pattern to avoid to recalculate them each time
            @cachedPatterns.push
                key: key
                pattern: @_routeToRegExp route.pattern

            # each pattern has two routes: full-width or with a right panel
            @routes[route.pattern] = key
            @routes["#{route.pattern}/*rightPanel"] = key

        # Backbone's magic
        @_bindRoutes()

        # Updates the LayoutStore for each matched request
        @flux = options.flux
        @flux.router = @
        @on 'route', (name, args) =>
            [leftPanelInfo, rightPanelInfo] = @_processSubRouting name, args

            leftAction = @fluxActionFactory leftPanelInfo
            rightAction = @fluxActionFactory rightPanelInfo

            @previous = @current
            @current = leftPanel: leftPanelInfo, rightPanel: rightPanelInfo

            if leftAction?
                leftAction leftPanelInfo, 'left'

            if rightAction?
                rightAction rightPanelInfo, 'right'
            @trigger 'fluxRoute', @current


    ###
        Gets the Flux action to execute given a panel info.
    ###
    fluxActionFactory: (panelInfo) ->

        fluxAction = null
        pattern = @patterns[panelInfo?.action]

        if pattern?
            fluxAction = @flux.actions.layout[pattern.fluxAction]

            if not fluxAction?
                console.warn "`#{pattern.fluxAction}` method not found in layout actions."

            return fluxAction


    ###
        Extracts and matches the second part of the URl if it exists.
    ###
    _processSubRouting: (name, args) ->
        [leftPanelInfo, rightPanelInfo] = args

        # if the first panel route doesn't have a parameter or if it,
        # the rightPanelInfo is its first parameter.
        # Otherwise, leftPanelInfo is the parameter value.
        isNumber = /[0-9]+/.test leftPanelInfo
        if not rightPanelInfo? and leftPanelInfo? and \
           leftPanelInfo.indexOf(':') is -1
            rightPanelInfo = leftPanelInfo

        # check all the routes for the second part of the URL
        route = _.first _.filter @cachedPatterns, (element) ->
            return element.pattern.test rightPanelInfo

        # if a route has been found, we format it
        if route?
            args = @_extractParameters route.pattern, rightPanelInfo
            rightPanelInfo = action: route.key, parameter: args[0]
        else
            rightPanelInfo = null

        # normalize the leftPanelInfo
        leftPanelInfo = action: name, parameter: leftPanelInfo

        return [leftPanelInfo, rightPanelInfo]


    ###
        Builds a route from panel information.
        Two modes:
            - options has leftPanel and/or rightPanel attributes with the
              panel(s) information.
            - options has the panel information along a `direction` attribute
              that can be `left` or `right`. It's the short version.
    ###
    buildUrl: (options) ->

        # Loads the panel from the options or the current router status to keep
        # track of current URLs
        if options.leftPanel? or options.rightPanel?
            leftPanelInfo = options.leftPanel or @current.leftPanel
            rightPanelInfo = options.rightPanel or @current.rightPanel
        else
            # Handles short version
            if options.direction?
                if options.direction is 'left'
                    leftPanelInfo = options
                    rightPanelInfo = @current.rightPanel
                else if options.direction is 'right'
                    leftPanelInfo = @current.leftPanel
                    rightPanelInfo = options
                else
                    console.warn '`direction` should be `left`, `right`.'
            else
                console.warn '`direction` parameter is mandatory when using short call.'

        # if the `fullWidth` parameter is set, it ignores the right panel info
        if (options.leftPanel? or options.direction is 'left') and options.fullWidth
            if options.leftPanel? or options.direction is 'right'
                console.warn "You shouldn't use the fullWidth option with a right panel"
            rightPanelInfo = null

        # Actual building
        leftPart = @_getURLFromCurrentRoute leftPanelInfo
        rightPart = @_getURLFromCurrentRoute rightPanelInfo

        url = "##{leftPart}"
        if rightPart? and rightPart.length > 0
            url = "#{url}/#{rightPart}"

        return url


    ###
        Closes a panel given a direction. If a full-width panel is closed,
        the URL points to the default route.
    ###
    buildClosePanelUrl: (direction) ->

        # If a left panel is closed, the right panel becomes full-width.
        # If a full-width panel is closed, `@current.rightPanel` is null and
        # the default route is loaded.
        if direction is 'left' or direction is 'full'
            panelInfo = @current.rightPanel
        else
            panelInfo = @current.leftPanel

        if panelInfo?
            panelInfo.direction = 'left'
            panelInfo.fullWidth = true
            return @buildUrl panelInfo
        else
            return '#' # loads the default route


    # Builds the URL string from a route. Only handles routes with
    # the `:id` named parameter or no parameter.
    _getURLFromCurrentRoute: (panel) ->
        if panel?
            pattern = @patterns[panel.action].pattern

            if panel.action is 'mailbox.emails' and not panel.parameter?
                defaultMailbox = @flux.store('MailboxStore').getDefault()
                if defaultMailbox?
                    panel.parameter = defaultMailbox.id
                else
                    panel.parameter = null

            partURL = pattern.replace ':id', panel.parameter

            return partURL
        else
            return ''
