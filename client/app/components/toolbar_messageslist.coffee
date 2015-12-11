{aside, i, button} = React.DOM
classer = React.addons.classSet

FiltersToolbarMessagesList = require './toolbar_messageslist_filters'
ActionsToolbarMessagesList = require './toolbar_messageslist_actions'
SearchBar                  = require './search_bar'

LayoutActionCreator  = require '../actions/layout_action_creator'
RouterMixin           = require '../mixins/router_mixin'


module.exports = ToolbarMessagesList = React.createClass
    displayName: 'ToolbarMessagesList'

    mixins: [
        RouterMixin,
    ]

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

    onFilterChange: (params) ->

        # change here if we add an UI for sorting
        # @props.queryParams is the current value
        sortOrder = '-'
        sortField = 'date'
        before = '-'
        after = '-'
        flag = '-'
        type = params.type
        sort = sortOrder + sortField

        switch type
            when 'from', 'dest'
                if params.value
                    before = params.value
                    after = "#{params.value}\uFFFF"

            when 'date'
                if params.range
                    [before, after] = params.range

            when 'flag'
                if params.value
                    flag = params.value

        window.cozyMails.messageClose()
        @redirect
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters: [
                @props.accountID, @props.mailboxID,
                sort, type, flag, before, after
            ]


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
            else unless @props.noFilters
                FiltersToolbarMessagesList
                    accountID:   @props.accountID
                    mailboxID:   @props.mailboxID
                    queryParams:    @props.queryParams
                    onFilterChange: @onFilterChange

            SearchBar()
