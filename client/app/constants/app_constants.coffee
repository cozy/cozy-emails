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
        'RECEIVE_RAW_MESSAGE_REALTIME' : 'RECEIVE_RAW_MESSAGE_REALTIME'
        'MESSAGE_SEND'              : 'MESSAGE_SEND'
        'LAST_ACTION'               : 'LAST_ACTION'
        'MESSAGE_CURRENT'           : 'MESSAGE_CURRENT'
        'RECEIVE_MESSAGE_DELETE'    : 'RECEIVE_MESSAGE_DELETE'
        'RECEIVE_MAILBOX_UPDATE'    : 'RECEIVE_MAILBOX_UPDATE'

        'MESSAGE_TRASH_REQUEST'     : 'MESSAGE_TRASH_REQUEST'
        'MESSAGE_TRASH_SUCCESS'     : 'MESSAGE_TRASH_SUCCESS'
        'MESSAGE_TRASH_FAILURE'     : 'MESSAGE_TRASH_FAILURE'
        'MESSAGE_MOVE_REQUEST'     : 'MESSAGE_MOVE_REQUEST'
        'MESSAGE_MOVE_SUCCESS'     : 'MESSAGE_MOVE_SUCCESS'
        'MESSAGE_MOVE_FAILURE'     : 'MESSAGE_MOVE_FAILURE'
        'MESSAGE_FLAGS_REQUEST'     : 'MESSAGE_FLAGS_REQUEST'
        'MESSAGE_FLAGS_SUCCESS'     : 'MESSAGE_FLAGS_SUCCESS'
        'MESSAGE_FLAGS_FAILURE'     : 'MESSAGE_FLAGS_FAILURE'
        'MESSAGE_FETCH_REQUEST'     : 'MESSAGE_FETCH_REQUEST'
        'MESSAGE_FETCH_SUCCESS'     : 'MESSAGE_FETCH_SUCCESS'
        'MESSAGE_FETCH_FAILURE'     : 'MESSAGE_FETCH_FAILURE'
        'MESSAGE_UNDO_REQUEST'     : 'MESSAGE_UNDO_REQUEST'
        'MESSAGE_UNDO_SUCCESS'     : 'MESSAGE_UNDO_SUCCESS'
        'MESSAGE_UNDO_FAILURE'     : 'MESSAGE_UNDO_FAILURE'
        'MESSAGE_UNDO_TIMEOUT'     : 'MESSAGE_UNDO_TIMEOUT'

        'CONVERSATION_FETCH_REQUEST'     : 'CONVERSATION_FETCH_REQUEST'
        'CONVERSATION_FETCH_SUCCESS'     : 'CONVERSATION_FETCH_SUCCESS'
        'CONVERSATION_FETCH_FAILURE'     : 'CONVERSATION_FETCH_FAILURE'


        'MESSAGE_RECOVER_REQUEST'     : 'MESSAGE_RECOVER_REQUEST'
        'MESSAGE_RECOVER_SUCCESS'     : 'MESSAGE_RECOVER_SUCCESS'
        'MESSAGE_RECOVER_FAILURE'     : 'MESSAGE_RECOVER_FAILURE'

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
        'RESIZE_PREVIEW_PANE'       : 'RESIZE_PREVIEW_PANE'
        'MAXIMIZE_PREVIEW_PANE'     : 'MAXIMIZE_PREVIEW_PANE'
        'MINIMIZE_PREVIEW_PANE'     : 'MINIMIZE_PREVIEW_PANE'
        'DISPLAY_MODAL'             : 'DISPLAY_MODAL'
        'HIDE_MODAL'                : 'HIDE_MODAL'
        'REFRESH'                   : 'REFRESH'
        'INTENT_AVAILABLE'          : 'INTENT_AVAILABLE'

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

        'REFRESH_REQUEST'              : 'REFRESH_REQUEST'
        'REFRESH_SUCCESS'              : 'REFRESH_SUCCESS'
        'REFRESH_FAILURE'              : 'REFRESH_FAILURE'

        # List
        'LIST_FILTER'               : 'LIST_FILTER'
        'LIST_SORT'                 : 'LIST_SORT'

        # Toasts
        'TOASTS_SHOW'               : 'TOASTS_SHOW'
        'TOASTS_HIDE'               : 'TOASTS_HIDE'

        # Drawer
        'DRAWER_SHOW':   'DRAWER_SHOW'
        'DRAWER_HIDE':   'DRAWER_HIDE'
        'DRAWER_TOGGLE': 'DRAWER_TOGGLE'


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
        COL:  'column'
        ROW:  'row'
        RROW: 'row-reverse'

    SpecialBoxIcons:
        inboxMailbox: 'fa-inbox'
        draftMailbox: 'fa-file-text-o'
        sentMailbox: 'fa-send-o'
        trashMailbox: 'fa-trash-o'
        junkMailbox: 'fa-fire'
        allMailbox: 'fa-archive'

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
        EXPUNGE_MAILBOX             : 'TOOLTIP_EXPUNGE_MAILBOX'
        ADD_CONTACT                 : 'TOOLTIP_ADD_CONTACT'
        SHOW_CONTACT                : 'TOOLTIP_SHOW_CONTACT'

