RouterGetter = require './router'

module.exports =

    isAllSelected: (state) ->
        state.get('selection').allSelected

    getSelection: (state) ->
        messages = RouterGetter.getMessagesList(state)

        if @isAllSelected(state) and messages?.size
            messages = messages.map (message) -> message.get('id')
            return messages?.toArray()

        else
            return state.get('selection').selected.toArray()
