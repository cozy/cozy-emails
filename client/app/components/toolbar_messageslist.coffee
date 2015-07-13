{aside, i, button} = React.DOM
classer = React.addons.classSet

FiltersToolbarMessagesList = require './toolbar_messageslist_filters'
SearchToolbarMessagesList  = require './toolbar_messageslist_search'
ActionsToolbarMessagesList = require './toolbar_messageslist_actions'

LayoutActionCreator  = require '../actions/layout_action_creator'


module.exports = ToolbarMessagesList = React.createClass
    displayName: 'ToolbarMessagesList'

    propTypes:
        settings:             React.PropTypes.object.isRequired
        accountID:            React.PropTypes.string.isRequired
        mailboxID:            React.PropTypes.string.isRequired
        mailboxes:            React.PropTypes.object.isRequired
        messages:             React.PropTypes.object.isRequired
        edited:               React.PropTypes.bool.isRequired
        selected:             React.PropTypes.object.isRequired
        allSelected:          React.PropTypes.bool.isRequired
        displayConversations: React.PropTypes.bool.isRequired
        toggleEdited:         React.PropTypes.func.isRequired
        toggleAll:            React.PropTypes.func.isRequired
        afterAction:          React.PropTypes.func


    render: ->
        aside role: 'toolbar',
            # Drawer toggler
            button
                className: 'drawer-toggle'
                onClick:   LayoutActionCreator.drawerToggle
                title:     t 'menu toggle'

                i className: 'fa fa-navicon'

            # Select all Checkbox
            button
                role:                     'menuitem'
                'aria-selected':          @props.edited
                onClick:                  @props.toggleAll

                i className: classer
                    fa:                  true
                    'fa-square-o':       not @props.edited
                    'fa-check-square-o': @props.allSelected
                    'fa-minus-square-o': @props.edited and
                                         not @props.allSelected

            if @props.edited
                ActionsToolbarMessagesList
                    settings:             @props.settings
                    mailboxID:            @props.mailboxID
                    mailboxes:            @props.mailboxes
                    messages:             @props.messages
                    selected:             @props.selected
                    displayConversations: @props.displayConversations
                    afterAction:          @props.afterAction
            unless @props.edited
                FiltersToolbarMessagesList
                    accountID:   @props.accountID
                    mailboxID:   @props.mailboxID
                    queryParams: @props.queryParams
                    filter:      @props.filter
            unless @props.edited
                SearchToolbarMessagesList
                    accountID:   @props.accountID
                    mailboxID:   @props.mailboxID
                    queryParams: @props.queryParams
                    filter:      @props.filter
