React = require 'react'
{span, a, button} = React.DOM

{Tooltips} = require '../constants/app_constants'

{AddressLabel} = require('./basics/components').factories

ContactActionCreator = require '../actions/contact_action_creator'
LayoutActionCreator = require '../actions/layout_action_creator'

# Display contact label as a link to the contact page if the contact
# exists, else it displays it as a clickable span than allows to create
# a contact object in the Cozy for this contact.
module.exports = React.createClass

    render: ->
        span
            ref: 'contact'
            className: 'participant',
            AddressLabel
                contact: @props.contact

            if (contactID = @props.model?.get 'id')?
                a
                    className: 'show-contact'
                    href: "/#apps/contacts/contact/#{contactID}"
                    target: "_blank"
                    button
                        className: 'fa fa-user'
                        'aria-describedby': Tooltips.SHOW_CONTACT
                        'data-tooltip-direction': 'top'
            else
                span
                    className: 'add-contact'
                    onClick: @addContact
                    button
                        className: 'fa fa-user-plus'
                        'aria-describedby': Tooltips.ADD_CONTACT
                        'data-tooltip-direction': 'top'


    addContact: (event) ->
        event.stopPropagation()
        LayoutActionCreator.displayModal {
            title       : t 'message contact creation title'
            subtitle    : t 'message contact creation',
                contact: @props.address
            closeLabel  : t 'app cancel'
            actionLabel : t 'app confirm'
            action      : =>
                ContactActionCreator.createContact @props.contact
                LayoutActionCreator.hideModal()
        }
