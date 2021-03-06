
var gulp            = require('gulp');
var del             = require('del');
var riot            = require('gulp-riot');
var sass            = require('gulp-sass');
var concat          = require('gulp-concat');



//watch for development
gulp.task('watch', function() {
    gulp.start('copy', 'scripts', 'styles');
    gulp.watch('./src/assets/**/*.*', ['copy']);
    gulp.watch('./src/**/*.js', ['scripts']);
    gulp.watch('./src/**/*.tag', ['scripts']);
    gulp.watch('./src/**/*.scss', ['styles']);
});



//css
gulp.task('styles', ['clean:css'], function () {
    return gulp.src(['./src/app.scss', './src/components/*.scss', './src/screens/*.scss'])
        .pipe(concat('app.css'))
        .pipe(sass().on('error', sass.logError))
        .pipe(gulp.dest('./dist/css'));
});
gulp.task('clean:css', function() {
    var deletedFiles = del.sync(['dist/css/**/*.*']);
});



//riot
gulp.task('riot', function () {
    return gulp.src(['./src/**/*.tag'])
        .pipe(riot())
        .pipe(concat('tags.js'))
        .pipe(gulp.dest('./dist/js'));
});



//javascript
gulp.task('scripts', ['riot'], function() {
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



//assets
gulp.task('copy', function() {
    console.log('COPYING')
    return gulp.src(['./src/assets/**/*.*'])
        .pipe(gulp.dest('./dist/assets'));
});



gulp.task('default', ['watch']);



