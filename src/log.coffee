async  = require 'async'
colors = require 'colors'
fs     = require 'fs'
util   = require 'util'
EventEmitter = require('events').EventEmitter

# ATTENTION:
# Be careful to not bind two Loggers to each other, as this will end
# in an infinite logging loop!


# Advanced logging class. Features colored output, logging to console and to
# files, as well as.
# If you use logging in multiple classes, you'll have to bind every logger
# to the master logger.
# Note that this is not required, if you do not output to a logfile.
class Log
    # @param filePath - Optional. If passed, logger will output to the file
    # instead of the console.
    constructor: (filePath) ->
        @d = new Date()
        @writeToFile = if filePath? then true else false
        # If the file exsists, truncate it, else create it
        fs.closeSync fs.openSync filePath, 'w' if @writeToFile
        @writeToConsole = true
        @filePath = filePath
        @writingQueue = []
    
    # Override if the logger should ouput to stdout.
    # @param writeToConsole - Boolean. If true, logger will output to stdout.
    setWriteToConsole: (writeToConsole) ->
        @writeToConsole = writeToConsole

    # Override if the logger should output to the file.
    # @param writeToFile - Boolean. If true, logger will output to the file.
    setWriteToFile: (writeToFile) ->
        @writeToFile = writeToFile

    # Set if the logger should show debug messages created by .debug().
    # By default, a logger will not show these. Note that every logger will
    # still emit the debug event, so you only have to set this on the master
    # logger.
    # @param verbose - Boolean. If true, logger will show debug messages.
    setVerbose: (verbose) ->
        @verbose = verbose

    # Used to create debug messages.
    # @emits 'logDebug' - Allways emitted. Used for binding to other loggers.
    # @param tag - A tag to show. Used for locating the origin of the message.
    # @param message - The actual log message.
    debug: (tag, message) ->
        # Debug messages should not be written to the logfile
        @emit 'logDebug', {tag: tag, message: message}
        if @writeToConsole and @verbose
            m = "[D/#{tag}][#{@timeTag()}]#{message}"
            console.log m.white

    # Used to create info messages.
    # @emits 'logInfo' - Allways emitted. Used for binding to other loggers.
    # @param tag - A tag to show. Used for locating the origin of the message.
    # @param message - The actual log message.
    info: (tag, message) ->
        @emit 'logInfo', {tag: tag, message: message}
        m = "[I/#{tag}][#{@timeTag()}]#{message}"
        @writingQueue.push m
        if @writeToConsole
            console.log m.green
        @startWrite()

    # Used to create warn messages.
    # @emits 'logWarn' - Allways emitted. Used for binding to other loggers.
    # @param tag - A tag to show. Used for locating the origin of the message.
    # @param message - The actual log message.
    warn: (tag, message) ->
        @emit 'logWarn', {tag: tag, message: message}
        m = "[W/#{tag}][#{@timeTag()}]#{message}"
        @writingQueue.push m
        if @writeToConsole
            console.log m.yellow
        @startWrite()

    # Used to create error messages.
    # @emits 'logError' - Allways emitted. Used for binding to other loggers.
    # @param tag - A tag to show. Used for locating the origin of the message.
    # @param message - The actual log message.
    error: (tag, message) ->
        @emit 'logError', {tag: tag, message: message}
        m = "[E/#{tag}][#{@timeTag()}]#{message}"
        @writingQueue.push m
        if @writeToConsole
            console.error m.red
        @startWrite()

    # Used to create fatal messages.
    # @emits 'logFatal' - Allways emitted. Used for binding to other loggers.
    # @param tag - A tag to show. Used for locating the origin of the message.
    # @param message - The actual log message.
    fatal: (tag, message) ->
        @emit 'logFatal', {tag: tag, message: message}
        m = "[F/#{tag}][#{@timeTag()}]#{message}"
        @writingQueue.push m
        if @writeToConsole
            console.error m.red.underline
        @startWrite()

    # Used to trace errors.
    # @emits 'logTrace' - Allways emitted. Used for binding to other loggers.
    # @param tag - A tag to show. Used for locating the origin of the message.
    # @param message - The actual log message.
    # @param error - The error object to trace.
    trace: (tag, message, error) ->
        @emit 'logTrace', {tag: tag, message: message,  error: error}
        m = "[T/#{tag}][#{@timeTag()}]#{message}\n\tTrace:\n\t#{error.stack}"
        @writingQueue.push m
        if @writeToConsole
            console.error m.red
        @startWrite()

    # Binds another logger to this one. Because you cannot pass by reference
    # in JS, you need to bind all loggers to one master logger, so that only
    # once instance tries to write to the file at once. Binding is not needed
    # for loggers that will only output to STDOUT.
    # @param logger - The slave that will get bound to the master.
    bind: (logger) ->
        logger.on 'logDebug', (data) =>
            @debug data.tag, data.message
        logger.on 'logInfo', (data) =>
            @info data.tag, data.message
        logger.on 'logWarn', (data) =>
            @warn data.tag, data.message
        logger.on 'logError', (data) =>
            @error data.tag, data.message
        logger.on 'logFatal', (data) =>
            @fatal data.tag, data.message
    
    # Internal method, writes all of the remaining messages to the file.
    startWrite: () ->
        # Used as a measure of precaution, as the queue should never get
        # bigger than 50 entries between writes.
        if @writingQueue.length > 50
            console.error "ATTENTION: THE LOG WRITING QUEUE IS TOO BIG!"

        # Only output if the logger is set to write to a file.
        if @writeToFile is true
            writeStream = fs.createWriteStream @filePath, {
                flags: 'a'
                defaultEncoding: 'utf8'
                autoClose: true
            }
            writeStream.once 'open', () =>
                async.each @writingQueue
                , (message, callback) ->
                    writeStream.once 'error', (error) ->
                        callback error
                    writeStream.write message + '\n'
                    callback null

                , (err) =>
                    if err?
                        @error "Log", "Error writing to file: #{err}.
                            Now disabling file logging output."
                        @writeToFile = false
                    writeStream.end()
                    @writingQueue = []
        else
            @writingQueue.splice 0, @writingQueue.length
    
    # Internal method, creates a string with the current time and date.
    timeTag: () ->
        @d = new Date()
        "#{@d.toLocaleTimeString()} on #{@d.toLocaleDateString()}"

    # Disables all visible logging and returns itself, used for getting a
    # bindable instance of a logger.
    getInstanceForBinding: () ->
        @writeToFile = false
        @writeToConsole = false
        @

util.inherits Log, EventEmitter

module.exports = Log
