###
    Participant mixin.
###
_     = require 'underscore'
React = require 'react'

{span, a, i} = React.DOM

ContactLabel = React.createFactory require '../components/contact_label'

ContactStore = require '../stores/contact_store'


module.exports =
    formatUsers: (users) ->
        return unless users?

        if _.isArray users
            items = []
            for user in users
                items.push ContactLabel
                    contact: user
                    tooltip: true

                items.push ", " if user isnt _.last users
            return items
        else
            return ContactLabel
                contact: users
                tooltip: true
