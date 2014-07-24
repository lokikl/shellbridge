shellbridge is a daemon written in javascript, enabling an interactive shell experience inside editors like vim. Inspired by xiki but in a different way.

* Execute arbitary shell commands in text editors
* Multiple long-lasting commands can be running in parallel
* Interactive commands supported like mysql, redis-cli, ssh and even bash.


Demo on vim
===========

![alt tag](https://raw.githubusercontent.com/lokikl/shellbridge/master/vim-demo.gif)


Prerequisite
============

vim 7.3+ and nodejs are required.

My env. is ubuntu 14.04, nodejs 0.10.25 and vim 7.4 p183.


How to install
==============

1. Checkout the codes, symbolic link shellbridge.js to /usr/local/bin/shellbridge
2. `npm install stdio node-json-minify ps-tree`
3. `cp shellbridgerc ~/.shellbridgerc`
4. `shellbridge --server` to start the daemon
5. Start vim with any servername eg. `vim --servername shell`
6. Source editors/shellbridge.vim, then `Alt-n` to get started
7. Insert `echo 123` then `Ctrl-Enter` to execute the line
8. Inspect shellbridge.vim for more movement


Getting Involved
================

This simple project is fun. Feel free to ask question or contribute. :)
