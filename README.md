shellbridge is a daemon written in javascript, enabling an interactive shell experience inside editors like vim. Inspired by xiki but in a different way.

* Execute arbitary shell commands in text editors
* Multiple long-lasting commands can be running in parallel
* Interactive commands supported like mysql, redis-cli, ssh and even bash.


Demo on vim
===========

![alt tag](https://raw.githubusercontent.com/lokikl/shellbridge/master/vim-demo.gif)


How to install
==============

1. Checkout the codes
2. `npm install stdio node-json-minify`
3. `./shellbridge --server` to start the daemon
4. Open vim and source editors/shellbridge.vim
5. `Alt-n` to get started
6. Type in `echo 123` then `Ctrl-Enter` to execute the line
7. Inspect shellbridge.vim for more movement


Getting Involved
================

This simple project is fun. Feel free to ask question or contribute. :)
