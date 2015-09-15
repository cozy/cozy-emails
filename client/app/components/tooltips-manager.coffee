###
This component must be used to declare tooltips.
They can't be then referenced from the other components.

See https://github.com/m4dz/aria-tips#use
###

{Tooltips} = require '../constants/app_constants'
{div, p} = React.DOM


module.exports = React.createClass
    displayName: 'TooltipManager'

    # The tooltip's content should not change so we prevent any refresh.
    shouldComponentUpdate: -> return false


    render: ->

        # Mounts all existing tooltips so they can be referenced by other
        # components at any time.
        div null,
            @getTooltip Tooltips.REPLY, t('tooltip reply')
            @getTooltip Tooltips.REPLY_ALL, t('tooltip reply all')
            @getTooltip Tooltips.FORWARD, t('tooltip forward')
            @getTooltip Tooltips.REMOVE_MESSAGE, t('tooltip remove message')
            @getTooltip Tooltips.OPEN_ATTACHMENTS, t('tooltip open attachments')
            @getTooltip Tooltips.OPEN_ATTACHMENT, t('tooltip open attachment')
            @getTooltip Tooltips.DOWNLOAD_ATTACHMENT, t('tooltip download attachment')
            @getTooltip Tooltips.PREVIOUS_CONVERSATION, t('tooltip previous conversation')
            @getTooltip Tooltips.NEXT_CONVERSATION, t('tooltip next conversation')
            @getTooltip Tooltips.FILTER_ONLY_UNREAD, t('tooltip filter only unread')
            @getTooltip Tooltips.FILTER_ONLY_IMPORTANT, t('tooltip filter only important')
            @getTooltip Tooltips.FILTER_ONLY_WITH_ATTACHMENT, t('tooltip filter only attachment')
            @getTooltip Tooltips.ACCOUNT_PARAMETERS, t('tooltip account parameters')
            @getTooltip Tooltips.DELETE_SELECTION, t('tooltip delete selection')
            @getTooltip Tooltips.FILTER, t('tooltip filter')
            @getTooltip Tooltips.QUICK_FILTER, t('tooltip display filters')
            @getTooltip Tooltips.EXPUNGE_MAILBOX, t('tooltip expunge mailbox')

            # Message header: tooltips for contact action.
            @getTooltip Tooltips.ADD_CONTACT, t('tooltip add contact')
            @getTooltip Tooltips.SHOW_CONTACT, t('tooltip show contact')


    # Generate default markup for a tooltip.
    getTooltip: (id, content) ->
        return p
            id: id
            role: "tooltip"
            'aria-hidden': "true",
            content

