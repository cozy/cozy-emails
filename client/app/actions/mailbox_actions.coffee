XHRUtils = require '../utils/XHRUtils'

module.exports =

    create: (inputValues) ->
        @dispatch 'NEW_MAILBOX_WAITING', true
        XHRUtils.createMailbox inputValues, (error, mailbox) =>
            setTimeout =>
                @dispatch 'NEW_MAILBOX_WAITING', false
                if error?
                    @dispatch 'NEW_MAILBOX_ERROR', error
                else
                    @dispatch 'ADD_MAILBOX', mailbox
            , 2000

    edit: (inputValues) ->
        @dispatch 'NEW_MAILBOX_WAITING', true
        XHRUtils.editMailbox inputValues, (error, mailbox) =>
            setTimeout =>
                @dispatch 'NEW_MAILBOX_WAITING', false
                if error?
                    @dispatch 'NEW_MAILBOX_ERROR', error
                else
                    @dispatch 'EDIT_MAILBOX', mailbox
            , 2000

    remove: (mailboxID) ->
        @dispatch 'REMOVE_MAILBOX', mailboxID
        XHRUtils.removeMailbox mailboxID
        window.router.navigate '', true



