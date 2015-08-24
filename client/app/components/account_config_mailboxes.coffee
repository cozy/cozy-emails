{div, h4, ul, li, span, form, i, input, label} = React.DOM
classer = React.addons.classSet

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
RouterMixin = require '../mixins/router_mixin'
MailboxList = require './mailbox_list'
MailboxItem = require './account_config_item'
{SubTitle, Form} = require './basic_components'
AccountDelete = require './account_config_delete'


module.exports = AccountConfigMailboxes = React.createClass
    displayName: 'AccountConfigMailboxes'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]


    # Do not update component if nothing has changed.
    shouldComponentUpdate: (nextProps, nextState) ->
        isNextState = _.isEqual nextState, @state
        isNextProps = _.isEqual nextProps, @props
        return not (isNextState and isNextProps)

    getInitialState: ->
        @propsToState @props


    componentWillReceiveProps: (props) ->
        @setState @propsToState props


    # Turn properties into a react state. It mainly set a n array of
    # object for each mailbox set in the properties.
    propsToState: (props) ->
        state = {}
        state.mailboxesFlat = {}

        if props.mailboxes.value isnt ''

            props.mailboxes.value.map (mailbox, key) ->
                id = mailbox.get 'id'
                state.mailboxesFlat[id] = {}
                ['id', 'label', 'depth'].map (prop) ->
                    state.mailboxesFlat[id][prop] = mailbox.get prop
            .toJS()

        return state


    render: ->
        favorites = @props.favoriteMailboxes.value

        if @props.mailboxes.value isnt '' and favorites isnt ''
            mailboxes = @props.mailboxes.value.map (mailbox, key) =>
                try
                    favorite = favorites.get(mailbox.get('id'))?
                    MailboxItem {accountID: @props.id.value, mailbox, favorite}
                catch error
                    console.error error, favorites
            .toJS()

        Form className: 'form-horizontal',

            @renderError()

            SubTitle
                className: 'config-title'
                text: t "account special mailboxes"

            @renderMailboxChoice t('account draft mailbox'), "draftMailbox"
            @renderMailboxChoice t('account sent mailbox'),  "sentMailbox"
            @renderMailboxChoice t('account trash mailbox'), "trashMailbox"

            SubTitle
                className: 'config-title'
                t "account mailboxes"

            ul className: "folder-list list-unstyled boxes container",
                if mailboxes?
                    li className: 'row box title', key: 'title',
                        span
                            className: "col-xs-1",
                            ''
                        span
                            className: "col-xs-1",
                            ''
                        span
                            className: "col-xs-6",
                            ''
                        span
                            className: "col-xs-1",
                            ''
                        span
                            className: "col-xs-1 text-center",
                            t 'mailbox title total'
                        span
                            className: "col-xs-1 text-center",
                            t 'mailbox title unread'
                        span
                            className: "col-xs-1 text-center",
                            t 'mailbox title new'

                mailboxes

                li className: "row box new", key: 'new',

                    span
                        className: "col-xs-1 box-action add"
                        onClick: @addMailbox
                        title: t("mailbox title add"),
                            i className: 'fa fa-plus'

                    span
                        className: "col-xs-1 box-action cancel"
                        onClick: @undoMailbox
                        title: t("mailbox title add cancel"),
                            i className: 'fa fa-undo'

                    div className: 'col-xs-6',
                        input
                            id: 'newmailbox',
                            ref: 'newmailbox',
                            type: 'text',
                            className: 'form-control',
                            placeholder: t "account newmailbox placeholder"
                            onKeyDown: @onKeyDown

                    label
                        className: 'col-xs-2 text-center control-label',
                        t "account newmailbox parent"

                    div className: 'col-xs-2 text-center',
                        MailboxList
                            allowUndefined: true
                            mailboxes: @state.mailboxesFlat
                            selectedMailboxID: @state.newMailboxParent
                            onChange: (mailbox) =>
                                @setState newMailboxParent: mailbox

                if @props.selectedAccount?
                    AccountDelete
                        selectedAccount: @props.selectedAccount


    renderError: ->

        if @props.error and @props.error.name is 'AccountConfigError'
            message = t 'config error ' + @props.error.field
            div className: 'alert alert-warning', message

        else if @props.error
            div className: 'alert alert-warning', @props.error.message

        else if Object.keys(@props.errors).length isnt 0
            div className: 'alert alert-warning', t 'account errors'


    renderMailboxChoice: (labelText, box) ->
        if @props.id? and @props.mailboxes.value isnt ''
            errorClass = if @props[box].value? then '' else 'has-error'
            div className: "form-group #{box} #{errorClass}",
                label
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    labelText
                div className: 'col-sm-3',
                    MailboxList
                        allowUndefined: true
                        mailboxes: @state.mailboxesFlat
                        selectedMailboxID: @props[box].value
                        onChange: (mailbox) => @onMailboxChange mailbox, box


    onMailboxChange: (mailbox, box) ->
        @props[box].requestChange mailbox, =>
            @props.onSubmit()


    # Typing enter runs the mailbox creation process.
    onKeyDown: (evt) ->
        switch evt.key
            when "Enter"
                evt?.preventDefault()
                evt?.stopPropagation()
                @addMailbox()


    # Save new mailbox information to the server.
    addMailbox: (event) ->
        event?.preventDefault()

        mailbox =
            label: @refs.newmailbox.getDOMNode().value.trim()
            accountID: @props.id.value
            parentID: @state.newMailboxParent

        AccountActionCreator.mailboxCreate mailbox, (error) =>
            if error?
                LayoutActionCreator.alertError \
                    "#{t("mailbox create ko")} #{error}"
            else
                LayoutActionCreator.notify t("mailbox create ok"),
                    autoclose: true
                @refs.newmailbox.getDOMNode().value = ''


    # Undo mailbox creation (hide the mailbox creation widget).
    undoMailbox: (event) ->
        event.preventDefault()

        @refs.newmailbox.getDOMNode().value = ''
        @setState newMailboxParent: null

