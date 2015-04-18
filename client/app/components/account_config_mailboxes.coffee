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


module.exports = AccountConfigMailboxes = React.createClass
    displayName: 'AccountConfigMailboxes'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))

    _propsToState: (props) ->
        state = props
        state.mailboxesFlat = {}
        if state.mailboxes.value isnt ''
            state.mailboxes.value.map (mailbox, key) ->
                id = mailbox.get 'id'
                state.mailboxesFlat[id] = {}
                ['id', 'label', 'depth'].map (prop) ->
                    state.mailboxesFlat[id][prop] = mailbox.get prop
            .toJS()
        return state

    getInitialState: ->
        @_propsToState(@props)

    componentWillReceiveProps: (props) ->
        @setState @_propsToState(props)

    render: ->
        favorites = @state.favoriteMailboxes.value
        if @state.mailboxes.value isnt '' and favorites isnt ''
            mailboxes = @state.mailboxes.value.map (mailbox, key) =>
                try
                    favorite = favorites.get(mailbox.get('id'))?
                    MailboxItem {accountID: @state.id.value, mailbox, favorite}
                catch error
                    console.error error, favorites
            .toJS()
        form className: 'form-horizontal',

            @renderError()
            h4 className: 'config-title', t "account special mailboxes"
            @_renderMailboxChoice t('account draft mailbox'), "draftMailbox"
            @_renderMailboxChoice t('account sent mailbox'),  "sentMailbox"
            @_renderMailboxChoice t('account trash mailbox'), "trashMailbox"

            h4 className: 'config-title', t "account mailboxes"
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

    renderError: ->
        if @props.error and @props.error.name is 'AccountConfigError'
            message = t 'config error ' + @props.error.field
            div className: 'alert alert-warning', message
        else if @props.error
            div className: 'alert alert-warning', @props.error.message
        else if Object.keys(@state.errors).length isnt 0
            div className: 'alert alert-warning', t 'account errors'

    _renderMailboxChoice: (labelText, box) ->
        if @state.id? and @state.mailboxes.value isnt ''
            errorClass = if @state[box].value? then '' else 'has-error'
            div className: "form-group #{box} #{errorClass}",
                label
                    className: 'col-sm-2 col-sm-offset-2 control-label',
                    labelText
                div className: 'col-sm-3',
                    MailboxList
                        allowUndefined: true
                        mailboxes: @state.mailboxesFlat
                        selectedMailboxID: @state[box].value
                        onChange: (mailbox) =>
                            # requestChange is asynchroneous, so we need
                            # to also call setState to only call onSubmet
                            # once state has really been updated
                            @state[box].requestChange mailbox
                            newState = {}
                            newState[box] =
                                value = mailbox
                            @setState newState, =>
                                @props.onSubmit()

    onKeyDown: (evt) ->
        switch evt.key
            when "Enter"
                @addMailbox()

    addMailbox: (event) ->
        event?.preventDefault()

        mailbox =
            label: @refs.newmailbox.getDOMNode().value.trim()
            accountID: @state.id.value
            parentID: @state.newMailboxParent

        AccountActionCreator.mailboxCreate mailbox, (error) =>
            if error?
                LAC.alertError "#{t("mailbox create ko")} #{error}"
            else
                LAC.notify t("mailbox create ok"),
                    autoclose: true
                @refs.newmailbox.getDOMNode().value = ''

    undoMailbox: (event) ->
        event.preventDefault()

        @refs.newmailbox.getDOMNode().value = ''
        @setState newMailboxParent: null


