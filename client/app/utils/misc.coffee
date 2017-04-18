exports.sortByDate = (order) ->
    criteria = 'date'
    order = if order is '+' then -1 else 1
    return sortFunction = (message1, message2) ->
        val1 = message1.get criteria
        val2 = message2.get criteria
        if val1 > val2 then return -1 * order
        else if val1 < val2 then return 1 * order
        else return 0
