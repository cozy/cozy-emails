{
    div, p, h3, h4, form, label, input, button, ul, li, a, span, i,
    fieldset, legend
} = React.DOM
classer = React.addons.classSet

MailboxList          = require './mailbox-list'
AccountActionCreator = require '../actions/account_action_creator'
RouterMixin = require '../mixins/router_mixin'
LAC  = require '../actions/layout_action_creator'
classer = React.addons.classSet


module.exports = MailboxItem = React.createClass
    displayName: 'MailboxItem'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    propTypes:
        mailbox: React.PropTypes.object

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))

    #componentWillReceiveProps: (props) ->
    #    @setState edited: false

    getInitialState: ->
        return {
            edited: false
            favorite: @props.favorite
        }

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

    onKeyDown: (evt) ->
        switch evt.key
            when "Enter"
                @updateMailbox()

    editMailbox: (e) ->
        e.preventDefault()
        @setState edited: true

    undoMailbox: (e) ->
        e.preventDefault()
        @setState edited: false

    updateMailbox: (e) ->
        e?.preventDefault()

        mailbox =
            label: @refs.label.getDOMNode().value.trim()
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.accountID

        AccountActionCreator.mailboxUpdate mailbox, (error) =>
            if error?
                LAC.alertError "#{t("mailbox update ko")} #{error}"
            else
                LAC.notify t("mailbox update ok"),
                    autoclose: true
                @setState edited: false

    toggleFavorite: (e) ->
        mailbox =
            favorite: not @state.favorite
            mailboxID: @props.mailbox.get 'id'
            accountID: @props.accountID

        AccountActionCreator.mailboxUpdate mailbox, (error) ->
            if error?
                LAC.alertError "#{t("mailbox update ko")} #{error}"
            else
                LAC.notify t("mailbox update ok"),
                    autoclose: true

        @setState favorite: not @state.favorite

    deleteMailbox: (e) ->
        e.preventDefault()

        if window.confirm(t 'account confirm delbox')
            mailbox =
                mailboxID: @props.mailbox.get 'id'
                accountID: @props.accountID

            AccountActionCreator.mailboxDelete mailbox, (error) ->
                if error?
                    LAC.alertError "#{t("mailbox delete ko")} #{error}"
                else
                    LAC.notify t("mailbox delete ok"),
                        autoclose: true

