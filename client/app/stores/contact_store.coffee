_         = require 'underscore'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


class ContactStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _query = ""

    # all known contacts
    _contacts = Immutable.OrderedMap()

    # result of last search
    _results  = Immutable.OrderedMap()

    _import = (rawResults) ->
        return unless rawResults

        rawResults = [ rawResults ] unless Array.isArray rawResults

        convert = (map) ->
            # Extract each contact from rawResults
            rawResults.forEach (result) ->
                contact = Immutable.Map(result).delete('docType')

                # Get avatar from binary if exists, or fallback to datapoint
                if result._attachments?.picture
                    avatar = """
                        contacts/#{result.id}/picture.jpg
                    """
                else
                    _point = _.findWhere(result.datapoints?, {name: 'avatar'})
                    avatar = _point.value if _point

                contact = contact.set 'avatar', avatar if avatar

                # For eavh address, bind a contact w/ the relevant address to
                # it into the global map (see
                # Immutable.OrderedMap.withMutations for more informations).
                result.datapoints?.forEach (datapoint) ->
                    return unless datapoint.name is 'email'
                    address = datapoint.value
                    map.set address, contact.set 'address', address

        _results  = _results.withMutations convert
        _contacts = _contacts.withMutations convert

    _import window?.contacts


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.CREATE_CONTACT_SUCCESS, (rawResults) =>
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
