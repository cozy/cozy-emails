{div, h3, a, i, textarea, form, label, button, span, ul, li, input} = React.DOM
classer = React.addons.classSet
AccountStore = require '../stores/AccountStore'
{ComposeActions} = require '../constants/AppConstants'
MessageUtils = require '../utils/MessageUtils'

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
                parameters: @props.selectedAccount?.get 'id'
            rightPanel:
                action: 'compose'

        closeUrl = @buildClosePanelUrl @props.layout

        classLabel = 'col-sm-2 col-sm-offset-0 control-label'
        classInput = 'col-sm-8'

        accounts = AccountStore.getAll()

        if @props.selectedAccount?
            currentAccount = @props.selectedAccount.get 'label'
        else
            currentAccount = @accounts.first

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
                        button id: 'compose-from', className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', onClick: @onMark, null,
                            currentAccount
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            accounts.map (account, key) =>
                                @getAccountRender account, key
                            .toJS()
                div className: 'form-group',
                    label htmlFor: 'compose-to', className: classLabel, t "compose to"
                    div className: classInput,
                        input id: 'compose-to', valueLink: @linkState('to'), type: 'text', className: 'form-control', placeholder: t "compose to help"
                div className: 'form-group',
                    label htmlFor: 'compose-cc', className: classLabel, t "compose cc"
                    div className: classInput,
                        input id: 'compose-cc', valueLink: @linkState('cc'), type: 'text', className: 'form-control', placeholder: t "compose cc help"
                div className: 'form-group',
                    label htmlFor: 'compose-bcc', className: classLabel, t "compose bcc"
                    div className: classInput,
                        input id: 'compose-bcc', valueLink: @linkState('bcc'), type: 'text', className: 'form-control', placeholder: t "compose bcc help"
                div className: 'form-group',
                    label htmlFor: 'compose-subject', className: classLabel, t "compose subject"
                    div className: classInput,
                        input id: 'compose-subject', valueLink: @linkState('subject'), type: 'text', className: 'form-control', placeholder: t "compose subject help"
                div className: 'form-group',
                    textarea defaultValue: @linkState('body').value

    getAccountRender: (account, key) ->

        isSelected = (not @props.selectedAccount? and key is 0) \
                     or @props.selectedAccount?.get('id') is account.id

        li null, selected: isSelected, account.get 'label'

    getInitialState: (forceDefault) ->
        message = @props.message
        if message?
            today = moment()
            date = moment message.get 'createdAt'
            if date.isBefore today, 'year'
                formatter = 'DD/MM/YYYY'
            else if date.isBefore today, 'day'
                formatter = 'DD MMMM'
            else
                formatter = 'hh:mm'
        switch @props.action
            when ComposeActions.REPLY
                return {
                    to: message.getReplyToAddress()
                    cc: ''
                    bcc: ''
                    subject: t('compose reply prefix') + message.get 'subject'
                    body: t('compose reply separator', {date: date.format(formatter), sender: message.get 'from'}) + message.get 'text'
                }
            when ComposeActions.REPLY_ALL
                return {
                    to: MessageUtils.displayAddresses(message.getReplyToAddress(), true)
                    cc: MessageUtils.displayAddresses(Array.concat(message.get('to'), message.get('cc')), true)
                    bcc: ''
                    subject: t('compose reply prefix') + message.get 'subject'
                    body: t('compose reply separator', {date: date.format(formatter), sender: message.get 'from'}) + message.get 'text'
                }
            when ComposeActions.FORWARD
                return {
                    to: ''
                    cc: ''
                    bcc: ''
                    subject: t('compose forward prefix') + message.get 'subject'
                    body: t('compose forward separator', {date: date.format(formatter), sender: message.get 'from'}) + message.get 'text'
                }
            when null
                return {
                    to: ''
                    cc: ''
                    bcc: ''
                    subject: ''
                    body: t 'compose default'
                }
