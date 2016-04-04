#loggos - the simple nodejs logger for your amazing projects!

Nlog is a simple logging library to get you up and running as fast as possible.
It features: 
- colored ouput
- logging to a file and to stdout/stderr
- asynchronous writing to logfiles, to speed up things

## Installation
To use loggos, just do a simple `npm install --save loggos`.

## Examples
```javascript
var Log = require("loggos");
log = new Log("logfile.log"); 
//By default, loggos will stop writing to stdout, when a logfile is specified.
log.setWriteToConsole(true);

log.info("Tag", "This is an informational message");

```

For more usage examples, browse the source, I think I have commented enough :)
