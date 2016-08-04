'use strict';
const assert = require('chai').assert;

const ActionTypes = require('../app/constants/app_constants').ActionTypes;
const layoutReducer = require('../app/reducers/layout');

describe('Layout Reducer', () => {
  describe('Actions', () => {

    describe('TOASTS_SHOW', () => {
      it('should set hidden to false', () => {
        // arrange
        let state = null;
        let action = {
          type: ActionTypes.TOASTS_SHOW
        };

        // act
        let result = layoutReducer(state, action);

        // assert
        assert.isFalse(result.hidden);
      });
    });

    describe('TOASTS_HIDE', () => {
      it('should set hidden to true', () => {
        // arrange
        let state = null;
        let action = {
          type: ActionTypes.TOASTS_HIDE
        };

        // act
        let result = layoutReducer(state, action);

        // assert
        assert.isTrue(result.hidden);
      });
    });

    describe('INTENT_AVAILABLE', () => {
      it('should set intentAvailable to true', () => {
        // arrange
        let state = null;
        let action = {
          type: ActionTypes.INTENT_AVAILABLE,
          value: true,
        };

        // act
        let result = layoutReducer(state, action);

        // assert
        assert.isTrue(result.intentAvailable);
      });

      it('should set intentAvailable to false', () => {
        // arrange
        let state = null;
        let action = {
          type: ActionTypes.INTENT_AVAILABLE,
          value: false,
        };

        // act
        let result = layoutReducer(state, action);

        // assert
        assert.isFalse(result.intentAvailable);
      });
    });
  });
});
