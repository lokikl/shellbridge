# shellbridge on vim 7.3/ubuntu 14.04

# caution:
# This is currently not working as I still haven't figured out how to start vim in clientserver inside docker.
# Cuz clientserver need xterm
# It'd be great if any expert can help me on this, really hope it can be demo with docker

# You may build a docker image yourself and run it in a container
# sudo docker build -t myshellbridge .
# sudo docker run -ti myshellbridge /bin/bash

FROM ubuntu
MAINTAINER Loki Ng <dev@lokikl.com>

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y nodejs npm
RUN apt-get install -y xorg-dev libx11-dev libncurses5-dev
RUN apt-get install -y mercurial

RUN hg clone https://vim.googlecode.com/hg/ ~/vim
RUN cd ~/vim; hg pull; hg update
RUN cd ~/vim; ./configure --with-features=huge --disable-largefile --enable-rubyinterp --with-features=huge
RUN cd ~/vim; make; make install

# RUN sudo npm install -g shellbridge@0.1.6

# RUN echo source `npm root -g`/shellbridge/editors/shellbridge.vim > ~/.vimrc

