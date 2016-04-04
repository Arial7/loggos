module.exports = function(grunt) {
	require('time-grunt')(grunt);
    require('grunt-task-loader')(grunt);
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        coffee: {
            compile: {
                files: {
					'bin/log.js'      : 'src/log.coffee',
                }
            }
        },
        coffeelint: {
            lint: ['src/**/*.coffee'],
            options: {
                configFile: 'coffeelint.json'
            }
        },
        watch: {
            coffee: {
                files:['src/**/*.coffee'],
                tasks: ['newer:coffee']
            }
		}
    });
    grunt.registerTask('default',['watch']);
    grunt.registerTask('build', ['coffeelint', 'coffee']);
}
