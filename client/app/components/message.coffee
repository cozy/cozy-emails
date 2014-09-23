{div, ul, li, span, i, p, h3, a, button, pre} = React.DOM
MailboxList  = require './mailbox-list'
Compose      = require './compose'
FilePicker   = require './file-picker'
MessageUtils = require '../utils/message_utils'
{ComposeActions, MessageFlags} = require '../constants/app_constants'
LayoutActionCreator       = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'
RouterMixin = require '../mixins/router_mixin'

# Flux stores
AccountStore = require '../stores/account_store'

FlagsConstants =
    SEEN   : MessageFlags.SEEN
    UNSEEN : "Unseen"
    FLAGGED: MessageFlags.FLAGGED
    NOFLAG : "Noflag"

classer = React.addons.classSet

module.exports = React.createClass
    displayName: 'Message'

    mixins: [
        RouterMixin
    ]

    getInitialState: ->
        return {
            active: false,
            composing: false
            composeAction: ''
        }

    _prepareMessage: ->
        message = @props.message

        # display full headers
        fullHeaders = []
        for key, value of message.get 'headers'
            if Array.isArray(value)
                fullHeaders.push "#{key}: #{value.join('\n    ')}"
            else
                fullHeaders.push "#{key}: #{value}"

        text = message.get 'text'
        html = message.get 'html'

        if text and not html and @state.composeInHTML
            html = markdown.toHTML text

        if html and not text and not @state.composeInHTML
            text = toMarkdown html

        return {
            attachments: message.get('attachments') or []
            flags      : message.get('flags') or []
            fullHeaders: fullHeaders
            text       : text
            html       : html
            date       : MessageUtils.formatDate message.get 'createdAt'
        }

    componentWillMount: ->
        @_markRead @props.message

    componentWillReceiveProps: ->
        @_markRead @props.message

    _markRead: (message) ->
        # Mark message as seen if needed
        flags = message.get('flags').slice()
        if flags.indexOf(MessageFlags.SEEN) is -1
            flags.push MessageFlags.SEEN
            MessageActionCreator.updateFlag message, flags

    render: ->

        message  = @props.message
        prepared = @_prepareMessage()

        clickHandler = if @props.isLast then null else @onFold

        classes = classer
            message: true
            active: @state.active

        # display attachment
        display = (file) ->
            url = "/message/#{message.get 'id'}/attachments/#{file.name}"
            window.open url

        li className: classes, key: @props.key, onClick: clickHandler, 'data-id': @props.message.get('id'),
            @getToolboxRender message.get('id'), prepared
            div className: 'header row',
                div className: 'col-md-8',
                    i className: 'sender-avatar fa fa-user'
                    div className: 'participants',
                        span  className: 'sender', MessageUtils.displayAddresses(message.get('from'), true)
                        span className: 'receivers', t "mail receivers", {dest: MessageUtils.displayAddresses(message.get('to'), true)}
                        span className: 'receivers', t "mail receivers cc", {dest: MessageUtils.displayAddresses(message.get('cc'), true)}
                    span className: 'hour', prepared.date
                div className: 'col-md-4',
                    FilePicker({editable: false, files: prepared.attachments.map(MessageUtils.convertAttachments), display: display})
            div className: 'full-headers',
                pre null, prepared.fullHeaders.join "\n"
            div className: 'preview',
                p null, prepared.text
            div className: 'content', dangerouslySetInnerHTML: {__html: prepared.html}
            div className: 'clearfix'

            # Display Compose block
            @getComposeRender()

    getComposeRender: ->
        if @state.composing
            selectedAccount = @props.selectedAccount
            layout          = 'second'
            message         = @props.message
            action          = @state.composeAction
            callback        = (error) =>
                if not error?
                    @setState composing: false
            Compose {selectedAccount, layout, message, action, callback}

    getToolboxRender: (id, prepared) ->

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
                        button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', t 'mail action mark',
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            if prepared.flags.indexOf(FlagsConstants.SEEN) is -1
                                li null,
                                    a role: 'menuitem', onClick: @onMark, 'data-value': FlagsConstants.UNSEEN, t 'mail mark unread'
                            else
                                li null,
                                    a role: 'menuitem', onClick: @onMark, 'data-value': FlagsConstants.SEEN, t 'mail mark read'
                            if prepared.flags.indexOf(FlagsConstants.FLAGGED) is -1
                                li null,
                                    a role: 'menuitem', onClick: @onMark, 'data-value': FlagsConstants.FLAGGED, t 'mail mark fav'
                            else
                                li null,
                                    a role: 'menuitem', onClick: @onMark, 'data-value': FlagsConstants.NOFLAG, t 'mail mark nofav'
                            #li null,
                            #    a role: 'menuitem', onClick: @onMark, 'data-value': '', t 'mail mark spam'
                            #li null,
                            #    a role: 'menuitem', onClick: @onMark, 'data-value': '', t 'mail mark nospam'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', t 'mail action move',
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            mailboxes.map (mailbox, key) =>
                                @getMailboxRender mailbox, key
                            .toJS()
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', t 'mail action more',
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            li role: 'presentation',
                                a onClick: @onHeaders, 'data-message-id': id, t 'mail action headers'
                            li role: 'presentation',
                                a onClick: @onConversation, 'data-action' : 'delete', t 'mail action conversation delete'
                            li role: 'presentation',
                                a onClick: @onConversation, 'data-action' : 'seen',   t 'mail action conversation seen'
                            li role: 'presentation',
                                a onClick: @onConversation, 'data-action' : 'unseen', t 'mail action conversation unseen'
                            li role: 'presentation', className: 'divider'
                            li role: 'presentation', t 'mail action conversation move'
                            mailboxes.map (mailbox, key) =>
                                @getMailboxRender mailbox, key, true
                            .toJS()
                            li role: 'presentation', className: 'divider'


    getMailboxRender: (mailbox, key, conversation) ->
        # Don't display current mailbox
        if mailbox.get('id') is @props.selectedMailbox.get('id')
            return
        pusher = ""
        pusher += "--" for j in [1..mailbox.get('depth')] by 1
        li role: 'presentation', key: key,
            a role: 'menuitem', onClick: @onMove, 'data-value': key, 'data-conversation': conversation, "#{pusher}#{mailbox.get 'label'}"

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
        if window.confirm(t 'mail confirm delete')
            MessageActionCreator.delete @props.message, (error) =>
                if error?
                    LayoutActionCreator.alertError "#{t("message action delete ko")} #{error}"
                else
                    LayoutActionCreator.alertSuccess t "message action delete ok"
                    @redirect
                        direction: 'first'
                        action: 'account.mailbox.messages'
                        parameters: [@props.selectedAccount.get('id'), @props.selectedMailbox.get('id'), 1]
                        fullWidth: true

    onCopy: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"

    onMove: (args) ->
        newbox = args.target.dataset.value
        if args.target.dataset.conversation?
            ConversationActionCreator.move @props.message.get('conversationID'), newbox, (error) =>
                if error?
                    LayoutActionCreator.alertError "#{t("conversation move ko")} #{error}"
                else
                    LayoutActionCreator.alertSuccess t "conversation move ok"
                    @redirect
                        direction: 'first'
                        action: 'account.mailbox.messages'
                        parameters: [@props.selectedAccount.get('id'), @props.selectedMailbox.get('id'), 1]
                        fullWidth: true
        else
            oldbox = @props.selectedMailbox.get 'id'
            MessageActionCreator.move @props.message, oldbox, newbox, (error) =>
                if error?
                    LayoutActionCreator.alertError "#{t("message action move ko")} #{error}"
                else
                    LayoutActionCreator.alertSuccess t "message action move ok"
                    @redirect
                        direction: 'first'
                        action: 'account.mailbox.messages'
                        parameters: [@props.selectedAccount.get('id'), @props.selectedMailbox.get('id'), 1]
                        fullWidth: true

    onMark: (args) ->
        flags = @props.message.get('flags').slice()
        flag = args.target.dataset.value
        switch flag
            when FlagsConstants.SEEN
                flags.push MessageFlags.SEEN
            when FlagsConstants.UNSEEN
                flags = flags.filter (e) -> return e isnt FlagsConstants.SEEN
            when FlagsConstants.FLAGGED
                flags.push MessageFlags.FLAGGED
            when FlagsConstants.NOFLAG
                flags = flags.filter (e) -> return e isnt FlagsConstants.FLAGGED
        MessageActionCreator.updateFlag @props.message, flags, (error) ->
            if error?
                LayoutActionCreator.alertError "#{t("message action mark ko")} #{error}"
            else
                LayoutActionCreator.alertSuccess t "message action mark ok"

    onConversation: (args) ->
        id     = @props.message.get 'conversationID'
        action = args.target.dataset.action
        switch action
            when 'delete'
                ConversationActionCreator.delete id, (error) ->
                    if error?
                        LayoutActionCreator.alertError "#{t("conversation delete ko")} #{error}"
                    else
                        LayoutActionCreator.alertSuccess t "conversation delete ok"
            when 'seen'
                ConversationActionCreator.seen id, (error) ->
                    if error?
                        LayoutActionCreator.alertError "#{t("conversation seen ok ")} #{error}"
                    else
                        LayoutActionCreator.alertSuccess t "conversation seen ko "
            when 'unseen'
                ConversationActionCreator.unseen id, (error) ->
                    if error?
                        LayoutActionCreator.alertError "#{t("conversation unseen ok")} #{error}"
                    else
                        LayoutActionCreator.alertSuccess t "conversation unseen ko"

    onHeaders: (event) ->
        event.preventDefault()
        messageId = event.target.dataset.messageId
        document.querySelector(".conversation [data-id='#{messageId}']").classList.toggle('with-headers')
