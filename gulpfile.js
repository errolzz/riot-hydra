
var gulp            = require('gulp');
var del             = require('del');
var riot            = require('gulp-riot');
var sass            = require('gulp-sass');
var concat          = require('gulp-concat');
var browserSync     = require('browser-sync').create();



//watch for development
gulp.task('watch', function() {
    gulp.start('copy', 'html', 'scripts', 'styles');
    gulp.watch('./src/**/*.js', ['scripts']);
    gulp.watch('./src/**/*.tag', ['scripts']);
    gulp.watch('./src/**/*.scss', ['styles']);
    gulp.watch('./src/**/*.html', ['html']);
});



//html
gulp.task('html', function() {
    return gulp.src('./src/**/*.html')
        .pipe(gulp.dest('./dist'))
});


//css
gulp.task('scss', ['clean:css'], function () {
    return gulp.src(['./src/app.scss', './src/components/*.scss', './src/screens/*.scss'])
        .pipe(concat('app.css'))
        .pipe(sass().on('error', sass.logError))
        .pipe(gulp.dest('./dist/css'));
});
gulp.task('clean:css', function() {
    var deletedFiles = del.sync(['dist/css/**/*.*']);
});
gulp.task('styles', ['scss'], function() {
    browserSync.reload();
});



//riot
gulp.task('riot', function () {
    return gulp.src(['./src/**/*.tag'])
        .pipe(riot())
        .pipe(concat('tags.js'))
        .pipe(gulp.dest('./dist/js'));
});



//javascript
gulp.task('js', ['riot'], function() {
    gulp.src(['./node_modules/riot/riot.js', 
            './node_modules/riotcontrol/riotcontrol.js', 
            './src/**/*.js', 
            './dist/js/tags.js'])
        .pipe(concat('scripts.js'))
        .pipe(gulp.dest('./dist/js'));
    setTimeout(function() {
        del.sync(['dist/js/tags.js']);
    }, 1000);
});
gulp.task('scripts', ['js'], function() {
    browserSync.reload();
});



//assets
gulp.task('copy', function() {
    return gulp.src(['./assets/**/*.*'])
        .pipe(gulp.dest('./dist/assets'));
});



//server
gulp.task('browser-sync', function() {
    browserSync.init({
        port: 8000,
        server: {
            baseDir: './dist'
        }
    });
});



gulp.task('default', ['watch', 'browser-sync']);



