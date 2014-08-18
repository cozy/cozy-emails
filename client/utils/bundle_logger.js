/* bundleLogger
   ------------
   Provides gulp style logs to the bundle method in browserify.js
*/

var gutil        = require('gulp-util');
var prettyHrtime = require('pretty-hrtime');
var startTime;

module.exports = {
  start: function() {
    startTime = process.hrtime();
    gutil.log('Rebundling JS files...');
  },

  end: function() {
    var taskTime = process.hrtime(startTime);
    var prettyTime = prettyHrtime(taskTime);
    gutil.log('Finished', gutil.colors.green("re-bundling"), 'in', gutil.colors.magenta(prettyTime));
  },

  log: function(time) {
    gutil.log('Rebundled in', gutil.colors.magenta(time/1000), 's');
  }
};