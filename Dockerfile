# shellbridge on vim 7.3/ubuntu 14.04

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

