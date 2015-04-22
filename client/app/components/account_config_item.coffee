{li, span, i} = React.DOM
classer = React.addons.classSet

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
RouterMixin = require '../mixins/router_mixin'


# Line for the mailbox list.
module.exports = MailboxItem = React.createClass
    displayName: 'MailboxItem'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    propTypes:
        mailbox: React.PropTypes.object


    getInitialState: ->
        return {
            edited: false
            favorite: @props.favorite
        }


    # Whether it's edit mode or not, it displays widgets to edit mailbox
    # properties like the name. Otherwise it displays box information and
    # button to switch to edit mode and button to delete the current mailbox.
    render: ->
        pusher = ""
        pusher += "    " for j in [1..@props.mailbox.get('depth')] by 1
        key = @props.mailbox.get 'id'

        if @state.favorite
            favoriteClass = "fa fa-eye mailbox-visi-yes"
            favoriteTitle = t "mailbox title favorite"
        else
            favoriteClass = "fa fa-eye-slash mailbox-visi-no"
            favoriteTitle = t "mailbox title not favorite"

        nbTotal  = @props.mailbox.get('nbTotal') or 0
        nbUnread = @props.mailbox.get('nbUnread') or 0
        nbRecent = @props.mailbox.get('nbRecent') or 0

        classItem = classer
            'row': true
            'box': true
            'box-item': true
            edited: @state.edited

        if @state.edited
            li className: classItem, key: key,
                span
                    className: "col-xs-1 box-action save"
                    onClick: @updateMailbox
                    title: t("mailbox title edit save"),
                        i className: 'fa fa-check'
                span
                    className: "col-xs-1 box-action cancel"
                    onClick: @undoMailbox
                    title: t("mailbox title edit cancel"),
                        i className: 'fa fa-undo'
                input
                    className: "col-xs-6 box-label"
                    ref: 'label',
                    defaultValue: @props.mailbox.get 'label'
                    type: 'text'
                    onKeyDown: @onKeyDown,

        else
            li className: classItem, key: key,
                span
                    className: "col-xs-1 box-action edit",
                    onClick: @editMailbox,
                    title: t("mailbox title edit"),
                        i className: 'fa fa-pencil'
                span
                    className: "col-xs-1 box-action delete",
                    onClick: @deleteMailbox,
                    title: t("mailbox title delete"),
                        i className: 'fa fa-trash-o'
                span
                    className: "col-xs-6 box-label",
                    onClick: @editMailbox,
                    "#{pusher}#{@props.mailbox.get 'label'}"
                span
                    className: "col-xs-1 box-action favorite",
                    title: favoriteTitle
                    onClick: @toggleFavorite,
                        i className: favoriteClass
                span
                    className: "col-xs-1 text-center box-count box-total",
                    nbTotal
                span
                    className: "col-xs-1 text-center box-count box-unread",
                    nbUnread
                span
                    className: "col-xs-1 text-center box-count box-new",
                    nbRecent


    # When enter key is typed, it updates the mailbox information.
    onKeyDown: (evt) ->
        switch evt.key
            when "Enter"
                @updateMailbox()


    # Go in edit mode.
    editMailbox: (event) ->
        event.preventDefault()
        @setState edited: true


    # Go back to non edition mode.
    undoMailbox: (event) ->
        event.preventDefault()
        @setState edited: false


    # Save mailbox details to sever. Display an alert if an error occurs.
    updateMailbox: (event) ->
        event?.preventDefault()

        mailbox =
            label: @refs.label.getDOMNode().value.trim()
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.accountID

        AccountActionCreator.mailboxUpdate mailbox, (error) =>
            if error?
                message = "#{t("mailbox update ko")} #{error}"
                LayoutActionCreator.alertError message
            else
                LayoutActionCreator.notify t("mailbox update ok"),
                    autoclose: true
                @setState edited: false


    # Set mailbox as favorite. Save information to the server. It shows
    # an alert if an error occurs.
    toggleFavorite: (event) ->
        mailbox =
            favorite: not @state.favorite
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.accountID

        AccountActionCreator.mailboxUpdate mailbox, (error) ->
            if error?
                message = "#{t("mailbox update ko")} #{error}"
                LayoutActionCreator.alertError message
            else
                LayoutActionCreator.notify t("mailbox update ok"),
                    autoclose: true

        @setState favorite: not @state.favorite


    # Ask for confirmation before sending box deletion request to the server.
    # Display an alert if an error occurs.
    deleteMailbox: (event) ->
        event.preventDefault() if event?

        if window.confirm(t 'account confirm delbox')
            mailbox =
                mailboxID: @props.mailbox.get 'id'
                accountID: @props.accountID

            AccountActionCreator.mailboxDelete mailbox, (error) ->
                if error?
                    message = "#{t("mailbox delete ko")} #{error}"
                    LayoutActionCreator.alertError message
                else
                    layoutActionCreator.notify t("mailbox delete ok"),
                        autoclose: true

