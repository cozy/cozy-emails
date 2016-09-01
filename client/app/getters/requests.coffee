{RequestStatus, Requests} = require '../constants/app_constants'

module.exports =

    getInFlight: (state) ->
        state?.get('requests')?.get 'inflight'


    getValue: (state, req) ->
        results = state?.get('requests')?.get 'success'
        results?.get req

    getError: (state, req) ->
        results = state?.get('requests')?.get 'error'
        results?.get req


    isRequestError: (state) ->
        !!state?.get('requests')?.get('error')?.size


    isLoading: (state, req) ->
        @getInFlight(state) is req


    getRefreshes: (state) ->
        state.get('refreshes')


    isRefreshError: (state) ->
        length = @getRefreshes(state).get('errors')?.length
        return length isnt undefined and length > 0


    isRefreshing: (state)->
        @getRefreshes(state).size isnt 0 or
        @isLoading(state, Requests.REFRESH_MAILBOX)


    # FIXME : why?
    # TODO : shouldn'y we remove this
    # if it is useless?
    isIndexing: (state, accountID) ->
        return false
        # actions = [Requests.INDEX_MAILBOX, Requests.ADD_ACCOUNT]
        # @getRequests(state).find (request, name) =>
        #     if name in actions and @isLoading state, name
        #         return request.res?.accountID is accountID


    isConversationLoading: (state) ->
        @isLoading state, Requests.FETCH_CONVERSATION


    isAccountCreationBusy: (state) ->
        @getInFlight(state) in [
            Requests.DISCOVER_ACCOUNT,
            Requests.CHECK_ACCOUNT,
            Requests.ADD_ACCOUNT
        ]

    # isAccountDiscoverable: (state) ->
    #     discover = @getValue state, Requests.DISCOVER_ACCOUNT
    #     check    = @getValue state, Requests.CHECK_ACCOUNT
    #
    #     if discover.status is RequestStatus.SUCCESS
    #         return true
    #     # autodiscover failed w/o check in course: switch to manual config
    #     else if discover.status is RequestStatus.ERROR and check.status is null
    #         return false
    #     else
    #         return check.status is null


    getAccountCreationAlert: (state) ->
        createFailure = @getError state, Requests.ADD_ACCOUNT
        checkFailure = @getError state, Requests.CHECK_ACCOUNT
        discoverFailure = @getError state, Requests.DISCOVER_ACCOUNT

        if createFailure
            status: 'CREATE_FAILED'

        if checkFailure
            fields = checkFailure.error.response.body.causeFields

            status: 'CHECK_FAILED'
            type: if fields and 'smtpServer' in fields
                'SMTP_SERVER'
            else if fields and 'imapServer' in fields
                'IMAP_SERVER'
            else
                'AUTH'

        # FIXME : this bahavior is partially implemented
        # missing last condition

        # 1. autodiscover failed: set an alert
        # 2. only if check isn't already performed
        else if discoverFailure
            status: 'DISCOVER_FAILED'

        else
            null


    # FIXME: this may not work
    # FIXME : on ne stocke plus la valeur
    # par contre le stocker dasn Account
    getAccountCreationDiscover: (state) ->
        discover = @getValue state, Requests.DISCOVER_ACCOUNT
        # if discover.status is RequestStatus.SUCCESS
        #     discover.res


    # FIXME: this may not work
    # return create request result
    # i.e. `{account}` on success
    getAccountCreationSuccess: (state) ->
        @getValue state, Requests.ADD_ACCOUNT
