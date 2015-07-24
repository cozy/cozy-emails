Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


class ContactStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _query = ""

    # all known contacts
    _contacts = Immutable.OrderedMap.empty()

    # result of last search
    _results  = Immutable.OrderedMap.empty()

    _import = (rawResults) ->
        _results = Immutable.OrderedMap.empty()

        if rawResults?

            if not Array.isArray rawResults
                rawResults = [ rawResults ]

            convert = (map) ->

                rawResults.forEach (rawResult) ->
                    addresses = []

                    rawResult.datapoints.forEach (point) ->
                        if point.name is 'email'
                            addresses.push point.value
                        if point.name is 'avatar'
                            rawResult.avatar = point.value

                    delete rawResult.docType
                    if rawResult._attachments?.picture
                        rawResult.avatar = """
                            contacts/#{rawResult.id}/picture.jpg
                        """

                    addresses.forEach (address) ->
                        rawResult.address = address
                        contact = Immutable.Map rawResult
                        map.set address, contact

            _results  = _results.withMutations convert
            _contacts = _contacts.withMutations convert

    _import window.contacts


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_CONTACT_RESULTS, (rawResults) =>
            _import rawResults
            @emit 'change'

        handle ActionTypes.CONTACT_LOCAL_SEARCH, (query) =>
            query = query.toLowerCase()
            re = new RegExp query, 'i'
            _results = _contacts.filter (contact) ->
                obj  = contact.toObject()
                full = ''
                ['address', 'fn'].forEach (key) ->
                    if typeof obj[key] is 'string'
                        full += obj[key]
                return re.test full
            .toOrderedMap()

            @emit 'change'


    ###
        Public API
    ###

    getResults: ->
        return _results


    getQuery: ->
        return _query


    getByAddress: (address) ->
        return _contacts.get address


    getAvatar: (address) ->
        return _contacts.get(address)?.get 'avatar'


    isExist: (address) ->
        return @getByAddress(address)?


module.exports = new ContactStore()

