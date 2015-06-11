###

    -- Coffee port of Facebook's flux dispatcher. It was in ES6 and I haven't
    been successful in adding a transpiler. --

    Copyright (c) 2014, Facebook, Inc.
    All rights reserved.

    This source code is licensed under the BSD-style license found in the
    LICENSE file in the root directory of this source tree. An additional grant
    of patent rights can be found in the PATENTS file in the same directory.
 ###

invariant = require '../invariant'

_lastID = 1
_prefix = 'ID_'

module.exports = Dispatcher = class Dispatcher
    constructor: ->
        this._callbacks = {}
        this._isPending = {}
        this._isHandled = {}
        this._isDispatching = false
        this._pendingPayload = null

    ###
        Registers a callback to be invoked with every dispatched payload.
        Returns a token that can be used with `waitFor()`.

        @param {function} callback
        @return {string}
    ###
    register: (callback) ->
        id = _prefix + _lastID++
        this._callbacks[id] = callback
        return id

    ###
        Removes a callback based on its token.

        @param {string} id
    ###
    unregister: (id) ->
        message = 'Dispatcher.unregister(...): `%s` does not map to a ' + \
                  'registered callback.'
        invariant(
            this._callbacks[id],
            message,
            id
        )
        delete this._callbacks[id]

    ###
        Waits for the callbacks specified to be invoked before continuing
        execution of the current callback. This method should only be used by a
        callback in response to a dispatched payload.

        @param {array<string>} ids
    ###
    waitFor: (ids) ->
        invariant(
            this._isDispatching,
            'Dispatcher.waitFor(...): Must be invoked while dispatching.'
        )
        message = 'Dispatcher.waitFor(...): Circular dependency detected ' + \
                  'while waiting for `%s`.'
        message2 = 'Dispatcher.waitFor(...): `%s` does not map to a ' + \
                   'registered callback.'
        for ii in [0..ids.length - 1] by 1
            id = ids[ii]
            if this._isPending[id]
                invariant(
                    this._isHandled[id],
                    message,
                    id
                )
                continue

            invariant(
                this._callbacks[id],
                message2,
                id
            )
            this._invokeCallback id

    ###
        Dispatches a payload to all registered callbacks.

        @param {object} payload
    ###
    dispatch: (payload) ->
        console.log "DIS", payload.action.type, payload.action.value
        message = 'Dispatch.dispatch(...): Cannot dispatch in the middle ' + \
                  'of a dispatch.'
        invariant(
            not this._isDispatching,
            message
        )
        this._startDispatching(payload)
        try
            for id of this._callbacks
                if this._isPending[id]
                    continue
                this._invokeCallback id
        finally
            this._stopDispatching()

    ###
        Is this Dispatcher currently dispatching.

        @return {boolean}
    ###
    isDispatching: -> return this._isDispatching

    ###
        Call the callback stored with the given id. Also do some internal
        bookkeeping.

        @param {string} id
        @internal
    ###
    _invokeCallback: (id) ->
        this._isPending[id] = true
        this._callbacks[id](this._pendingPayload)
        this._isHandled[id] = true

    ###
        Set up bookkeeping needed when dispatching.

        @param {object} payload
        @internal
    ###
    _startDispatching: (payload) ->
        for id of this._callbacks
            this._isPending[id] = false
            this._isHandled[id] = false

        this._pendingPayload = payload
        this._isDispatching = true

    ###
        Clear bookkeeping used for dispatching.

        @internal
    ###
    _stopDispatching: ->
        this._pendingPayload = null
        this._isDispatching = false
