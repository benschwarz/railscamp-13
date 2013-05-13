module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    watch: {
      files: ['sass/*.scss'],
      tasks: 'sass'
    },

    sass: {
      main: {
        files: {
          'public/css/screen.css': [
            'components/normalize-css/normalize.css',
            'sass/screen.scss'
          ]
        }
      }
    },

    connect: {
      server: {
        options: {
          port: 3000,
          base: './public'
        }
      }
    }
  });

  grunt.registerTask('default', ['sass']);
  grunt.registerTask('dev', ['connect', 'watch']);

  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);
};