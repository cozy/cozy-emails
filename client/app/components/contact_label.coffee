React = require 'react'
{span, a, button} = React.DOM

{Tooltips} = require '../constants/app_constants'

{AddressLabel} = require('./basic_components').factories

ContactActionCreator = require '../actions/contact_action_creator'
LayoutActionCreator = require '../actions/layout_action_creator'

# Display contact label as a link to the contact page if the contact
# exists, else it displays it as a clickable span than allows to create
# a contact object in the Cozy for this contact.
module.exports = React.createClass

    gotoContact: ->
        ContactActionCreator.gotoContactList @props.contact

    render: ->
        if @props.model?
            span
                ref: 'contact'
                AddressLabel
                    contact: @props.contact
                a
                    className: 'show-contact'
                    onClick: @gotoContact

                    button
                        className: 'fa fa-user'
                        'aria-describedby': Tooltips.SHOW_CONTACT
                        'data-tooltip-direction': 'top'

        else
            span
                ref: 'contact'
                className: 'participant',
                AddressLabel
                    contact: @props.contact,

                span
                    className: 'add-contact',
                    button
                        className: 'fa fa-user-plus'
                        onClick: @addContact
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
