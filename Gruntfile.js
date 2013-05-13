module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    watch: {
      sass: {
        files: ['sass/*.scss'],
        tasks: 'sass'
      },
      javascript: {
        files: ['javascript/**/*.js'],
        tasks: 'javascript'
      }
    },

    sass: {
      dist: {
        files: {
          'public/css/screen.css': [
            'components/normalize-css/normalize.css',
            'sass/screen.scss'
          ]
        }
      }
    },

    requirejs: {
      rc13: {
        options: {
          name: "rc13",
          baseUrl: 'javascript',
          mainConfigFile: 'javascript/config.js',
          insertRequire: ["rc13"],
          optimize: "none",
          out: "build/rc13.js"
        }
      }
    },

    uglify: {
      rc13: {
        options: {
          compress: false,
          mangle: false,
          beautify: true
        },
        files: {
          'public/js/rc13.js': ['components/requirejs/require.js', 'build/rc13.js']
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

  grunt.registerTask('javascript', ['requirejs:rc13', 'uglify:rc13']);

  grunt.registerTask('default', ['sass']);
  grunt.registerTask('dev', ['connect', 'watch']);

  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);
};