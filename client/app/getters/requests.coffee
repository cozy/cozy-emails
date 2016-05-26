{Requests
RequestStatus} = require '../constants/app_constants'

RequestsStore = require '../stores/requests_store'


module.exports =
    isAccountCreationBusy: ->
        RequestStatus.INFLIGHT in [
            RequestsStore.get(Requests.DISCOVER_ACCOUNT).status
            RequestsStore.get(Requests.CHECK_ACCOUNT).status
            RequestsStore.get(Requests.ADD_ACCOUNT).status
        ]


    isAccountDiscoverable: ->
        discover = RequestsStore.get Requests.DISCOVER_ACCOUNT
        check    = RequestsStore.get Requests.CHECK_ACCOUNT

        if discover.status is RequestStatus.SUCCESS
            return true
        # autodiscover failed w/o check in course: switch to manual config
        else if discover.status is RequestStatus.ERROR and check.status is null
            return false
        else
            return check.status is null


    getAccountCreationAlert: ->
        discover = RequestsStore.get Requests.DISCOVER_ACCOUNT
        check    = RequestsStore.get Requests.CHECK_ACCOUNT
        create   = RequestsStore.get Requests.ADD_ACCOUNT

        if create.status is RequestStatus.ERROR
            'CREATE_FAILED'

        else if check.status is RequestStatus.ERROR
            'CHECK_FAILED'

        # autodiscover failed: set an alert only if check isn't already
        # performed
        else if discover.status is RequestStatus.ERROR and check.status is null
            'DISCOVER_FAILED'

        else
            null


    isAccountOAuth: ->
        check = RequestsStore.get Requests.CHECK_ACCOUNT

        if check.status is RequestStatus.ERROR
            check.res.oauth
        else
            false


    getAccountCreationDiscover: ->
        discover = RequestsStore.get Requests.DISCOVER_ACCOUNT

        if discover.status is RequestStatus.SUCCESS
            discover.res
        else
            false


    getAccountCreationSuccess: ->
        create = RequestsStore.get Requests.ADD_ACCOUNT

        # return create request result (i.e. `{account}`) on success
        if create.status is RequestStatus.SUCCESS
            create.res
        else
            false
