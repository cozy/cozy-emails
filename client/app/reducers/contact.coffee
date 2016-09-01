Immutable =  require 'immutable'

{ActionTypes} = require '../constants/app_constants'
contactMapper = require '../libs/mappers/contact'

# DEFAULT_STATE = Immutable.Map
#     # all known contacts
#     contacts: Immutable.OrderedMap()
#     # result of last search
#     results : Immutable.OrderedMap()

module.exports = (state = Immutable.Map(), action) ->

    switch action.type

        # CREATE_CONTACT_SUCCESS
        when ActionTypes.CREATE_CONTACT_SUCCESS
            return state unless action.value

            contact = action.value
            contactsMutator = contactMapper.toMapMutator contact

            return state.withMutations(contactsMutator)

        # CONTACT_LOCAL_SEARCH
        # when ActionTypes.CONTACT_LOCAL_SEARCH
        #     return state unless action.value
        #     query = action.value?.toLowerCase()
        #
        #     queryRegExp = new RegExp query, 'i'
        #
        #     nextState =
        #         contacts: state.contacts
        #         results: state.contacts.filter (contact) ->
        #             return queryRegExp.test [
        #                 contact.get('address'),
        #                 contact.get('fn')
        #             ].join('')

    return state
