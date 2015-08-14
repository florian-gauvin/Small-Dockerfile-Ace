# Version 1.0
FROM ubuntu:14.04
MAINTAINER Florian GAUVIN "florian.gauvin@nl.thalesgroup.com"

ENV DEBIAN_FRONTEND noninteractive

#Download all the packages needed 

RUN apt-get update && apt-get install -y \
	git \
	wget \
	unzip \
        && apt-get clean 

#Download and install the latest version of Docker (You need to be the same version to use this Dockerfile)

RUN wget -qO- https://get.docker.com/ | sh

#Prepare the usr directory by downloading in it : the base image, Openjdk8 and Apache Ace

WORKDIR /usr

RUN 	git clone https://github.com/florian-gauvin/rootfs.tar-ace.git && \
	wget http://www.eu.apache.org/dist/ace/apache-ace-2.0.1/apache-ace-2.0.1-bin.zip && \
	unzip apache-ace-2.0.1-bin.zip

#Decompress the base image

WORKDIR /usr/rootfs.tar-ace

RUN tar -xf rootfs.tar &&\
	rm rootfs.tar

# Install etcdctl
RUN cd /tmp \
	&& export ETCDVERSION=v2.0.13 \
	&& curl -k -L https://github.com/coreos/etcd/releases/download/$ETCDVERSION/etcd-$ETCDVERSION-linux-amd64.tar.gz | gunzip | tar xf - \
	&& cp etcd-$ETCDVERSION-linux-amd64/etcdctl /usr/rootfs.tar-ace/bin/

#Add the resources

ADD resources /usr/rootfs.tar-ace/tmp

#Download and add openjdk8 to the base image, then add ace to the base image, finally the base image is complete so we can recompress it

WORKDIR /usr/

RUN	git clone https://github.com/florian-gauvin/openjdk8-compact2.git && \
	cp -r openjdk8-compact2/j2re-compact2-image/ rootfs.tar-ace/usr/ && \
	cp -r /usr/apache-ace-2.0.1-bin /usr/rootfs.tar-ace/usr && \
	cd /usr/rootfs.tar-ace/ && \
	tar -cf rootfs.tar * && \
	mkdir /usr/image && \
	cp rootfs.tar /usr/image && \ 
	cd /usr && \
	rm -fr rootfs.tar-ace apache-ace-2.0.1-bin.zip apache-ace-2.0.1-bin openjdk8-compact2

#When the builder image is launch, it creates the openjdk8 and ace docker image that you will be able to see by running the command : docker images

ENTRYPOINT for i in `seq 0 100`; do sudo mknod -m0660 /dev/loop$i b 7 $i; done && \
	service docker start && \
	docker import - inaetics/ace-agent < /usr/image/rootfs.tar &&\
	/bin/bash

