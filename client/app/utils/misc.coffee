exports.getSortFunction = (criteria, order) ->
    return sortFunction = (message1, message2) ->
        val1 = message1.get criteria
        val2 = message2.get criteria
        if val1 > val2 then return -1 * order
        else if val1 < val2 then return 1 * order
        else return 0

exports.reverseDateSort = exports.getSortFunction 'date', -1
