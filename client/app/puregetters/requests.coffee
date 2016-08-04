{RequestStatus, Requests} = require '../constants/app_constants'

module.exports =
    getRequests: (state) ->
        state.get('requests')

    get: (state, req) ->
        @getRequests(state).get req

    isLoading: (state, req) ->
        RequestStatus.INFLIGHT is @get(state, req)?.status

    getRefreshes: (state) ->
        state.get('refreshes')

    isRefreshError: (state) ->
        @getRefreshes(state).get('errors')?.length

    isRefreshing: (state)->
        @getRefreshes(state).size isnt 0 or
        @isLoading(state, Requests.REFRESH_MAILBOX)

    isIndexing: (state, accountID) ->
        actions = [Requests.INDEX_MAILBOX, Requests.ADD_ACCOUNT]
        @getRequests(state).find (request, name) =>
            if name in actions and @isLoading state, name
                return request.res?.accountID is accountID

    isConversationLoading: (state) ->
        @isLoading state, Requests.FETCH_CONVERSATION

    isAccountCreationBusy: (state) ->
        RequestStatus.INFLIGHT in [
            @get(state, Requests.DISCOVER_ACCOUNT).status
            @get(state, Requests.CHECK_ACCOUNT).status
            @get(state, Requests.ADD_ACCOUNT).status
        ]

    isAccountDiscoverable: (state) ->
        discover = @get state, Requests.DISCOVER_ACCOUNT
        check    = @get state, Requests.CHECK_ACCOUNT

        if discover.status is RequestStatus.SUCCESS
            return true
        # autodiscover failed w/o check in course: switch to manual config
        else if discover.status is RequestStatus.ERROR and check.status is null
            return false
        else
            return check.status is null


    getAccountCreationAlert: (state) ->
        discover = @get state, Requests.DISCOVER_ACCOUNT
        check    = @get state, Requests.CHECK_ACCOUNT
        create   = @get state, Requests.ADD_ACCOUNT

        if create.status is RequestStatus.ERROR
            status: 'CREATE_FAILED'

        else if check.status is RequestStatus.ERROR
            fields = check.res.error.response.body.causeFields

            status: 'CHECK_FAILED'
            type: if fields and 'smtpServer' in fields
                'SMTP_SERVER'
            else if fields and 'imapServer' in fields
                'IMAP_SERVER'
            else
                'AUTH'

        # autodiscover failed: set an alert only if check isn't already
        # performed
        else if discover.status is RequestStatus.ERROR and check.status is null
            status: 'DISCOVER_FAILED'

        else
            null


    isAccountOAuth: (state) ->
        check = @get state, Requests.CHECK_ACCOUNT

        if check.status is RequestStatus.ERROR
            check.res.oauth
        else
            false


    getAccountCreationDiscover: (state) ->
        discover = @get state, Requests.DISCOVER_ACCOUNT

        if discover.status is RequestStatus.SUCCESS
            discover.res
        else
            false


    getAccountCreationSuccess: (state) ->
        create = @get state, Requests.ADD_ACCOUNT

        # return create request result (i.e. `{account}`) on success
        if create.status is RequestStatus.SUCCESS
            create.res
        else
            false
