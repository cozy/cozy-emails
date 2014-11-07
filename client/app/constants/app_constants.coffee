module.exports =

    ActionTypes:
        # Account
        'ADD_ACCOUNT'               : 'ADD_ACCOUNT'
        'REMOVE_ACCOUNT'            : 'REMOVE_ACCOUNT'
        'EDIT_ACCOUNT'              : 'EDIT_ACCOUNT'
        'SELECT_ACCOUNT'            : 'SELECT_ACCOUNT'
        'NEW_ACCOUNT_WAITING'       : 'NEW_ACCOUNT_WAITING'
        'NEW_ACCOUNT_ERROR'         : 'NEW_ACCOUNT_ERROR'

        # Mailbox
        'MAILBOX_ADD'               : 'MAILBOX_ADD'
        'MAILBOX_UPDATE'            : 'MAILBOX_UPDATE'
        'MAILBOX_DELETE'            : 'MAILBOX_DELETE'

        # Message
        'RECEIVE_RAW_MESSAGE'       : 'RECEIVE_RAW_MESSAGE'
        'RECEIVE_RAW_MESSAGES'      : 'RECEIVE_RAW_MESSAGES'
        'MESSAGE_SEND'              : 'MESSAGE_SEND'
        'MESSAGE_DELETE'            : 'MESSAGE_DELETE'
        'MESSAGE_BOXES'             : 'MESSAGE_BOXES'
        'MESSAGE_FLAG'              : 'MESSAGE_FLAG'

        # Search
        'SET_SEARCH_QUERY'          : 'SET_SEARCH_QUERY'
        'RECEIVE_RAW_SEARCH_RESULTS': 'RECEIVE_RAW_SEARCH_RESULTS'
        'CLEAR_SEARCH_RESULTS'      : 'CLEAR_SEARCH_RESULTS'

        # Contacts
        'SET_CONTACT_QUERY'          : 'SET_CONTACT_QUERY'
        'RECEIVE_RAW_CONTACT_RESULTS': 'RECEIVE_RAW_CONTACT_RESULTS'
        'CLEAR_CONTACT_RESULTS'      : 'CLEAR_CONTACT_RESULTS'

        # Layout
        'SHOW_MENU_RESPONSIVE'      : 'SHOW_MENU_RESPONSIVE'
        'HIDE_MENU_RESPONSIVE'      : 'HIDE_MENU_RESPONSIVE'
        'DISPLAY_ALERT'             : 'DISPLAY_ALERT'
        'HIDE_ALERT'                : 'HIDE_ALERT'
        'REFRESH'                   : 'REFRESH'

        # Mailbox
        'RECEIVE_RAW_MAILBOXES'     : 'RECEIVE_RAW_MAILBOXES'

        # Settings
        'SETTINGS_UPDATED'          : 'SETTINGS_UPDATED'

        # Tasks
        'RECEIVE_TASK_UPDATE'       : 'RECEIVE_TASK_UPDATE'
        'RECEIVE_TASK_DELETE'       : 'RECEIVE_TASK_DELETE'

        # List
        'LIST_FILTER'               : 'LIST_FILTER'
        'LIST_QUICK_FILTER'         : 'LIST_QUICK_FILTER'
        'LIST_SORT'                 : 'LIST_SORT'

    PayloadSources:
        'VIEW_ACTION'   : 'VIEW_ACTION'
        'SERVER_ACTION' : 'SERVER_ACTION'

    ComposeActions:
        'REPLY'         : 'REPLY'
        'REPLY_ALL'     : 'REPLY_ALL'
        'FORWARD'       : 'FORWARD'

    AlertLevel:
        'SUCCESS'      : 'SUCCESS'
        'INFO'         : 'INFO'
        'WARNING'      : 'WARNING'
        'ERROR'        : 'ERROR'

    NotifyType:
        'SERVER' : 'SERVER'
        'CLIENT' : 'CLIENT'

    MessageFlags:
        'FLAGGED'      : '\\Flagged'
        'SEEN'         : '\\Seen'
        'DRAFT'        : '\\Draft'

    MessageFilter:
        'ALL'          : 'all'
        'FLAGGED'      : 'flagged'
        'UNSEEN'       : 'unseen'

    MailboxFlags:
        'DRAFT'   :  '\\Drafts'
        'SENT'    :  '\\Sent'
        'TRASH'   :  '\\Trash'
        'ALL'     :  '\\All'
        'SPAM'    :  '\\Junk'
        'FLAGGED' :  '\\Flagged'
