
_ = require 'lodash'

SelectionStore = require '../stores/selection_store'

class SelectionGetter

    isAllSelected: ->
        SelectionStore.getAllSelected()

    getSelection: (messages) ->
        if @isAllSelected() and messages?.size
            messages = messages.map (message) -> message.get('id')
            return messages.toArray()
        return SelectionStore.getSelected()?.toArray()

module.exports = new SelectionGetter()
