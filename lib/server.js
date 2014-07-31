var net        = require('net');
var exec       = require('child_process').exec;
var fs         = require('fs');
var psTree     = require('ps-tree'); // for killing process by pid
JSON.minify    = require("node-json-minify");

var HOST = '127.0.0.1';
var PORT = 49221;

function readConfigFile() {
  var homePath = process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE;
  var configFile = homePath + '/.shellbridgerc';
  if (!fs.existsSync(configFile)) {
    configFile = __dirname + '/../shellbridgerc';
    if (!fs.existsSync(configFile)) {
      console.log('~/.shellbridgerc expected but not found.');
      process.exit(1);
    } else {
      console.log("~/.shellbridgerc not found, fallback to default:", configFile);
    }
  }
  var content = fs.readFileSync(configFile, 'utf8');
  var config = JSON.parse(JSON.minify(content));
  return config;
}
var config = readConfigFile();
console.log(config);

function extendCmd(cmd) {
  for(var matcher in config.commands) {
    var regexp = new RegExp(matcher);
    if (cmd.match(regexp)) {
      var c = config.commands[matcher];
      if (c.replace) {
        cmd = cmd.replace(regexp, c.replace);
      }
    }
  }
  return cmd;
}

function kill(pid, signal, callback) {
  signal   = signal || 'SIGKILL';
  callback = callback || function () {};
  var killTree = true;
  if(killTree) {
    psTree(pid, function (err, children) {
      [pid].concat(
        children.map(function (p) {
        return p.PID;
      })
      ).forEach(function (tpid) {
        try { process.kill(tpid, signal) }
        catch (ex) { }
      });
      callback();
    });
  } else {
    try { process.kill(pid, signal) }
    catch (ex) { }
    callback();
  }
}

String.prototype.trim = function() {
  return this.replace(/^\s+|\s+$/g, "");
};

function sendToEditor(sessionName, id, msg) {
  msg = msg.replace(/"/g, "\\\"").replace(/'/g, "&#39;");
  var insert = config.insertCmd.replace('%s', id).replace('%o', msg);
  var cmd = config.editorCmd.replace('%s', sessionName).replace('%c', insert);
  if (config.logEditorCmd) { console.log("edit:", cmd); }
  exec(cmd);
}

var nextID = 0;
var processes = {}; // process pool

function processData(sock, q) {
  q.cmd = extendCmd(q.cmd);

  if (q.kill) {
    sock.write("killed");
    var id = q.cmd.match(/%(\d*)!?\|/)[1];
    kill(processes[id].pid);

  } else if (q.id > -1) {
    sock.write(q.id + '');
    console.log('cont: ', q.id, "cmd", q.cmd);
    processes[q.id].stdin.write(q.cmd + "\n");

  } else {
    nextID += 1;
    var processID = nextID;
    sock.write(processID + '');

    console.log('proc: ' + processID);
    processes[processID] = exec(q.cmd.replace(/.*\| */, ''), {
      'cwd': q.directory
    });

    var outputBuffer = '';
    var streamToEditor = function(output) {
      output = outputBuffer + output;
      var o = output.split("\n");
      outputBuffer = o.pop();
      output = o.join("\n").trim();
      if (output != "") {
        sendToEditor(q.session, processID, output);
      }
    }

    processes[processID].stdout.on('data', streamToEditor);
    processes[processID].stderr.on('data', streamToEditor);
    processes[processID].stdout.on('close', function() {
      console.log(' end:', processID);
    });
    processes[processID].on('error', function (code) {
      console.log('error ' + code);
    });
    processes[processID].on('exit', function (code) {
      console.log("done:", processID);
      streamToEditor("!!done\n");
    });
  }
}

// Create a server instance, and chain the listen function to it
// The function passed to net.createServer() becomes the event handler for the 'connection' event
// The sock object the callback function receives UNIQUE for each connection
net.createServer(function(sock) {
  // Add a 'data' event handler to this instance of socket
  sock.on('data', function(data) {
    console.log('% ' + sock.remoteAddress + ':' + sock.remotePort + ': ' + data);
    try {
      var q = JSON.parse(data);
      processData(sock, q);
    } catch(err) {
      console.log("Error occurred", err);
    }
  });

  // Add a 'close' event handler to this instance of socket
  sock.on('close', function(data) { });
}).listen(PORT, HOST);

console.log('\n', 'Server started on ' + HOST +':'+ PORT);
