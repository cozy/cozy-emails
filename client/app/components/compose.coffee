{div, h3, a, i, textarea, form, label, button, span, ul, li, input} = React.DOM
classer = React.addons.classSet

FilePicker = require './file_picker'
MailsInput = require './mails_input'

{ComposeActions} = require '../constants/app_constants'

MessageUtils = require '../utils/message_utils'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

RouterMixin = require '../mixins/router_mixin'

module.exports = Compose = React.createClass
    displayName: 'Compose'

    mixins: [
        RouterMixin,
        React.addons.LinkedStateMixin # two-way data binding
    ]

    propTypes:
        selectedAccount: React.PropTypes.object.isRequired
        layout:          React.PropTypes.string.isRequired
        accounts:        React.PropTypes.object.isRequired
        message:         React.PropTypes.object
        action:          React.PropTypes.string
        callback:        React.PropTypes.func
        settings:        React.PropTypes.object.isRequired

    render: ->

        expandUrl = @buildUrl
            direction: 'first'
            action: 'compose'
            fullWidth: true

        collapseUrl = @buildUrl
            firstPanel:
                action: 'account.mailbox.messages'
                parameters: @state.currentAccount?.get 'id'
            secondPanel:
                action: 'compose'

        closeUrl = @buildClosePanelUrl @props.layout

        classLabel = 'col-sm-2 col-sm-offset-0 control-label'
        classInput = 'col-sm-8'

        div id: 'email-compose',
            h3 null,
                a href: closeUrl, className: 'close-email hidden-xs hidden-sm',
                    i className:'fa fa-times'
                t 'compose'
                if @props.layout isnt 'full'
                    a href: expandUrl, className: 'expand hidden-xs hidden-sm',
                        i className: 'fa fa-arrows-h'
                else
                    a href: collapseUrl, className: 'close-email pull-right',
                        i className:'fa fa-compress'
            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'compose-from', className: classLabel, t "compose from"
                    div className: classInput,
                        button id: 'compose-from', className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', null,
                            span ref: 'account', @state.currentAccount.get 'label'
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            @props.accounts.map (account, key) =>
                                @getAccountRender account, key
                            .toJS()
                        div className: 'btn-toolbar compose-toggle', role: 'toolbar',
                            div className: 'btn-group btn-group-sm',
                                button className: 'btn btn-default', type: 'button', onClick: @onToggleCc,
                                    span className: 'tool-long', t 'compose toggle cc'
                            div className: 'btn-group btn-group-sm',
                                button className: 'btn btn-default', type: 'button', onClick: @onToggleBcc,
                                    span className: 'tool-long', t 'compose toggle bcc'


                MailsInput
                    id: 'compose-to'
                    valueLink: @linkState 'to'
                    label: t 'compose to'
                    placeholder: t 'compose to help'

                MailsInput
                    id: 'compose-cc'
                    className: 'compose-cc'
                    valueLink: @linkState 'cc'
                    label: t 'compose cc'
                    placeholder: t 'compose cc help'

                MailsInput
                    id: 'compose-bcc'
                    className: 'compose-bcc'
                    valueLink: @linkState 'bcc'
                    label: t 'compose bcc'
                    placeholder: t 'compose bcc help'

                div className: 'form-group',
                    label htmlFor: 'compose-subject', className: classLabel, t "compose subject"
                    div className: classInput,
                        input id: 'compose-subject', ref: 'subject', valueLink: @linkState('subject'), type: 'text', className: 'form-control', placeholder: t "compose subject help"
                div className: 'form-group',
                    if @state.composeInHTML
                        div className: 'rt-editor form-control', ref: 'html', contentEditable: true, dangerouslySetInnerHTML: {__html: @linkState('html').value}
                    else
                        textarea className: 'editor', ref: 'content', defaultValue: @linkState('body').value
                
                div className: 'attachements', FilePicker 
                    editable: true
                    form: false
                    valueLink: @linkState 'attachments'
                
                div className: 'composeToolbox',
                    div className: 'btn-toolbar', role: 'toolbar',
                        div className: 'btn-group btn-group-sm',
                            button className: 'btn btn-default', type: 'button', onClick: @onDraft,
                                span className: 'fa fa-save'
                                span className: 'tool-long', t 'compose action draft'
                        div className: 'btn-group btn-group-lg',
                            button className: 'btn btn-default', type: 'button', onClick: @onSend,
                                span className: 'fa fa-send'
                                span className: 'tool-long', t 'compose action send'

    componentDidMount: ->
        # scroll compose window into view
        node = @getDOMNode()
        node.scrollIntoView()
        if @state.composeInHTML
            # Some DOM manipulation when replying inside the message.
            # When inserting a new line, we must close all blockquotes,
            # insert a blank line and then open again blockquotes
            jQuery('#email-compose .rt-editor').on('keypress', (e) ->
                if e.keyCode is 13
                    # timeout to let the editor perform its own stuff
                    setTimeout ->
                        matchesSelector = document.documentElement.matches or
                              document.documentElement.matchesSelector or
                              document.documentElement.webkitMatchesSelector or
                              document.documentElement.mozMatchesSelector or
                              document.documentElement.oMatchesSelector or
                              document.documentElement.msMatchesSelector

                        target = document.getSelection().anchorNode
                        if matchesSelector? and not matchesSelector.call(target, '.rt-editor blockquote *')
                            # we are not inside a blockquote, nothing to do
                            return

                        if target.lastChild
                            target = target.lastChild.previousElementSibling
                        parent = target

                        # alternative 1
                        # we create 2 ranges, one from the begining of message
                        # to the caret position, the second from caret to the
                        # end. We then create fragments from the ranges and
                        # override message with first fragment, a blank line
                        # and second fragment
                        process = ->
                            current = parent
                            parent = parent?.parentNode
                        process()
                        process() while (parent? and
                            not parent.classList.contains 'rt-editor')
                        rangeBefore = document.createRange()
                        rangeBefore.setEnd target, 0
                        rangeBefore.setStartBefore parent.firstChild
                        rangeAfter = document.createRange()
                        if target.nextSibling?
                            # remove the BR the <enter> key probably inserted
                            rangeAfter.setStart target.nextSibling, 0
                        else
                            rangeAfter.setStart target, 0
                        rangeAfter.setEndAfter parent.lastChild
                        before = rangeBefore.cloneContents()
                        after = rangeAfter.cloneContents()
                        inserted = document.createElement 'p'
                        inserted.innerHTML = "<br />"
                        parent.innerHTML = ""
                        parent.appendChild before
                        parent.appendChild inserted
                        parent.appendChild after

                        ###
                        # alternative 2
                        # We move every node from the caret to the end of the
                        # message to a new DOM tree, then insert a blank line
                        # and the new tree
                        parent = target
                        p2 = null
                        p3 = null
                        process = ->
                            p3 = p2
                            current = parent
                            parent = parent.parentNode
                            p2 = parent.cloneNode false
                            if p3?
                                p2.appendChild p3
                            s = current.nextSibling
                            while s?
                                p2.appendChild(s.cloneNode(true))
                                s2 = s.nextSibling
                                parent.removeChild s
                                s = s2
                        process()
                        process() while (parent.parentNode? and
                            not parent.parentNode.classList.contains 'rt-editor')
                        after = p2
                        inserted = document.createElement 'p'
                        inserted.innerHTML = "<br />"
                        if parent.nextSibling
                            parent.parentNode.insertBefore inserted, parent.nextSibling
                            parent.parentNode.insertBefore after, parent.nextSibling
                        else
                            parent.parentNode.appendChild inserted
                            parent.parentNode.appendChild after
                        ###

                        inserted.focus()
                        sel = window.getSelection()
                        sel.collapse inserted, 0

                    , 0
            )


    getAccountRender: (account, key) ->

        isSelected = (not @state.currentAccount? and key is 0) \
                     or @state.currentAccount?.get('id') is account.get 'id'

        if not isSelected
            li role: 'presentation', key: key,
                a role: 'menuitem', onClick: @onAccountChange, 'data-value': key, account.get 'label'

    getInitialState: (forceDefault) ->
        message = @props.message
        state =
            currentAccount: @props.selectedAccount
            composeInHTML:  @props.settings.get 'composeInHTML'
            attachments: []


        return state

    onAccountChange: (args) ->
        selected = args.target.dataset.value
        if (selected isnt @state.currentAccount.get 'id')
            @setState currentAccount : @props.accounts.get selected
            #this.refs.account.getDOMNode().innerHTML = @state.currentAccount.get 'label'

    onDraft: (args) ->
        @_doSend true

    onSend: (args) ->
        @_doSend false

    _doSend: (isDraft) ->

        account = @props.accounts.get @state.accountID

        from = 
            name: account?.get('name') or undefined
            address: account.get('login')

        unless ~from.address.indexOf '@'
            from.address += '@' + account.get('imapServer')

        message =
            from        : [from]
            to          : @state.to
            cc          : @state.cc
            bcc         : @state.bcc
            subject     : this.refs.subject.getDOMNode().value.trim()
            isDraft     : isDraft
            attachments : @state.attachments


        if @state.composeInHTML
            message.html    = this.refs.html.getDOMNode().innerHTML
            message.content = toMarkdown(message.html)
        else
            message.content = this.refs.content.getDOMNode().value.trim()

        callback = @props.callback

        MessageActionCreator.send message, (error) ->
            if isDraft
                msgKo = t "message action draft ko"
                msgOk = t "message action draft ok"
            else
                msgKo = t "message action sent ko"
                msgOk = t "message action sent ok"
            if error?
                LayoutActionCreator.alertError "#{msgKo} :  error"
            else
                LayoutActionCreator.alertSuccess msgOk
            if callback?
                callback error

    onToggleCc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-cc'

    onToggleBcc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-bcc'
