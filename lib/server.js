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
  if (q.request_id) {
    nextID += 1;
    console.log(" req: ", nextID);
    sock.write(nextID + '');

  } else if (q.kill) {
    console.log("kill: ", q.id);
    kill(processes[q.id].pid); // TODO: no done message sent after kill

  } else {
    // sock.write('');
    console.log('proc: ' + q.id);
    q.cmd = extendCmd(q.cmd);

    var proc = processes[q.id];
    if (proc) { // cont. existing process
      console.log('cont: ', q.id, "cmd", q.cmd);
      proc.stdin.write(q.cmd + "\n");
      sock.write("received");

    } else {
      processes[q.id] = exec(q.cmd.replace(/.*\| */, ''), {
        'cwd': q.directory
      });
      proc = processes[q.id];
      sock.write("received");

      var outputBuffer = '';
      var streamToEditor = function(output) {
        output = outputBuffer + output;
        var o = output.split("\n");
        outputBuffer = o.pop();
        output = o.join("\n").trim();
        if (output !== "") {
          sendToEditor(q.session, q.id, output);
        }
      }
      proc.stdout.on('data', streamToEditor);
      proc.stderr.on('data', streamToEditor);
      proc.stdout.on('close', function() {
        console.log("done:", q.id);
        setTimeout(function() {
          streamToEditor("!!done\n");
        }, 500);
      });
      proc.on('error', function (code) {
        console.log('error ' + code);
      });
    }
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
