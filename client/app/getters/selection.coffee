
reduxStore = require '../reducers/_store'
RouterGetter = require './router'

module.exports =

    isAllSelected: ->
        reduxStore.getState().get('selection').allSelected

    getSelection: ->
        messages = RouterGetter.getMessagesList()


        if @isAllSelected() and messages?.size
            messages = messages.map (message) -> message.get('id')
            return messages?.toArray()

        else
            return reduxStore.getState().get('selection').selected.toArray()
