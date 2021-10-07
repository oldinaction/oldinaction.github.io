var gulp = require('gulp');
var minifycss = require('gulp-minify-css');
var uglify = require('gulp-uglify');
var htmlmin = require('gulp-htmlmin');
var htmlclean = require('gulp-htmlclean');
// mac安装gulp-imagemin相关依赖失败
//var imagemin = require('gulp-imagemin');

gulp.task('minify-html', function() {
    return gulp.src('./public/**/*.html')
        .pipe(htmlclean())
        .pipe(htmlmin({
            removeComments: true,
            minifyJS: true,
            minifyCSS: true,
            minifyURLs: true,
        }))
        .pipe(gulp.dest('./public'))
});

gulp.task('minify-css', function() {
    return gulp.src('./public/**/*.css')
        .pipe(minifycss({
            compatibility: 'ie8'
        }))
        .pipe(gulp.dest('./public'));
});

gulp.task('minify-js', function() {
    return gulp.src('./public/js/**/*.js')
        .pipe(uglify())
        .pipe(gulp.dest('./public'));
});

//gulp.task('minify-images', function() {
//    return gulp.src('./public/images/**/*.*')
//        .pipe(imagemin(
//        [imagemin.gifsicle({'optimizationLevel': 3}), 
//        imagemin.jpegtran({'progressive': true}), 
//        imagemin.optipng({'optimizationLevel': 7}), 
//        imagemin.svgo()],
//        {'verbose': true}))
//        .pipe(gulp.dest('./public/images'))
//});

gulp.task('default', gulp.parallel(
    'minify-html','minify-css','minify-js'
    //,'minify-images'
));
