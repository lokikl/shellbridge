shellbridge is a daemon written in javascript, enabling an interactive shell experience inside editors like vim. Inspired by xiki but in a different way.

* Execute arbitary shell commands in text editors
* Multiple long-lasting commands can be running in parallel
* Interactive commands supported like mysql, redis-cli, ssh and even bash.


Demo on vim
===========

![alt tag](https://raw.githubusercontent.com/lokikl/shellbridge/master/demo/vim-demo.gif)


Prerequisite
============

* vim 7.3+ compiled with +client-server option
* newer nodejs

You may get them by `apt-get install nodejs npm vim vim-gnome` on ubuntu.

My env. is ubuntu 14.04, nodejs 0.10.25 and vim 7.4 p183.

For Ubuntu 12.04, please install newer node and npm from PPA and the official installer script.


How to install
==============

1. `sudo npm install -g shellbridge`
2. `shellbridge --server` to start the daemon
3. ``echo source `npm root -g`/shellbridge/editors/shellbridge.vim >> ~/.vimrc``
4. Start vim with any servername eg. `vim --servername anyword`
5. `Alt-n` to initialize the shellbridge interface
6. Insert `echo 123` then `Alt-n` to execute the line


Updates
=======

#### 0.1.10

* identified lines indended as subcmd, no need to be indented with exactly 2 spaces
* updated default key mappings:
  1. alt n to start/execute
  2. alt s to sort
* showed all key mappings when started

#### 0.1.7

* vim key mappings are now configurable
* optimized vim conceal
* fixed the abnormal highlighting


#### 0.1.3

Supported multiline execution and added output buffer

![alt tag](https://raw.githubusercontent.com/lokikl/shellbridge/master/demo/multiline_output_buffer.gif)


Getting Involved
================

This simple project is fun. I enjoy so much working on it. Please feel free to ask me/file an issue if you got any problem on setup. Any suggestions are welcome. Thank you so much for give it a try. :)
