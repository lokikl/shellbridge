var net = require('net');

var ShellBridgeClient = {};

ShellBridgeClient.run = function(ops) {
  var cmd = ops.args.join(' ');
  var cmd2 = cmd.replace(/.*\| */, '')

  var HOST = '127.0.0.1';
  var PORT = 49221;

  var client = new net.Socket();
  client.connect(PORT, HOST, function() {
    if (ops.kill) {
      client.write(JSON.stringify({
        kill: true,
        cmd: cmd
      }));
    } else {
      client.write(JSON.stringify({
        cmd: cmd,
        id: ops.id,
        session: ops.session,
        directory: ops.directory
      }));
    }
  });

  // Add a 'data' event handler for the client socket
  // data is what the server sent to this socket
  client.on('data', function(data) {
    if (ops.id === "-1") {
      console.log(data+'');
    } else {
      console.log(ops.id);
    }
    client.destroy();
  });

  // Add a 'close' event handler for the client socket
  client.on('close', function() {
    // console.log('Connection closed');
  });
}

module.exports = ShellBridgeClient;
