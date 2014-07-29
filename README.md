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
* nodejs

You may get them by `apt-get install nodejs npm vim vim-gnome` on ubuntu.

My env. is ubuntu 14.04, nodejs 0.10.25 and vim 7.4 p183.

For Ubuntu 12.04, nodejs maybe outdated. Please install from PPA or the official website.


How to install
==============

1. `sudo npm install -g shellbridge`
2. `shellbridge --server` to start the daemon
3. ``echo source `npm root -g`/shellbridge/editors/shellbridge.vim >> ~/.vimrc``
4. Start vim with any servername eg. `vim --servername anyword`
5. `Alt-n` to initialize the shellbridge interface
6. Insert `echo 123` then `Enter` to execute the line
7. Inspect shellbridge.vim for more movement


Updates
=======

#### 0.1.7

* vim key mappings are now configurable
* optimized vim conceal
* fixed the abnormal highlighting


#### 0.1.3

Supported multiline execution and added output buffer

![alt tag](https://raw.githubusercontent.com/lokikl/shellbridge/master/demo/multiline_output_buffer.gif)


Getting Involved
================

This simple project is fun. Feel free to ask question or contribute. :)
