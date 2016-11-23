
_ = require 'lodash'

SearchStore = require '../stores/search_store'

module.exports =

    # Highlight search pattern in a string
    highlightSearch: (text) ->
        return [] unless text
        return [text] if SearchStore.getCurrentSearch() is ''

        search  = new RegExp SearchStore.getCurrentSearch(), 'gi'
        substrs = text.match search

        return [text] unless substrs

        text.split(search).reduce (memo, part, index) ->
            if part.length
                memo.push part
            if substrs[index]
                memo.push span className: 'hlt-search', substrs[index]
            return memo
        , []
