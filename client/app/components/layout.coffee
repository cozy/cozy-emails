React = require 'react'
{div, section, main, h1, img, p} = React.DOM

AriaTips = require '../../vendor/aria-tips/aria-tips'

Menu                  = React.createFactory require './menu/menu'
Modal                 = React.createFactory require './modal'
ToastContainer        = React.createFactory require './toast_container'
Tooltips              = React.createFactory require './tooltips-manager'
MessageList           = React.createFactory require './message_list'
Conversation          = React.createFactory require './conversation'
AccountWizardCreation = React.createFactory require './accounts/wizard/creation'

{AccountActions} = require '../constants/app_constants'


module.exports = React.createClass

    displayName: 'layout'

    # AriaTips must bind the elements declared as tooltip to their
    # respective tooltip when the component is mounted (DOM elements exist).
    componentDidMount: ->
        AriaTips.bind()

    render: ->
        className = "layout layout-column layout-preview-#{@props.previewSize}"

        if @props.isIndexing
            return div className: 'reindexing-message',
                img
                    className: 'spinner'
                    src: "img/spinner.svg"
                h1 null,
                    'We need to reindex your emails.'
                p null,
                    'This page will refresh in a minute.'
        div {className},
            div className: 'app',
                Menu
                    ref             : 'menu'
                    key             : 'menu-' + @props.accountID
                    accountID       : @props.accountID
                    mailboxID       : @props.mailboxID
                    accounts        : @props.accounts
                    composeURL      : @props.composeURL
                    newAccountURL   : @props.newAccountURL
                    nbUnread        : @props.nbUnread
                    nbFlagged       : @props.nbFlagged
                    displayModal    : @props.displayModal
                    isMailboxLoading: @props.isMailboxLoading
                    isRefreshError: @props.isRefreshError

                main null,
                    div
                        className: 'panels',

                        if @props.lastSync?
                            MessageList
                                ref                 : "messageList"
                                key                 : "messageList-#{@props.mailboxID}-#{@props.conversationsLengths}"
                                accountID           : @props.accountID
                                mailboxID           : @props.mailboxID
                                conversationID      : @props.conversationID
                                messages            : @props.messages
                                emptyMessages       : @props.emptyMessages
                                isAllSelected       : @props.isAllSelected
                                selection           : @props.selection
                                hasNextPage         : @props.hasNextPage
                                lastSync            : @props.lastSync
                                isLoading           : @props.isLoading
                                onLoadMore          : @props.onLoadMore
                                login               : @props.login
                                gotoConversation    : @props.gotoConversation
                                conversationsLengths: @props.conversationsLengths
                                contacts            : @props.contacts

                        if @props.lastSync? and @props.messageID
                            Conversation
                                ref                     : "conversation"
                                key                     : "conversation-#{@props.messageID}"
                                accountID               : @props.accountID
                                messageID               : @props.messageID
                                conversationID          : @props.conversationID
                                subject                 : @props.subject
                                messages                : @props.conversation
                                contacts                : @props.contacts
                                isConversationLoading   : @props.isConversationLoading
                                isTrashbox   : @props.isTrashbox
                                trashboxID: @props.trashboxID
                                displayModal: @props.displayModal
                                doDisplayImages: @props.doDisplayImages
                                doDeleteMessage: @props.doDeleteMessage
                                doMarkMessage: @props.doMarkMessage
                                doCloseConversation: @props.doCloseConversation
                                doGotoMessage: @props.doGotoMessage

                        else
                            section
                                'key'          : 'placeholder'
                                'aria-expanded': false


            if @props.action is AccountActions.CREATE


                AccountWizardCreation
                    key: 'modal-account-wizard'
                    isBusy: @props.creation_isBusy
                    isDiscoverable: @props.creation_isDiscoverable
                    alert: @props.creation_alert
                    OAuth: @props.creation_OAuth
                    account: @props.creation_account
                    discover: @props.creation_discover

                    doAccountDiscover : @props.doAccountDiscover
                    doAccountCheck    : @props.doAccountCheck
                    doCloseModal      : @props.doCloseModal



            # Display feedback
            Modal @props.modal if @props.modal?


            ToastContainer
                toasts: @props.toasts
                hidden: @props.toastsHidden
                displayModal: @props.displayModal
                doDeleteToast: @props.doDeleteToast
                toastsHide: @props.toastHide
                toastsShow: @props.toastsShow
                clearToasts: @props.clearToasts


            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips key: "tooltips"
