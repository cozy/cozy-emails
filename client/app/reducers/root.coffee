
selectionReducer = require './selection'
messagesReducer = require './message'
{combineReducers} = require('redux')


module.exports = combineReducers({
    selection: selectionReducer
    messages: messagesReducer
})
