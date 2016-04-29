_          = require 'underscore'
classNames = require 'classnames'
React      = require 'react'
ReactDOM   = require 'react-dom'

{div, section, a, form, label, input} = React.DOM

ComposeEditor  = React.createFactory require './compose_editor'
ComposeToolbox = React.createFactory require './compose_toolbox'
FilePicker     = React.createFactory require './file_picker'
MailsInput     = React.createFactory require './mails_input'
AccountPicker  = React.createFactory require './account_picker'

LayoutStore = require '../stores/layout_store'

RouterGetter = require '../getters/router'

MessageUtils = require '../utils/message_utils'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
RouterActionCreator = require '../actions/router_action_creator'
NotificationActionsCreator = require '../actions/notification_action_creator'

LinkedStateMixin = require 'react-addons-linked-state-mixin'

{MessageActions} = require '../constants/app_constants'

# Component that allows the user to write emails.
module.exports = React.createClass
    displayName: 'Compose'

    mixins: [
        LinkedStateMixin
    ]

    propTypes:
        message:    React.PropTypes.object
        id:         React.PropTypes.string
        message:    React.PropTypes.object
        inReplyTo:  React.PropTypes.object
        account:    React.PropTypes.object
        action:     React.PropTypes.string
        settings:   React.PropTypes.object.isRequired

    getInitialState: ->
        MessageUtils.createBasicMessage @props

    isNew: ->
        not @state.conversationID

    getChildKey: (name) ->
        'compose-' + (@state.id or 'new') + '-' + name

    componentWillReceiveProps: (nextProps) ->
        @setState MessageUtils.createBasicMessage nextProps
        nextProps

    componentDidMount: ->
        # scroll compose window into view
        @refs.compose.scrollIntoView()

        # Compare changes
        @_oldState = @state

    componentDidUpdate: ->
        # Initialize @state
        # with values from server
        @saveDraft() if @isNew() and @hasChanged()


    hasChanged: (props, state) ->
        _diff = _.filter @state, (value, key) =>
            @_oldState[key] isnt value
        _diff?.length

    resetChange: (message) ->
        if message
            @state.mailboxIDs = message.mailboxIDs
            @state.id = message.id
            @state.conversationID = message.conversationID
        @_oldState = @state

    componentWillUnmount: ->
        # Save Message into Draft
        if @hasChanged()
            MessageActionCreator.send 'UNMOUNT', _.clone @state

    render: ->
        classLabel = 'compose-label'
        classInput = 'compose-input'

        section
            ref: 'compose'
            className: classNames
                compose: true
                panel: true
            'aria-expanded': true,

            form className: 'form-compose', method: 'POST',
                div className: 'form-group account',
                    label
                        htmlFor: 'compose-from',
                        className: classLabel,
                        t "compose from"
                    AccountPicker
                        accounts: RouterGetter.getAccounts()
                        signature: RouterGetter.getAccountSignature()
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
                    key: @getChildKey 'to'

                MailsInput
                    id: 'compose-cc'
                    className: 'compose-cc'
                    valueLink: @linkState 'cc'
                    label: t 'compose cc'
                    placeholder: t 'compose cc help'
                    ref: 'cc'
                    key: @getChildKey 'cc'

                MailsInput
                    id: 'compose-bcc'
                    className: 'compose-bcc'
                    valueLink: @linkState 'bcc'
                    label: t 'compose bcc'
                    placeholder: t 'compose bcc help'
                    ref: 'bcc'
                    key: @getChildKey 'bcc'

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
                        account           : @props.account
                        settings          : @props.settings
                        onSend            : @sendMessage
                        composeInHTML     : @state.composeInHTML
                        getPicker         : @getPicker
                        useIntents        : LayoutStore.intentAvailable()
                        ref               : 'editor'
                        key               : @getChildKey 'editor'

                div className: 'attachements',
                    FilePicker
                        className: ''
                        editable: true
                        valueLink: @linkState 'attachments'
                        ref: 'attachments'
                        key: @getChildKey 'attachments'

                ComposeToolbox
                    send      : @sendMessage
                    delete    : @deleteDraft
                    save      : @saveDraft
                    cancel    : @close
                    canDelete : @state.id?
                    ref       : 'toolbox'
                    key       : @getChildKey 'toolbox'

                div className: 'clearfix', null


    # If we are answering to a message, canceling should bring back to
    # this message.
    # The message URL requires many information: account ID, mailbox ID,
    # conversation ID and message ID. These infor are collected via current
    # selection and message information.
    finalRedirect: ->
        # FIXME : it should be into message_action_creator
        RouterActionCreator.gotoMessage
            messageID: @state.id

    # Cancel brings back to default view.
    # If it's while replying to a message,
    # it brings back to this message.
    close: (event) ->
        @finalRedirect()

    showModal: (params, success) ->
        return if @isNew()

        doDelete = =>
            # Do not try to save client changes
            # After deleting message
            @resetChange()

            messageID = @state.id
            MessageActionCreator.delete {messageID}
            LayoutActionCreator.hideModal()

            # specific callback
            success() if _.isFunction success

        _.extend params, action: doDelete
        LayoutActionCreator.displayModal params

    saveDraft: (event) ->
        event.preventDefault() if event?
        @state.isDraft = true
        @sendActionMessage 'SAVE_DRAFT', =>
            @refs.toolbox.setState action: null if @refs.toolbox

    sendMessage: (event) ->
        event.preventDefault() if event?
        @state.isDraft = false

        @sendActionMessage 'MESSAGE_SEND_REQUEST', @finalRedirect

    validateMessage: ->
        return if @state.isDraft
        error = 'dest': ['to']
        getGroupedError error, @state, _.isEmpty

    sendActionMessage: (action, success) ->
        return if @state.isSaving
        if (validate = @validateMessage())
            NotificationActionsCreator.alertError t 'compose error no ' + validate[1]
            success(null, @state) if _.isFunction success
            return

        # Do not save twice
        @state.isSaving = true

        MessageActionCreator.send action, _.clone(@state), (error, message) =>
            delete @state.isSaving

            return if error? or not message?

            # Check for Updates
            @resetChange message

            unless @state.id
                # Update Info before the unmount
                # that will autosave the message
                @state.id = message.id
                @state.conversationID = message.conversationID

                # Refresh page with the right messageID
                RouterActionCreator.gotoMessage
                    action: MessageActions.EDIT
                    messageID: message.id
                return

            else if _.isFunction success
                success error, message


    deleteDraft: (event) ->
        event.preventDefault() if event

        if _.isEmpty (subject = @state.subject)
            params = subject: subject
            confirmMessage = t 'mail confirm delete', params
        else
            confirmMessage = t 'mail confirm delete nosubject'

        @showModal
            title       : t 'mail confirm delete title'
            subtitle    : confirmMessage
            closeLabel  : t 'mail confirm delete cancel'
            actionLabel : t 'mail confirm delete delete'
        , @finalRedirect

    toggleField: (event) ->
        ref = event.currentTarget.getAttribute 'data-ref'
        view = @refs[ref]
        value = !view.state.focus

        view.setState focus: value

    # Get the file picker component
    # method used to pass it to the editor
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
