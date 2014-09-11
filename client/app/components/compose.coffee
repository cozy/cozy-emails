{div, h3, a, i, textarea, form, label, button, span, ul, li, input} = React.DOM
classer = React.addons.classSet
AccountStore  = require '../stores/AccountStore'
SettingsStore = require '../stores/SettingsStore'

{ComposeActions} = require '../constants/AppConstants'

MessageUtils = require '../utils/MessageUtils'

LayoutActionCreator  = require '../actions/LayoutActionCreator'
MessageActionCreator = require '../actions/MessageActionCreator'

RouterMixin = require '../mixins/RouterMixin'

module.exports = Compose = React.createClass
    displayName: 'Compose'

    mixins: [
        RouterMixin,
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->

        expandUrl = @buildUrl
            direction: 'left'
            action: 'compose'
            fullWidth: true

        collapseUrl = @buildUrl
            leftPanel:
                action: 'account.mailbox.messages'
                parameters: @state.currentAccount?.get 'id'
            rightPanel:
                action: 'compose'

        closeUrl = @buildClosePanelUrl @props.layout

        classLabel = 'col-sm-2 col-sm-offset-0 control-label'
        classInput = 'col-sm-8'

        accounts = AccountStore.getAll()

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
                            accounts.map (account, key) =>
                                @getAccountRender account, key
                            .toJS()
                div className: 'form-group',
                    label htmlFor: 'compose-to', className: classLabel, t "compose to"
                    div className: classInput,
                        input id: 'compose-to', ref: 'to', valueLink: @linkState('to'), type: 'text', className: 'form-control', placeholder: t "compose to help"
                div className: 'form-group',
                    label htmlFor: 'compose-cc', className: classLabel, t "compose cc"
                    div className: classInput,
                        input id: 'compose-cc', ref: 'cc', valueLink: @linkState('cc'), type: 'text', className: 'form-control', placeholder: t "compose cc help"
                div className: 'form-group',
                    label htmlFor: 'compose-bcc', className: classLabel, t "compose bcc"
                    div className: classInput,
                        input id: 'compose-bcc', ref: 'bcc', valueLink: @linkState('bcc'), type: 'text', className: 'form-control', placeholder: t "compose bcc help"
                div className: 'form-group',
                    label htmlFor: 'compose-subject', className: classLabel, t "compose subject"
                    div className: classInput,
                        input id: 'compose-subject', ref: 'subject', valueLink: @linkState('subject'), type: 'text', className: 'form-control', placeholder: t "compose subject help"
                div className: 'form-group',
                    if @state.composeInHTML
                        div className: 'rt-editor', contentEditable: true, dangerouslySetInnerHTML: {__html: @linkState('html').value}
                    else
                        textarea className: 'editor', ref: 'content', defaultValue: @linkState('body').value
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
            jQuery('#email-compose .rt-editor').on('keypress', (e) ->
                if e.keyCode is 13
                    # timeout to let the editeor perform its own stuff
                    setTimeout ->
                        target = document.getSelection().anchorNode
                        if target.lastChild
                            target = target.lastChild.previousElementSibling
                        parent = target
                        p2 = null
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
                        process() while (parent.parentNode? && not parent.parentNode.classList.contains 'rt-editor')
                        second = p2
                        inserted = document.createElement 'p'
                        inserted.innerHTML = "<br />"
                        if parent.nextSibling
                            parent.parentNode.insertBefore inserted, parent.nextSibling
                            parent.parentNode.insertBefore second, parent.nextSibling
                        else
                            parent.parentNode.appendChild inserted
                            parent.parentNode.appendChild second

                        inserted.focus()
                        sel = window.getSelection()
                        sel.collapse inserted, 0
                    , 50
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
            composeInHTML:  SettingsStore.get 'composeInHTML'

        if message?
            today = moment()
            date = moment message.get 'createdAt'
            if date.isBefore today, 'year'
                formatter = 'DD/MM/YYYY'
            else if date.isBefore today, 'day'
                formatter = 'DD MMMM'
            else
                formatter = 'hh:mm'
            dateHuman = date.format(formatter)
            sender = MessageUtils.displayAddresses(message.get 'from')

            text = message.get 'text'
            html = message.get 'html'

            if text and not html and state.composeInHTML
                html = markdown.toHTML text

            if html and not text and not state.composeInHTML
                text = toMarkdown html

        switch @props.action
            when ComposeActions.REPLY
                state.to = MessageUtils.displayAddresses message.getReplyToAddress(), true
                state.cc = ''
                state.bcc = ''
                state.subject = "#{t 'compose reply prefix'}#{message.get 'subject'}"
                state.body = t('compose reply separator', {date: dateHuman, sender: sender}) +
                    MessageUtils.generateReplyText(text) + "\n"
                state.html = """
                    <p>#{t('compose reply separator', {date: dateHuman, sender: sender})}</p>
                    <blockquote>#{html}</blockquote>
                    """
            when ComposeActions.REPLY_ALL
                state.to = MessageUtils.displayAddresses(message.getReplyToAddress(), true)
                state.cc = MessageUtils.displayAddresses(Array.concat(message.get('to'), message.get('cc')), true)
                state.bcc = ''
                state.subject = "#{t 'compose reply prefix'}#{message.get 'subject'}"
                state.body = t('compose reply separator', {date: dateHuman, sender: sender}) +
                    MessageUtils.generateReplyText(text) + "\n"
                state.html = """
                    <p>#{t('compose reply separator', {date: dateHuman, sender: sender})}</p>
                    <blockquote>#{html}</blockquote>
                    """
            when ComposeActions.FORWARD
                state.to = ''
                state.cc = ''
                state.bcc = ''
                state.subject = "#{t 'compose forward prefix'}#{message.get 'subject'}"
                state.body = t('compose forward separator', {date: dateHuman, sender: sender}) + text
                state.html = "<p>#{t('compose forward separator', {date: dateHuman, sender: sender})}</p>" + html

            when null
                state.to      = ''
                state.cc      = ''
                state.bcc     = ''
                state.subject = ''
                state.body    = t 'compose default'

        return state

    onAccountChange: (args) ->
        selected = args.target.dataset.value
        if (selected isnt @state.currentAccount.get 'id')
            @setState currentAccount : AccountStore.getByID selected
            #this.refs.account.getDOMNode().innerHTML = @state.currentAccount.get 'label'

    onDraft: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"

    onSend: (args) ->
        message =
            from        : @state.currentAccount.get 'login'
            to          : this.refs.to.getDOMNode().value.trim()
            cc          : this.refs.cc.getDOMNode().value.trim()
            bcc         : this.refs.bcc.getDOMNode().value.trim()
            subject     : this.refs.subject.getDOMNode().value.trim()
            #headers     :
            #date        :
            #encoding    :

        if @state.composeInHTML
            message.html    = this.refs.html.getDOMNode().innerHTML
            message.content = toMarkdown(message.html)
        else
            message.content = this.refs.content.getDOMNode().value.trim()

        if @props.message?
            msg   = @props.message
            msgId = msg.get 'id'
            message.inReplyTo = msgId

            references = msg.references
            if references?
                message.references = references + msgId
            else
                message.references = msgId

        callback = @props.callback
        MessageActionCreator.send message, (error) ->
            if error?
                LayoutActionCreator.alertError(t "message action sent ko") + error
            else
                LayoutActionCreator.alertSuccess t "message action sent ok"
            if callback?
                callback error
