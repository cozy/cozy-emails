
selectionReducer = require './selection'
messagesReducer = require './message'
layoutReducer = require './layout'
{combineReducers} = require('redux')


module.exports = combineReducers({
    selection: selectionReducer
    messages: messagesReducer
    layout: layoutReducer
})
