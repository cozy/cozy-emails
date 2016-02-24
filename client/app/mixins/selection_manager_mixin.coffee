Immutable = require 'immutable'

NEED_GETSELECTABLES = """
    Components using selection_mananager should provide
    a getSelectables method
"""

module.exports =

    getInitialState: ->
        selected: Immutable.Set()
        allSelected: false

    componentWillReceiveProps: (props, state) ->
        throw new Error(NEED_GETSELECTABLES) unless @getSelectables

        # remove selected messages that are not in view anymore
        @setState
            allSelected: false
            selected: @state.selected.intersect @getSelectables props, state

    hasSelected: ->
        @state.selected.size > 0

    allSelected: ->
        @state.allSelected

    setNoneSelected: ->
        @setState
            allSelected: false,
            selected: Immutable.Set()

    setAllSelected: ->
        @setState
            allSelected: true,
            selected: Immutable.Set @getSelectables().toArray()

    addToSelected: (key) ->
        selected = @state.selected.add key
        allLength = @getSelectablesLength?() or @getSelectables().size
        @setState
            allSelected: selected.size is allLength
            selected: selected

    removeFromSelected: (key) ->
        @setState
            allSelected: false
            selected:  @state.selected.remove key

    getSelected: ->
        @state.selected.toObject()
