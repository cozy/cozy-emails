###
    Routing component. We let Backbone handling browser stuff
    and we format the varying parts of the layout.

    URLs are built in the following way:
        - a first part that represents the first panel
        - a second part that represents the second panel
        - if there is just one part, it represents a full width panel

    Since Backbone.Router only handles one part, routes initialization mechanism
    is overriden so we can post-process the second part of the URL.

    Example: a defined pattern will generates two routes.
        - `mailbox/a/path/:id`
        - `mailbox/a/path/:id/*secondPanel`

        Each pattern is actually the pattern itself plus the pattern itself and
        another pattern.
###

LayoutActionCreator = require '../actions/LayoutActionCreator'

module.exports = class Router extends Backbone.Router

    patterns: {}

    # default route
    routes: {}

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

            # each pattern has two routes: full-width or with a second panel
            @routes[route.pattern] = key
            @routes["#{route.pattern}/*secondPanel"] = key

        # Backbone's magic
        @_bindRoutes()

        # Updates the LayoutStore for each matched request
        @on 'route', (name, args) =>

            [firstPanelInfo, secondPanelInfo] = @_processSubRouting name, args

            firstAction = @fluxActionFactory firstPanelInfo
            secondAction = @fluxActionFactory secondPanelInfo

            @previous = @current
            @current = firstPanel: firstPanelInfo, secondPanel: secondPanelInfo

            if firstAction?
                firstAction firstPanelInfo, 'first'

            if secondAction?
                secondAction secondPanelInfo, 'second'
            @trigger 'fluxRoute', @current


    ###
        Gets the Flux action to execute given a panel info.
    ###
    fluxActionFactory: (panelInfo) ->

        fluxAction = null
        pattern = @patterns[panelInfo?.action]

        if pattern?
            fluxAction = LayoutActionCreator[pattern.fluxAction]

            if not fluxAction?
                console.warn "`#{pattern.fluxAction}` method not found in " + \
                             "layout actions."

            return fluxAction


    ###
        Extracts and matches the second part of the URl if it exists.
    ###
    _processSubRouting: (name, args) ->
        # removes the last argument which is always `null`, not sure why
        args.pop()

        # next comes the secondPanel url if it exists
        # or a firstPanel parameter if there is not secondPanel
        secondPanelString = args.pop()

        # if first panel number of expected params is bigger what is first
        # it means there are no second panel and that what we got before was a
        # parameter of the first panel
        params = @patterns[name].pattern.match(/:[\w]+/g) or []
        if params.length > args.length and secondPanelString?
            args.push secondPanelString
            secondPanelString = null

        firstPanelParameters = args

        # checks all the routes for the second part of the URL
        route = _.first _.filter @cachedPatterns, (element) ->
            return element.pattern.test secondPanelString

        # if a route has been found, we retrieve the params' value and format it
        if route?
            args = @_extractParameters route.pattern, secondPanelString
            # remove the last argument which is alway `null`, not sure why
            args.pop()
            secondPanelInfo = action: route.key, parameters: args
        else
            secondPanelInfo = null


        # normalizes the firstPanelInfo
        firstPanelInfo = action: name, parameters: firstPanelParameters
        return [firstPanelInfo, secondPanelInfo]


    ###
        Builds a route from panel information.
        Two modes:
            - options has firstPanel and/or secondPanel attributes with the
              panel(s) information.
            - options has the panel information along a `direction` attribute
              that can be `first` or `second`. It's the short version.
    ###
    buildUrl: (options) ->

        # Loads the panel from the options or the current router status to keep
        # track of current URLs
        if options.firstPanel? or options.secondPanel?
            firstPanelInfo = options.firstPanel or @current.firstPanel
            secondPanelInfo = options.secondPanel or @current.secondPanel
        else
            # Handles short version
            if options.direction?
                if options.direction is 'first'
                    firstPanelInfo = options
                    secondPanelInfo = @current.secondPanel
                else if options.direction is 'second'
                    firstPanelInfo = @current.firstPanel
                    secondPanelInfo = options
                else
                    console.warn '`direction` should be `first`, `second`.'
            else
                console.warn '`direction` parameter is mandatory when ' + \
                             'using short call.'

        # if the `fullWidth` parameter is set, it ignores the second panel info
        isFirstDirection = options.firstPanel? or options.direction is 'first'
        if isFirstDirection and options.fullWidth
            if options.secondPanel? and options.direction is 'second'
                console.warn "You shouldn't use the fullWidth option with " + \
                             "a second panel"
            secondPanelInfo = null

        # Actual building
        firstPart = @_getURLFromRoute firstPanelInfo
        secondPart = @_getURLFromRoute secondPanelInfo

        url = "##{firstPart}"
        if secondPart? and secondPart.length > 0
            url = "#{url}/#{secondPart}"

        return url


    ###
        Closes a panel given a direction. If a full-width panel is closed,
        the URL points to the default route.
    ###
    buildClosePanelUrl: (direction) ->

        # If a first panel is closed, the second panel becomes full-width.
        # If a full-width panel is closed, `@current.secondPanel` is null and
        # the default route is loaded.
        if direction is 'first' or direction is 'full'
            panelInfo = _.clone @current.secondPanel
        else
            panelInfo = _.clone @current.firstPanel

        if panelInfo?
            panelInfo.direction = 'first'
            panelInfo.fullWidth = true
            return @buildUrl panelInfo
        else
            return '#' # loads the default route


    # Builds the URL string from a route.
    _getURLFromRoute: (panel) ->
        # Clones the parameter because we are going to mutate it
        panel = _.clone panel

        if panel?
            pattern = @patterns[panel.action].pattern

            if panel.parameters? and not (panel.parameters instanceof Array)
                panel.parameters = [panel.parameters]

            # gets default values (if relevant) to ease `@buildUrl` usage
            if (defaultParameters = @_getDefaultParameters(panel.action))?
                # sets the parameters if they don't exist at all...
                if not panel.parameters? or panel.parameters.length is 0
                    panel.parameters = defaultParameters

                # ... or adds them in the relevant place if only some of them
                # are missing
                else
                    for defaultParameter, key in defaultParameters
                        if not panel.parameters[key]?
                            panel.parameters.splice key, 0, defaultParameter

            # we default to empty array if there is no parameter in the route
            parametersInPattern = pattern.match(/:[\w]+/gi) or []

            # the pattern is progressively filled with values
            filledPattern = pattern
            if panel.parameters
                for paramInPattern, key in parametersInPattern
                    paramValue = panel.parameters[key]
                    filledPattern = filledPattern.replace paramInPattern, \
                                                                    paramValue

            return filledPattern
        else
            return ''
