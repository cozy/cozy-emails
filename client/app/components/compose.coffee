{div, section, h3, a, i, textarea, form, label} = React.DOM
{span, ul, li, input} = React.DOM

classer = React.addons.classSet

ComposeEditor  = require './compose_editor'
ComposeToolbox = require './compose_toolbox'
FilePicker     = require './file_picker'
MailsInput     = require './mails_input'

AccountPicker = require './account_picker'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'

{ComposeActions, Tooltips} = require '../constants/app_constants'

MessageUtils = require '../utils/message_utils'


LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

RouterMixin = require '../mixins/router_mixin'


# Component that allows the user to write emails.
module.exports = Compose = React.createClass
    displayName: 'Compose'


    mixins: [
        RouterMixin,
        React.addons.LinkedStateMixin # two-way data binding
    ]


    propTypes:
        selectedAccountID:    React.PropTypes.string.isRequired
        selectedAccountLogin: React.PropTypes.string.isRequired
        layout:               React.PropTypes.string
        accounts:             React.PropTypes.object.isRequired
        message:              React.PropTypes.object
        action:               React.PropTypes.string
        callback:             React.PropTypes.func
        onCancel:             React.PropTypes.func
        settings:             React.PropTypes.object.isRequired
        useIntents:           React.PropTypes.bool.isRequired


    getDefaultProps: ->
        layout: 'full'


    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))


    render: ->
        return unless @props.accounts

        toggleFullscreen = ->
            LayoutActionCreator.toggleFullscreen()

        closeUrl = @buildClosePanelUrl @props.layout

        classLabel = 'compose-label'
        classInput = 'compose-input'
        classCc    = if @state.ccShown  then ' shown ' else ''
        classBcc   = if @state.bccShown then ' shown ' else ''

        focusEditor = Array.isArray(@state.to) and
            @state.to.length > 0 and
            @state.subject isnt ''

        section
            className: classer
                compose: true
                panel:   @props.layout is 'full'
            'aria-expanded': true,

            form className: 'form-compose', method: 'POST',
                div className: 'form-group account',
                    label
                        htmlFor: 'compose-from',
                        className: classLabel,
                        t "compose from"
                    AccountPicker
                        accounts: @props.accounts
                        valueLink: @linkState 'accountID'
                div className: 'clearfix', null

                div className: classInput,
                    div
                        className: 'btn-toolbar compose-toggle',
                        role: 'toolbar',
                            div null
                                a
                                    className: 'compose-toggle-cc',
                                    onClick: @onToggleCc,
                                    t 'compose toggle cc'
                                a
                                    className: 'compose-toggle-bcc',
                                    onClick: @onToggleBcc,
                                    t 'compose toggle bcc'

                MailsInput
                    id: 'compose-to'
                    valueLink: @linkState 'to'
                    label: t 'compose to'
                    ref: 'to'

                MailsInput
                    id: 'compose-cc'
                    className: 'compose-cc' + classCc
                    valueLink: @linkState 'cc'
                    label: t 'compose cc'
                    placeholder: t 'compose cc help'
                    ref: 'cc'

                MailsInput
                    id: 'compose-bcc'
                    className: 'compose-bcc' + classBcc
                    valueLink: @linkState 'bcc'
                    label: t 'compose bcc'
                    placeholder: t 'compose bcc help'
                    ref: 'bcc'

                div className: 'form-group',
                    div className: classInput,
                        input
                            id: 'compose-subject'
                            name: 'compose-subject'
                            ref: 'subject'
                            valueLink: @linkState('subject')
                            type: 'text'
                            className: 'form-control compose-subject'
                            placeholder: t "compose subject help"

                div className: '',
                    ComposeEditor
                        id                : 'compose-editor'
                        messageID         : @props.message?.get 'id'
                        html              : @linkState('html')
                        text              : @linkState('text')
                        accounts          : @props.accounts
                        accountID         : @state.accountID
                        settings          : @props.settings
                        onSend            : @onSend
                        composeInHTML     : @state.composeInHTML
                        focus             : focusEditor
                        ref               : 'editor'
                        getPicker         : @getPicker
                        useIntents        : @props.useIntents

                div className: 'attachements',
                    FilePicker
                        className: ''
                        editable: true
                        valueLink: @linkState 'attachments'
                        ref: 'attachments'

                ComposeToolbox
                    saving    : @state.saving
                    sending   : @state.sending
                    onSend    : @onSend
                    onDelete  : @onDelete
                    onDraft   : @onDraft
                    onCancel  : @onCancel
                    canDelete : @props.message?

                div className: 'clearfix', null


    # If we are answering to a message, canceling should bring back to
    # this message.
    # The message URL requires many information: account ID, mailbox ID,
    # conversation ID and message ID. These infor are collected via current
    # selection and message information.
    finalRedirect: ->
        if @props.inReplyTo?
            @redirect MessageStore.getMessageHash @props.inReplyTo

        # Else it should bring to the default view
        else
            @redirect @buildUrl
                direction: 'first'
                action: 'default'
                fullWidth: true


    # Cancel brings back to default view. If it's while replying to a message,
    # it brings back to this message.
    onCancel: (event) ->
        event.preventDefault()

        # Action after cancelation: call @props.onCancel
        # or navigate to message list.
        if @props.onCancel?
            @props.onCancel()
        else
            @finalRedirect()


    _initCompose: ->

        if @_saveInterval
            window.clearInterval @_saveInterval

        @_saveInterval = window.setInterval @_autosave, 30000

        # First save of draft
        @_autosave()

        # scroll compose window into view
        @getDOMNode().scrollIntoView()

        # Focus
        if not Array.isArray(@state.to) or @state.to.length is 0
            setTimeout ->
                document.getElementById('compose-to')?.focus()
            , 10
        else if @props.inReplyTo?
            document.getElementById('compose-editor')?.focus()


    componentDidMount: ->
        @_initCompose()


    componentDidUpdate: ->
        switch @state.focus
            when 'cc'
                setTimeout ->
                    document.getElementById('compose-cc').focus()
                , 0
                @setState focus: ''

            when 'bcc'
                setTimeout ->
                    document.getElementById('compose-bcc').focus()
                , 0
                @setState focus: ''


    componentWillUnmount: ->
        if @_saveInterval
            window.clearInterval @_saveInterval

        # delete draft
        doDelete = =>
            window.setTimeout =>
                LayoutActionCreator.hideModal()
                messageID = @state.id
                MessageActionCreator.delete {messageID, silent, isDraft: true, inReplyTo: @props.inReplyTo}
            , 5

        # save draft one last time
        doSave = =>
            if @state.originalConversationID?
                # save one last time the draft, adding the conversationID
                message =
                    id            : @state.id
                    accountID     : @state.accountID
                    mailboxIDs    : @state.mailboxIDs
                    from          : @state.from
                    to            : @state.to
                    cc            : @state.cc
                    bcc           : @state.bcc
                    subject       : @state.subject
                    isDraft       : true
                    attachments   : @state.attachments
                    inReplyTo     : @state.inReplyTo
                    references    : @state.references
                    text          : @state.text
                    html          : @state.html
                    conversationID: @state.originalConversationID
                MessageActionCreator.send message, (error, message) ->
                    if error? or not message?
                        msg = "#{t "message action draft ko"} #{error}"
                        LayoutActionCreator.alertError msg
                    else
                        msg = "#{t "message action draft ok"}"
                        LayoutActionCreator.notify msg, autoclose: true
                        if message.conversationID?
                            # reload conversation to update its length
                            cid = message.conversationID
                            MessageActionCreator.fetchConversation cid
            else


        # If message has not been sent, ask if we should keep it or not
        #  - if yes, and the draft belongs to a conversation, add the
        #    conversationID and save the draft
        #  - if no, delete the draft
        if not @state.isDeleted and @state.isDraft and @state.id?

            if @state.composeInHTML
                newContent = MessageUtils.cleanReplyText(@state.html).replace /\s/gim, ''
                oldContent = MessageUtils.cleanReplyText(@state.initHtml).replace /\s/gim, ''
                updated = newContent isnt oldContent
            else
                updated = @state.text isnt @state.initText

            # if draft has not been updated, delete without asking confirmation
            silent = @state.isNew and not updated
            if silent
                doDelete()
            else
                # we need a timeout because of React's components life cycle
                setTimeout ->
                    # display a modal asking if we should keep or delete the draft
                    modal =
                        title       : t 'app confirm delete'
                        subtitle    : t 'compose confirm keep draft'
                        closeModal  : ->
                            doSave()
                            LayoutActionCreator.hideModal()
                        closeLabel  : t 'compose confirm draft keep'
                        actionLabel : t 'compose confirm draft delete'
                        action      : doDelete
                    LayoutActionCreator.displayModal modal
                , 0


    getInitialState: ->

        # edition of an existing draft
        if message = @props.message
            state =
                composeInHTML: @props.settings.get 'composeInHTML'
                isNew: false
            if (not message.get('html')?) and message.get('text')
                state.conposeInHTML = false

            # TODO : smarter ?
            state[key] = value for key, value of message.toJS()
            # we want the immutable attachments
            state.attachments = message.get 'attachments'

        # new draft
        else
            account = @props.accounts[@props.selectedAccountID]
            state = MessageUtils.makeReplyMessage(
                account.login,
                @props.inReplyTo,
                @props.action,
                @props.settings.get('composeInHTML'),
                account.signature
            )
            state.isNew = true
            state.accountID ?= @props.selectedAccountID
            # use another field to prevent the empty conversationID of draft
            # to override the original conversationID
            state.originalConversationID = state.conversationID

        state.isDraft  = true
        state.sending  = false
        state.saving   = false
        state.ccShown  = Array.isArray(state.cc) and state.cc.length > 0
        state.bccShown = Array.isArray(state.bcc) and state.bcc.length > 0
        # save initial message content, to don't ask confirmation if
        # it has not been updated
        state.initHtml = state.html
        state.initText = state.text

        return state


    componentWillReceiveProps: (nextProps) ->
        if nextProps.message isnt @props.message
            @props.message = nextProps.message
            @setState @getInitialState()


    onDraft: (event) ->
        event.preventDefault()
        @_doSend true


    onSend: (event) ->
        event.preventDefault() if event?
        @_doSend false


    _doSend: (isDraft) ->

        account = @props.accounts[@state.accountID]

        from =
            name: account.name or undefined
            address: account.login

        message =
            id            : @state.id
            accountID     : @state.accountID
            mailboxIDs    : @state.mailboxIDs
            from          : [from]
            to            : @state.to
            cc            : @state.cc
            bcc           : @state.bcc
            subject       : @state.subject
            isDraft       : isDraft
            attachments   : @state.attachments
            inReplyTo     : @state.inReplyTo
            references    : @state.references

        if not isDraft
            # Add conversationID when sending message
            # we don't add conversationID to draft, otherwise the full
            # conversation would be updated, closing the compose panel
            message.conversationID = @state.originalConversationID

        valid = true
        if not isDraft
            if @state.to.length is 0 and
               @state.cc.length is 0 and
               @state.bcc.length is 0
                valid = false
                LayoutActionCreator.alertError t "compose error no dest"
                setTimeout ->
                    document.getElementById('compose-to').focus()
                , 0
            else if @state.subject is ''
                valid = false
                LayoutActionCreator.alertError t "compose error no subject"
                setTimeout =>
                    @refs.subject.getDOMNode().focus()
                , 0

        if valid
            if @state.composeInHTML
                message.html = @_cleanHTML @state.html
                message.text = MessageUtils.cleanReplyText message.html
                message.html = MessageUtils.wrapReplyHtml message.html
            else
                message.text = @state.text.trim()

            if not isDraft and @_saveInterval
                window.clearInterval @_saveInterval

            if isDraft
                @setState saving: true
            else
                @setState sending: true, isDraft: false

            MessageActionCreator.send message, (error, message) =>
                if (not error?) and (not @state.id?) and (message?)
                    MessageActionCreator.setCurrent message.id

                state = _.clone @state
                if isDraft
                    state.saving = false
                else
                    state.isDraft = false
                    state.sending = false
                # Don't override local attachments nor message content
                # (server override cid: URLs with relative URLs)
                state[key] = value for key, value of message when key isnt 'attachments' and
                    key isnt 'html' and key isnt 'text'

                state[key] = @state[key] for key in Object.keys(@state) when key isnt "saving"

                # Sometime, when user cancel composing, the component has been
                # unmounted before we come back from autosave, and setState fails
                if @isMounted()
                    @setState state

                if isDraft
                    msgKo = t "message action draft ko"
                else
                    msgKo = t "message action sent ko"
                    msgOk = t "message action sent ok"
                if error? or not message?
                    LayoutActionCreator.alertError "#{msgKo} #{error}"
                else
                    # don't display confirmation message when draft has been saved
                    if not isDraft
                        LayoutActionCreator.notify msgOk, autoclose: true

                    if not @state.id?
                        MessageActionCreator.setCurrent message.id

                    if not isDraft
                        if message.conversationID?
                            # reload conversation to update its length
                            cid = message.conversationID
                            MessageActionCreator.fetchConversation cid
                        @finalRedirect()


    _autosave: ->
        if @props.settings.get 'autosaveDraft'
            @_doSend true


    # set source of attached images
    _cleanHTML: (html) ->
        parser = new DOMParser()
        doc    = parser.parseFromString html, "text/html"

        if not doc
            doc = document.implementation.createHTMLDocument("")
            doc.documentElement.innerHTML = html

        if doc
            # the contentID of attached images will be in the data-src attribute
            # override image source with this attribute
            imageSrc = (image) ->
                image.setAttribute 'src', "cid:#{image.dataset.src}"
            images = doc.querySelectorAll 'IMG[data-src]'
            imageSrc image for image in images

            return doc.documentElement.innerHTML
        else
            console.error "Unable to parse HTML content of message"
            return html


    onDelete: (e) ->
        e.preventDefault()
        subject = @props.message.get 'subject'

        if subject? and subject isnt ''
            params = subject: @props.message.get 'subject'
            confirmMessage = t 'mail confirm delete', params

        else
            confirmMessage = t 'mail confirm delete nosubject'

        doDelete = =>
            LayoutActionCreator.hideModal()
            messageID = @props.message.get('id')
            # this will prevent asking a second time when unmounting component
            @setState isDeleted: true, =>
                MessageActionCreator.delete {messageID}, (error) =>
                    unless error?
                        if @props.callback
                            @props.callback()
                        else
                            parameters = [
                                @props.selectedAccountID
                                @props.selectedMailboxID
                            ]

                            @redirect
                                direction: 'first'
                                action: 'account.mailbox.messages'
                                parameters: parameters
                                fullWidth: true

        modal =
            title       : t 'mail confirm delete title'
            subtitle    : confirmMessage
            closeModal  : ->
                LayoutActionCreator.hideModal()
            closeLabel  : t 'mail confirm delete cancel'
            actionLabel : t 'mail confirm delete delete'
            action      : doDelete
        LayoutActionCreator.displayModal modal


    onToggleCc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-cc'
        focus = if not @state.ccShown then 'cc' else ''
        @setState ccShown: not @state.ccShown, focus: focus


    onToggleBcc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-bcc'
        focus = if not @state.bccShown then 'bcc' else ''
        @setState bccShown: not @state.bccShown, focus: focus


    # Get the file picker component (method used to pass it to the editor)
    getPicker: ->
        return @refs.attachments

