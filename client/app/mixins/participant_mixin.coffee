###
    Participant mixin.
###
{span, a, i} = React.DOM

ContactStore = require '../stores/contact_store'
ContactLabel = require '../components/contact_label'


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
