# shellbridge on vim 7.3/ubuntu 14.04

FROM ubuntu
MAINTAINER Loki Ng <dev@lokikl.com>

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y nodejs npm vim

RUN sudo npm install -g shellbridge

RUN echo source `npm root -g`/shellbridge/editors/shellbridge.vim > ~/.vimrc

