_ = require 'lodash'
{SpecialBoxIcons} = require '../constants/app_constants'

class IconGetter

    getMailboxIcon: (account, mailboxID) ->
        for label, value of SpecialBoxIcons
            if mailboxID is account.get label
                return {label, value}

module.exports = new IconGetter()
