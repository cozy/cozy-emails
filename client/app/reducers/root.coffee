selectionReducer = require './selection'
contactReducer = require './contact'
messagesReducer = require './message'
layoutReducer = require './layout'
{combineReducers} = require 'redux'


module.exports = combineReducers({
    selection: selectionReducer
    messages: messagesReducer
    contact: contactReducer
    layout: layoutReducer
})
