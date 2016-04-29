_ = require 'lodash'

{SpecialBoxIcons} = require '../constants/app_constants'

RouterStore = require '../stores/router_store'

class IconGetter

    getMailboxIcon: (params={}) ->
        {account, mailboxID, type} = params
        mailboxID ?= RouterStore.getMailboxID()

        if (value = SpecialBoxIcons[type])
            return {type, value}

        account ?= RouterStore.getAccount()
        for type, value of SpecialBoxIcons
            if mailboxID is account?.get type
                return {type, value}

module.exports = new IconGetter()
