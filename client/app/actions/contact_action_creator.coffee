{ActionTypes} = require '../constants/app_constants'
XHRUtils = require '../libs/xhr'

module.exports = ContactActionCreator = (dispatch) ->

    createContact: (contact) ->
        options =
            name: 'create'
            data:
                type: 'contact'
                contact: contact

        dispatch
            type: ActionTypes.CREATE_CONTACT_REQUEST
            value: options

        XHRUtils.activityCreate options, (error, res) ->
            if error
                dispatch
                    type: ActionTypes.CREATE_CONTACT_FAILURE
                    value: error
            else
                dispatch
                    type: ActionTypes.CREATE_CONTACT_SUCCESS
                    value: res
