_ = require 'lodash'

{Icons} = require '../constants/app_constants'

RouterStore = require '../stores/router_store'

MessageUtils = require '../utils/message_utils'

class IconGetter

    getMailboxIcon: (params={}) ->
        {account, mailboxID, type} = params
        mailboxID ?= RouterStore.getMailboxID()

        if (value = Icons[type])
            return {type, value}

        account ?= RouterStore.getAccount()
        for type, value of Icons
            if mailboxID is account?.get type
                return {type, value}

    getAttachmentIcon: (file) ->
        type = MessageUtils.getAttachmentType file.contentType
        Icons[type] or 'fa-file-o'


module.exports = new IconGetter()
