module.exports = TooltipRefresherMixin =


    # AriaTips must bind the elements declared as tooltip to their
    # respective tooltip when the component is mounted (DOM elements exist).
    componentDidMount: ->
        AriaTips.bind()


    # AriaTips must bind the elements declared as tooltip to their
    # respective tooltip, each time the application component (the root)
    # is updated to make sure new tooltips are also bound.
    componentDidUpdate: ->
        AriaTips.bind()
