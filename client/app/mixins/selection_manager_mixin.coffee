NEED_GETSELECTABLES = """
    Components using selection_mananager should provide
    a getSelectables method
"""

module.exports =

    getInitialState: ->
        selected: Immutable.Set()
        allSelected: false

    componentWillReceiveProps: (props) ->
        throw new Error(NEED_GETSELECTABLES) unless @getSelectables

        # remove selected messages that are not in view anymore
        @setState
            allSelected: false
            selected: @state.selected.intersect @getSelectables props

    hasSelected: ->
        @state.selected.length > 0

    allSelected: ->
        @state.allSelected

    setNoneSelected: ->
        @setState
            allSelected: false,
            selected: Immutable.Set()

    setAllSelected: ->
        @setState
            allSelected: true,
            selected: Immutable.Set.from @getSelectables()

    addToSelected: (key) ->
        selected = @state.selected.add key
        allLength = @getSelectablesLength?() or @getSelectables().length
        @setState
            allSelected: selected.length is allLength
            selected: selected

    removeFromSelected: (key) ->
        @setState
            allSelected: false
            selected:  @state.selected.remove key

    getSelected: ->
        return @state.selected
