moment      = require 'moment'

module.exports =

    # Display date as a readable string.
    # Make it shorter if compact is set to true.
    getCreatedAt: (message) ->
        return unless (date = message?.get 'createdAt')?

        today = moment()
        date  = moment date

        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'MMM DD'
        else
            formatter = 'HH:mm'

        return date.format formatter
