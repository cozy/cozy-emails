selectionReducer = require './selection'
contactReducer = require './contact'
messagesReducer = require './message'
{combineReducers} = require 'redux'


module.exports = combineReducers({
    selection: selectionReducer
    messages: messagesReducer
    contact: contactReducer
})
