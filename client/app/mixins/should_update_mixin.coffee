_ = require 'underscore'

shallowEqual = (A, B, log) ->
    return true if A is B
    for own key, value of A when B[key] isnt value
        console.log "DIFF ON #{key}" if log
        return false
    for own key of B when B[key]? and not A[key]?
        console.log "LOST #{key}" if log
        return false
    return true


module.exports =

    ImmutableEquality:
        shouldComponentUpdate: (nextProps, nextState) ->
            shallowEqual(@props, nextProps) and shallowEqual(@state, nextState)

    UnderscoreEqualitySlow:
        shouldComponentUpdate: (nextProps, nextState) ->
            isNextState = _.isEqual nextState, @state
            isNextProps = _.isEqual nextProps, @props
            return not (isNextState and isNextProps)

    Logging:
        shouldComponentUpdate: (nextProps, nextState) ->
            not shallowEqual(nextProps, @props, true) or
            not shallowEqual(nextState, @state, true)
