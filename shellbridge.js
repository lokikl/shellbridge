#!/usr/bin/env nodejs

var stdio = require('stdio');

var ops = stdio.getopt({
  'server': {description: 'Start shellbridge server'},
  'id': {key: 'i', description: 'Session id', args: 1},
  'session': {key: 's', description: 'Session name', args: 1},
  'directory': {key: 'd', description: 'Working directory', args: 1},
  'kill': {key: 'k', description: 'Kill process'}
});

if (ops.server) {
  require('./lib/server.js');
} else {
  var ShellBridgeClient = require('./lib/client.js');
  ShellBridgeClient.run(ops);
}
