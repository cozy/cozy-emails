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
        'MAILBOX_CREATE'            : 'MAILBOX_CREATE'
        'MAILBOX_UPDATE'            : 'MAILBOX_UPDATE'
        'MAILBOX_DELETE'            : 'MAILBOX_DELETE'
        'MAILBOX_EXPUNGE'           : 'MAILBOX_EXPUNGE'

        # Message
        'RECEIVE_RAW_MESSAGE'       : 'RECEIVE_RAW_MESSAGE'
        'RECEIVE_RAW_MESSAGES'      : 'RECEIVE_RAW_MESSAGES'
        'MESSAGE_SEND'              : 'MESSAGE_SEND'
        'MESSAGE_DELETE'            : 'MESSAGE_DELETE'
        'MESSAGE_BOXES'             : 'MESSAGE_BOXES'
        'MESSAGE_FLAG'              : 'MESSAGE_FLAG'
        'LAST_ACTION'               : 'LAST_ACTION'
        'MESSAGE_CURRENT'           : 'MESSAGE_CURRENT'
        'RECEIVE_MESSAGE_DELETE'    : 'RECEIVE_MESSAGE_DELETE'
        'RECEIVE_MAILBOX_UPDATE'    : 'RECEIVE_MAILBOX_UPDATE'
        'SET_FETCHING'              : 'SET_FETCHING'

        # Search
        'SET_SEARCH_QUERY'          : 'SET_SEARCH_QUERY'
        'RECEIVE_RAW_SEARCH_RESULTS': 'RECEIVE_RAW_SEARCH_RESULTS'
        'CLEAR_SEARCH_RESULTS'      : 'CLEAR_SEARCH_RESULTS'

        # Contacts
        'SET_CONTACT_QUERY'          : 'SET_CONTACT_QUERY'
        'RECEIVE_RAW_CONTACT_RESULTS': 'RECEIVE_RAW_CONTACT_RESULTS'
        'CLEAR_CONTACT_RESULTS'      : 'CLEAR_CONTACT_RESULTS'
        'CONTACT_LOCAL_SEARCH'       : 'CONTACT_LOCAL_SEARCH'

        # Layout
        'SET_DISPOSITION'           : 'SET_DISPOSITION'
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
        'CLEAR_TOASTS'              : 'CLEAR_TOASTS'

        # Refreshes
        'RECEIVE_REFRESH_UPDATE'       : 'RECEIVE_REFRESH_UPDATE'
        'RECEIVE_REFRESH_STATUS'       : 'RECEIVE_REFRESH_STATUS'
        'RECEIVE_REFRESH_DELETE'       : 'RECEIVE_REFRESH_DELETE'
        'RECEIVE_REFRESH_NOTIF'        : 'RECEIVE_REFRESH_NOTIF'

        # List
        'LIST_FILTER'               : 'LIST_FILTER'
        'LIST_SORT'                 : 'LIST_SORT'

        # Toasts
        'TOASTS_SHOW'               : 'TOASTS_SHOW'
        'TOASTS_HIDE'               : 'TOASTS_HIDE'

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

    MessageFlags:
        'FLAGGED'      : '\\Flagged'
        'SEEN'         : '\\Seen'
        'DRAFT'        : '\\Draft'

    MessageFilter:
        'ALL'          : 'all'
        'ATTACH'       : 'attach'
        'FLAGGED'      : 'flagged'
        'UNSEEN'       : 'unseen'

    MailboxFlags:
        'DRAFT'   :  '\\Drafts'
        'SENT'    :  '\\Sent'
        'TRASH'   :  '\\Trash'
        'ALL'     :  '\\All'
        'SPAM'    :  '\\Junk'
        'FLAGGED' :  '\\Flagged'

    FlagsConstants:
        SEEN   : '\\Seen'
        UNSEEN : 'Unseen'
        FLAGGED: '\\Flagged'
        NOFLAG : 'Noflag'

    Dispositions:
        HORIZONTAL : 'horizontal'
        VERTICAL   : 'vertical'
        THREE      : 'three'

    SpecialBoxIcons:
        inboxMailbox : 'fa-inbox'
        draftMailbox : 'fa-edit'
        sentMailbox  : 'fa-share-square-o'
        trashMailbox : 'fa-trash-o'
        junkMailbox  : 'fa-exclamation'
        allMailbox   : 'fa-archive'

    Tooltips:
        REPLY                       : 'TOOLTIP_REPLY'
        REPLY_ALL                   : 'TOOLTIP_REPLY_ALL'
        FORWARD                     : 'TOOLTIP_FORWARD'
        REMOVE_MESSAGE              : 'TOOLTIP_REMOVE_MESSAGE'
        OPEN_ATTACHMENTS            : 'TOOLTIP_OPEN_ATTACHMENTS'
        OPEN_ATTACHMENT             : 'TOOLTIP_OPEN_ATTACHMENT'
        DOWNLOAD_ATTACHMENT         : 'TOOLTIP_DOWNLOAD_ATTACHMENT'
        PREVIOUS_CONVERSATION       : 'TOOLTIP_PREVIOUS_CONVERSATION'
        NEXT_CONVERSATION           : 'TOOLTIP_NEXT_CONVERSATION'
        FILTER_ONLY_UNREAD          : 'TOOLTIP_FILTER_ONLY_UNREAD'
        FILTER_ONLY_IMPORTANT       : 'TOOLTIP_FILTER_ONLY_IMPORTANT'
        FILTER_ONLY_WITH_ATTACHMENT : 'TOOLTIP_FILTER_ONLY_WITH_ATTACHMENT'
        ACCOUNT_PARAMETERS          : 'TOOLTIP_ACCOUNT_PARAMETERS'
        DELETE_SELECTION            : 'TOOLTIP_DELETE_SELECTION'
        FILTER                      : 'TOOLTIP_FILTER'
        QUICK_FILTER                : 'TOOLTIP_QUICK_FILTER'
        COMPOSE_IMAGE               : 'TOOLTIP_COMPOSE_IMAGE'
        COMPOSE_MOCK                : 'TOOLTIP_COMPOSE_MOCK'




