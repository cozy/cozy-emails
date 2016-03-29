
_ = require 'lodash'

SelectionStore = require '../stores/selection_store'

class SelectionGetter

    getProps: (messages) ->
        selectAll = SelectionStore.getAllSelected()
        if selectAll and messages?.size
            selection = messages.map (message) -> message.get('id')
        else
            selection = SelectionStore.getSelected()

        return {
            selection: selection.toArray()
            isAllSelected: selectAll
        }


module.exports = new SelectionGetter()
