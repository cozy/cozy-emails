module.exports =

      # Application
      "app loading"             : "Loading…"
      "app back"                : "Back"
      "app cancel"              : "Cancel"
      "app menu"                : "Menu"
      "app search"              : "Search…"
      "app alert close"         : "Close"
      "app unimplemented"       : "Not implemented yet"
      "app error"               : "Argh, I'm unable to perform this action,
                                    please try again"

      # Compose window
      "compose"                   : "Compose new email"
      "compose default"           : 'Hello, how are you doing today?'
      "compose from"              : "From"
      "compose to"                : "To"
      "compose to help"           : "Recipients list"
      "compose cc"                : "Cc"
      "compose cc help"           : "Copy list"
      "compose bcc"               : "Bcc"
      "compose bcc help"          : "Hidden copy list"
      "compose subject"           : "Subject"
      "compose content"           : "Content"
      "compose subject help"      : "Message subject"
      "compose reply prefix"      : "Re: "
      "compose reply separator"   : "\n\nOn %{date}, %{sender} wrote \n"
      "compose forward prefix"    : "Fwd: "
      "compose forward separator" : "\n\nOn %{date}, %{sender} wrote \n"
      "compose action draft"      : "Save draft"
      "compose action send"       : "Send"
      "compose action delete"     : "Delete draft"
      "compose action sending"    : "Sending"
      "compose toggle cc"         : "Cc"
      "compose toggle bcc"        : "Bcc"
      "compose error no dest"     : "You can not send a message to nobody"
      "compose error no subject"  : "Please set a subject"
      "compose confirm keep draft": "Message not sent, keep the draft?"
      "compose draft deleted"     : "Draft deleted"

      # Menu
      "menu show"               : "Show menu"
      "menu compose"            : "Compose"
      "menu account new"        : "New Mailbox"
      "menu settings"           : "Parameters"
      "menu mailbox total"      : "%{smart_count} message|||| %{smart_count} messages"
      "menu mailbox unread"     : ", %{smart_count} unread message ||||, %{smart_count} unread messages "
      "menu mailbox new"        : " and %{smart_count} new message|||| and %{smart_count} new messages "
      "menu favorites on"       : "Favorites"
      "menu favorites off"      : "All"
      "menu toggle"             : "Toggle Menu"

      # List
      "list empty"              : "No email in this box."
      "no flagged message"      : "No Important email in this box."
      "no unseen message"       : "All emails have been read in this box"
      "no attach message"       : "No message with attachments"
      "no filter message"       : "No email for this filter."
      "list fetching"           : "Loading…"
      "list search empty"       : "No result found for the query \"%{query}\"."
      "list count"              : "%{smart_count} message in this
                                  box |||| %{smart_count} messages in this box"
      "list search count"       : "%{smart_count} result found. ||||
                                    %{smart_count} results found."
      "list filter"               : "Filter"
      "list filter all"           : "All"
      "list filter unseen"        : "Unseen"
      "list filter unseen title"  : "Show only unread messages"
      "list filter flagged"       : "Important"
      "list filter flagged title" : "Show only Important messages"
      "list filter attach"        : "Attachments"
      "list filter attach title"  : "Show only messages with attachments"
      "list sort"                 : "Sort"
      "list sort date"            : "Date"
      "list sort subject"         : "Subject"
      "list option compact"       : "Compact"
      "list next page"            : "More messages"
      "list end"                  : "This is the end of the road"
      "list mass no message"      : "No message selected"
      "list delete confirm"       : """
                                    Do you really want to delete this message ? ||||
                                    Do you really want to delete %{smart_count} messages?
                                    """
      "list delete conv confirm"  : """
                                    Do you really want to delete this conversation ? ||||
                                    Do you really want to delete %{smart_count} conversation?
                                    """

      # Mail
      "mail receivers"          : "To: "
      "mail receivers cc"       : "Cc: "
      "mail action reply"       : "Reply"
      "mail action reply all"   : "Reply all"
      "mail action forward"     : "Forward"
      "mail action delete"      : "Delete"
      "mail action mark"        : "Mark as…"
      "mail action copy"        : "Copy…"
      "mail action move"        : "Move…"
      "mail action more"        : "More…"
      "mail action headers"     : "Headers"
      "mail action raw"         : "Raw message"
      "mail mark spam"          : "Spam"
      "mail mark nospam"        : "No spam"
      "mail mark fav"           : "Important"
      "mail mark nofav"         : "Not important"
      "mail mark read"          : "Read"
      "mail mark unread"        : "Unread"
      "mail confirm delete"     : "Do you really want to delete message “%{subject}”?"
      "mail confirm delete nosubject" : "Do you really want to delete this message?"
      "mail action conversation delete" : "Delete conversation"
      "mail action conversation move"   : "Move conversation"
      "mail action conversation seen"   : "Mark conversation as read"
      "mail action conversation unseen" : "Mark conversation as unread"
      "mail conversation length": """
            %{smart_count} message dans cette conversation. ||||
            %{smart_count} messages dans cette conversation.
      """

      # Account
      "account new"                 : "New account"
      "account edit"                : "Edit account"
      "account add"                 : "Add"
      "account save"                : "Save"
      "account saving"              : "Saving"
      "account check"               : "Check connection"
      "account accountType short"   : "IMAP"
      "account accountType"         : "Account type"
      "account imapPort short"      : "993"
      "account imapPort"            : "Port"
      "account imapSSL"             : "Use SSL"
      "account imapServer short"    : "imap.provider.tld"
      "account imapServer"          : "IMAP server"
      "account imapTLS"             : "Use TLS"
      "account label short"         : "A short mailbox name"
      "account label"               : "Account label"
      "account login short" : "Your email address"
      "account login"             : "Email address"
      "account name short"       : "Your name, as it will be displayed"
      "account name"           : "Your name"
      "account password"            : "Password"
      "account receiving server"    : "Receiving server"
      "account sending server"      : "Sending server"
      "account smtpLogin short"     : "SMTP user"
      "account smtpLogin"           : "SMTP user (if different from main login)"
      "account smtpMethod"          : "Authentification method"
      "account smtpMethod NONE"     : "None"
      "account smtpMethod PLAIN"    : "Plain"
      "account smtpMethod LOGIN"    : "Login"
      "account smtpMethod CRAM-MD5" : "Cram-MD5"
      "account smtpPassword short"  : "SMTP password"
      "account smtpPassword"        : "SMTP password (if different from main password)"
      "account smtpPort short"      : "465"
      "account smtpPort"            : "Port"
      "account smtpSSL"             : "Use SSL"
      "account smtpServer short"    : "smtp.provider.tld"
      "account smtpServer"          : "SMTP server"
      "account smtpTLS"             : "Use STARTTLS"
      "account remove"              : "Remove this account"
      "account remove confirm"      : "Do you really want to remove this
                                        account?"
      "account draft mailbox"       : "Draft box"
      "account sent mailbox"        : "Sent box"
      "account trash mailbox"       : "Trash"
      "account mailboxes"           : "Folders"
      "account special mailboxes"   : "Special mailboxes"
      "account newmailbox label"    : "New Folder"
      "account newmailbox placeholder" : "Name"
      "account newmailbox parent"   : "Parent:"
      "account confirm delbox"      : "Do you really want to delete all
                                        messages in this box?"
      "account tab account"         : "Account"
      "account tab mailboxes"       : "Folders"
      "account errors"              : "Some data are missing or invalid"
      "account type"                : "Account type"
      "account updated"             : "Account updated"
      "account checked"             : "Parameters ok"
      "account creation ok"         : "Yeah! The account has been successfully
        created. Now select the mailboxes you want to see in the menu"
      "account refreshed"           : "Account refreshed"
      "account refresh error"       : "Error refreshing accounts, check parameters"
      "account identifiers"         : "Identification"
      "account actions"             : "Actions"
      "account danger zone"         : "Danger Zone"
      "account no special mailboxes": "Please configure special folders first"
      "account smtp hide advanced"  : "Hide advanced parameters"
      "account smtp show advanced"  : "Show advanced parameters"
      "mailbox create ok"           : "Folder created"
      "mailbox create ko"           : "Error creating folder"
      "mailbox update ok"           : "Folder updated"
      "mailbox update ko"           : "Error updating folder"
      "mailbox delete ok"           : "Folder deleted"
      "mailbox delete ko"           : "Error deleting folder"
      "mailbox expunge ok"          : "Folder expunged"
      "mailbox expunge ko"          : "Error expunging folder"
      "mailbox title edit"          : "Rename folder"
      "mailbox title delete"        : "Delete folder"
      "mailbox title edit save"     : "Save"
      "mailbox title edit cancel"   : "Cancel"
      "mailbox title add"           : "Add new folder"
      "mailbox title add cancel"    : "Cancel"
      "mailbox title favorite"      : "Folder is displayed"
      "mailbox title not favorite"  : "Folder not displayed"
      "mailbox title total"         : "Total"
      "mailbox title unread"        : "Unread"
      "mailbox title new"           : "New"
      "config error auth"           : "Wrong connection parameters"
      "config error imapPort"       : "Wrong IMAP port"
      "config error imapServer"     : "Wrong IMAP server"
      "config error imapTLS"        : "Wrong IMAP TLS"
      "config error smtpPort"       : "Wrong SMTP Port"
      "config error smtpServer"     : "Wrong SMTP Server"
      "config error nomailboxes"    : "No folder in this account, please create
                                        one"

      # Message Action
      "message action sent ok"      : "Message sent"
      "message action sent ko"      : "Error sending message: "
      "message action draft ok"     : "Message saved"
      "message action draft ko"     : "Error saving message: "
      "message action delete ok"    : "Message “%{subject}” deleted"
      "message action delete ko"    : "Error deleting message: "
      "message action move ok"      : "Message moved"
      "message action move ko"      : "Error moving message: "
      "message action mark ok"      : "Message marked"
      "message action mark ko"      : "Error marking message: "
      "conversation move ok"        : "Conversation moved"
      "conversation move ko"        : "Error moving conversation"
      "conversation delete ok"      : "Conversation “%{subject}” deleted"
      "conversation delete ko"      : "Error deleting conversation"
      "conversation seen ok"        : "Conversation marked as read"
      "conversation seen ko"        : "Error"
      "conversation unseen ok"      : "Conversation marked as unread"
      "conversation unseen ko"      : "Error"
      "conversation undelete"       : "Undo conversation deletion"
      "message images warning"      : "Display of images inside message has
                                        been blocked"
      "message images display"      : "Display images"
      "message html display"        : "Display HTML"
      "message delete no trash"     : "Please select a Trash folder"
      "message delete already"      : "Message already in trash folder"
      "message move already"        : "Message already in this folder"
      "message undelete"            : "Undo message deletion"
      "message undelete ok"         : "Message undeleted"
      "message undelete error"      : "Error undoing some action"
      "message undelete unnavalable": "Undo not available"
      "message preview title"       : "View attachments"

      # Settings
      "settings title"             : "Settings"
      "settings button save"       : "Save"
      #"settings label mpp"         : "Messages per page"
      "settings plugins"           : "Add ons"
      "settings plugins"           : "Modules complémentaires"
      "settings plugin add"        : "Add"
      "settings plugin del"        : "Delete"
      "settings plugin help"       : "Help"
      "settings plugin new name"   : "Plugin Name"
      "settings plugin new url"    : "Plugin URL"
      # SETTINGS
      "settings label composeInHTML"        : "Rich message editor"
      "settings label composeOnTop"         : "Reply on top of message"
      "settings label desktopNotifications" : "Notifications"
      "settings label displayConversation"  : "Display conversations"
      "settings label displayPreview"       : "Display message preview"
      "settings label messageDisplayHTML"   : "Display message in HTML"
      "settings label messageDisplayImages" : "Display images inside messages"
      "settings label messageConfirmDelete" : "Confirm before deleting a message"
      "settings label layoutStyle"            : "Display Layout"
      "settings label layoutStyle horizontal" : "Horizontal"
      "settings label layoutStyle vertical"   : "Vertical"
      "settings label layoutStyle three"      : "Three cols"
      "settings label listStyle"            : "Message list style"
      "settings label listStyle default"    : "Normal"
      "settings label listStyle compact"    : "Compact"
      "settings lang"             : "Language"
      "settings lang en"          : "English"
      "settings lang fr"          : "Français"
      "settings save error"       : "Unable to save settings, please try again"

      # File picker
      "picker drop here"           : "Drop files here"

      # Mailbox List
      "mailbox pick one"           : "Pick one"
      "mailbox pick null"          : "No box for this"

      # Tasks
      "task account-fetch"         : 'Refreshing %{account}'
      "task box-fetch"             : 'Refreshing %{box}'
      "task apply-diff-fetch"      : 'Fetching mails from %{box} of %{account}'
      "task apply-diff-remove"     : 'Deleting mails from %{box} of %{account}'
      "task recover-uidvalidity"   : 'Analysing'
      "there were errors"          : '%{smart_count} error. |||| %{smart_count}
                                        errors.'
      "modal please report"        : "Please transmit this information to cozy."
      "modal please contribute"    : "Please contribute"

      # Validation
      "validate must not be empty" : "Mandatory field"

      # Toast
      "toast hide"      : "Hide alerts"
      "toast show"      : "Display alerts"
      "toast close all" : "Close all alerts"

      # Notifications
      "notif new title": 'CozyEmail'
      "notif new": """
        %{smart_count} new message in %{box} of %{account}||||
        %{smart_count} new messages in %{box} of %{account}||||
      """

      # Contacts
      "contact form"             : "Select contacts"
      "contact form placeholder" : "contact name"
      "contact create success"   : "%{contact} has been added to your contacts"
      "contact create error"     : "Error adding to your contacts : {error}"

      # GMail security
      "gmail security tile": "About Gmail security"
      "gmail security body": """
            Gmail considers connection using username and password not safe.
            Please click on the following link, make sure
            you are connected with your %{login} account and enable access for
            less secure apps.
      """
      "gmail security link": "Enable access for less secure apps."

      # Plugins
      'plugin name Gallery'            : 'Attachments gallery'
      'plugin name medium-editor'      : 'Medium editor'
      'plugin name MiniSlate'          : 'MiniSlate editor'
      'plugin name Sample JS'          : 'Sample'
      'plugin name Keyboard shortcuts' : 'Keyboard shortcuts'
      'plugin name VCard'              : 'Contacts VCards'
      'plugin modal close'             : 'Close'

      # Misc
      'calendar unknown format' : """
            This message contains an invite to an event in a currently unknown format.
            """
