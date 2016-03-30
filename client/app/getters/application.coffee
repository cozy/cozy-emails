AccountStore = require '../stores/account_store'
LayoutStore = require '../stores/layout_store'
SearchStore = require '../stores/search_store'
MessageStore = require '../stores/message_store'
RefreshesStore = require '../stores/refreshes_store'
SettingsStore = require '../stores/settings_store'

RouterGetter = require '../getters/router'

classNames = require 'classnames'
colorhash = require '../utils/colorhash'

class ApplicationGetter

    getState: (name, state={}) ->
        mailboxID = RouterGetter.getMailboxID()
        accountID = RouterGetter.getMailboxID()
        if 'menu' is name
            return {
                mailboxID        : mailboxID
                onlyFavorites    : not state or state.onlyFavorites is true
                refreshes        : RefreshesStore.getRefreshing()
                accountID        : accountID
                search           : SearchStore.getCurrentSearch()
            }

        return {
            mailboxID       : mailboxID
            accountID       : accountID
            messageID       : MessageStore.getCurrentID()
            action          : RouterGetter.getAction()
            currentSearch   : SearchStore.getCurrentSearch()
            modal           : LayoutStore.getModal()
        }

    getProps: (name, props={}) ->
        mailboxID = RouterGetter.getMailboxID()

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
                 className: className
            }

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
                ref: name
                composeURL: RouterGetter.getURL
                    action: 'message.new'
                    mailboxID: mailboxID
                newAccountURL: RouterGetter.getURL
                    action: 'account.new'
                    accountID: RouterGetter.getMailboxID()
                action: RouterGetter.getAction()
                accounts: accounts.toArray()
            }

        if 'panel' is name
            action = RouterGetter.getAction()
            prefix = name + '-' + mailboxID + '-' + action
            return {
                ref               : 'Panel-' + action
                key               : prefix
                action            : action
                mailboxID         : mailboxID
                accountID         : RouterGetter.getAccountID()
                messageID         : MessageStore.getCurrentID()
                # tab               : params.tab
                useIntents        : LayoutStore.intentAvailable()
                selectedMailboxID : mailboxID
                searchValue       : SearchStore.getCurrentSearch()
                accounts          : AccountStore.getAll()
                settings          : SettingsStore.get()
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
            result.allBoxesAreFavorite = mailboxes.size is favorites.size
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
            specialMboxes = specialMailboxes.map (mailbox) -> account.get mailbox
            result.specialMboxes = mailboxes.filter (mailbox) ->
                mailbox.get('id') in specialMboxes
            result.unSpecialMboxes = mailboxes.filter (mailbox) ->
                mailbox.get('id') not in specialMboxes
            return result


module.exports = new ApplicationGetter()
