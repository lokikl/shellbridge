shellbridge is a daemon written in javascript, enabling an interactive shell experience inside editors like vim. Inspired by xiki but in a different way.

* Execute arbitrary shell commands in text editors
* Multiple long-lasting commands can be running in parallel
* Interactive commands supported like mysql, redis-cli, ssh and even bash.


Demo on vim
-----------

![alt tag](https://raw.githubusercontent.com/lokikl/shellbridge/master/demo/vim-demo.gif)


Prerequisite
------------

* vim 7.3+ compiled with +client-server option
* newer nodejs

You may get them by `apt-get install nodejs npm vim vim-gnome` on ubuntu.

My env. is ubuntu 14.04, nodejs 0.10.25 and vim 7.4 p183.

For Ubuntu 12.04, please install newer node and npm from PPA and the official installer script.


How to install
--------------

1. `sudo npm install -g shellbridge`
2. `shellbridge --server` to start the daemon
3. ``echo source `npm root -g`/shellbridge/editors/shellbridge.vim >> ~/.vimrc``
4. Start vim with any servername, eg. `vim --servername anyword`
5. `Alt-n` to initialize the shellbridge interface
6. Insert `echo 123` then `Alt-n` to execute the line


Q & A
-----

#### How can I run with root?

`echo <your pwd> | sudo -S bash` will do the trick. For convenient, you could map it in your `~/.shellbridgerc` to have a quick start next time.

#### How can I run the mysql client?

You may start by `mysql -n`. A mapping is shipped in the default shellbridgerc, you should be able to start it by `mysql` only.

#### Can shellbridge be run on editors other than vim?

Sure, in fact shellbridge interact with editors through only 2 commands: insertCmd & editorCmd. shellbridge can talk to everything has these 2 APIs implemented. The first step would be configuring your `~/.shellbridgerc` and hack your favorite editor.

#### Can I change those key mappings in vim?

Yes, every key mapping can be changed. Feel free to add mapping below in your `~/.vimrc`

`let g:shellbridge_init = "<m-n>"`

Available mappings are
`g:shellbridge_init`
`g:shellbridge_exec`
`g:shellbridge_kill`
`g:shellbridge_cleanup`
`g:shellbridge_select`
`g:shellbridge_next`
`g:shellbridge_previous`
`g:shellbridge_sort`
`g:shellbridge_filter`



Updates
-------

#### 0.1.17

* supported performing actions below inside output
** clear
** sort
** filter

#### 0.1.13

* added syntax highlight to ended commands
* revamped the end-to-end architecture

#### 0.1.12

* supported filtering output by `alt f`

#### 0.1.10

* identified lines indented as sub-command, no need to be indented with exactly 2 spaces
* updated default key mappings:
  1. alt n to start/execute
  2. alt s to sort
* showed all key mappings when started

#### 0.1.7

* vim key mappings are now configurable
* optimized vim conceal
* fixed the abnormal highlighting


#### 0.1.3

* Supported multiple line execution and added output buffer

Getting Involved
----------------

This simple project is fun. I enjoy so much working on it. Please feel free to ask/file issue if you got any problem on setup. Any suggestions are welcome. Thanks so much for giving it a try. :)
