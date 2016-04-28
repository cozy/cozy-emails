_ = require 'lodash'

{Icons} = require '../constants/app_constants'

AccountStore = require '../stores/account_store'
MessageUtils = require '../utils/message_utils'

class IconGetter

    getMailboxIcon: (params={}) ->
        {account, mailboxID, type} = params
        mailboxID ?= AccountStore.getMailboxID()

        if (value = Icons[type])
            return {type, value}

        account ?= AccountStore.getSelected()
        for type, value of Icons
            if mailboxID is account?.get type
                return {type, value}


    getAttachmentIcon: (file) ->
        type = MessageUtils.getAttachmentType file.contentType
        Icons[type] or 'fa-file-o'


module.exports = new IconGetter()
