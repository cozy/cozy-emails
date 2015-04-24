###
    Participant mixin.
###
{span, a, i} = React.DOM

ContactStore = require '../stores/contact_store'


module.exports =
    formatUsers: (users) ->
        return unless users?

        format = (user) ->
            items = []
            if user.name
                key = user.address.replace /\W/g, ''
                items.push "#{user.name} "
                items.push span className: 'contact-address', key: key,
                    i className: 'fa fa-angle-left'
                    user.address
                    i className: 'fa fa-angle-right'
            else
                items.push user.address
            return items

        if _.isArray users
            items = []
            for user in users
                contact = ContactStore.getByAddress user.address
                items.push if contact?
                    a
                        target: '_blank'
                        href: "/#apps/contacts/contact/#{contact.get 'id'}"
                        onClick: (event) -> event.stopPropagation()
                        format(user)

                else
                    span
                        className: 'participant'
                        onClick: (event) -> event.stopPropagation()
                        format(user)

                items.push ", " if user isnt _.last(users)
            return items
        else
            return format(users)
