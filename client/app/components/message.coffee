{div, ul, li, span, i, p, h3, a, button} = React.DOM
MailboxList  = require './mailbox-list'
Compose      = require './compose'
MessageUtils = require '../utils/MessageUtils'
{ComposeActions} = require '../constants/AppConstants'
LayoutActionCreator  = require '../actions/LayoutActionCreator'

# Flux stores
AccountStore = require '../stores/AccountStore'

classer = React.addons.classSet

module.exports = React.createClass
    displayName: 'Message'

    getInitialState: ->
        return {
            active: false,
            composing: false
            composeAction: ''
        }

    render: ->

        message = @props.message

        text = message.get 'text'
        html = message.get 'html'

        if text and not html and state.composeInHTML
            html = markdown.toHTML text

        if html and not text and not state.composeInHTML
            text = toMarkdown html

        clickHandler = if @props.isLast then null else @onFold

        classes = classer
            message: true
            active: @state.active

        today = moment()
        date = moment message.get 'createdAt'
        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'DD MMMM'
        else
            formatter = 'hh:mm'

        li className: classes, key: @props.key, onClick: clickHandler,
            @getToolboxRender()
            div className: 'header',
                i className: 'fa fa-user'
                div className: 'participants',
                    span  className: 'sender', MessageUtils.displayAddresses(message.get('from'), true)
                    span className: 'receivers', t "mail receivers", {dest: MessageUtils.displayAddresses(message.get('to'), true)}
                    span className: 'receivers', t "mail receivers cc", {dest: MessageUtils.displayAddresses(message.get('cc'), true)}
                span className: 'hour', date.format formatter
            div className: 'preview',
                p null, message.get 'text'
            div className: 'content', dangerouslySetInnerHTML: {__html: html}
            div className: 'clearfix'

            # Display Compose block
            if @state.composing
                selectedAccount = @props.selectedAccount
                layout          = 'right'
                message         = message
                action          = @state.composeAction
                callback        = (error) =>
                    if not error?
                        @setState composing: false
                Compose {selectedAccount, layout, message, action, callback}

    getToolboxRender: ->

        mailboxes = AccountStore.getSelectedMailboxes true

        div className: 'messageToolbox',
            div className: 'btn-toolbar', role: 'toolbar',
                div className: 'btn-group btn-group-sm btn-group-justified',
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default', type: 'button', onClick: @onReply,
                            span className: 'fa fa-reply'
                            span className: 'tool-long', t 'mail action reply'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default', type: 'button', onClick: @onReplyAll,
                            span className: 'fa fa-reply-all'
                            span className: 'tool-long', t 'mail action reply all'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default', type: 'button', onClick: @onForward,
                            span className: 'fa fa-mail-forward'
                            span className: 'tool-long', t 'mail action forward'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default', type: 'button', onClick: @onDelete,
                            span className: 'fa fa-trash-o'
                            span className: 'tool-long', t 'mail action delete'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', onClick: @onMark, t 'mail action mark',
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            li null,
                                a href: '#', t 'mail mark fav'
                            li null,
                                a href: '#', t 'mail mark nofav'
                            li null,
                                a href: '#', t 'mail mark spam'
                            li null,
                                a href: '#', t 'mail mark nospam'
                            li null,
                                a href: '#', t 'mail mark read'
                            li null,
                                a href: '#', t 'mail mark unread'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', onClick: @onMove, t 'mail action move',
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            mailboxes.map (mailbox, key) =>
                                @getMailboxRender mailbox, key
                            .toJS()


    getMailboxRender: (mailbox, key) ->
        pusher = ""
        pusher += "--" for j in [1..mailbox.get('depth')] by 1
        url    = ''
        li role: 'presentation', key: key,
            a href: url, role: 'menuitem', "#{pusher}#{mailbox.get 'label'}"

    onFold: (args) ->
        @setState active: not @state.active

    onReply: (args) ->
        @setState composing: true
        @setState composeAction: ComposeActions.REPLY

    onReplyAll: (args) ->
        @setState composing: true
        @setState composeAction: ComposeActions.REPLY_ALL

    onForward: (args) ->
        @setState composing: true
        @setState composeAction: ComposeActions.FORWARD

    onDelete: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"

    onCopy: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"

    onMove: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"
