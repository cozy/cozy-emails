AccountStore = require '../stores/account_store'
LayoutStore = require '../stores/layout_store'
SearchStore = require '../stores/search_store'
MessageStore = require '../stores/message_store'
RefreshesStore = require '../stores/refreshes_store'

RouterGetter = require '../getters/router'

classNames = require 'classnames'
colorhash = require '../utils/colorhash'

class ApplicationGetter

    getState: (name, state) ->
        messageID = MessageStore.getCurrentID()
        inReplyTo = MessageStore.getByID messageID if RouterGetter.isReply()

        return {
            mailboxID       : RouterGetter.getMailboxID()
            accountID       : RouterGetter.getAccountID()
            messageID       : messageID
            message         : MessageStore.getByID messageID
            action          : RouterGetter.getAction()
            isEditable      : RouterGetter.isEditable()
            inReplyTo       : inReplyTo
            currentSearch   : SearchStore.getCurrentSearch()
            modal           : LayoutStore.getModal()
            nextURL         : RouterGetter.getNextURL()
        }

    getProps: (name, props={}) ->
        mailboxID = RouterGetter.getMailboxID()
        accountID = RouterGetter.getMailboxID()

        if 'application' is name
            disposition = LayoutStore.getDisposition()
            isCompact = LayoutStore.getListModeCompact()
            isFullScreen = LayoutStore.isPreviewFullscreen()
            previewSize = LayoutStore.getPreviewSize()
            className = ['layout'
                "layout-#{disposition}"
                if isCompact then "layout-compact"
                "layout-preview-#{previewSize}"].join(' ')

            return {
                 className    : className
            }

        if 'account' is name and (account = props.account) and (state = props.state)
            accountID = account.get 'id'
            isSelected = accountID is RouterGetter.getAccountID()
            mailboxes = RouterGetter.getMailboxes()
            favorites = AccountStore.getSelectedFavorites true

            result = {}
            result.key = 'account-' + accountID
            result.isSelected = isSelected
            result.url = RouterGetter.getURL
                action: 'account.new'
                accountID: accountID
            result.nbUnread = account.get 'totalUnread'
            result.className = classNames active: isSelected
            result.allBoxesAreFavorite = mailboxes?.size is favorites?.size
            result.accountColor  = colorhash(account.get 'label')
            result.urlconfig = RouterGetter.getURL
                action: 'account.edit'
                accountID: accountID
            result.progress = RefreshesStore.getRefreshing().get accountID
            result.icon = 'fa fa-ellipsis-h'

            if state.onlyFavorites
                mailboxes = favorites
                result.toggleFavoritesLabel = t 'menu favorites off'
            else
                result.toggleFavoritesLabel = t 'menu favorites on'

            # This is here for a convenient way to fond special mailboxes names.
            # NOTE: should we externalize them in app_constants?
            specialMailboxes = [
                'inboxMailbox'
                'draftMailbox'
                'sentMailbox'
                'trashMailbox'
                'junkMailbox'
                'allMailbox'
            ]
            specialMboxes = specialMailboxes?.map (mailbox) ->
                account.get mailbox
            result.specialMboxes = mailboxes?.filter (mailbox) ->
                mailbox.get('id') in specialMboxes
            result.unSpecialMboxes = mailboxes?.filter (mailbox) ->
                mailbox.get('id') not in specialMboxes
            return result


module.exports = new ApplicationGetter()
