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

    getInitialState: ->
        MessageUtils.makeReplyMessage @props

    isNew: ->
        not @state.originalConversationID

    unsetNew: ->
        @state.originalConversationID = @state.conversationID

    shouldComponentUpdate: (nextProps, nextState) ->
        !!nextProps.accounts

    componentWillUpdate: (nextProps, nextState) ->
        nextState.attachments = Immutable.Vector.from nextState.attachments
        if nextState.composeInHTML
            nextState.html = MessageUtils.cleanHTML nextState.html
            nextState.text = MessageUtils.cleanReplyText nextState.html
            nextState.html = MessageUtils.wrapReplyHtml nextState.html
        else
            nextState.text = nextState.text.trim()

    componentDidMount: ->
        # scroll compose window into view
        @getDOMNode().scrollIntoView()

        # Focus
        if not Array.isArray(@state.to) or @state.to.length is 0
            setTimeout ->
                document.getElementById('compose-to')?.focus()
            , 10
        else if @props.inReplyTo?
            document.getElementById('compose-editor')?.focus()

    componentDidUpdate: ->
        # Initialize @state
        # with values from server
        @saveDraft() if @isNew()

        # focus
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
        success = (error, message) =>
            msg = "#{t "message action draft ok"}"
            LayoutActionCreator.notify msg, autoclose: true

            # reload conversation to update its length
            if message and message.conversationID?
                cid = message.conversationID
                MessageActionCreator.fetchConversation cid

        unless (hasChanged = @props.lastUpdate isnt @state.date)
            message = @state
            error = null
            setTimeout ->
                success error, message
            , 0
            return

        # Show Modal
        init = =>
            @showModal
                title       : t 'app confirm delete'
                subtitle    : t 'compose confirm keep draft'
                closeLabel  : t 'compose confirm draft keep'
                actionLabel : t 'compose confirm draft delete'
                closeModal  : =>
                    LayoutActionCreator.hideModal()
                    MessageActionCreator.send @state, (error, message) ->
                        if error? or not message?
                            msg = "#{t "message action draft ko"} #{error}"
                            LayoutActionCreator.alertError msg
                            success error, message
                            return

                        success error, message

        setTimeout init, 0

    render: ->
        # Each render do not send data to server
        # update date for client modifications
        @state.date = new Date().toISOString()

        closeUrl = @buildClosePanelUrl @props.layout

        classLabel = 'compose-label'
        classInput = 'compose-input'

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
                                    onClick: @toggleField,
                                    'data-ref': 'cc'
                                    t 'compose toggle cc'
                                a
                                    className: 'compose-toggle-bcc',
                                    onClick: @toggleField,
                                    'data-ref': 'bcc'
                                    t 'compose toggle bcc'

                MailsInput
                    id: 'compose-to'
                    valueLink: @linkState 'to'
                    label: t 'compose to'
                    ref: 'to'

                MailsInput
                    id: 'compose-cc'
                    className: 'compose-cc'
                    valueLink: @linkState 'cc'
                    label: t 'compose cc'
                    placeholder: t 'compose cc help'
                    ref: 'cc'

                MailsInput
                    id: 'compose-bcc'
                    className: 'compose-bcc'
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
                            valueLink: @linkState 'subject'
                            type: 'text'
                            className: 'form-control compose-subject'
                            placeholder: t "compose subject help"

                div className: 'compose-content',
                    ComposeEditor
                        id                : 'compose-editor'
                        messageID         : @state.id
                        html              : @linkState('html')
                        text              : @linkState('text')
                        accounts          : @props.accounts
                        accountID         : @state.accountID
                        settings          : @props.settings
                        onSend            : @sendMessage
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
                    send      : @sendMessage
                    delete    : @deleteDraft
                    save      : @saveDraft
                    cancel    : @close
                    canDelete : @state.id?
                    ref: 'toolbox'

                div className: 'clearfix', null


    # If we are answering to a message, canceling should bring back to
    # this message.
    # The message URL requires many information: account ID, mailbox ID,
    # conversation ID and message ID. These infor are collected via current
    # selection and message information.
    finalRedirect: ->
        if @props.inReplyTo?
            conversationID = @state.conversationID
            accountID = @props.selectedAccountID
            messageID = @state.id
            mailboxes = Object.keys @props.inReplyTo.get 'mailboxIDs'
            mailboxID = AccountStore.pickBestBox accountID, mailboxes

            @redirect
                firstPanel:
                    action: 'account.mailbox.messages'
                    parameters: {accountID, mailboxID}

                secondPanel:
                    action: 'conversation'
                    parameters: {conversationID, messageID}

        # Else it should bring to the default view
        else
            @redirect
                direction: 'first'
                action: 'default'
                fullWidth: true

    # Cancel brings back to default view. If it's while replying to a message,
    # it brings back to this message.
    close: (event) ->
        event.preventDefault()

        # Action after cancelation: call @props.onCancel
        # or navigate to message list.
        if @props.onCancel?
            @props.onCancel()
        else
            @finalRedirect()

    showModal: (params, success) ->
        return if @isNew()

        doDelete = =>
            messageID = @state.id
            MessageActionCreator.delete {messageID}
            LayoutActionCreator.hideModal()

            if @props.callback
                @props.callback()
                return

            # specific callback
            success() if _.isFunction success

        _.extend params, action: doDelete
        LayoutActionCreator.displayModal params

    saveDraft: (event) ->
        event.preventDefault() if event?
        @state.isDraft = true
        @sendActionMessage =>
            @refs.toolbox.setState action: null if @refs.toolbox

    sendMessage: (event) ->
        event.preventDefault() if event?
        @state.isDraft = false
        @sendActionMessage =>
            @refs.toolbox.setState action: null if @refs.toolbox

    validateMessage: ->
        return if @state.isDraft
        error = 'dest': ['to']
        getGroupedError error, @state, _.isEmpty

    sendActionMessage: (success) ->
        return if @props.isSaving
        if (validate = @validateMessage())
            LayoutActionCreator.alertError t 'compose error no ' + validate[1]
            success() if _.isFunction success
            return

        @props.isSaving = true
        @props.lastUpdate = @state.date
        MessageActionCreator.send @state, (error, message) =>
            if error? or not message?
                if @state.isDraft
                    msgKo = t "message action draft ko"
                else
                    msgKo = t "message action sent ko"
                LayoutActionCreator.alertError "#{msgKo} #{error}"

                @props.isSaving = false
                success() if _.isFunction success
                return

            unless @state.id
                MessageActionCreator.setCurrent message.id

                # Initialize @state
                # Must stay silent (do not use setState)
                _keys = _.without _.keys(message), 'attachments', 'html', 'text'
                _.each _keys, (key) =>
                    if _.isUndefined @state[key]
                        @state[key] = message[key]

            # use another field to prevent the empty conversationID of draft
            # to override the original conversationID
            @unsetNew() if @isNew()

            # TODO : move this into render
            unless @state.isDraft
                # Display confirmation message
                # for no-draft email
                msgOk = t "message action sent ok"
                LayoutActionCreator.notify msgOk, autoclose: true

                # reload conversation to update its length
                if (cid = message.conversationID)
                    MessageActionCreator.fetchConversation cid

                @finalRedirect()

            @props.isSaving = false
            success() if _.isFunction success

    deleteDraft: (event) ->
        event.preventDefault() if event

        if _.isEmpty (subject = @state.subject)
            params = subject: subject
            confirmMessage = t 'mail confirm delete', params
        else
            confirmMessage = t 'mail confirm delete nosubject'

        doDelete = =>
            @redirect
                direction: 'first'
                action: 'account.mailbox.messages'
                fullWidth: true
                parameters: [
                    @props.selectedAccountID
                    @props.selectedMailboxID
                ]

        @showModal
            title       : t 'mail confirm delete title'
            subtitle    : confirmMessage
            closeLabel  : t 'mail confirm delete cancel'
            actionLabel : t 'mail confirm delete delete'
        , doDelete

    toggleField: (event) ->
        target = event.currentTarget.getAttribute 'data-ref'
        element = @refs[target].getDOMNode()
        element.classList.toggle 'shown'

    # Get the file picker component (method used to pass it to the editor)
    getPicker: ->
        return @refs.attachments

getGroupedError = (error, message, test) ->
    type = null
    group = null
    _.find error, (properties, key) ->
        type = _.find properties, (property) ->
            test message[property]
        group = key if type?
        type
    if type or group then [type, group] else null
