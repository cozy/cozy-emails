module.exports =

    ActionTypes:
        # Account
        'ADD_ACCOUNT'               : 'ADD_ACCOUNT'
        'REMOVE_ACCOUNT'            : 'REMOVE_ACCOUNT'
        'EDIT_ACCOUNT'              : 'EDIT_ACCOUNT'
        'SELECT_ACCOUNT'            : 'SELECT_ACCOUNT'
        'NEW_ACCOUNT_WAITING'       : 'NEW_ACCOUNT_WAITING'
        'NEW_ACCOUNT_ERROR'         : 'NEW_ACCOUNT_ERROR'

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

        # Layout
        'SHOW_MENU_RESPONSIVE'      : 'SHOW_MENU_RESPONSIVE'
        'HIDE_MENU_RESPONSIVE'      : 'HIDE_MENU_RESPONSIVE'
        'SELECT_ACCOUNT'            : 'SELECT_ACCOUNT'
        'DISPLAY_ALERT'             : 'DISPLAY_ALERT'

        # Mailbox
        'RECEIVE_RAW_MAILBOXES'     : 'RECEIVE_RAW_MAILBOXES'

        # Settings
        'SETTINGS_UPDATED'          : 'SETTINGS_UPDATED'

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
        'FLAGGED'      : 'Flagged'
        'SEEN'         : 'Seen'
        'DRAFT'        : 'Draft'
