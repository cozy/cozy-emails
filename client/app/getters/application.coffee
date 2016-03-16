AccountStore = require '../stores/account_store'
LayoutStore = require '../stores/layout_store'
SearchStore = require '../stores/search_store'
MessageStore = require '../stores/message_store'
RefreshesStore = require '../stores/refreshes_store'

RouteGetter = require '../getters/router'

classNames = require 'classnames'
colorhash = require '../utils/colorhash'

class ApplicationGetter

    getState: (name, state={}) ->
        if 'menu' is name
            # Filter Accounts
            # FIXME : it should be into AccountStore
            accounts = AccountStore.getAll().sort (account1, account2) ->
                if selectedAccount?.get('id') is account1.get('id')
                    return -1
                if selectedAccount?.get('id') is account2.get('id')
                    return 1
                return 0

            return {
                onlyFavorites    : not state or state.onlyFavorites is true
                isDrawerExpanded : LayoutStore.isDrawerExpanded()
                refreshes        : RefreshesStore.getRefreshing()
                accounts         : accounts.toArray()
                selectedAccount  : AccountStore.getSelectedOrDefault()
                mailboxes        : AccountStore.getSelectedMailboxes true
                favorites        : AccountStore.getSelectedFavorites true
                search           : SearchStore.getCurrentSearch()
            }

        return {
            selectedAccount       : AccountStore.getSelectedOrDefault()
            currentSearch         : SearchStore.getCurrentSearch()
            modal                 : LayoutStore.getModal()
            useIntents            : LayoutStore.intentAvailable()
            selectedMailboxID     : AccountStore.getSelectedMailbox()?.get('id')
        }

    getProps: (name, props={}) ->
        if 'application' is name
            disposition = LayoutStore.getDisposition()
            isCompact = LayoutStore.getListModeCompact()
            isFullScreen = LayoutStore.isPreviewFullscreen()
            previewSize = LayoutStore.getPreviewSize()
            className = ['layout'
                "layout-#{disposition}"
                if isCompact then "layout-compact"
                if isFullScreen then "layout-preview-fullscreen"
                "layout-preview-#{previewSize}"].join(' ')

            return {
                 action: (action = LayoutStore.getRoute())
                 className: className
                 disposition: disposition
                 isFullScreen: action isnt 'message.show'
            }

        if 'menu' is name
            return {
                composeURL: RouteGetter.getURL action: 'message.new'
                newAccountURL: RouteGetter.getURL action: 'account.new'
                action: LayoutStore.getRoute()
            }

        if 'panel' is name
            mailboxID = AccountStore.getSelectedMailbox()?.get 'id'
            prefix = mailboxID + '-' + props.action
            return {
                ref               : name
                key               : MessageStore.getQueryKey prefix
                action            : props.action
                accountID         : AccountStore.getSelectedOrDefault()?.get 'id'
                mailboxID         : mailboxID
                messageID         : MessageStore.getCurrentID()
                # tab               : params.tab
                useIntents        : LayoutStore.intentAvailable()
                selectedMailboxID : mailboxID
            }

        if 'account' is name and (account = props.account) and (state = props.state)
            isSelected = account is AccountStore.getSelectedOrDefault()
            accountID = account.get 'id'

            result = {}
            result.key = 'account-' + accountID
            result.isSelected = isSelected
            result.url = RouteGetter.getURL action: 'account.new'
            result.nbUnread = account.get 'totalUnread'
            result.className = classNames active: isSelected
            result.allBoxesAreFavorite = state.mailboxes.size is state.favorites.size
            result.accountColor  = colorhash(account.get 'label')
            result.urlconfig = RouteGetter.getURL
                action: 'account.edit'
                accountID: accountID
            result.progress = RefreshesStore.getRefreshing().get accountID
            result.icon = 'fa fa-ellipsis-h'

            if state.onlyFavorites
                mailboxes = state.favorites
                result.toggleFavoritesLabel = t 'menu favorites off'
            else
                mailboxes = state.mailboxes
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
            specialMboxes = specialMailboxes.map (mailbox) -> account.get mailbox
            result.specialMboxes = mailboxes.filter (mailbox) ->
                mailbox.get('id') in specialMboxes
            result.unSpecialMboxes = mailboxes.filter (mailbox) ->
                mailbox.get('id') not in specialMboxes
            return result


module.exports = new ApplicationGetter()
