'use strict';

const assert = require('chai').assert;
const Immutable = require('immutable');

const settingsReducer = require('../app/reducers/settings');

describe('Settings Reducer', () => {
  describe('Actions', () => {
    describe('SETTINGS_UPDATE_SUCCESS', () => {

      it('should initiate state\’s settings',  () => {
        // arrange
        let state = null
        let action = {
          type: 'SETTINGS_UPDATE_SUCCESS',
          value: {
            setting1: 'value1',
            setting2:  'value2'
          }
        };

        // act
        let result = settingsReducer(state, action);

        // assert
        assert.isNotNull(result);
        assert.equal(result.size, 2);
        assert.equal('value1', result.get('setting1'));
        assert.equal('value2', result.get('setting2'));
      });

      it('should merge state with new values', () => {
        // arrange
        let state = Immutable.Map({
          setting1: 'value1',
          setting2: 'value2'
        });

        let action = {
          type: 'SETTINGS_UPDATE_SUCCESS',
          value: {
            setting2: 'newValue2',
            setting3: 'value3'
          }
        };

        // act
        let result = settingsReducer(state, action);

        // assert
        assert.equal(result.size, 3);
        assert.equal('value1', result.get('setting1'));
        assert.equal('newValue2', result.get('setting2'));
        assert.equal('value3', result.get('setting3'));
      });

    });
  });
});
