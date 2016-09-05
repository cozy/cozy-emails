Immutable =  require 'immutable'

{ActionTypes} = require '../constants/app_constants'

module.exports = (state = Immutable.Map(), action, appstate) ->

    switch action.type

        # CONTACT_LOCAL_SEARCH
        when ActionTypes.CONTACT_LOCAL_SEARCH
            return state unless action.value
            query = action.value?.toLowerCase()

            queryRegExp = new RegExp query, 'i'

            return appstate.get('contacts').filter (contact) ->
                return queryRegExp.test [
                    contact.get('address'),
                    contact.get('fn')
                ].join('')

    return state
