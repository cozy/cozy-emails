
selectionReducer = require './selection'
messagesReducer = require './message'
settingsReducer = require './settings'
{combineReducers} = require('redux')


module.exports = combineReducers({
    selection: selectionReducer
    messages: messagesReducer
    settings: settingsReducer
})
