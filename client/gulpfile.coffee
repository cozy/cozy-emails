gulp       = require 'gulp'
coffeeify  = require 'coffeeify'
browserify = require 'browserify'
watchify   = require 'watchify'

rename     = require 'gulp-rename'
stylus     = require 'gulp-stylus'
nib        = require 'nib'

gulpif     = require 'gulp-if'
uglify     = require 'gulp-uglify'
mincss     = require 'gulp-minify-css'

source      = require 'vinyl-source-stream'
sourceMaps  = require 'gulp-sourcemaps'
buffer      = require 'vinyl-buffer'
concat      = require 'gulp-concat'
#order       = require 'gulp-order'


bundleLogger = require './utils/bundle_logger'
handleErrors = require './utils/handle_errors'

isProd = -> process.env.BUILD_ENV is "production"
global = {}

gulp.task 'setWatch', -> global.isWatching = true

gulp.task 'stylus', ->
  gulp.src ['./vendor/styles/**/*.css', './app/styles/application.styl']
    .pipe stylus use: [nib()]
    .pipe concat 'app.css'
    .pipe gulpif isProd(), mincss()
    .pipe gulp.dest './public/css'

gulp.task 'coffee', ->
    browserifyConfig =
        entries: ['./app/initialize.coffee']
        extensions: ['.coffee']
        debug: true

        cache: {}
        packageCache: {}
        fullPaths: true

    bundler = browserify browserifyConfig
    bundler.transform 'coffeeify'

    bundleLogger.start()

    rebundle = ->
        bundler
            .bundle()
            .pipe source 'initialize.js'
            .pipe buffer()
            .pipe rename 'bundle.js'
            .pipe sourceMaps.init loadMaps: true
                .pipe gulpif isProd(), uglify()

            .pipe sourceMaps.write('.')
            .pipe gulp.dest './public/js'

    if global.isWatching
        bundler = watchify bundler, watchify.args
        bundler.on 'update', rebundle
    bundler.on 'error', handleErrors
    bundler.on 'time', bundleLogger.log
    bundler.on 'end', bundleLogger.end

    rebundle()


gulp.task 'watch', ['setWatch',  'coffee'], ->
    gulp.watch './app/styles/application.styl', ['stylus']

gulp.task 'build',   ['stylus', 'coffee']
