Immutable      = require 'immutable'
React          = require 'react'

{div, h4, ul, li, span, p, form, i, input, label} = React.DOM

{SubTitle, Form} = require('./basic_components').factories
MailboxItem      = React.createFactory require './account_config_item'
MailboxPicker    = React.createFactory require './mailbox_picker'
AccountDelete    = React.createFactory require './account_config_delete'

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'

RouterMixin           = require '../mixins/router_mixin'
ShouldComponentUpdate = require '../mixins/should_update_mixin'
LinkedStateMixin      = require 'react-addons-linked-state-mixin'

cachedTransform = require '../libs/cached_transform'


module.exports = AccountConfigMailboxes = React.createClass
    displayName: 'AccountConfigMailboxes'

    mixins: [
        RouterMixin
        LinkedStateMixin
        ShouldComponentUpdate.UnderscoreEqualitySlow
    ]

    propTypes:
        # to change the values on the account itself
        editedAccount: React.PropTypes.instanceOf(Immutable.Map).isRequired
        requestChange: React.PropTypes.func.isRequired
        errors: React.PropTypes.instanceOf(Immutable.Map).isRequired
        onSubmit: React.PropTypes.func.isRequired

    getInitialState: ->
        newMailboxName: ''
        newMailboxParent: null

    makeLinkState: (field) ->
        currentValue = @props.editedAccount.get(field)
        cachedTransform @, '__cacheLS', currentValue, =>
            value: currentValue
            requestChange: (value) =>
                changes = {}
                changes[field] = value
                @props.requestChange changes

    render: ->
        Form className: 'form-horizontal',

            SubTitle className: 'config-title', t "account special mailboxes"
            unless @areSpecialMailboxesConfigured()
                p className: 'warning', t('account special mailboxes warning')
            @renderMailboxChoice 'draft'
            @renderMailboxChoice 'sent'
            @renderMailboxChoice 'trash'


            SubTitle className: 'config-title', t "account mailboxes"

            ul className: "folder-list list-unstyled boxes container",
                if @props.editedAccount.get('mailboxes').size
                    @renderTableHeader()

                @props.editedAccount.get('mailboxes')
                    .map (mailbox, key) =>
                        MailboxItem
                            key: key
                            accountID: @props.editedAccount.get('id')
                            favorite: key in @props.editedAccount.get('favorites')
                            mailbox: mailbox
                    .toArray()

                @renderTableFooter()

    renderError: ->
        if @props.error and @props.error.name is 'AccountConfigError'
            message = t 'config error ' + @props.error.field
            div className: 'alert alert-warning', message

        else if @props.error
            div className: 'alert alert-warning', @props.error.message

        else if Object.keys(@props.errors).length isnt 0
            div className: 'alert alert-warning', t 'account errors'

    renderTableHeader: ->
        li className: 'row box title', key: 'title',
            span className: "col-xs-1", ''
            span className: "col-xs-1", ''
            span className: "col-xs-6", ''
            span className: "col-xs-1", ''
            span className: "col-xs-1 text-center",
                t 'mailbox title total'
            span className: "col-xs-1 text-center",
                t 'mailbox title unread'
            span className: "col-xs-1 text-center",
                t 'mailbox title new'

    renderTableFooter: ->
        li className: "row box new", key: 'new',

            span
                className: "col-xs-1 box-action add"
                onClick: @addMailboxClicked
                title: t("mailbox title add"),
                    i className: 'fa fa-plus'

            span
                className: "col-xs-1 box-action cancel"
                onClick: @resetMailboxClicked
                title: t("mailbox title add cancel"),
                    i className: 'fa fa-undo'

            div className: 'col-xs-6',
                input
                    id: 'newmailbox',
                    type: 'text',
                    className: 'form-control',
                    placeholder: t "account newmailbox placeholder"
                    valueLink: @linkState 'newMailboxName'
                    onKeyDown: @onNewMailboxKeyDown

            label
                className: 'col-xs-2 text-center control-label',
                t "account newmailbox parent"

            div className: 'col-xs-2 text-center',
                MailboxPicker
                    allowUndefined: true
                    valueLink: @linkState 'newMailboxParent'
                    mailboxes: @props.editedAccount.get('mailboxes')

    renderMailboxChoice: (which) ->
        property = "#{which}Mailbox"
        labelText = t "account #{which} mailbox"

        className = "form-group #{which} mailbox-choice "
        className += 'has-error' unless @props.editedAccount.get(property)?

        div className: className,
            label
                className: 'col-sm-2 col-sm-offset-2 control-label',
                labelText
            div className: 'col-sm-3',
                MailboxPicker
                    allowUndefined: false
                    valueLink: @makeLinkState property
                    mailboxes: @props.editedAccount.get('mailboxes')

    # Typing enter runs the mailbox creation process.
    onNewMailboxKeyDown: (event) ->
        if event.key is "Enter"
            event.preventDefault()
            @setState newMailboxName: event.target.value, =>
                @addMailboxClicked()

    # Save new mailbox information to the server.
    addMailboxClicked: (event) ->
        event?.preventDefault()

        mailbox =
            label: @state.newMailboxName
            accountID: @props.editedAccount.get 'id'
            parentID: @state.newMailboxParent

        AccountActionCreator.mailboxCreate mailbox, (error) =>
            @setState newMailboxName: '' unless error


    # Undo mailbox creation (hide the mailbox creation widget).
    resetMailboxClicked: (event) ->
        event.preventDefault()

        @refs.newmailbox.value = ''
        @setState newMailboxParent: null


    # Return true if all special mailboxes are configured, false otherwise.
    areSpecialMailboxesConfigured: ->
        editedAccount = @props.editedAccount
        return editedAccount.get('sentMailbox')? and \
               editedAccount.get('draftMailbox')? and \
               editedAccount.get('trashMailbox')?
