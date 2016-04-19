_ = require 'lodash'

{SpecialBoxIcons} = require '../constants/app_constants'

AccountStore = require '../stores/account_store'

class IconGetter

    getMailboxIcon: (params={}) ->
        {account, mailboxID, type} = params
        mailboxID ?= AccountStore.getMailboxID()

        if (value = SpecialBoxIcons[type])
            return {type, value}

        account ?= AccountStore.getSelected()
        for type, value of SpecialBoxIcons
            if mailboxID is account?.get type
                return {type, value}

module.exports = new IconGetter()
