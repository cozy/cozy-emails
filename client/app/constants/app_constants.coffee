module.exports =

    ActionTypes:
        # Account
        'DISCOVER_ACCOUNT_REQUEST': 'DISCOVER_ACCOUNT_REQUEST'
        'DISCOVER_ACCOUNT_SUCCESS': 'DISCOVER_ACCOUNT_SUCCESS'
        'DISCOVER_ACCOUNT_FAILURE': 'DISCOVER_ACCOUNT_FAILURE'
        'CHECK_ACCOUNT_REQUEST':    'CHECK_ACCOUNT_REQUEST'
        'CHECK_ACCOUNT_SUCCESS':    'CHECK_ACCOUNT_SUCCESS'
        'CHECK_ACCOUNT_FAILURE':    'CHECK_ACCOUNT_FAILURE'
        'ADD_ACCOUNT_REQUEST':      'ADD_ACCOUNT_REQUEST'
        'ADD_ACCOUNT_SUCCESS':      'ADD_ACCOUNT_SUCCESS'
        'ADD_ACCOUNT_FAILURE':      'ADD_ACCOUNT_FAILURE'
        'REMOVE_ACCOUNT_REQUEST':   'REMOVE_ACCOUNT_REQUEST'
        'REMOVE_ACCOUNT_SUCCESS':   'REMOVE_ACCOUNT_SUCCESS'
        'REMOVE_ACCOUNT_FAILURE':   'REMOVE_ACCOUNT_FAILURE'
        'EDIT_ACCOUNT_REQUEST':     'EDIT_ACCOUNT_REQUEST'
        'EDIT_ACCOUNT_SUCCESS':     'EDIT_ACCOUNT_SUCCESS'
        'EDIT_ACCOUNT_FAILURE':     'EDIT_ACCOUNT_FAILURE'
        'EDIT_ACCOUNT_TAB':         'EDIT_ACCOUNT_TAB'
        'SELECT_ACCOUNT':           'SELECT_ACCOUNT'
        'NEW_ACCOUNT_SETTING':      'NEW_ACCOUNT_SETTING'

        # Mailbox
        # 'MAILBOX_ADD'               : 'MAILBOX_ADD'
        'MAILBOX_CREATE_REQUEST'    : 'MAILBOX_CREATE_REQUEST'
        'MAILBOX_CREATE_SUCCESS'    : 'MAILBOX_CREATE_SUCCESS'
        'MAILBOX_CREATE_FAILURE'    : 'MAILBOX_CREATE_FAILURE'
        'MAILBOX_UPDATE_REQUEST'    : 'MAILBOX_UPDATE_REQUEST'
        'MAILBOX_UPDATE_FAILURE'    : 'MAILBOX_UPDATE_FAILURE'
        'MAILBOX_DELETE_REQUEST'    : 'MAILBOX_DELETE_REQUEST'
        'MAILBOX_DELETE_SUCCESS'    : 'MAILBOX_DELETE_SUCCESS'
        'MAILBOX_DELETE_FAILURE'    : 'MAILBOX_DELETE_FAILURE'
        'MAILBOX_EXPUNGE_REQUEST'   : 'MAILBOX_EXPUNGE_REQUEST'
        'MAILBOX_EXPUNGE_SUCCESS'   : 'MAILBOX_EXPUNGE_SUCCESS'
        'MAILBOX_EXPUNGE_FAILURE'   : 'MAILBOX_EXPUNGE_FAILURE'
        'MAILBOX_EXPUNGE'           : 'MAILBOX_EXPUNGE'
        'MAILBOX_SELECT'            : 'MAILBOX_SELECT'
        'MAILBOX_SELECT_ALL'        : 'MAILBOX_SELECT_ALL'

        # Message
        'RECEIVE_ACCOUNT_CREATE'        : 'RECEIVE_ACCOUNT_CREATE'
        'RECEIVE_ACCOUNT_UPDATE'        : 'RECEIVE_ACCOUNT_UPDATE'
        'RECEIVE_RAW_MESSAGE'           : 'RECEIVE_RAW_MESSAGE'
        'RECEIVE_RAW_MESSAGES'          : 'RECEIVE_RAW_MESSAGES'
        'RECEIVE_RAW_MESSAGE_REALTIME'  : 'RECEIVE_RAW_MESSAGE_REALTIME'
        'MESSAGE_SEND_REQUEST'          : 'MESSAGE_SEND_REQUEST'
        'MESSAGE_SEND_SUCCESS'          : 'MESSAGE_SEND_SUCCESS'
        'MESSAGE_SEND_FAILURE'          : 'MESSAGE_SEND_FAILURE'
        'RECEIVE_MESSAGE_DELETE'        : 'RECEIVE_MESSAGE_DELETE'
        'RECEIVE_MAILBOX_CREATE'        : 'RECEIVE_MAILBOX_CREATE'
        'RECEIVE_MAILBOX_UPDATE'        : 'RECEIVE_MAILBOX_UPDATE'

        'MESSAGE_TRASH_REQUEST'         : 'MESSAGE_TRASH_REQUEST'
        'MESSAGE_TRASH_SUCCESS'         : 'MESSAGE_TRASH_SUCCESS'
        'MESSAGE_TRASH_FAILURE'         : 'MESSAGE_TRASH_FAILURE'
        'MESSAGE_MOVE_REQUEST'          : 'MESSAGE_MOVE_REQUEST'
        'MESSAGE_MOVE_SUCCESS'          : 'MESSAGE_MOVE_SUCCESS'
        'MESSAGE_MOVE_FAILURE'          : 'MESSAGE_MOVE_FAILURE'
        'MESSAGE_FLAGS_REQUEST'         : 'MESSAGE_FLAGS_REQUEST'
        'MESSAGE_FLAGS_SUCCESS'         : 'MESSAGE_FLAGS_SUCCESS'
        'MESSAGE_FLAGS_FAILURE'         : 'MESSAGE_FLAGS_FAILURE'
        'MESSAGE_FETCH_REQUEST'         : 'MESSAGE_FETCH_REQUEST'
        'MESSAGE_FETCH_SUCCESS'         : 'MESSAGE_FETCH_SUCCESS'
        'MESSAGE_FETCH_FAILURE'         : 'MESSAGE_FETCH_FAILURE'


        # Search
        'SEARCH_PARAMETER_CHANGED' : 'SEARCH_PARAMETER_CHANGED'
        'SEARCH_REQUEST'           : 'SEARCH_REQUEST'
        'SEARCH_SUCCESS'           : 'SEARCH_SUCCESS'
        'SEARCH_FAILURE'           : 'SEARCH_FAILURE'

        # Contacts
        'SEARCH_CONTACT_REQUEST'    : 'SEARCH_CONTACT_REQUEST'
        'SEARCH_CONTACT_SUCCESS'    : 'SEARCH_CONTACT_SUCCESS'
        'SEARCH_CONTACT_FAILURE'    : 'SEARCH_CONTACT_FAILURE'
        'CREATE_CONTACT_REQUEST'    : 'CREATE_CONTACT_REQUEST'
        'CREATE_CONTACT_SUCCESS'    : 'CREATE_CONTACT_SUCCESS'
        'CREATE_CONTACT_FAILURE'    : 'CREATE_CONTACT_FAILURE'
        'CONTACT_LOCAL_SEARCH'       : 'CONTACT_LOCAL_SEARCH'

        # Router
        'ROUTES_INITIALIZE'     : 'ROUTES_INITIALIZE'
        'ROUTE_CHANGE'          : 'ROUTE_CHANGE'

        # Layout
        'DISPLAY_MODAL'             : 'DISPLAY_MODAL'
        'HIDE_MODAL'                : 'HIDE_MODAL'
        'INTENT_AVAILABLE'          : 'INTENT_AVAILABLE'

        # Settings
        'SETTINGS_UPDATE_REQUEST'  : 'SETTINGS_UPDATE_REQUEST'
        'SETTINGS_UPDATE_SUCCESS'   : 'SETTINGS_UPDATE_SUCCESS'
        'SETTINGS_UPDATE_FAILURE'   : 'SETTINGS_UPDATE_FAILURE'

        # Tasks
        'RECEIVE_TASK_UPDATE'       : 'RECEIVE_TASK_UPDATE'
        'RECEIVE_TASK_DELETE'       : 'RECEIVE_TASK_DELETE'
        'CLEAR_TOASTS'              : 'CLEAR_TOASTS'

        # Refreshes
        'RECEIVE_INDEXES_REQUEST'      : 'RECEIVE_INDEXES_REQUEST'
        'RECEIVE_INDEXES_COMPLETE'     : 'RECEIVE_INDEXES_COMPLETE'
        'RECEIVE_REFRESH_UPDATE'       : 'RECEIVE_REFRESH_UPDATE'
        'RECEIVE_REFRESH_STATUS'       : 'RECEIVE_REFRESH_STATUS'
        'RECEIVE_REFRESH_NOTIF'        : 'RECEIVE_REFRESH_NOTIF'

        'REFRESH_REQUEST'              : 'REFRESH_REQUEST'
        'REFRESH_SUCCESS'              : 'REFRESH_SUCCESS'
        'REFRESH_FAILURE'              : 'REFRESH_FAILURE'

        # Toasts
        'TOASTS_SHOW'               : 'TOASTS_SHOW'
        'TOASTS_HIDE'               : 'TOASTS_HIDE'


    Requests:
        'DISCOVER_ACCOUNT':     'DISCOVER_ACCOUNT'
        'CHECK_ACCOUNT':        'CHECK_ACCOUNT'
        'ADD_ACCOUNT':          'ADD_ACCOUNT'
        'REFRESH_MAILBOX':      'REFRESH_MAILBOX'
        'INDEX_MAILBOX':        'INDEX_MAILBOX'


    RequestStatus:
        'SUCCESS':  'SUCCESS'
        'ERROR':    'ERROR'
        'INFLIGHT': 'INFLIGHT'


    PayloadSources:
        'VIEW_ACTION'   : 'VIEW_ACTION'
        'SERVER_ACTION' : 'SERVER_ACTION'


    AccountActions:
        'EDIT'      : 'account.edit'
        'CREATE'    : 'account.new'

    MessageActions:
        'SHOW_ALL'      : 'message.list'
        'SHOW'          : 'message.show'
        'EDIT'          : 'message.edit'
        'REPLY'         : 'message.reply'
        'REPLY_ALL'     : 'message.reply.all'
        'FORWARD'       : 'message.forward'
        'CREATE'        : 'message.new'
        'GROUP_NEXT'    : 'conversation.next'
        'PAGE_NEXT'     : 'page.next'

    SearchActions:
        'SHOW_ALL'      : 'search'

    OAuthDomains:
        'gmail.com':      'https://www.google.com/settings/security/lesssecureapps'
        'googlemail.com': 'https://www.google.com/settings/security/lesssecureapps'

    ServersEncProtocols: [
        'ssl'
        'starttls'
    ]

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
        'INBOX'   :  '\\Inbox'
        'DRAFT'   :  '\\Drafts'
        'SENT'    :  '\\Sent'
        'TRASH'   :  '\\Trash'
        'ALL'     :  '\\All'
        'SPAM'    :  '\\Junk'
        'FLAGGED' :  '\\Flagged'

    MailboxSpecial:
        'inboxMailbox'  : 'INBOX'
        'draftMailbox'  : 'DRAFT'
        'sentMailbox'   : 'SENT'
        'trashMailbox'  : 'TRASH'
        'junkMailbox'   : 'SPAM'
        'allMailbox'    : 'ALL'

    # FIXME: should decide between:
    # FlagsConstants or MessageFlags
    FlagsConstants:
        SEEN   : '\\Seen'
        UNSEEN : 'Unseen'
        FLAGGED: '\\Flagged'
        NOFLAG : 'Noflag'

    Icons:
        'inboxMailbox'  : 'fa-inbox'
        'draftMailbox'  : 'fa-file-text-o'
        'sentMailbox'   : 'fa-send-o'
        'trashMailbox'  : 'fa-trash-o'
        'junkMailbox'   : 'fa-fire'
        'allMailbox'    : 'fa-archive'
        'unreadMailbox' : 'fa-eye'
        'flaggedMailbox': 'fa-star'

        'archive'       : 'fa-file-archive-o'
        'audio'         : 'fa-file-audio-o'
        'code'          : 'fa-file-code-o'
        'image'         : 'fa-file-image-o'
        'pdf'           : 'fa-file-pdf-o'
        'word'          : 'fa-file-word-o'
        'presentation'  : 'fa-file-powerpoint-o'
        'spreadsheet'   : 'fa-file-excel-o'
        'text'          : 'fa-file-text-o'
        'video'         : 'fa-file-video-o'
        'word'          : 'fa-file-word-o'


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
        HELP_SHORTCUTS              : 'TOOLTIP_HELP_SHORTCUT'
