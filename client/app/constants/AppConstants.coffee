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

        # Layout
        'SHOW_MENU_RESPONSIVE'      : 'SHOW_MENU_RESPONSIVE'
        'HIDE_MENU_RESPONSIVE'      : 'HIDE_MENU_RESPONSIVE'
        'SELECT_ACCOUNT'            : 'SELECT_ACCOUNT'

        # Mailbox
        'RECEIVE_RAW_MAILBOXES'     : 'RECEIVE_RAW_MAILBOXES'

        # Settings
        'SETTINGS_UPDATED'          : 'SETTINGS_UPDATED'

    PayloadSources:
        'VIEW_ACTION'   : 'VIEW_ACTION'
        'SERVER_ACTION' : 'SERVER_ACTION'
