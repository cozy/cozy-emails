{section, header, ul, li, span, i, p, h3, a, button} = React.DOM

messageUtils = require '../utils/message_utils'
ContactStore = require '../stores/contact_store'
StoreWatchMixin = require '../mixins/store_watch_mixin'
ContactActionCreator = require '../actions/contact_action_creator'
{AddressLabel} = require './basic_components'


# Small component used to display contact label in message headers.
module.exports = ContactLabel = React.createClass

    # Dirty hack to listen contact store changes.
    mixins: [
        StoreWatchMixin [ContactStore]
    ]


    # Dirty hack to not break the store watch mixin initialization.
    getStateFromStores: ->
        return {}


    # Display contact label as a link to the contact page if the contact
    # exists, else it displays it as a clickable span than allows to create
    # a contact object in the Cozy for this contact.
    render: ->

        if @props.contact?

            contactModel = ContactStore.getByAddress @props.contact.address

            if contactModel?
                a
                    target: '_blank'
                    href: "/#apps/contacts/contact/#{contactModel.get 'id'}"
                    onClick: (event) ->
                        event.stopPropagation()
                    AddressLabel
                        contact: @props.contact

            else
                span
                    className: 'participant'
                    onClick: @onContactClicked
                    AddressLabel
                        contact: @props.contact
        else
            span null


    # When a contact is clicked, it asks to the user if he wants to add it to
    # its Cozy. If the user agrees it runs a contact creation action.
    onContactClicked: (event) ->
        params = contact: messageUtils.displayAddress @props.contact
        if confirm t 'message contact creation', params
            ContactActionCreator.createContact @props.contact
        event.stopPropagation()
