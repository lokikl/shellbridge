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

You may get them by `apt-get install nodejs npm` on ubuntu.

My env. is ubuntu 14.04, nodejs 0.10.25 and vim 7.4 p183.


How to install
==============

1. `sudo npm install -g shellbridge`
2. `shellbridge --server` to start the daemon
3. ``echo source `npm root -g`/shellbridge/editors/shellbridge.vim > ~/.vimrc``
4. Start vim with any servername eg. `vim --servername shell`
5. `Alt-n` to initialize the shellbridge interface
6. Insert `echo 123` then `Ctrl-Enter` to execute the line
7. Inspect shellbridge.vim for more movement


Getting Involved
================

This simple project is fun. Feel free to ask question or contribute. :)
