var gulp        = require('gulp');
var plumber     = require('gulp-plumber');
var jade        = require('gulp-jade');
var stylus      = require('gulp-stylus');
var browserSync = require('browser-sync');


gulp.task('templates', function () {
  gulp.src('./src/*.jade')
    .pipe(plumber())
    .pipe(jade())
    .pipe(gulp.dest('./dist/'))
    .pipe(browserSync.reload({stream: true}));
});

gulp.task('styles', function () {
  gulp.src('./src/styles/app.styl')
    .pipe(plumber())
    .pipe(stylus({use: require('cozy-ui/lib/stylus')()}))
    .pipe(gulp.dest('./dist/styles/'))
    .pipe(browserSync.reload({stream: true}));
});

gulp.task('serve', ['templates', 'styles'], function () {
  browserSync({
      server: {
          baseDir: './dist'
      },
      open: false
  });

  gulp.src('./src/assets/**/*')
    .pipe(gulp.dest('./dist/'))

  gulp.watch('./src/**/*.jade', ['templates']);
  gulp.watch('./src/styles/**/*.styl', ['styles']);
});
