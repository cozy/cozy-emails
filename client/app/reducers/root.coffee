
selectionReducer = require './selection'
{combineReducers} = require('redux')


module.exports = combineReducers({
    selection: selectionReducer
})
