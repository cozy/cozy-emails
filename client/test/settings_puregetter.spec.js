'use strict';

const assert = require('chai').assert;
const Immutable = require('immutable');

const settingsPureGetter = require('../app/puregetters/settings');

describe('Settings pure getter', () => {
  describe('Methods', () => {

    describe('get', () => {

      it('should return all settings when no param', () => {
        // arrange
        let expectedSettings = {
          setting1: 'value1',
          setting2: 'value2',
          setting3: 'value3',
        };

        let state = Immutable.Map({
          settings: Immutable.Map(expectedSettings)
        });

        // act
        let result = settingsPureGetter.get(state);

        // assert
        assert.deepEqual(result, expectedSettings);

      });

      it('should return given setting', () => {
        // arrage
        let expectedValue = 'value2';
        let settings = {
          setting1: 'value1',
          setting2: 'value2',
          setting3: 'value3'
        };

        let state = Immutable.Map({
          settings: Immutable.Map(settings)
        });

        // act
        let result = settingsPureGetter.get(state, 'setting2');

        // assert
        assert.equal(result, expectedValue);

      });

    });

  });
});
