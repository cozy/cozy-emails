selectionReducer = require './selection'
contactReducer = require './contact'
messagesReducer = require './message'
layoutReducer = require './layout'
accountReducer = require './account'
{combineReducers} = require 'redux'


module.exports = combineReducers({
    selection: selectionReducer
    messages: messagesReducer
    contact: contactReducer
    layout: layoutReducer
    account: accountReducer
})
