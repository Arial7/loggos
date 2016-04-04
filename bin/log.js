(function() {
  var EventEmitter, Log, async, colors, fs, util;

  async = require('async');

  colors = require('colors');

  fs = require('fs');

  util = require('util');

  EventEmitter = require('events').EventEmitter;

  Log = (function() {
    function Log(filePath) {
      this.d = new Date();
      this.writeToFile = filePath != null ? true : false;
      if (this.writeToFile) {
        fs.closeSync(fs.openSync(filePath, 'w'));
      }
      this.writeToConsole = true;
      this.filePath = filePath;
      this.writingQueue = [];
    }

    Log.prototype.setWriteToConsole = function(writeToConsole) {
      return this.writeToConsole = writeToConsole;
    };

    Log.prototype.setWriteToFile = function(writeToFile) {
      return this.writeToFile = writeToFile;
    };

    Log.prototype.setVerbose = function(verbose) {
      return this.verbose = verbose;
    };

    Log.prototype.debug = function(tag, message) {
      var m;
      this.emit('logDebug', {
        tag: tag,
        message: message
      });
      if (this.writeToConsole && this.verbose) {
        m = "[D/" + tag + "][" + (this.timeTag()) + "]" + message;
        return console.log(m.white);
      }
    };

    Log.prototype.info = function(tag, message) {
      var m;
      this.emit('logInfo', {
        tag: tag,
        message: message
      });
      m = "[I/" + tag + "][" + (this.timeTag()) + "]" + message;
      this.writingQueue.push(m);
      if (this.writeToConsole) {
        console.log(m.green);
      }
      return this.startWrite();
    };

    Log.prototype.warn = function(tag, message) {
      var m;
      this.emit('logWarn', {
        tag: tag,
        message: message
      });
      m = "[W/" + tag + "][" + (this.timeTag()) + "]" + message;
      this.writingQueue.push(m);
      if (this.writeToConsole) {
        console.log(m.yellow);
      }
      return this.startWrite();
    };

    Log.prototype.error = function(tag, message) {
      var m;
      this.emit('logError', {
        tag: tag,
        message: message
      });
      m = "[E/" + tag + "][" + (this.timeTag()) + "]" + message;
      this.writingQueue.push(m);
      if (this.writeToConsole) {
        console.error(m.red);
      }
      return this.startWrite();
    };

    Log.prototype.fatal = function(tag, message) {
      var m;
      this.emit('logFatal', {
        tag: tag,
        message: message
      });
      m = "[F/" + tag + "][" + (this.timeTag()) + "]" + message;
      this.writingQueue.push(m);
      if (this.writeToConsole) {
        console.error(m.red.underline);
      }
      return this.startWrite();
    };

    Log.prototype.trace = function(tag, message, error) {
      var m;
      this.emit('logTrace', {
        tag: tag,
        message: message,
        error: error
      });
      m = "[T/" + tag + "][" + (this.timeTag()) + "]" + message + "\n\tTrace:\n\t" + error.stack;
      this.writingQueue.push(m);
      if (this.writeToConsole) {
        console.error(m.red);
      }
      return this.startWrite();
    };

    Log.prototype.bind = function(logger) {
      logger.on('logDebug', (function(_this) {
        return function(data) {
          return _this.debug(data.tag, data.message);
        };
      })(this));
      logger.on('logInfo', (function(_this) {
        return function(data) {
          return _this.info(data.tag, data.message);
        };
      })(this));
      logger.on('logWarn', (function(_this) {
        return function(data) {
          return _this.warn(data.tag, data.message);
        };
      })(this));
      logger.on('logError', (function(_this) {
        return function(data) {
          return _this.error(data.tag, data.message);
        };
      })(this));
      return logger.on('logFatal', (function(_this) {
        return function(data) {
          return _this.fatal(data.tag, data.message);
        };
      })(this));
    };

    Log.prototype.startWrite = function() {
      var writeStream;
      if (this.writingQueue.length > 50) {
        console.error("ATTENTION: THE LOG WRITING QUEUE IS TOO BIG!");
      }
      if (this.writeToFile === true) {
        writeStream = fs.createWriteStream(this.filePath, {
          flags: 'a',
          defaultEncoding: 'utf8',
          autoClose: true
        });
        return writeStream.once('open', (function(_this) {
          return function() {
            return async.each(_this.writingQueue, function(message, callback) {
              writeStream.once('error', function(error) {
                return callback(error);
              });
              writeStream.write(message + '\n');
              return callback(null);
            }, function(err) {
              if (err != null) {
                _this.error("Log", "Error writing to file: " + err + ". Now disabling file logging output.");
                _this.writeToFile = false;
              }
              writeStream.end();
              return _this.writingQueue = [];
            });
          };
        })(this));
      } else {
        return this.writingQueue.splice(0, this.writingQueue.length);
      }
    };

    Log.prototype.timeTag = function() {
      this.d = new Date();
      return (this.d.toLocaleTimeString()) + " on " + (this.d.toLocaleDateString());
    };

    Log.prototype.getInstanceForBinding = function() {
      this.writeToFile = false;
      this.writeToConsole = false;
      return this;
    };

    return Log;

  })();

  util.inherits(Log, EventEmitter);

  module.exports = Log;

}).call(this);
