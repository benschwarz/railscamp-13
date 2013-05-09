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
          'css/screen.css': 'sass/screen.scss'
        }
      }
    },

    connect: {
      server: {
        options: {
          port: 3000,
          base: './'
        }
      }
    }
  });
 
  grunt.registerTask('default', ['sass', 'concat']);
  grunt.registerTask('dev', ['connect', 'watch']);

  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);
};