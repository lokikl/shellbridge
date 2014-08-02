var net = require('net');

var ShellBridgeClient = {};

ShellBridgeClient.run = function(ops) {
  if (ops.args) {
    var cmd = ops.args.join(' ');
    var cmd2 = cmd.replace(/.*\| */, '')
  }

  var HOST = '127.0.0.1';
  var PORT = 49221;

  var client = new net.Socket();
  client.connect(PORT, HOST, function() {
    if (ops['request-id']) {
      var p = {request_id: true};
      client.write(JSON.stringify(p));

    } else if (ops.kill) {
      var p = {kill: true, id: ops.kill};
      client.write(JSON.stringify(p));
      client.destory();

    } else {
      var p = {
        cmd: cmd,
        id: ops.id,
        session: ops.session,
        directory: ops.directory
      };
      client.write(JSON.stringify(p));
      client.destory();
    }
  });

  // Add a 'data' event handler for the client socket
  // data is what the server sent to this socket
  client.on('data', function(data) {
    if (ops['request-id']) { // request for new id
      console.log(data+'');
    } else if (ops.id === "-1") { // new cmd, return id (deprecated)
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
