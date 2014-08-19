###
    We store flux instance a separate file to be able to access it from various
    places of the application (i.e. utils)
###

Fluxxor = require 'fluxxor'

# Requires all the stores
MailboxStore = require './stores/mailboxes'
EmailStore = require './stores/emails'
LayoutStore = require './stores/layout'
ImapFolderStore = require './stores/imap_folders'

# Builds up stores
stores =
    MailboxStore: new MailboxStore()
    EmailStore: new EmailStore()
    LayoutStore: new LayoutStore()
    ImapFolderStore: new ImapFolderStore()

# Requires and builds up actions
actions =
    layout: require './actions/layout_actions'
    mailbox: require './actions/mailbox_actions'
    email: require './actions/email_actions'
    imapFolder: require './actions/imap_folder_actions'

flux = new Fluxxor.Flux stores, actions

module.exports = flux
